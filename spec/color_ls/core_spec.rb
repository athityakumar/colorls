# coding: utf-8
require 'spec_helper'

RSpec.describe ColorLS::Core do
  subject { described_class.new(colors: Hash.new('black')) }

  context 'ls' do
    it 'works with Unicode characters' do
      camera = 'Cámara'.force_encoding(ColorLS::file_encoding)
      imagenes = 'Imágenes'.force_encoding(ColorLS::file_encoding)

      dirInfo = instance_double(
        'FileInfo',
        :group => "sys",
        :mtime => Time.now,
        :directory? => true,
        :owner => "user",
        :name => imagenes,
        :show => imagenes,
        :nlink => 1,
        :size => 128,
        :blockdev? => false,
        :chardev? => false,
        :socket? => false,
        :symlink? => false,
        :stats => OpenStruct.new(
          mode: 0o444, # read for user, owner, other
          setuid?: false,
          setgid?: false,
          sticky?: false
        ),
        :executable? => true
      )

      fileInfo = instance_double(
        'FileInfo',
        :group => "sys",
        :mtime => Time.now,
        :directory? => false,
        :owner => "user",
        :name => camera,
        :show => camera,
        :nlink => 1,
        :size => 128,
        :blockdev? => false,
        :chardev? => false,
        :socket? => false,
        :symlink? => false,
        :stats => OpenStruct.new(
          mode: 0o444, # read for user, owner, other
          setuid?: false,
          setgid?: false,
          sticky?: false
        ),
        :executable? => false
      )

      expect(::Dir).to receive(:entries).and_return([camera])

      allow(ColorLS::FileInfo).to receive(:new).and_return(dirInfo)
      allow(ColorLS::FileInfo).to receive(:new).with(File.join(imagenes, camera), link_info: false) { fileInfo }

      expect { subject.ls('Imágenes') }.to output(/mara/).to_stdout
    end
  end
end
