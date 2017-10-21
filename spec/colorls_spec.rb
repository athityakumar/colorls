require 'spec_helper'

RSpec.describe ColorLS do
  FIXTURES = 'spec/fixtures'.freeze

  it 'has a version number' do
    expect(ColorLS::VERSION).not_to be nil
  end

  it 'lists info of a hidden file with --long option' do
    expect { ColorLS::Flags.new('--long', "#{FIXTURES}/.hidden-file").process }.to_not output(/No Info/).to_stdout
  end

  it 'does not list hidden files without --all option' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(/\.hidden-file/).to_stdout
  end

  it 'lists hidden files with --all option' do
    expect { ColorLS::Flags.new('--all', FIXTURES).process }.to output(/\.hidden-file/).to_stdout
  end

  it 'does not show a report without --report option' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(/Found \d+ contents/).to_stdout
  end

  it 'shows a report with --report option' do
    expect { ColorLS::Flags.new('--report', FIXTURES).process }.to output(/Found \d+ contents/).to_stdout
  end
end
