# frozen_string_literal: true

module ColorLS
  class Core
    def initialize(input, all: false, report: false, sort: false, show: false,
      mode: nil, git_status: false, almost_all: false, colors: [], group: nil,
      reverse: false, hyperlink: false, tree_depth: nil)
      @input        = File.absolute_path(input)
      @count        = {folders: 0, recognized_files: 0, unrecognized_files: 0}
      @all          = all
      @almost_all   = almost_all
      @hyperlink    = hyperlink
      @report       = report
      @sort         = sort
      @reverse      = reverse
      @group        = group
      @show         = show
      @one_per_line = mode == :one_per_line
      @long         = mode == :long
      @tree         = {mode: mode == :tree, depth: tree_depth}
      @horizontal   = mode == :horizontal
      process_git_status_details(git_status)

      @screen_width = IO.console.winsize[1]
      @screen_width = 80 if @screen_width.zero?

      init_colors colors

      @contents   = init_contents(input)
      init_icons
    end

    def ls
      return print "\n   Nothing to show here\n".colorize(@colors[:empty]) if @contents.empty?

      layout = case
               when @tree[:mode] then
                 print "\n"
                 return tree_traverse(@input, 0, 1, 2)
               when @horizontal then
                 HorizontalLayout.new(@contents, item_widths, @screen_width)
               when @one_per_line || @long then
                 SingleColumnLayout.new(@contents)
               else
                 VerticalLayout.new(@contents, item_widths, @screen_width)
               end

      layout.each_line do |line, widths|
        ls_line(line, widths)
      end

      display_report if @report
      true
    end

    private

    def init_colors(colors)
      @colors  = colors
      @modes = Hash.new do |hash, key|
        color = case key
                when 'r' then :read
                when 'w' then :write
                when '-' then :no_access
                when 'x', 's', 'S', 't', 'T' then :exec
                end
        hash[key] = key.colorize(@colors[color]).freeze
      end
    end

    # how much characters an item occupies besides its name
    CHARS_PER_ITEM = 12

    def item_widths
      @contents.map { |item| item.name.size + CHARS_PER_ITEM }
    end

    def init_contents(path)
      info = FileInfo.new(path, link_info = @long)

      if info.directory?
        @contents = Dir.entries(path)

        filter_hidden_contents

        @contents.map! { |e| FileInfo.new(File.join(path, e), link_info = @long) }

        filter_contents if @show
        sort_contents   if @sort
        group_contents  if @group
      else
        @contents = [info]
      end
      @total_content_length = @contents.length

      return @contents unless @long
      
      init_nlink_lengths
      init_user_lengths
      init_group_lengths
      @contents
    end

    def filter_hidden_contents
      @contents -= %w[. ..] unless @all
      @contents.keep_if { |x| !x.start_with? '.' } unless @all || @almost_all
    end
    
    def init_nlink_lengths
      @nlinklength = @contents.map do |c|
        c.nlink.to_s.length
      end.max
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
      when :extension
        @contents.sort_by! do |f|
          name = f.name
          ext = File.extname(name)
          name = name.chomp(ext) unless ext.empty?
          [ext, name].map { |s| CLocale.strxfrm(s) }
        end
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

    def format_mode(rwx, special, char)
      m_r = (rwx & 4).zero? ? '-' : 'r'
      m_w = (rwx & 2).zero? ? '-' : 'w'
      m_x = if special
              (rwx & 1).zero? ? char.upcase : char
            else
              (rwx & 1).zero? ? '-' : 'x'
            end

      @modes[m_r] + @modes[m_w] + @modes[m_x]
    end
        
    def nlink(content)
      content.nlink.to_s.rjust(@nlinklength.to_i, ' ')
    end    

    def mode_info(stat)
      m = stat.mode

      format_mode(m >> 6, stat.setuid?, 's') +
        format_mode(m >> 3, stat.setgid?, 's') +
        format_mode(m, stat.sticky?, 't')
    end

    def user_info(content)
      content.owner.ljust(@userlength, ' ').colorize(@colors[:user])
    end

    def group_info(group)
      group.to_s.ljust(@grouplength, ' ').colorize(@colors[:normal])
    end

    def size_info(filesize)
      size = Filesize.from("#{filesize} B").pretty.split(' ')
      size = "#{size[0][0..-4].rjust(4,' ')} #{size[1].ljust(3,' ')}"
      return size.colorize(@colors[:file_large])  if filesize >= 512 * 1024 ** 2
      return size.colorize(@colors[:file_medium]) if filesize >= 128 * 1024 ** 2

      size.colorize(@colors[:file_small])
    end

    def mtime_info(file_mtime)
      now = Time.now
      
      if now.strftime("%Y") == file_mtime.strftime("%Y")
        mtime = file_mtime.strftime("%b %e %H:%M")
      else
        mtime = file_mtime.strftime("%b %e  %Y")
      end
      
      return mtime.colorize(@colors[:hour_old]) if now - file_mtime < 60 * 60
      return mtime.colorize(@colors[:day_old])  if now - file_mtime < 24 * 60 * 60

      mtime.colorize(@colors[:no_modifier])
    end

    def process_git_status_details(git_status)
      @git_status = case
                    when !git_status then nil
                    when File.directory?(@input) then Git.status(@input)
                    else Git.status(File.dirname(@input))
                    end
    end

    def git_info(content)
      return '' unless @git_status

      if content.directory?
        git_dir_info(content.name)
      else
        git_file_info(content.name)
      end
    end

    def git_file_info(path)
      return '  ✓ '.colorize(@colors[:unchanged]) unless @git_status[path]

      Git.colored_status_symbols(@git_status[path], @colors)
    end

    def git_dir_info(path)
      modes = if path == '.'
                Set.new(@git_status.values).flatten
              else
                @git_status.fetch(path, nil)
              end

      return Git.colored_status_symbols(modes, @colors) unless modes.nil?

      '    '
    end

    def long_info(content)
      return '' unless @long

      [mode_info(content.stats), nlink(content), user_info(content), group_info(content.group),
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

    def fetch_string(path, content, key, color, increment)
      @count[increment] += 1
      value = increment == :folders ? @folders[key] : @files[key]
      logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
      name = content.name
      name = make_link(path, name) if @hyperlink
      name += content.directory? ? '/' : ' '
      entry = logo + '  ' + name

      "#{long_info(content)} #{git_info(content)} #{entry.colorize(color)}#{symlink_info(content)}"
    end

    def ls_line(chunk, widths)
      padding = 0
      line = +''
      chunk.each_with_index do |content, i|
        line << ' ' * padding
        line << '  ' << fetch_string(@input, content, *options(content))
        padding = widths[i] - content.name.length - CHARS_PER_ITEM
      end
      print line << "\n"
    end

    def file_color(file, key)
      color_key = case
                  when file.chardev? then :chardev
                  when file.blockdev? then :blockdev
                  when file.socket? then :socket
                  else
                    @files.key?(key) ? :recognized_file : :unrecognized_file
                  end
      @colors[color_key]
    end

    def options(content)
      if content.directory?
        key = content.name.to_sym
        key = @folder_aliases[key] unless @folders.key? key
        key = :folder if key.nil?
        color = @colors[:dir]
        group = :folders
      else
        key = content.name.split('.').last.downcase.to_sym
        key = @file_aliases[key] unless @files.key? key
        key = :file if key.nil?
        color = file_color(content, key)
        group = @files.key?(key) ? :recognized_files : :unrecognized_files
      end

      [key, color, group]
    end

    def tree_traverse(path, prespace, depth, indent)
      contents = init_contents(path)
      contents.each do |content|
        icon = content == contents.last || content.directory? ? ' └──' : ' ├──'
        print tree_branch_preprint(prespace, indent, icon).colorize(@colors[:tree])
        print " #{fetch_string(path, content, *options(content))} \n"
        next unless content.directory?

        tree_traverse("#{path}/#{content}", prespace + indent, depth + 1, indent) if keep_going(depth)
      end
    end

    def keep_going(depth)
      @tree[:depth].nil? || depth < @tree[:depth]
    end

    def tree_branch_preprint(prespace, indent, prespace_icon)
      return prespace_icon if prespace.zero?

      ' │ ' * (prespace/indent) + prespace_icon + '─' * indent
    end

    def make_link(path, name)
      href = "file://#{path}/#{name}"
      "\033]8;;#{href}\007#{name}\033]8;;\007"
    end
  end
end
