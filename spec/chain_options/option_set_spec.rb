# frozen_string_literal: true

describe ChainOptions::OptionSet, type: :model do

  let(:test_class) do
    Class.new do
      def no_number_5(value_or_collection)
        value_or_collection.is_a?(Array) ? !value_or_collection.include?(5) : value_or_collection != 5
      end

      def even_numbers(value)
        value.even?
      end
    end
  end

  let(:option_set) { described_class.new(test_class.new, chain_options, values) }

  #----------------------------------------------------------------
  #                        #current_value
  #----------------------------------------------------------------

  describe '#current_value' do
    let(:chain_options) { {test_option: {default: 42}} }

    context 'when a custom value was set' do
      let(:values) { {test_option: 23} }
      it 'returns the custom value' do
        expect(option_set.current_value(:test_option)).to eql 23
      end
    end

    context 'when no custom value was set' do
      let(:values) { {} }
      it 'returns the default value' do
        expect(option_set.current_value(:test_option)).to eql 42
      end
    end
  end

  #----------------------------------------------------------------
  #                          #new_value
  #----------------------------------------------------------------

  describe '#new_value' do
    let(:values) { {} }

    context 'when a transformation was given' do
      context 'as a symbol' do
        let(:chain_options) { {test_option: {transform: :to_s}} }

        it 'calls the symbol as method on each element in the given value' do
          expect(option_set.new_value(:test_option, 4, 5)).to eql %w[4 5]
        end

        it 'does not return a collection unless a collection was given' do
          aggregate_failures do
            expect(option_set.new_value(:test_option, 42)).to eql '42'
            expect(option_set.new_value(:test_option, [42])).to eql ['42']
          end
        end
      end

      context 'as a proc' do
        let(:chain_options) { {test_option: {transform: ->(v) { v + 1 }}} }

        it 'passes each element in the given value to the proc' do
          expect(option_set.new_value(:test_option, 1, 2)).to eql [2, 3]
        end
      end
    end

    context 'when a validation was set up' do
      shared_examples 'validation execution' do
        context 'and `:invalid` is set to `:default`' do
          let(:chain_options) { {numbers: {validate: validation, invalid: :default, default: 666}} }

          it 'returns the default value if the given value is not valid' do
            aggregate_failures do
              expect(option_set.new_value(:numbers, 1, 2, 3, 4)).to eql [1, 2, 3, 4]
              expect(option_set.new_value(:numbers, 5)).to eql 666
              expect(option_set.new_value(:numbers, 1, 2, 3, 4, 5)).to eql 666
            end
          end
        end

        context 'and `:invalid` is set to `:raise`' do
          let(:chain_options) { {numbers: {validate: validation, invalid: :raise}} }

          it 'raises an ArgumentError if the value is not valid' do
            aggregate_failures do
              expect(option_set.new_value(:numbers, 1, 2, 3, 4)).to eql [1, 2, 3, 4]
              expect { option_set.new_value(:numbers, 5) }.to raise_error ArgumentError, /not valid/
              expect { option_set.new_value(:numbers, 1, 2, 3, 4, 5) }.to raise_error ArgumentError, /not valid/
            end
          end
        end
      end

      context 'using a symbol' do
        let(:validation) { :no_number_5 }
        include_examples 'validation execution'
      end

      context 'using a proc' do
        let(:validation) { ->(value) { value.is_a?(Array) ? !value.include?(5) : value != 5 } }
        include_examples 'validation execution'
      end
    end

    context 'when a filter was set up' do
      let(:chain_options) { {numbers: {filter: filter}} }

      context 'as a symbol' do
        let(:filter) { :even_numbers }

        it 'only sets the matching elements as new value' do
          aggregate_failures do
            expect(option_set.new_value(:numbers, 1, 2, 3, 4)).to eql [2, 4]
            expect(option_set.new_value(:numbers, 1)).to eql []
          end
        end
      end

      context 'as a proc' do
        let(:filter) { ->(value) { value.even? } }

        it 'only sets the matching elements as new value' do
          aggregate_failures do
            expect(option_set.new_value(:numbers, 1, 2, 3, 4)).to eql [2, 4]
            expect(option_set.new_value(:numbers, 1)).to eql []
          end
        end
      end
    end

    context 'when the option was set to `incremental`' do
      let(:chain_options) { {test_option: {incremental: true, default: [[1, 2, 3]]}} }

      context 'and a custom value was already set up' do
        let(:values) { {test_option: [[3, 2, 1]]} }

        it 'appends the new value to the existing value' do
          aggregate_failures do
            expect(option_set.new_value(:test_option, 4, 5, 6)).to eql [[3, 2, 1], [4, 5, 6]]
            expect(option_set.new_value(:test_option, 4)).to eql [[3, 2, 1], [4]]
          end
        end
      end

      context 'and no value was set up yet' do
        let(:values) { {} }

        it 'keeps the given value in a 2D array' do
          aggregate_failures do
            expect(option_set.new_value(:test_option, 4, 5, 6)).to eql [[4, 5, 6]]
            expect(option_set.new_value(:test_option, 4)).to eql [[4]]
          end
        end
      end
    end

    context 'when an option is set to allow blocks' do
      let(:chain_options) { {procs: {allow_block: true}} }
      let(:values) { {} }

      it 'saves the blocks as proc objects' do
        aggregate_failures do
          expect(option_set.new_value(:procs, &:__id__)).to be_a_kind_of Proc
          expect(option_set.new_value(:procs, -> { 42 })).to be_a_kind_of Proc
        end
      end
    end
  end
end
