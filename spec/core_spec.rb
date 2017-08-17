require 'spec_helper'

RSpec.describe ColorLS do
  it 'lists info of a hidden file with --long option' do
    expect { ColorLS::Flags.new('--long', 'spec/fixtures/.hidden-file').process }.to_not output(/No Info/).to_stdout
  end
end
