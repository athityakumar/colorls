# frozen_string_literal: true

require 'colorls/monkeys'

RSpec.describe String do # rubocop:disable RSpec/FilePath
  describe '#uniq' do
    it 'removes all duplicate characters' do
      expect('abca'.uniq).to be == 'abc'
    end
  end

  describe String, '#colorize' do
    it 'colors a string with red' do
      expect('hello'.colorize(:red)).to be == Rainbow('hello').red
    end
  end
end
