require 'spec_helper'

RSpec.describe ColorLS do
  FIXTURES = 'spec/fixtures'.freeze

  it 'has a version number' do
    expect(ColorLS::VERSION).not_to be nil
  end

  it 'lists info of a hidden file with --long option' do
    expect { ColorLS::Flags.new('--long', "#{FIXTURES}/.hidden-file").process }.to_not output(/No Info/).to_stdout
  end

  it 'does not list file info without --long' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout
  end

  it 'lists file info with --long' do
    expect { ColorLS::Flags.new('--long', FIXTURES).process }.to output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout
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

  it 'sorts all results alphabetically without --sort-dirs or --sort-files' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to output(/a-file.+symlinks.+z-file/).to_stdout
  end

  it 'sorts results alphabetically, directories first with --sort-dirs' do
    expect { ColorLS::Flags.new('--sort-dirs', FIXTURES).process }.to output(/symlinks.+a-file.+z-file/).to_stdout
  end

  it 'sorts results alphabetically, files first with --sort-files' do
    expect { ColorLS::Flags.new('--sort-files', FIXTURES).process }.to output(/a-file.+z-file.+symlinks/).to_stdout
  end

  it 'displays dirs & files without --dirs or --files' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to output(/a-file.+symlinks/).to_stdout
  end

  it 'displays dirs only with --dirs' do
    expect { ColorLS::Flags.new('--dirs', FIXTURES).process }.to_not output(/a-file/).to_stdout
  end

  it 'displays files only with --files' do
    expect { ColorLS::Flags.new('--files', FIXTURES).process }.to_not output(/symlinks/).to_stdout
  end

  it 'displays multiple files per line without -1' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(/(.*\n){3}/).to_stdout
  end

  it 'displays one file per line with -1' do
    expect { ColorLS::Flags.new('-1', FIXTURES).process }.to output(/(.*\n){3}/).to_stdout
  end

  it 'does not display hidden files without --almost-all' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(/\.hidden-file/).to_stdout
  end

  it 'displays hidden files with --almost-all' do
    expect { ColorLS::Flags.new('--almost-all', FIXTURES).process }.to output(/\.hidden-file/).to_stdout
  end

  it 'does not display ./ or ../ with --almost-all' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(%r(\.{1,2}/)).to_stdout
  end

  it 'does not display file hierarchy without --tree' do
    expect { ColorLS::Flags.new(FIXTURES).process }.to_not output(/├──/).to_stdout
  end

  it 'displays file hierarchy with --tree' do
    expect { ColorLS::Flags.new('--tree', FIXTURES).process }.to output(/├──/).to_stdout
  end
end
