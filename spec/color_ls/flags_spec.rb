# coding: utf-8
require 'spec_helper'

RSpec.describe ColorLS::Flags do
  FIXTURES = 'spec/fixtures'.freeze

  subject do
    begin
      described_class.new(*args).process
    rescue SystemExit => e
      raise "colorls exited with #{e.status}" unless e.success?
    end
  end

  context 'with no flags' do
    let(:args) { [FIXTURES] }

    it('does not list file info')              { expect { subject }.not_to output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout }
    it('does not display hidden files')        { expect { subject }.not_to output(/\.hidden-file/).to_stdout }
    it('does not show a report')               { expect { subject }.not_to output(/Found \d+ contents/).to_stdout }
    it('displays dirs & files alphabetically') { expect { subject }.to output(/a-file.+symlinks.+z-file/m).to_stdout }

    it 'displays multiple files per line' do
      expect(::STDOUT).to receive(:tty?).and_return(true)

      expect { subject }.not_to output(/(.*\n){3}/).to_stdout
    end

    it('does not display ./ or ../')           { expect { subject }.not_to output(%r(\.{1,2}/)).to_stdout }
    it('does not display file hierarchy')      { expect { subject }.not_to output(/├──/).to_stdout }
  end

  context 'with --reverse flag' do
    let(:args) { ['--reverse', '-x', FIXTURES] }

    it('displays dirs & files in reverse alphabetical order') { expect { subject }.to output(/z-file.+symlinks.+a-file/m).to_stdout }
  end

  context 'with --format flag' do
    let(:args) { ['--format=single-column', FIXTURES] }

    it { expect { subject }.to output(/.*a-file.*\n # on the first line
                                       (?m:.*)      # more lines...
                                       .*z-file.*\n # on the last line
                                      /x).to_stdout }
  end

  context 'with --long flag & file path' do
    let(:args) { ['--long', "#{FIXTURES}/.hidden-file"] }

    it('lists info of a hidden file') { expect { subject }.not_to output(/No Info/).to_stdout }
  end

  context 'with --long flag' do
    let(:args) { ['--long', FIXTURES] }

    it('lists file info') { expect { subject }.to output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout }
  end

  context 'with --long flag for `a.txt`' do
    let(:args) { ['--long', "#{FIXTURES}/a.txt"] }

    it 'shows special permission bits' do
      fileInfo = instance_double(
        'FileInfo',
        :group => "sys",
        :mtime => Time.now,
        :directory? => false,
        :owner => "user",
        :name => "a.txt",
        :show => "a.txt",
        :nlink => 1,
        :size => 128,
        :blockdev? => false,
        :chardev? => false,
        :socket? => false,
        :symlink? => false,
        :stats => OpenStruct.new(
          mode: 0o444, # read for user, owner, other
          setuid?: true,
          setgid?: true,
          sticky?: true
        )
      )

      allow(ColorLS::FileInfo).to receive(:new).with("#{FIXTURES}/a.txt", link_info: true) { fileInfo }

      expect { subject }.to output(/r-Sr-Sr-T  .*  a.txt/mx).to_stdout
    end

    it 'shows number of hardlinks' do
      fileInfo = instance_double(
        'FileInfo',
        :group => "sys",
        :mtime => Time.now,
        :directory? => false,
        :owner => "user",
        :name => "a.txt",
        :show => "a.txt",
        :nlink => 5, # number of hardlinks
        :size => 128,
        :blockdev? => false,
        :chardev? => false,
        :socket? => false,
        :symlink? => false,
        :stats => OpenStruct.new(
          mode: 0o444, # read for user, owner, other
          setuid?: true,
          setgid?: true,
          sticky?: true
        )
      )

      allow(ColorLS::FileInfo).to receive(:new).with("#{FIXTURES}/a.txt", link_info: true) { fileInfo }

      expect { subject }.to output(/\S+\s+ 5 .*  a.txt/mx).to_stdout
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

      expect { subject }.to output(/\s+  \d+  \s+  \d+  .*  a.txt/mx).to_stdout
    end
  end

  context 'with --all flag' do
    let(:args) { ['--all', FIXTURES] }

    it('lists hidden files') { expect { subject }.to output(/\.hidden-file/).to_stdout }
  end

  context 'with --sort-dirs flag' do
    let(:args) { ['--sort-dirs', '-1', FIXTURES] }

    it('sorts results alphabetically, directories first') { expect { subject }.to output(/symlinks.+a-file.+z-file/m).to_stdout }
  end

  context 'with --sort-files flag' do
    let(:args) { ['--sort-files', '-1', FIXTURES] }

    it('sorts results alphabetically, files first') { expect { subject }.to output(/a-file.+z-file.+symlinks/m).to_stdout }
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

    let(:args) { ['--sort=time', '-x', FIXTURES] }

    it { expect { subject }.to output(expected).to_stdout }
  end

  context 'with --sort=size flag' do
    let(:args) { ['--sort=size', '--group-directories-first', '-1', FIXTURES] }

    it 'sorts results by size' do
      expect(::STDOUT).to receive(:tty?).and_return(true)

      expect { subject }.to output(/symlinks.+a-file.+z-file/m).to_stdout
    end
  end

  context 'with --help flag' do
    let(:args) { ['--help', FIXTURES] }

    it { expect { subject }.to output(/prints this help/).to_stdout }
  end

  context 'with -h flag only' do
    let(:args) { ['-h'] }

    it { expect { subject }.to output(/prints this help/).to_stdout }
  end

  context 'with -h and additional argument' do
    let(:args) { ['-h', FIXTURES] }

    it { expect { subject }.to output(/a-file/).to_stdout }
  end

  context 'with -h and additional options' do
    let(:args) { ['-ht'] }

    it { expect { subject }.not_to output(/show this help/).to_stdout }
  end

  context 'with --human-readable flag' do
    let(:args) { ['--human-readable', FIXTURES] }

    it { expect { subject }.to output(/a-file/).to_stdout }
  end

  context 'with --sort=extension flag' do
    let(:args) { ['--sort=extension', '-1', FIXTURES] }

    it('sorts results by extension') { expect { subject }.to output(/a-file.+symlinks.+z-file.+a.md.+a.txt.+z.txt/m).to_stdout }
  end

  context 'with --dirs flag' do
    let(:args) { ['--dirs', FIXTURES] }

    it('displays dirs only') { expect { subject }.not_to output(/a-file/).to_stdout }
  end

  context 'with --files flag' do
    let(:args) { ['--files', FIXTURES] }

    it('displays files only') { expect { subject }.not_to output(/symlinks/).to_stdout }
  end

  context 'with -1 flag' do
    let(:args) { ['-1', FIXTURES] }

    it('displays one file per line') { expect { subject }.to output(/(.*\n){3}/).to_stdout }
  end

  context 'with --almost-all flag' do
    let(:args) { ['--almost-all', FIXTURES] }

    it('displays hidden files') { expect { subject }.to output(/\.hidden-file/).to_stdout }
  end

  context 'with --tree flag' do
    let(:args) { ['--tree', FIXTURES] }

    it('displays file hierarchy') { expect { subject }.to output(/├──/).to_stdout }
    it { expect { subject }.to output(/third-level-file.txt/).to_stdout }
  end

  context 'with --tree=1 flag' do
    let(:args) { ['--tree=1', FIXTURES] }

    it('displays file hierarchy') { expect { subject }.to output(/├──/).to_stdout }
    it { expect { subject }.not_to output(/ReadmeLink.md|Supportlink|doesnotexisttest.txt|third-level-file.txt/).to_stdout }
  end

  context 'with --tree=3 flag' do
    let(:args) { ['--tree=3', FIXTURES] }

    it('displays file hierarchy') { expect { subject }.to output(/├──/).to_stdout }
    it { expect { subject }.to output(/third-level-file.txt/).to_stdout }
  end

  context 'with --hyperlink flag' do
    let(:args) { ['--hyperlink', FIXTURES] }

    href = "file://#{File.absolute_path(FIXTURES)}/a.txt"

    it { expect { subject }.to output(include(href)).to_stdout }
  end

  context 'symlinked directory' do
    let(:args) { ['-x', File.join(FIXTURES, 'symlinks', 'Supportlink')] }

    it { expect { subject }.to output(/Supportlink/).to_stdout }
  end

  context 'symlinked directory with trailing separator' do
    let(:args) { ['-x', File.join(FIXTURES, 'symlinks', 'Supportlink', File::SEPARATOR)] }

    it { expect { subject }.to output(/yaml_sort_checker.rb/).to_stdout }
  end

  context 'when passing invalid flags' do
    let(:args) { ['--snafu'] }

    it 'should issue a warning, hint about `--help` and exit' do
      allow(::Kernel).to receive(:warn) do |message|
        expect(message).to output "--snafu"
      end

      expect { subject }.to raise_error('colorls exited with 2').and output(/--help/).to_stderr
    end
  end

  context 'for invalid locale' do
    let(:args) { [FIXTURES] }

    it 'should warn but not raise an error' do
      allow(CLocale).to receive(:setlocale).with(CLocale::LC_COLLATE, '').and_raise(RuntimeError.new("setlocale error"))

      expect { subject }.to output(/setlocale error/).to_stderr.and output.to_stdout
    end
  end

  context 'with unrecognized files' do
    let(:args) { ['--report', FIXTURES] }

    it 'should show a report with unrecognized files' do
      expect { subject }.to output(/Unrecognized files\s+: 3/).to_stdout
    end
  end

  context 'with not exist path' do
    let(:args) { ['not_exist_file'] }

    it 'should exit with status code 2' do
      expect {subject}.to output(/   Specified path 'not_exist_file' doesn't exist./).to_stderr
      expect(subject).to eq 2
    end
  end
end
