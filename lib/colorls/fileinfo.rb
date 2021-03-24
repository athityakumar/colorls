# frozen_string_literal: true

require 'forwardable'

module ColorLS
  class FileInfo
    extend Forwardable

    @@users  = {}              # rubocop:disable Style/ClassVars
    @@groups = {}              # rubocop:disable Style/ClassVars

    attr_reader :stats, :name, :path, :parent

    def initialize(name:, parent:, path: nil, link_info: true)
      @name = name
      @parent = parent
      @path = path.nil? ? File.join(parent, name) : +path
      @stats = File.lstat(@path)
      @show_name = nil

      @path.force_encoding(ColorLS.file_encoding)

      handle_symlink(@path) if link_info && @stats.symlink?
    end

    def self.info(path, link_info: true)
      FileInfo.new(name: File.basename(path), parent: File.dirname(path), path: path, link_info: link_info)
    end

    def self.dir_entry(dir, child, link_info: true)
      FileInfo.new(name: child, parent: dir, link_info: link_info)
    end

    def show
      return @show_name unless @show_name.nil?

      @show_name = @name.encode(Encoding.find('filesystem'), Encoding.default_external,
                                invalid: :replace, undef: :replace)
    end

    def dead?
      @dead
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

    def_delegators :@stats, :directory?, :socket?, :chardev?, :symlink?, :blockdev?, :mtime, :nlink, :size, :owned?,\
                   :executable?

    private

    def handle_symlink(path)
      @target = File.readlink(path)
      @dead = !File.exist?(path)
    rescue SystemCallError => e
      $stderr.puts "cannot read symbolic link: #{e}"
    end
  end
end
