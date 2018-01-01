module ColorLS
  class FileInfo
    @@users  = {}              # rubocop:disable Style/ClassVars
    @@groups = {}              # rubocop:disable Style/ClassVars

    attr_reader :stats
    attr_reader :name

    def initialize(path)
      @name = File.basename(path)
      @stats = File.lstat(path)
      return unless @stats.symlink?
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
      @@users[@stats.uid] = Etc.getpwuid(@stats.uid).name
    rescue ArgumentError
      @stats.uid.to_s
    end

    def group
      return @@groups[@stats.gid] if @@groups.key? @stats.gid
      @@groups[@stats.gid] = Etc.getgrgid(@stats.gid).name
    rescue ArgumentError
      @stats.gid.to_s
    end

    def mtime
      @stats.mtime
    end

    def size
      @stats.size
    end

    def directory?
      @stats.directory?
    end

    def symlink?
      @stats.symlink?
    end

    def link_target
      @target
    end

    def to_s
      name
    end
  end
end
