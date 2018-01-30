# frozen_string_literal: true

describe ChainOptions::Option do
  subject { described_class.new(options) }
  let(:options) { {} }

  describe '#new_value' do
    context 'given the option is incremental' do
      before(:each) { options[:incremental] = true }

      it 'concats values in an array' do
        subject.new_value([4])
        expect(subject.current_value).to eql([[4]])
        expect(subject.new_value([2, 3])).to eql([[4], [2, 3]])
      end
    end
  end
end
