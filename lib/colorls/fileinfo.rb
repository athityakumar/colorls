require 'forwardable'

module ColorLS
  class FileInfo
    extend Forwardable

    @@users  = {}              # rubocop:disable Style/ClassVars
    @@groups = {}              # rubocop:disable Style/ClassVars

    attr_reader :stats
    attr_reader :name

    def initialize(path, link_info=true)
      @name = File.basename(path)
      @stats = File.lstat(path)

      return unless link_info && @stats.symlink?

      @dead = !File.exist?(path)
      @target = File.readlink(path)
    end

    def self.info(path)
      FileInfo.new(path)
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

    def_delegators :@stats, :directory?, :socket?, :chardev?, :symlink?, :blockdev?, :mtime, :size, :owned?
  end
end
