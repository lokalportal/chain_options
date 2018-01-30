# frozen_string_literal: true

describe ChainOptions::Builder do
  let(:test_class) do
    Class.new do
      include ChainOptions::Integration

      chain_option :duck, default: 'waddle waddle'
      chain_option :time, default: -> { Time.zone.now }
      chain_option :blockable, default: nil, allow_block: true
    end
  end

  describe '#new' do
    it 'executes the given block, allowing setting options with `set`' do
      instance = test_class.new.build_options do
        set :duck, 'quack quack'
        set :time, Time.at(0)
        set(:blockable) do
          'I am from a block! Yay!'
        end
      end

      aggregate_failures do
        expect(instance.duck).to eql 'quack quack'
        expect(instance.time).to eql Time.at(0)
        expect(instance.blockable.call).to eql 'I am from a block! Yay!'
      end
    end

    it 'makes outer methods available in the executed block' do
      def outer_method
        'I am out!'
      end

      instance = test_class.new.build_options do
        set :duck, outer_method
      end

      expect(instance.duck).to eql outer_method
    end
  end
end
