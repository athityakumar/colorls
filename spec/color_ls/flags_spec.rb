# frozen_string_literal: true

require 'spec_helper'

FIXTURES = 'spec/fixtures'

RSpec.describe ColorLS::Flags do
  subject do
    described_class.new(*args).process
  rescue SystemExit => e
    raise "colorls exited with #{e.status}" unless e.success?
  end

  let(:a_txt_file_info) do
    instance_double(
      ColorLS::FileInfo,
      group: 'sys',
      mtime: Time.now,
      directory?: false,
      owner: 'user',
      name: 'a.txt',
      show: 'a.txt',
      nlink: 1,
      size: 128,
      blockdev?: false,
      chardev?: false,
      socket?: false,
      symlink?: false,
      hidden?: false,
      stats: instance_double(File::Stat,
                             mode: 0o444, # read for user, owner, other
                             setuid?: true,
                             setgid?: true,
                             sticky?: true),
      executable?: false
    )
  end

  before(:each, :use_file_info_stub) do
    allow(ColorLS::FileInfo).to receive(:new).with(
      path: File.join(FIXTURES, 'a.txt'),
      parent: FIXTURES,
      name: 'a.txt',
      link_info: true,
      show_filepath: true
    ) { a_txt_file_info }
  end

  context 'with no flags' do
    let(:args) { [FIXTURES] }

    it('does not list file info') {
      expect do
        subject
      end.not_to output(/((r|-).*(w|-).*(x|-).*){3}/).to_stdout
    }

    it('does not display hidden files')         { expect { subject }.not_to output(/\.hidden-file/).to_stdout }
    it('displays dirs & files alphabetically')  { expect { subject }.to output(/a-file.+symlinks.+z-file/m).to_stdout }

    it 'does not show a report' do
      expect { subject }.not_to output(/(Found \d+ items in total\.)|(Folders: \d+, Files: \d+\.)/).to_stdout
    end

    it 'displays multiple files per line' do
      allow($stdout).to receive(:tty?).and_return(true)

      expect { subject }.not_to output(/(.*\n){4}/).to_stdout
    end

    it('does not display ./ or ../')           { expect { subject }.not_to output(%r(\.{1,2}/)).to_stdout }
    it('does not display file hierarchy')      { expect { subject }.not_to output(/├──/).to_stdout }
  end

  context 'with --reverse flag' do
    let(:args) { ['--reverse', '-x', FIXTURES] }

    it('displays dirs & files in reverse alphabetical order') {
      expect do
        subject
      end.to output(/z-file.+symlinks.+a-file/m).to_stdout
    }
  end

  context 'with --format flag' do
    let(:args) { ['--format=single-column', FIXTURES] }

    it {
      expect { subject }.to output(/.*a-file.*\n # on the first line
                                       (?m:.*)      # more lines...
                                       .*z-file.*\n # on the last line
                                      /x).to_stdout
    }
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

    it 'shows special permission bits', :use_file_info_stub do
      expect { subject }.to output(/r-Sr-Sr-T  .*  a.txt/mx).to_stdout
    end

    it 'shows number of hardlinks', :use_file_info_stub do
      allow(a_txt_file_info).to receive(:nlink).and_return 5

      expect { subject }.to output(/\S+\s+ 5 .*  a.txt/mx).to_stdout
    end
  end

  context 'with --long and --non-human-readable flag for `2MB file`' do
    let(:args) { ['--long', '--non-human-readable', "#{FIXTURES}/two_megabyte_file.txt"] }

    it 'shows the file size in bytes' do
      expect { subject }.to output(/#{2 * 1024 * 1024}\sB/).to_stdout
    end
  end

  context 'with --long flag on windows' do
    let(:args) { ['--long', "#{FIXTURES}/a.txt"] }

    before do
      ColorLS::FileInfo.class_variable_set :@@users, {}  # rubocop:disable Style/ClassVars
      ColorLS::FileInfo.class_variable_set :@@groups, {} # rubocop:disable Style/ClassVars
    end

    it 'returns no user / group info' do
      allow(Etc).to receive(:getpwuid).and_return(nil)
      allow(Etc).to receive(:getgrgid).and_return(nil)

      expect { subject }.to output(/\s+  \d+  \s+  \d+  .*  a.txt/mx).to_stdout
    end
  end

  context 'with --all flag' do
    let(:args) { ['--all', FIXTURES] }

    it('lists hidden files') { expect { subject }.to output(/\.hidden-file/).to_stdout }
  end

  context 'with --sort-dirs flag' do
    let(:args) { ['--sort-dirs', '-1', FIXTURES] }

    it('sorts results alphabetically, directories first') {
      expect do
        subject
      end.to output(/symlinks.+a-file.+z-file/m).to_stdout
    }
  end

  context 'with --sort-files flag' do
    let(:args) { ['--sort-files', '-1', FIXTURES] }

    it('sorts results alphabetically, files first') {
      expect do
        subject
      end.to output(/a-file.+z-file.+symlinks/m).to_stdout
    }
  end

  context 'with --sort=time' do
    entries = Dir.entries(FIXTURES, encoding: Encoding::UTF_8).grep(/^[^.]/).shuffle.freeze
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
      allow($stdout).to receive(:tty?).and_return(true)

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

    it('sorts results by extension') {
      expect do
        subject
      end.to output(/a-file.+symlinks.+z-file.+a.md.+a.txt.+z.txt/m).to_stdout
    }
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

    it {
      expect do
        subject
      end.not_to output(/ReadmeLink.md|Supportlink|doesnotexisttest.txt|third-level-file.txt/).to_stdout
    }
  end

  context 'with --tree=3 flag' do
    let(:args) { ['--tree=3', FIXTURES] }

    it('displays file hierarchy') { expect { subject }.to output(/├──/).to_stdout }
    it { expect { subject }.to output(/third-level-file.txt/).to_stdout }
  end

  context 'with --hyperlink flag' do
    let(:args) { ['--hyperlink', FIXTURES] }

    href = if File::ALT_SEPARATOR.nil?
             "file://#{File.absolute_path(FIXTURES)}/a.txt"
           else
             "file:///#{File.absolute_path(FIXTURES)}/a.txt"
           end

    pattern = File.fnmatch('cat', 'CAT', File::FNM_SYSCASE) ? /#{href}/i : /#{href}/

    it { expect { subject }.to output(match(pattern)).to_stdout }
  end

  context 'symlinked directory' do
    let(:args) { ['-x', File.join(FIXTURES, 'symlinks', 'Supportlink')] }

    it { expect { subject }.to output(/Supportlink/).to_stdout }
  end

  context 'symlinked directory with trailing separator' do
    link_to_dir = File.join(FIXTURES, 'symlinks', 'Supportlink', File::SEPARATOR)
    let(:args) { ['-x', link_to_dir] }

    it 'shows the file in the linked directory' do
      stat = File.lstat link_to_dir

      if stat.directory?
        expect { subject }.to output(/yaml_sort_checker.rb/).to_stdout
      else
        skip 'symlinks not supported'
      end
    end
  end

  context 'when passing invalid flags' do
    let(:args) { ['--snafu'] }

    it 'issues a warning, hint about `--help` and exit' do # rubocop:todo RSpec/MultipleExpectations
      allow(Kernel).to receive(:warn) do |message|
        expect(message).to output '--snafu'
      end

      expect { subject }.to raise_error('colorls exited with 2').and output(/--help/).to_stderr
    end
  end

  context 'with invalid locale' do
    let(:args) { [FIXTURES] }

    it 'warns but not raise an error' do
      allow(CLocale).to receive(:setlocale).with(CLocale::LC_COLLATE, '').and_raise(RuntimeError.new('setlocale error'))

      expect { subject }.to output(/setlocale error/).to_stderr.and output.to_stdout
    end
  end

  context 'with --report flag' do
    let(:args) { ['--report', '--report=long', FIXTURES] }

    it 'shows a report with recognized and unrecognized files' do
      expect { subject }.to output(/Recognized files\s+: 4\n.+Unrecognized files\s+: 3/).to_stdout
    end
  end

  context 'with --report=short flag' do
    let(:args) { ['--report=short', FIXTURES] }

    it 'shows a brief report' do
      expect { subject }.to output(/Folders: \d+, Files: \d+\./).to_stdout
    end
  end

  context 'with --inode flag' do
    let(:args) { ['--inode', FIXTURES] }

    it 'shows inode number before logo' do
      expect { subject }.to output(/\d+ +[^ ]+ +a.md/).to_stdout
    end
  end

  context 'with non-existent path' do
    let(:args) { ['not_exist_file'] }

    it 'exits with status code 2' do # rubocop:todo RSpec/MultipleExpectations
      expect { subject }.to output(/colorls: Specified path 'not_exist_file' doesn't exist./).to_stderr
      expect(subject).to eq 2
    end
  end

  context 'with -o flag', :use_file_info_stub do
    let(:args) { ['-o', "#{FIXTURES}/a.txt"] }

    it 'lists without group info' do
      expect { subject }.not_to output(/sys/).to_stdout
    end

    it 'lists with user info' do
      expect { subject }.to output(/user/).to_stdout
    end
  end

  context 'with -g flag', :use_file_info_stub do
    let(:args) { ['-g', "#{FIXTURES}/a.txt"] }

    it 'lists with group info' do
      expect { subject }.to output(/sys/).to_stdout
    end

    it 'lists without user info' do
      expect { subject }.not_to output(/user/).to_stdout
    end
  end

  context 'with -o and -g flag', :use_file_info_stub do
    let(:args) { ['-og', "#{FIXTURES}/a.txt"] }

    it 'lists without group info' do
      expect { subject }.not_to output(/sys/).to_stdout
    end

    it 'lists without user info' do
      expect { subject }.not_to output(/user/).to_stdout
    end
  end

  context 'with -G flag in a listing format', :use_file_info_stub do
    let(:args) { ['-l', '-G', "#{FIXTURES}/a.txt"] }

    it 'lists without group info' do
      expect { subject }.not_to output(/sys/).to_stdout
    end

    it 'lists with user info' do
      expect { subject }.to output(/user/).to_stdout
    end
  end

  context 'with --indicator-style=none' do
    let(:args) { ['-dl', '--indicator-style=none', FIXTURES] }

    it { expect { subject }.to output(/.+second-level \n.+symlinks \n/).to_stdout }
  end

  context 'with --time-style option' do
    let(:args) { ['-l', '--time-style=+%y-%m-%d %k:%M', "#{FIXTURES}/a.txt"] }

    mtime = File.mtime("#{FIXTURES}/a.txt")

    it { expect { subject }.to output(/#{mtime.strftime("%y-%m-%d %k:%M")}/).to_stdout }
  end

  context 'with --no-hardlinks flag in a listing format', :use_file_info_stub do
    let(:args) { ['-l', '--no-hardlink', "#{FIXTURES}/a.txt"] }

    before do
      allow(a_txt_file_info).to receive(:nlink).and_return 987
    end

    it 'lists without hard links count' do
      expect { subject }.not_to output(/987/).to_stdout
    end
  end

  context 'with -L flag in a listing format' do
    let(:args) { ['-l', '-L', "#{FIXTURES}/a.txt"] }

    before do
      file_info = instance_double(
        ColorLS::FileInfo,
        group: 'sys',
        mtime: Time.now,
        directory?: false,
        owner: 'user',
        name: 'a.txt',
        show: 'a.txt',
        nlink: 1,
        size: 128,
        blockdev?: false,
        chardev?: false,
        socket?: false,
        symlink?: true,
        hidden?: false,
        link_target: "#{FIXTURES}/z.txt",
        dead?: false,
        executable?: false
      )

      allow(ColorLS::FileInfo).to receive(:new).and_call_original
      allow(ColorLS::FileInfo).to receive(:new).with(
        path: File.join(FIXTURES, 'a.txt'),
        parent: FIXTURES,
        name: 'a.txt',
        link_info: true,
        show_filepath: true
      ) { file_info }
    end

    it 'show information on the destination of symbolic links' do
      expect { subject }.not_to output(/128/).to_stdout
    end
  end

  context 'when argument is a file with relative path' do
    let(:args) { ["#{FIXTURES}/a.txt"] }

    it 'replicates the filepath provided in the argument' do
      expect { subject }.to output(/#{args.first}/).to_stdout
    end
  end
end
