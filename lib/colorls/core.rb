module ColorLS
  class Core
    def initialize(input=nil, all: false, report: false, sort: false, show: false,
      one_per_line: false, git_status: false,long: false, almost_all: false, tree: false, help: false, colors: [])
      @input        = input || Dir.pwd
      @count        = {folders: 0, recognized_files: 0, unrecognized_files: 0}
      @all          = all
      @almost_all   = almost_all
      @report       = report
      @sort         = sort
      @show         = show
      @one_per_line = one_per_line
      @long         = long
      @tree         = tree
      @help         = help
      @git_status   = git_status
      @screen_width = ::TermInfo.screen_size.last
      @colors       = colors

      @contents   = init_contents(@input)
      @max_widths = @contents.map(&:length)
      init_icons
    end

    def ls
      return print "\n   Nothing to show here\n".colorize(@colors[:empty]) if @contents.empty?

      return helplog if @help

      if @tree
        print "\n"
        tree_traverse(@input, 0, 2)
      else
        @contents = chunkify
        @max_widths = @contents.transpose.map { |c| c.map(&:length).max }
        @contents.each { |chunk| ls_line(chunk) }
      end
      print "\n"
      display_report if @report

      true
    end

    private

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

      @total_content_length = @contents.length

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
      @contents.sort! { |a, b| cmp_by_dirs(path, a, b) }
    end

    def cmp_by_dirs(path, a, b)
      is_a_dir = Dir.exist?("#{path}/#{a}")
      is_b_dir = Dir.exist?("#{path}/#{b}")

      return cmp_by_alpha(a, b) unless is_a_dir ^ is_b_dir

      result = is_a_dir ? -1 : 1
      result *= -1 if @sort == :files
      result
    end

    def cmp_by_alpha(a, b)
      a.downcase <=> b.downcase
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
      chunk.last += [''] * (chunk_size - chunk.last.count)
      @max_widths = chunk.transpose.map { |c| c.map(&:length).max }
      chunk
    end

    def in_line(chunk_size)
      return false if @max_widths.sum + 12 * chunk_size > @screen_width
      true
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
      "#{size[0][0..-4].rjust(3,' ')} #{size[1].ljust(3,' ')}".colorize(@colors[:normal])
    end

    def mtime_info(stat)
      mtime = stat.mtime.asctime.colorize(@colors[:no_modifier])
      mtime = mtime.colorize(@colors[:day_old]) if Time.now - stat.mtime < 24 * 60 * 60
      mtime = mtime.colorize(@colors[:hour_old]) if Time.now - stat.mtime < 60 * 60
      mtime
    end

    def git_info(path, content)
      return '' unless @git_status
      until File.exist?('.git') # check whether the repository is git controlled
        return '' if Dir.pwd=='/'
        Dir.chdir('..')
      end

      relative_path = path.remove(Dir.pwd+'/')
      relative_path = relative_path==path ? '' : relative_path+'/'

      status = Git.open('.').status
      return '(A)'.colorize(:green) if status.added.keys.any? { |a| a.include?("#{relative_path}#{content}") }
      return '(U)'.colorize(:red) if status.untracked.keys.any? { |u| u.include?("#{relative_path}#{content}") }
      return '(C)'.colorize(:yellow) if status.changed.keys.any? { |c| c.include?("#{relative_path}#{content}") }
      '(-)'
    end

    def long_info(path, content)
      return '' unless @long
      @git_status = true
      unless File.exist?("#{path}/#{content}")
        return '[No Info]'.colorize(@colors[:error]) + ' ' * (39 + @userlength + @grouplength)
      end
      stat = File.stat("#{path}/#{content}")
      a = [mode_info(stat), user_info(stat), group_info(stat), size_info(stat), mtime_info(stat),
           git_info(path,content)].join('  ')
      @git_status = false
      a
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
        "#{git_info(path,content)} ",
        logo.colorize(color),
        "  #{content.colorize(color)}#{slash?(path, content)}#{symlink_info(path, content)}"
      ].join
    end

    def ls_line(chunk)
      print "\n"
      chunk.each_with_index do |content, i|
        break if content.empty?

        print "  #{fetch_string(@input, content, *options(@input, content))}"
        print ' ' * (@max_widths[i] - content.length) unless @one_per_line || @long
      end
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

    def helplog
      print "\nUsage:  colorls <command> [-<attributes> (or) --<attributes>] <path> <keyword>\n\n
The available attributes are:\n
\t1                    list in a line
\ta  (or) all          list inclding hidden files in the directory
\tA  (or) almost-all   list almost all the files
\td  (or) dirs         list directories only
\tf  (or) files        list files only
\tl  (or) long         show list with long format
\tr  (or) report       detailed report of the files
\tsd (or) sort-dirs    sorted and grouped list of directiories followed by files
\t   (or) group-directories-first
\tsf (or) sort-files   sorted and grouped list of files followed by directiories
\tgs (or) git-status   shows the git status of the file [U:Untracked,A:Added,C:Changed]
\tt  (or) tree         shows tree view of the directory
\th  (or) help         show this page\n\n
The available commands are:\n
\tREADME.md    lists the README file irrespective of current path
\t*            colorls called recursively for each subsequent directory
\t| grep       lists the files having the given keyword in the name\n\n"
    end
  end
end
