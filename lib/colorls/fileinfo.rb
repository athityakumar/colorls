# frozen_string_literal: true

require 'forwardable'

module ColorLS
  class FileInfo
    extend Forwardable

    @@users  = {}              # rubocop:disable Style/ClassVars
    @@groups = {}              # rubocop:disable Style/ClassVars

    attr_reader :stats, :name, :path, :parent

    def initialize(name:, parent:, path: nil, link_info: true, show_filepath: false)
      @name = name
      @parent = parent
      @path = path.nil? ? File.join(parent, name) : +path
      @stats = File.lstat(@path)

      @path.force_encoding(ColorLS.file_encoding)

      handle_symlink(@path) if link_info && @stats.symlink?
      set_show_name(use_path: show_filepath)
    end

    def self.info(path, link_info: true, show_filepath: false)
      FileInfo.new(name: File.basename(path), parent: File.dirname(path), path: path, link_info: link_info,
                   show_filepath: show_filepath)
    end

    def self.dir_entry(dir, child, link_info: true)
      FileInfo.new(name: child, parent: dir, link_info: link_info)
    end

    def show
      @show_name
    end

    def dead?
      @dead
    end

    def hidden?
      @name.start_with?('.')
    end

    def owner
      return @@users[@stats.uid] if @@users.key? @stats.uid

      user = Etc.getpwuid(@stats.uid)
      @@users[@stats.uid] = user.nil? ? @stats.uid.to_s : user.name
    rescue ArgumentError
      @stats.uid.to_s
    end

    def group
      return @@groups[@stats.gid] if @@groups.key? @stats.gid

      group = Etc.getgrgid(@stats.gid)
      @@groups[@stats.gid] = group.nil? ? @stats.gid.to_s : group.name
    rescue ArgumentError
      @stats.gid.to_s
    end

    # target of a symlink (only available for symlinks)
    def link_target
      @target
    end

    def to_s
      name
    end

    def_delegators :@stats, :directory?, :socket?, :chardev?, :symlink?, :blockdev?, :mtime, :nlink, :size, :owned?,
                   :executable?

    private

    def handle_symlink(path)
      @target = File.readlink(path)
      @dead = !File.exist?(path)
    rescue SystemCallError => e
      $stderr.puts "cannot read symbolic link: #{e}"
    end

    def show_basename
      @name.encode(Encoding.find('filesystem'), Encoding.default_external,
                   invalid: :replace, undef: :replace)
    end

    def show_relative_path
      @path.encode(Encoding.find('filesystem'), Encoding.default_external,
                   invalid: :replace, undef: :replace)
    end

    def set_show_name(use_path: false)
      @show_name = show_basename unless use_path
      @show_name = show_basename if directory?
      @show_name = show_relative_path if use_path
    end
  end
end
