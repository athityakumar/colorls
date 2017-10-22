require 'spec_helper'

RSpec.describe ColorLS::Flags do
  FIXTURES = 'spec/fixtures'.freeze

  subject { ColorLS::Flags.new(*args).process }

  context 'with no flags' do
    let(:args) { [FIXTURES] }

    it { is_expected.to_not output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout } # does not list file info
    it { is_expected.to_not output(/\.hidden-file/).to_stdout } # does not list hidden files
    it { is_expected.to_not output(/Found \d+ contents/).to_stdout } # does not show a report
    it { is_expected.to output(/a-file.+symlinks.+z-file/).to_stdout } # sorts all results alphabetically
    it { is_expected.to output(/a-file.+symlinks/).to_stdout } # displays dirs & files
    it { is_expected.to_not output(/(.*\n){3}/).to_stdout } # displays multiple files per line
    it { is_expected.to_not output(/\.hidden-file/).to_stdout } # does not display hidden files
    it { is_expected.to_not output(%r(\.{1,2}/)).to_stdout } # does not display ./ or ../
    it { is_expected.to_not output(/├──/).to_stdout } # does not display file hierarchy
  end

  context 'with --long flag & file path' do
    let(:args) { ['--long', "#{FIXTURES}/.hidden-file"] }

    it { is_expected.to_not output(/No Info/).to_stdout } # lists info of a hidden file
  end

  context 'with --long flag' do
    let(:args) { ['--long', FIXTURES] }

    it { is_expected.to output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout } # lists file info
  end

  context 'with --all flag' do
    let(:args) { ['--all', FIXTURES] }

    it { is_expected.to output(/\.hidden-file/).to_stdout } # lists hidden files
  end

  context 'with --sort-dirs flag' do
    let(:args) { ['--sort-dirs', FIXTURES] }

    it { is_expected.to output(/symlinks.+a-file.+z-file/).to_stdout } # sorts results alphabetically, directories first
  end

  context 'with --sort-files flag' do
    let(:args) { ['--sort-files', FIXTURES] }

    it { is_expected.to output(/a-file.+z-file.+symlinks/).to_stdout } # sorts results alphabetically, files first
  end

  context 'with --dirs flag' do
    let(:args) { ['--dirs', FIXTURES] }

    it { is_expected.to_not output(/a-file/).to_stdout } # displays dirs only
  end

  context 'with --files flag' do
    let(:args) { ['--files', FIXTURES] }

    it { is_expected.to_not output(/symlinks/).to_stdout } # displays files only
  end

  context 'with -1 flag' do
    let(:args) { ['-1', FIXTURES] }

    it { is_expected.to output(/(.*\n){3}/).to_stdout } # displays one file per line
  end

  context 'with --almost-all flag' do
    let(:args) { ['--almost-all', FIXTURES] }

    it { is_expected.to output(/\.hidden-file/).to_stdout } # displays hidden files
  end

  context 'with --tree flag' do
    let(:args) { ['--tree', FIXTURES] }

    it { is_expected.to output(/├──/).to_stdout } # displays file hierarchy
  end
end
