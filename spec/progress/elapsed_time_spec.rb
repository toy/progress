# frozen_string_literal: true

require 'progress/elapsed_time'

describe Progress::ElapsedTime do
  let(:timeout){ 0.01 }

  describe '.now' do
    it 'returns incrementing value' do
      expect{ sleep timeout }.to change{ described_class.now }.by_at_least(timeout)
    end
  end
end
