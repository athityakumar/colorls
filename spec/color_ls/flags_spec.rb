require 'spec_helper'

RSpec.describe ColorLS::Flags do
  FIXTURES = 'spec/fixtures'.freeze

  subject { capture_stdout { described_class.new(*args).process } }

  def capture_stdout
    old = $stdout
    $stdout = fake = StringIO.new
    yield
    fake.string
  ensure
    $stdout = old
  end

  context 'with no flags' do
    let(:args) { [FIXTURES] }

    it { is_expected.not_to match(/((r|-).*(w|-).*(x|-).*){3}/) } # does not list file info
    it { is_expected.not_to match(/\.hidden-file/) } # does not display hidden files
    it { is_expected.not_to match(/Found \d+ contents/) } # does not show a report
    it { is_expected.to match(/a-file.+symlinks.+z-file/m) } # displays dirs & files alphabetically
    it { is_expected.not_to match(/(.*\n){3}/) } # displays multiple files per line
    it { is_expected.not_to match(%r(\.{1,2}/)) } # does not display ./ or ../
    it { is_expected.not_to match(/├──/) } # does not display file hierarchy
  end

  context 'with --reverse flag' do
    let(:args) { ['--reverse', FIXTURES] }

    it { is_expected.to match(/z-file.+symlinks.+a-file/m) } # displays dirs & files in reverse alphabetical order
  end

  context 'with --long flag & file path' do
    let(:args) { ['--long', "#{FIXTURES}/.hidden-file"] }

    it { is_expected.not_to match(/No Info/) } # lists info of a hidden file
  end

  context 'with --long flag' do
    let(:args) { ['--long', FIXTURES] }

    it { is_expected.to match(/((r|-).*(w|-).*(x|-).*){3}/) } # lists file info
  end

  context 'with --long flag and special bits' do
    let(:args) { ['--long', "#{FIXTURES}/a.txt"] }

    it 'shows special permission bits' do
      fileInfo = instance_double(
        'FileInfo',
        :group => "sys",
        :mtime => Time.now,
        :directory? => false,
        :owner => "user",
        :name => "a.txt",
        :size => 128,
        :symlink? => false,
        :stats => OpenStruct.new(
          mode: 0o444, # read for user, owner, other
          setuid?: true,
          setgid?: true,
          sticky?: true
        )
      )

      allow(ColorLS::FileInfo).to receive(:new).with("#{FIXTURES}/a.txt", true) { fileInfo }

      is_expected.to match(/r-Sr-Sr-T  \s+  user  \s+  sys  .*  a.txt/mx)
    end
  end

  context 'with --long flag on windows' do
    let(:args) { ['--long', "#{FIXTURES}/a.txt"] }

    before {
      ColorLS::FileInfo.class_variable_set :@@users, {}
      ColorLS::FileInfo.class_variable_set :@@groups, {}
    }

    it 'returns no user / group info' do
      expect(::Etc).to receive(:getpwuid).and_return(nil)
      expect(::Etc).to receive(:getgrgid).and_return(nil)

      is_expected.to match(/\s+  \d+  \s+  \d+  .*  a.txt/mx)
    end
  end

  context 'with --all flag' do
    let(:args) { ['--all', FIXTURES] }

    it { is_expected.to match(/\.hidden-file/) } # lists hidden files
  end

  context 'with --sort-dirs flag' do
    let(:args) { ['--sort-dirs', FIXTURES] }

    it { is_expected.to match(/symlinks.+a-file.+z-file/m) } # sorts results alphabetically, directories first
  end

  context 'with --sort-files flag' do
    let(:args) { ['--sort-files', FIXTURES] }

    it { is_expected.to match(/a-file.+z-file.+symlinks/m) } # sorts results alphabetically, files first
  end

  context 'with --sort=time' do
    entries = Dir.entries(FIXTURES).grep(/^[^.]/).shuffle.freeze
    mtime = Time.new(2017, 11, 7, 2, 2, 2).freeze

    files = entries.each_with_index do |e, i|
      t = mtime + i
      File.utime(t, t, File.join(FIXTURES, e))
      Regexp.quote(e)
    end

    expected = Regexp.new files.reverse.join('.+'), Regexp::MULTILINE

    let(:args) { ['--sort=time', FIXTURES] }

    it { is_expected.to match(expected) }
  end

  context 'with --sort=size flag' do
    let(:args) { ['--sort=size', FIXTURES] }

    it { is_expected.to match(/a-file.+z-file.+symlinks/) } # sorts results by size
  end

  context 'with --sort=extension flag' do
    let(:args) { ['--sort=extension', FIXTURES] }

    it { is_expected.to match(/a-file.+symlinks.+z-file.+a.md.+a.txt.+z.txt/m) } # sorts results by extension
  end

  context 'with --dirs flag' do
    let(:args) { ['--dirs', FIXTURES] }

    it { is_expected.not_to match(/a-file/) } # displays dirs only
  end

  context 'with --files flag' do
    let(:args) { ['--files', FIXTURES] }

    it { is_expected.not_to match(/symlinks/) } # displays files only
  end

  context 'with -1 flag' do
    let(:args) { ['-1', FIXTURES] }

    it { is_expected.to match(/(.*\n){3}/) } # displays one file per line
  end

  context 'with --almost-all flag' do
    let(:args) { ['--almost-all', FIXTURES] }

    it { is_expected.to match(/\.hidden-file/) } # displays hidden files
  end

  context 'with --tree flag' do
    let(:args) { ['--tree', FIXTURES] }

    it { is_expected.to match(/├──/) } # displays file hierarchy
  end

  context 'with --hyperlink flag' do
    let(:args) { ['--hyperlink', FIXTURES] }

    href = "file://#{File.absolute_path(FIXTURES)}/a.txt"

    it { is_expected.to match(href) }
  end

  context 'symlinked directory' do
    let(:args) { [File.join(FIXTURES, 'symlinks', 'Supportlink')] }

    it { is_expected.to match(/Supportlink/) }
  end

  context 'symlinked directory with trailing separator' do
    let(:args) { [File.join(FIXTURES, 'symlinks', 'Supportlink', File::SEPARATOR)] }

    it { is_expected.to match(/yaml_sort_checker.rb/) }
  end

  context 'when passing invalid flags' do
    let(:args) { ['--snafu'] }

    it 'should issue a warning, hint about `--help` and exit' do
      allow(::Kernel).to receive(:warn) do |message|
        expect(message).to match "--snafu"
      end

      expect { subject }.to raise_error(SystemExit).and output(/--help/).to_stderr
    end
  end
end
