module ColorLS
  class Core
    def initialize(input=nil, all: false, report: false, sort: false, show: false,
      one_per_line: false, long: false, almost_all: false, tree: false)
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
      @screen_width = ::TermInfo.screen_size.last

      @contents   = init_contents(@input)
      @max_widths = @contents.map(&:length)
      init_icons
    end

    def ls
      return print "\n   Nothing to show here\n".colorize(:yellow) if @contents.empty?

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
      @contents = if Dir.exist?(path)
                    Dir.entries(path)
                  else
                    [path]
                  end

      filter_hidden_contents
      filter_contents(path) if @show
      sort_contents(path)   if @sort

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
        begin
          user = Etc.getpwuid(File.stat("#{@input}/#{c}").uid).name
        rescue ArgumentError
          user = File.stat("#{@input}/#{c}").uid
        end
        user.to_s.length
      end.max
    end

    def init_group_lengths
      @grouplength = @contents.map do |c|
        begin
          group = Etc.getgrgid(File.stat("#{@input}/#{c}").gid).name
        rescue ArgumentError
          group = File.stat("#{@input}/#{c}").gid
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
      @files          = load_from_yaml('files.yaml')
      @file_aliases   = load_from_yaml('file_aliases.yaml', true)
      @folders        = load_from_yaml('folders.yaml')
      @folder_aliases = load_from_yaml('folder_aliases.yaml', true)

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
      return false if @max_widths.sum + 8 * chunk_size > @screen_width
      true
    end

    def display_report
      print "\n   Found #{@total_content_length} contents in directory "
        .colorize(:white)

      print File.expand_path(@input).to_s.colorize(:blue)

      puts  "\n\n\tFolders\t\t\t: #{@count[:folders]}"\
        "\n\tRecognized files\t: #{@count[:recognized_files]}"\
        "\n\tUnrecognized files\t: #{@count[:unrecognized_files]}"
        .colorize(:white)
    end

    def mode_info(stat)
      mode = ''
      stat.mode.to_s(2).rjust(16, '0')[-9..-1].each_char.with_index do |c, i|
        if c == '0'
          mode += '-'.colorize(:gray)
        else
          case (i % 3)
          when 0 then mode += 'r'.colorize(:yellow)
          when 1 then mode += 'w'.colorize(:magenta)
          when 2 then mode += 'x'.colorize(:cyan)
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
      user.colorize(:green) if user == Etc.getlogin
    end

    def group_info(stat)
      begin
        group = Etc.getgrgid(stat.gid).name
      rescue ArgumentError
        group = stat.gid
      end
      group.to_s.ljust(@grouplength, ' ')
    end

    def size_info(stat)
      size = Filesize.from("#{stat.size} B").pretty.split(' ')
      "#{size[0][0..-4].rjust(3,' ')} #{size[1].ljust(3,' ')}"
    end

    def mtime_info(stat)
      mtime = stat.mtime.asctime
      mtime = mtime.colorize(:yellow) if Time.now - stat.mtime < 24 * 60 * 60
      mtime = mtime.colorize(:green)  if Time.now - stat.mtime < 60 * 60
      mtime
    end

    def long_info(content)
      stat = File.stat("#{@input}/#{content}")
      "#{mode_info(stat)}  #{user_info(stat)}  #{group_info(stat)}  #{size_info(stat)}  #{mtime_info(stat)}  "
    end

    def fetch_string(content, key, color, increment)
      @count[increment] += 1
      value = increment == :folders ? @folders[key] : @files[key]
      logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }

      "#{@long ? long_info(content) : ''} #{logo.colorize(color)}  #{content.colorize(color)}"
    end

    def load_from_yaml(filename, aliase=false)
      filepath = File.join(File.dirname(__FILE__),"../yaml/#{filename}")
      yaml     = YAML.safe_load(File.read(filepath)).symbolize_keys
      return yaml unless aliase
      yaml
        .to_a
        .map! { |k, v| [k, v.to_sym] }
        .to_h
    end

    def ls_line(chunk)
      print "\n"
      chunk.each_with_index do |content, i|
        break if content.empty?

        print "  #{fetch_string(content, *options(@input, content))}"
        print Dir.exist?("#{@input}/#{content}") ? '/'.colorize(:blue) : ' '
        print ' ' * (@max_widths[i] - content.length)
      end
    end

    def options(path, content)
      if Dir.exist?("#{path}/#{content}")
        key = content.to_sym
        return %i[folder blue folders] unless @all_folders.include?(key)
        key = @folder_aliases[key] unless @folder_keys.include?(key)
        return [key, :blue, :folders]
      end

      key = content.downcase.to_sym

      return [key, :green, :recognized_files] if @file_keys.include?(key)

      key = content.split('.').last.downcase.to_sym

      return %i[file yellow unrecognized_files] unless @all_files.include?(key)

      key = @file_aliases[key] unless @file_keys.include?(key)
      [key, :green, :recognized_files]
    end

    def tree_traverse(path, prespace, indent)
      contents = init_contents(path)
      contents.each do |content|
        icon = (content == contents.last || Dir.exist?("#{path}/#{content}")) ? ' └──' : ' ├──'
        print tree_branch_preprint(prespace, indent, icon).colorize(:cyan)
        print " #{fetch_string(content, *options(path, content))} \n"
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
