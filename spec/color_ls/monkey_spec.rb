require 'colorls/monkeys'

RSpec.describe String, '#uniq' do
 it 'removes all duplicate characters' do
   expect('abca'.uniq).to be == 'abc'
 end
end

RSpec.describe String, '#colorize' do
  it 'colors a string with red' do
    expect('hello'.colorize(:red)).to be == Rainbow('hello').red
  end
end
