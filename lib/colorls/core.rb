module ColorLS
  class Core
    def initialize(input=nil, all: false, report: false, sort: false, show: false,
      mode: nil, git_status: false, almost_all: false, colors: [], group: nil,
      reverse: false)
      @input        = init_input_path(input)
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
      @screen_width = `tput cols`.chomp.to_i
      @colors       = colors

      @contents   = init_contents(@input)
      @max_widths = @contents.map(&:length)
      init_icons
    end

    def ls
      return print "\n   Nothing to show here\n".colorize(@colors[:empty]) if @contents.empty?

      if @tree
        print "\n"
        tree_traverse(@input, 0, 2)
      else
        @contents = chunkify
        @max_widths = @contents.transpose.map { |c| c.map(&:length).max }
        @contents.each { |chunk| ls_line(chunk) }
      end
      display_report if @report
      true
    end

    private

    def init_input_path(input)
      return Dir.pwd unless input
      return input unless Dir.exist?(input)

      actual = Dir.pwd
      Dir.chdir(input)
      input = Dir.pwd
      Dir.chdir(actual)
      input
    end

    def init_contents(path)
      is_directory = Dir.exist?(path)
      @contents = if is_directory
                    Dir.entries(path)
                  else
                    @input = File.dirname(path)
                    [File.basename(path)]
                  end

      filter_hidden_contents if is_directory
      filter_contents(path) if @show
      sort_contents(path)   if @sort
      group_contents(path)  if @group

      @total_content_length = @contents.count

      return @contents unless @long
      init_user_lengths(path)
      init_group_lengths(path)
      @contents
    end

    def filter_hidden_contents
      @contents -= %w[. ..] unless @all
      @contents.keep_if { |x| !x.start_with? '.' } unless @all || @almost_all
    end

    def init_user_lengths(path)
      @userlength = @contents.map do |c|
        next 0 unless File.exist?("#{path}/#{c}")
        begin
          user = Etc.getpwuid(File.stat("#{path}/#{c}").uid).name
        rescue ArgumentError
          user = File.stat("#{path}/#{c}").uid
        end
        user.to_s.length
      end.max
    end

    def init_group_lengths(path)
      @grouplength = @contents.map do |c|
        next 0 unless File.exist?("#{path}/#{c}")
        begin
          group = Etc.getgrgid(File.stat("#{path}/#{c}").gid).name
        rescue ArgumentError
          group = File.stat("#{path}/#{c}").gid
        end
        group.to_s.length
      end.max
    end

    def filter_contents(path)
      @contents.keep_if do |x|
        next Dir.exist?("#{path}/#{x}") if @show == :dirs
        !Dir.exist?("#{path}/#{x}")
      end
    end

    def sort_contents(path)
      case @sort
      when :time
        @contents.sort_by! { |a| -File.mtime(File.join(path, a)).to_f }
      when :size
        @contents.sort_by! { |a| -File.size(File.join(path, a)) }
      else
        @contents.sort! { |a, b| a.casecmp(b) }
      end
      @contents.reverse! if @reverse
    end

    def group_contents(path)
      return unless @group

      dirs, files = @contents.partition { |a| Dir.exist?("#{path}/#{a}") }

      @contents = case @group
                  when :dirs then dirs.push(*files)
                  when :files then files.push(*dirs)
                  end
    end

    def init_icons
      @files          = ColorLS.load_from_yaml('files.yaml')
      @file_aliases   = ColorLS.load_from_yaml('file_aliases.yaml', true)
      @folders        = ColorLS.load_from_yaml('folders.yaml')
      @folder_aliases = ColorLS.load_from_yaml('folder_aliases.yaml', true)

      @file_keys          = @files.keys
      @file_aliase_keys   = @file_aliases.keys
      @folder_keys        = @folders.keys
      @folder_aliase_keys = @folder_aliases.keys

      @all_files   = @file_keys + @file_aliase_keys
      @all_folders = @folder_keys + @folder_aliase_keys
    end

    def chunkify
      return @contents.zip if @one_per_line || @long

      chunk_size = @contents.count

      until in_line(chunk_size) || chunk_size <= 1
        chunk_size -= 1
        chunk       = get_chunk(chunk_size)
      end

      chunk || [@contents]
    end

    def get_chunk(chunk_size)
      chunk       = @contents.each_slice(chunk_size).to_a
      chunk[-1]  += [''] * (chunk_size - chunk.last.count)
      @max_widths = chunk.transpose.map { |c| c.map(&:length).max }
      chunk
    end

    def in_line(chunk_size)
      (@max_widths.sum + 12 * chunk_size <= @screen_width)
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

    def user_info(stat)
      begin
        user = Etc.getpwuid(stat.uid).name
      rescue ArgumentError
        user = stat.uid
      end
      user = user.to_s.ljust(@userlength, ' ')
      user.colorize(@colors[:user]) if user == Etc.getlogin
    end

    def group_info(stat)
      begin
        group = Etc.getgrgid(stat.gid).name
      rescue ArgumentError
        group = stat.gid
      end
      group.to_s.ljust(@grouplength, ' ').colorize(@colors[:normal])
    end

    def size_info(stat)
      size = Filesize.from("#{stat.size} B").pretty.split(' ')
      size = "#{size[0][0..-4].rjust(3,' ')} #{size[1].ljust(3,' ')}"
      return size.colorize(@colors[:file_large])  if stat.size >= 512 * 1024 ** 2
      return size.colorize(@colors[:file_medium]) if stat.size >= 128 * 1024 ** 2
      size.colorize(@colors[:file_small])
    end

    def mtime_info(stat)
      mtime = stat.mtime.asctime
      return mtime.colorize(@colors[:hour_old]) if Time.now - stat.mtime < 60 * 60
      return mtime.colorize(@colors[:day_old])  if Time.now - stat.mtime < 24 * 60 * 60
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

    def git_dir_info(path)
      modes = @git_status.select { |file, _mode| file.start_with?(path) }.values

      return '  ✓ '.colorize(@colors[:unchanged]) if modes.empty?
      Git.colored_status_symbols(modes.join.uniq, @colors)
    end

    def long_info(path, content)
      return '' unless @long
      unless File.exist?("#{path}/#{content}")
        return '[No Info]'.colorize(@colors[:error]) + ' ' * (38 + @userlength + @grouplength)
      end
      stat = File.stat("#{path}/#{content}")
      [mode_info(stat), user_info(stat), group_info(stat), size_info(stat), mtime_info(stat)]
        .join('  ')
    end

    def symlink_info(path, content)
      return '' unless @long && File.symlink?("#{path}/#{content}")
      if File.exist?("#{path}/#{content}")
        " ⇒ #{File.readlink("#{path}/#{content}")}/".colorize(@colors[:link])
      else
        ' ⇒ [Dead link]'.colorize(@colors[:dead_link])
      end
    end

    def slash?(path, content)
      Dir.exist?("#{path}/#{content}") ? '/'.colorize(@colors[:dir]) : ' '
    end

    def fetch_string(path, content, key, color, increment)
      @count[increment] += 1
      value = increment == :folders ? @folders[key] : @files[key]
      logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }

      [
        long_info(path, content),
        " #{git_info(path,content)} ",
        logo.colorize(color),
        "  #{content.colorize(color)}#{slash?(path, content)}#{symlink_info(path, content)}"
      ].join
    end

    def ls_line(chunk)
      chunk.each_with_index do |content, i|
        break if content.empty?

        print "  #{fetch_string(@input, content, *options(@input, content))}"
        print ' ' * (@max_widths[i] - content.length) unless @one_per_line || @long
      end
      print "\n"
    end

    def options(path, content)
      if Dir.exist?("#{path}/#{content}")
        key = content.to_sym
        color = @colors[:dir]
        return [:folder, color, :folders] unless @all_folders.include?(key)
        key = @folder_aliases[key] unless @folder_keys.include?(key)
        return [key, color, :folders]
      end

      color = @colors[:recognized_file]
      return [content.downcase.to_sym, color, :recognized_files] if @file_keys.include?(key)

      key = content.split('.').last.downcase.to_sym
      return [:file, @colors[:unrecognized_file], :unrecognized_files] unless @all_files.include?(key)

      key = @file_aliases[key] unless @file_keys.include?(key)
      [key, color, :recognized_files]
    end

    def tree_traverse(path, prespace, indent)
      contents = init_contents(path)
      contents.each do |content|
        icon = content == contents.last || Dir.exist?("#{path}/#{content}") ? ' └──' : ' ├──'
        print tree_branch_preprint(prespace, indent, icon).colorize(@colors[:tree])
        print " #{fetch_string(path, content, *options(path, content))} \n"
        next unless Dir.exist? "#{path}/#{content}"
        tree_traverse("#{path}/#{content}", prespace + indent, indent)
      end
    end

    def tree_branch_preprint(prespace, indent, prespace_icon)
      return prespace_icon if prespace.zero?
      ' │ ' * (prespace/indent) + prespace_icon + '─' * indent
    end
  end
end
