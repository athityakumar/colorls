# frozen_string_literal: false

require 'spec_helper'

RSpec.describe ColorLS::Core do
  subject { described_class.new(colors: Hash.new('black')) }

  context 'ls' do
    it 'works with Unicode characters' do
      camera = 'Cámara'.force_encoding(ColorLS.file_encoding)
      imagenes = 'Imágenes'.force_encoding(ColorLS.file_encoding)

      dir_info = instance_double(
        ColorLS::FileInfo,
        group: 'sys',
        mtime: Time.now,
        directory?: true,
        owner: 'user',
        name: imagenes,
        path: '.',
        show: imagenes,
        nlink: 1,
        size: 128,
        blockdev?: false,
        chardev?: false,
        socket?: false,
        symlink?: false,
        hidden?: false,
        stats: instance_double(File::Stat,
                               mode: 0o444, # read for user, owner, other
                               setuid?: false,
                               setgid?: false,
                               sticky?: false),
        executable?: true
      )

      file_info = instance_double(
        ColorLS::FileInfo,
        group: 'sys',
        mtime: Time.now,
        directory?: false,
        owner: 'user',
        name: camera,
        show: camera,
        nlink: 1,
        size: 128,
        blockdev?: false,
        chardev?: false,
        socket?: false,
        symlink?: false,
        hidden?: false,
        stats: instance_double(File::Stat,
                               mode: 0o444, # read for user, owner, other
                               setuid?: false,
                               setgid?: false,
                               sticky?: false),
        executable?: false
      )

      allow(Dir).to receive(:entries).and_return([camera])

      allow(ColorLS::FileInfo).to receive(:new).and_return(file_info)

      expect { subject.ls_dir(dir_info) }.to output(/mara/).to_stdout
    end

    it 'works for `...`' do
      file_info = instance_double(
        ColorLS::FileInfo,
        group: 'sys',
        mtime: Time.now,
        directory?: false,
        owner: 'user',
        name: '...',
        show: '...',
        nlink: 1,
        size: 128,
        blockdev?: false,
        chardev?: false,
        socket?: false,
        symlink?: false,
        hidden?: true,
        executable?: false
      )

      expect { subject.ls_files([file_info]) }.to output(/[.]{3}/).to_stdout
    end

    describe '#mode_info' do
      def stat_double(mode:)
        instance_double(File::Stat,
                        mode: mode, # permission and file type bits only
                        setuid?: (mode & 0o4000) != 0,
                        setgid?: (mode & 0o2000) != 0,
                        sticky?: (mode & 0o1000) != 0)
      end

      # rubocop:disable RSpec/ExampleLength
      it 'prefixes the permissions with the file type' do
        expect(subject.mode_info(stat_double(mode: 0o100644))).to eq('-rw-r--r--') # regular file
        expect(subject.mode_info(stat_double(mode: 0o040755))).to eq('drwxr-xr-x') # directory
        expect(subject.mode_info(stat_double(mode: 0o010644))).to eq('prw-r--r--') # pipe, issue #490
        expect(subject.mode_info(stat_double(mode: 0o140755))).to eq('srwxr-xr-x') # socket
        expect(subject.mode_info(stat_double(mode: 0o020644))).to eq('crw-r--r--') # character device
        expect(subject.mode_info(stat_double(mode: 0o060644))).to eq('brw-r--r--') # block device
        expect(subject.mode_info(stat_double(mode: 0o120777))).to eq('lrwxrwxrwx') # symlink
      end
      # rubocop:enable RSpec/ExampleLength

      it 'keeps setuid, setgid and sticky bits' do
        expect(subject.mode_info(stat_double(mode: 0o104755))).to eq('-rwsr-xr-x')
        expect(subject.mode_info(stat_double(mode: 0o102755))).to eq('-rwxr-sr-x')
        expect(subject.mode_info(stat_double(mode: 0o041755))).to eq('drwxr-xr-t')
      end
    end
  end
end
