# frozen_string_literal: true

require 'spec_helper'

# rubocop:todo RSpec/MultipleDescribes

RSpec.describe(ColorLS::HorizontalLayout, '#each_line') do
  subject { described_class.new(array, array.map(&:length), width) }

  context 'when empty' do
    let(:array) { [] }
    let(:width) { 10 }

    it 'does nothing' do
      expect { |b| subject.each_line(&b) }.not_to yield_control
    end
  end

  context 'with one item' do
    first = '1234567890'

    let(:array) { [first] }
    let(:width) { 11 }

    it 'is on a single line' do
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context 'with an item not fitting' do
    first = '1234567890'

    let(:array) { [first] }
    let(:width) { 1 }

    it 'is on a single column' do
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context 'with two items fitting' do
    first = '1234567890'

    let(:array) { [first, 'a'] }
    let(:width) { 100 }

    it 'is on a single line' do
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first, 'a'], [first.size, 1]])
    end
  end

  context 'with three items but place for two' do
    first = '1234567890'

    let(:array) { [first, 'a', first] }
    let(:width) { first.size + 1 }

    it 'is on two lines' do
      max_widths = [first.size, 1]
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first, 'a'], max_widths], [[first], max_widths])
    end
  end
end

RSpec.describe(ColorLS::VerticalLayout, '#each_line') do
  subject { described_class.new(array, array.map(&:length), width) }

  context 'when empty' do
    let(:array) { [] }
    let(:width) { 10 }

    it 'does nothing' do
      expect { |b| subject.each_line(&b) }.not_to yield_control
    end
  end

  context 'with one item' do
    first = '1234567890'

    let(:array) { [first] }
    let(:width) { 11 }

    it 'is on a single line' do
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context 'with an item not fitting' do
    first = '1234567890'

    let(:array) { [first] }
    let(:width) { 1 }

    it 'is on a single column' do
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first], [first.size]])
    end
  end

  context 'with two items fitting' do
    first = '1234567890'

    let(:array) { [first, 'a'] }
    let(:width) { 100 }

    it 'is on a single line' do
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first, 'a'], [first.size, 1]])
    end
  end

  context 'with three items but place for two' do
    first = '1234567890'

    let(:array) { [first, 'a', first] }
    let(:width) { first.size * 2 }

    it 'is on two lines' do
      max_widths = [first.size, first.size]
      expect { |b| subject.each_line(&b) }.to yield_successive_args([[first, first], max_widths], [['a'], max_widths])
    end
  end
end

# rubocop:enable RSpec/MultipleDescribes
