# frozen_string_literal: true

require 'rspec/expectations'

#
# Custom matcher to test for chain option behaviour.
#
# Every matcher call starts with `have_chain_option` which ensures the the given
# object actually has access to a chain option with the given name.
#
# ## Value Acceptance
#
# To test for values which should raise an exception when being set as a chain option value,
# continue the matcher as follows:
#   it { is_expected.to have_chain_option(:my_option).which_takes(42).and_raises_an_exception }
#
# ## Value Filters / Transformations
#
# To test whether the option is actually set to the correct value after passing an object to it,
# continue the matcher as follows:
#   it { is_expected.to have_chain_option(:my_option).which_takes(42).and_sets_it_as_value }
#
# If you expect the option to perform a filtering and/or transformation, you can also
# specify the actual value you expect to be set:
#   it { is_expected.to have_chain_option(:my_option).which_takes(42).and_sets("42").as_value }
#
# ## Default Value
#
# To test whether the option has a certain default value, continue the matcher as follows:
#   it { is_expected.to have_chain_option(:my_option).with_the_default_value(21) }
#
module ChainOptions
  module TestIntegration
    module Rspec
      extend ::RSpec::Matchers::DSL

      matcher :have_chain_option do |option_name|
        match do |instance|
          unless chain_option?(instance)
            error_lines "Expected the class `#{instance.class}`",
                        "to define the chain option `:#{option_name}`,",
                        "but it didn't."
            next false
          end

          if instance_variable_defined?('@expected_default_value')
            next false unless correct_default_value?(instance)
          end

          if instance_variable_defined?('@given_value')
            if @exception_expected
              check_for_exception(instance)
            elsif instance_variable_defined?('@expected_value')
              check_for_expected_value(instance)
            end
          end

          @error.nil?
        end

        def error_lines(*lines)
          @error = lines[1..-1].reduce(lines.first) do |error_string, line|
            error_string + "\n  #{line}"
          end
        end

        define_method :chain_option? do |instance|
          instance.class.available_chain_options.key?(option_name.to_sym)
        end

        define_method :correct_default_value? do |instance|
          actual_default_value = instance.send(option_name)
          next true if actual_default_value == @expected_default_value

          error_lines "Expected the chain option `:#{option_name}`",
                      "of the class `#{instance.class}`",
                      "to have the default value `#{@expected_default_value.inspect}`",
                      "but the actual default value is `#{actual_default_value.inspect}`"
        end

        define_method :check_for_exception do |instance|
          begin
            instance.send(option_name, @given_value)
            error_lines "Expected the chain option `:#{option_name}`",
                        "not to accept the value `#{@given_value.inspect}`,",
                        'but it did.'
          rescue ArgumentError => e
            unless e.message.include?('not valid')
              error_lines "Expected the chain option `:#{option_name}`",
                          "of the class `#{instance.class}`",
                          "to raise a corresponding Exception when given the value `#{@given_value.inspect}`",
                          "but instead `#{e}` was raised."
            end
          end
        end

        define_method :check_for_expected_value do |instance|
          begin
            actual_value = instance.send(option_name, @given_value).send(option_name)
            if actual_value != @expected_value
              error_lines "Expected the chain option `:#{option_name}`",
                          "of the class `#{instance.class}`",
                          "to accept the value `#{@given_value.inspect}`",
                          "and set the option value to `#{@expected_value.inspect}`,",
                          "but it was set to `#{actual_value.inspect}`"
            end
          rescue ArgumentError => e
            raise unless e.message.include?('not valid')

            error_lines "Expected the chain option `:#{option_name}`",
                        "of the class `#{instance.class}`,",
                        "but it didn't."
          end
        end

        chain :with_the_default_value do |expected_default_value|
          @expected_default_value = expected_default_value
        end

        chain :which_takes do |value|
          @given_value = value
        end

        chain :and_sets do |expected_value|
          @expected_value = expected_value
        end

        chain :and_sets_it_as_value do
          @expected_value = @given_value
        end

        chain :and_raises_an_exception do
          @exception_expected = true
        end

        chain(:as_value) {}

        failure_message do
          @error.to_s
        end
      end
    end
  end
end
