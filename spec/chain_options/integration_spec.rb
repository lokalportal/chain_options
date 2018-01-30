# frozen_string_literal: true

describe ChainOptions::Integration do
  let(:test_class) do
    Class.new do
      include ChainOptions::Integration

      chain_option :duck, default: 'waddle waddle'
      chain_option :number, default: -> { 5.downto(1).inject(:*) }
    end
  end

  let(:instance) { test_class.new }

  describe '#chain_option' do
    it 'defines an instance method with the given name' do
      aggregate_failures do
        expect(instance).to respond_to :duck, :number
      end
    end

    context 'when being called with an argument' do
      it 'returns a new instance of the host class with the new value set' do
        new_instance = instance.duck('quack quack')

        aggregate_failures do
          expect(new_instance).not_to eql instance
          expect(new_instance.duck).to eql 'quack quack'
        end
      end
    end

    context 'when being called without an argument' do
      it 'returns the current option value' do
        aggregate_failures do
          expect(instance.duck).to eql 'waddle waddle'
          expect(instance.number).to eql 5.downto(1).inject(:*)
        end
      end
    end
  end
end
