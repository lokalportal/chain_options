# frozen_string_literal: true

require 'chain_options/test_integration/rspec'
require 'rspec/matchers/fail_matchers'

describe ChainOptions::TestIntegration::Rspec do
  include RSpec::Matchers::FailMatchers
  include ChainOptions::TestIntegration::Rspec

  let(:test_class) do
    Class.new do
      include ChainOptions::Integration

      chain_option :duck, default: 'waddle waddle', transform: :to_s
      chain_option :superduck, validate: -> (value) { value == 'fly' }, invalid: :raise
    end
  end

  subject { test_class.new }

  def passes(&block)
    expect(&block).not_to raise_error
  end

  def fails(error_message, &block)
    expect(&block).to fail_with(error_message)
  end

  describe '.have_chain_option' do
    context 'if the given instance has a corresponding chain option' do
      it { passes { is_expected.to have_chain_option(:duck) } }
    end

    context 'if the given instance does not have a corresponding chain option' do
      it { fails(/to define the chain option `:goose`/) { is_expected.to have_chain_option(:goose) } }
    end

    describe '.which_takes' do
      describe '.and_raises_an_exception' do
        let(:matcher_call) do
          -> { is_expected.to have_chain_option(:superduck).which_takes(given_value).and_raises_an_exception }
        end

        context 'if the option raises an exception on an invalid value' do
          let(:given_value) { 'walk' }

          it { passes(&matcher_call) }
        end

        context 'if the option does not raise an exception on an invalid value' do
          let(:given_value) { 'fly' }

          it { fails(/not to accept the value/, &matcher_call) }
        end

        context 'if a different exception is raised' do

        end
      end

      describe '.and_sets_it_as_value' do
        let(:matcher_call) do
          -> { is_expected.to have_chain_option(:duck).which_takes(given_value).and_sets_it_as_value }
        end

        context 'if the given value is actually set as option value' do
          let(:given_value) { '*eats bread*' }

          it { passes(&matcher_call) }
        end

        context 'if another value is set as option value' do
          let(:given_value) { :eats_bread }

          it { fails(/but it was set to/, &matcher_call) }
        end
      end

      describe '.and_sets' do
        let(:matcher_call) do
          -> { is_expected.to have_chain_option(:duck).which_takes(given_value).and_sets(given_value).as_value }
        end

        context 'if the given value is actually set' do
          let(:given_value) { '*eats bread*' }

          it { passes(&matcher_call) }
        end

        context 'if a different value is set instead' do
          let(:given_value) { :eats_bread }

          it { fails(/but it was set to/, &matcher_call) }
        end
      end
    end

    describe '.with_the_default_value' do
      let(:matcher_call) do
        -> { is_expected.to have_chain_option(:duck).with_the_default_value(expected_default_value) }
      end

      context 'if the default value matches the given one' do
        let(:expected_default_value) { 'waddle waddle' }

        it { passes(&matcher_call) }
      end

      context 'if the default value does not match the given one' do
        let(:expected_default_value) { 'fly fly' }

        it { fails(/to have the default value/, &matcher_call) }
      end
    end
  end
end
