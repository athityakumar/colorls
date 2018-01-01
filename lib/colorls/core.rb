module ColorLS
  class Core
    def initialize(input, all: false, report: false, sort: false, show: false,
      mode: nil, git_status: false, almost_all: false, colors: [], group: nil,
      reverse: false)
      @input        = File.absolute_path(input)
      @count        = {folders: 0, recognized_files: 0, unrecognized_files: 0}
      @all          = all
      @almost_all   = almost_all
      @report       = report
      @sort         = sort
      @reverse      = reverse
      @group        = group
      @show         = show
      @one_per_line = mode == :one_per_line
      @long         = mode == :long
      @tree         = mode == :tree
      process_git_status_details(git_status)

      @screen_width = IO.console.winsize[1]
      @screen_width = 80 if @screen_width.zero?

      @colors       = colors

      @contents   = init_contents(@input)
      @max_widths = @contents.map { |c| c.name.length }
      init_icons
    end

    def ls
      return print "\n   Nothing to show here\n".colorize(@colors[:empty]) if @contents.empty?

      if @tree
        print "\n"
        tree_traverse(@input, 0, 2)
      else
        @contents = chunkify
        @contents.each { |chunk| ls_line(chunk) }
      end
      display_report if @report
      true
    end

    private

    def init_contents(path)
      info = FileInfo.new(path)

      if info.directory?
        @contents = Dir.entries(path)

        filter_hidden_contents

        @contents.map! { |e| FileInfo.info(File.join(path, e)) }

        filter_contents if @show
        sort_contents   if @sort
        group_contents  if @group
      else
        @contents = [info]
      end
      @total_content_length = @contents.length

      return @contents unless @long
      init_user_lengths
      init_group_lengths
      @contents
    end

    def filter_hidden_contents
      @contents -= %w[. ..] unless @all
      @contents.keep_if { |x| !x.start_with? '.' } unless @all || @almost_all
    end

    def init_user_lengths
      @userlength = @contents.map do |c|
        c.owner.length
      end.max
    end

    def init_group_lengths
      @grouplength = @contents.map do |c|
        c.group.length
      end.max
    end

    def filter_contents
      @contents.keep_if do |x|
        x.directory? == (@show == :dirs)
      end
    end

    def sort_contents
      case @sort
      when :time
        @contents.sort_by! { |a| -a.mtime.to_f }
      when :size
        @contents.sort_by! { |a| -a.size }
      else
        @contents.sort_by! { |a| CLocale.strxfrm(a.name) }
      end
      @contents.reverse! if @reverse
    end

    def group_contents
      return unless @group

      dirs, files = @contents.partition(&:directory?)

      @contents = case @group
                  when :dirs then dirs.push(*files)
                  when :files then files.push(*dirs)
                  end
    end

    def init_icons
      @files          = ColorLS::Yaml.new('files.yaml').load
      @file_aliases   = ColorLS::Yaml.new('file_aliases.yaml').load(aliase: true)
      @folders        = ColorLS::Yaml.new('folders.yaml').load
      @folder_aliases = ColorLS::Yaml.new('folder_aliases.yaml').load(aliase: true)

      @file_keys          = @files.keys
      @file_aliase_keys   = @file_aliases.keys
      @folder_keys        = @folders.keys
      @folder_aliase_keys = @folder_aliases.keys

      @all_files   = @file_keys + @file_aliase_keys
      @all_folders = @folder_keys + @folder_aliase_keys
    end

    def chunkify
      return @contents.zip if @one_per_line || @long

      chunk_size = @contents.size
      max_widths = @max_widths

      until in_line(chunk_size, max_widths) || chunk_size <= 1
        chunk_size -= 1
        max_widths      = @max_widths.each_slice(chunk_size).to_a
        max_widths[-1] += [0] * (chunk_size - max_widths.last.size)
        max_widths      = max_widths.transpose.map(&:max)
      end
      @max_widths = max_widths
      @contents = get_chunk(chunk_size)
    end

    def get_chunk(chunk_size)
      @contents.each_slice(chunk_size).to_a
    end

    def in_line(chunk_size, max_widths)
      (max_widths.sum + 12 * chunk_size <= @screen_width)
    end

    def display_report
      print "\n   Found #{@total_content_length} contents in directory "
        .colorize(@colors[:report])

      print File.expand_path(@input).to_s.colorize(@colors[:dir])

      puts  "\n\n\tFolders\t\t\t: #{@count[:folders]}"\
        "\n\tRecognized files\t: #{@count[:recognized_files]}"\
        "\n\tUnrecognized files\t: #{@count[:unrecognized_files]}"
        .colorize(@colors[:report])
    end

    def mode_info(stat)
      mode = ''
      stat.mode.to_s(2).rjust(16, '0')[-9..-1].each_char.with_index do |c, i|
        if c == '0'
          mode += '-'.colorize(@colors[:no_access])
        else
          case (i % 3)
          when 0 then mode += 'r'.colorize(@colors[:read])
          when 1 then mode += 'w'.colorize(@colors[:write])
          when 2 then mode += 'x'.colorize(@colors[:exec])
          end
        end
      end
      mode
    end

    def user_info(content)
      user = content.owner.ljust(@userlength, ' ')
      user.colorize(@colors[:user]) if content.owned?
    end

    def group_info(group)
      group.to_s.ljust(@grouplength, ' ').colorize(@colors[:normal])
    end

    def size_info(filesize)
      size = Filesize.from("#{filesize} B").pretty.split(' ')
      size = "#{size[0][0..-4].rjust(3,' ')} #{size[1].ljust(3,' ')}"
      return size.colorize(@colors[:file_large])  if filesize >= 512 * 1024 ** 2
      return size.colorize(@colors[:file_medium]) if filesize >= 128 * 1024 ** 2
      size.colorize(@colors[:file_small])
    end

    def mtime_info(file_mtime)
      mtime = file_mtime.asctime
      now = Time.now
      return mtime.colorize(@colors[:hour_old]) if now - file_mtime < 60 * 60
      return mtime.colorize(@colors[:day_old])  if now - file_mtime < 24 * 60 * 60
      mtime.colorize(@colors[:no_modifier])
    end

    def process_git_status_details(git_status)
      return false unless git_status

      actual_path = Dir.pwd
      Dir.chdir(@input)
      until File.exist?('.git') # check whether the repository is git controlled
        return false if Dir.pwd=='/'
        Dir.chdir('..')
      end

      @git_root_path = Dir.pwd
      Dir.chdir(actual_path)

      @git_status = Git.status(@git_root_path)
    end

    def git_info(path, content)
      return '' unless @git_status

      # puts "\n\n"

      Dir.chdir(@git_root_path)
      relative_path = path.remove(@git_root_path+'/')
      relative_path = relative_path==path ? '' : relative_path+'/'
      content_path  = "#{relative_path}#{content}"
      content_type  = Dir.exist?("#{@git_root_path}/#{content_path}") ? :dir : :file

      if content_type == :file then git_file_info(content_path)
      else git_dir_info(content_path)
      end
      # puts "\n\n"
    end

    def git_file_info(path)
      return '  ✓ '.colorize(@colors[:unchanged]) unless @git_status[path]
      Git.colored_status_symbols(@git_status[path], @colors)
    end

    Dir.class_eval do
      def self.deep_entries(path)
        (Dir.entries(path) - ['.', '..']).map do |entry|
          if Dir.exist?("#{path}/#{entry}")
            Dir.deep_entries("#{path}/#{entry}")
          else
            entry
          end
        end.flatten
      end
    end

    def git_dir_info(path)
      ignored = @git_status.select { |file, mode| file.start_with?(path) && mode==' ' }.keys
      present = Dir.deep_entries(path).map { |p| "#{path}/#{p}" }
      return '    ' if (present-ignored).empty?

      modes = (present-ignored).map { |file| @git_status[file] }-[nil]
      return '  ✓ '.colorize(@colors[:unchanged]) if modes.empty?
      Git.colored_status_symbols(modes.join.uniq, @colors)
    end

    def long_info(content)
      return '' unless @long
      [mode_info(content.stats), user_info(content), group_info(content.group),
       size_info(content.size), mtime_info(content.mtime)].join('  ')
    end

    def symlink_info(content)
      return '' unless @long && content.symlink?
      link_info = " ⇒ #{content.link_target}"
      if content.dead?
        "#{link_info} [Dead link]".colorize(@colors[:dead_link])
      else
        link_info.colorize(@colors[:link])
      end
    end

    def slash?(content)
      content.directory? ? '/'.colorize(@colors[:dir]) : ' '
    end

    def fetch_string(path, content, key, color, increment)
      @count[increment] += 1
      value = increment == :folders ? @folders[key] : @files[key]
      logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }

      [
        long_info(content),
        " #{git_info(path,content)} ",
        logo.colorize(color),
        "  #{content.name.colorize(color)}#{slash?(content)}#{symlink_info(content)}"
      ].join
    end

    def ls_line(chunk)
      chunk.each_with_index do |content, i|
        break if content.name.empty?

        print "  #{fetch_string(@input, content, *options(content))}"
        print ' ' * (@max_widths[i] - content.name.length) unless @one_per_line || @long
      end
      print "\n"
    end

    def options(content)
      if content.directory?
        key = content.name.to_sym
        color = @colors[:dir]
        return [:folder, color, :folders] unless @all_folders.include?(key)
        key = @folder_aliases[key] unless @folder_keys.include?(key)
        return [key, color, :folders]
      end

      color = @colors[:recognized_file]
      return [content.downcase.to_sym, color, :recognized_files] if @file_keys.include?(key)

      key = content.name.split('.').last.downcase.to_sym
      return [:file, @colors[:unrecognized_file], :unrecognized_files] unless @all_files.include?(key)

      key = @file_aliases[key] unless @file_keys.include?(key)
      [key, color, :recognized_files]
    end

    def tree_traverse(path, prespace, indent)
      contents = init_contents(path)
      contents.each do |content|
        icon = content == contents.last || content.directory? ? ' └──' : ' ├──'
        print tree_branch_preprint(prespace, indent, icon).colorize(@colors[:tree])
        print " #{fetch_string(path, content, *options(content))} \n"
        next unless content.directory?
        tree_traverse("#{path}/#{content}", prespace + indent, indent)
      end
    end

    def tree_branch_preprint(prespace, indent, prespace_icon)
      return prespace_icon if prespace.zero?
      ' │ ' * (prespace/indent) + prespace_icon + '─' * indent
    end
  end
end
