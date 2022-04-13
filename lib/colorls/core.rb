# frozen_string_literal: true

module ColorLS
  # on Windows (were the special 'nul' device exists) we need to use UTF-8
  @file_encoding = File.exist?('nul') ? Encoding::UTF_8 : Encoding::ASCII_8BIT

  def self.file_encoding
    @file_encoding
  end

  def self.terminal_width
    console = IO.console

    width = IO.console_size[1]

    return width if console.nil? || console.winsize[1].zero?

    console.winsize[1]
  end

  @screen_width = terminal_width

  def self.screen_width
    @screen_width
  end

  class Core
    def initialize(all: false, sort: false, show: false,
      mode: nil, show_git: false, almost_all: false, colors: [], group: nil,
      reverse: false, hyperlink: false, tree_depth: nil, show_inode: false,
      indicator_style: 'slash', long_style_options: {})
      @count = {folders: 0, recognized_files: 0, unrecognized_files: 0}
      @all          = all
      @almost_all   = almost_all
      @hyperlink    = hyperlink
      @sort         = sort
      @reverse      = reverse
      @group        = group
      @show         = show
      @one_per_line = mode == :one_per_line
      @show_inode   = show_inode
      init_long_format(mode,long_style_options)
      @tree         = {mode: mode == :tree, depth: tree_depth}
      @horizontal   = mode == :horizontal
      @git_status   = init_git_status(show_git)
      @time_style   = long_style_options.key?(:time_style) ? long_style_options[:time_style] : ''
      @indicator_style = indicator_style
      @hard_links_count = long_style_options.key?(:hard_links_count) ? long_style_options[:hard_links_count] : true
      # how much characters an item occupies besides its name
      @additional_chars_per_item = 12 + (@show_git ? 4 : 0) + (@show_inode ? 10 : 0)

      init_colors colors

      init_icons
    end

    def ls_dir(info)
      if @tree[:mode]
        print "\n"
        return tree_traverse(info.path, 0, 1, 2)
      end

      @contents = Dir.entries(info.path, encoding: ColorLS.file_encoding)

      filter_hidden_contents

      @contents.map! { |e| FileInfo.dir_entry(info.path, e, link_info: @long) }

      filter_contents if @show
      sort_contents   if @sort
      group_contents  if @group

      return print "\n   Nothing to show here\n".colorize(@colors[:empty]) if @contents.empty?

      ls
    end

    def ls_files(files)
      @contents = files

      ls
    end

    def display_report(report_mode)
      if report_mode == :short
        puts <<~REPORT

          \s\s\s\sFolders: #{@count[:folders]}, Files: #{@count[:recognized_files] + @count[:unrecognized_files]}.
        REPORT
          .colorize(@colors[:report])
      else
        puts <<~REPORT

              Found #{@count.values.sum} items in total.

          \tFolders\t\t\t: #{@count[:folders]}
          \tRecognized files\t: #{@count[:recognized_files]}
          \tUnrecognized files\t: #{@count[:unrecognized_files]}
        REPORT
          .colorize(@colors[:report])
      end
    end

    private

    def ls
      init_column_lengths

      layout = case
               when @horizontal
                 HorizontalLayout.new(@contents, item_widths, ColorLS.screen_width)
               when @one_per_line || @long
                 SingleColumnLayout.new(@contents)
               else
                 VerticalLayout.new(@contents, item_widths, ColorLS.screen_width)
               end

      layout.each_line do |line, widths|
        ls_line(line, widths)
      end
    end

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

    def init_long_format(mode, long_style_options)
      @long = mode == :long
      @show_group = long_style_options.key?(:show_group) ? long_style_options[:show_group] : true
      @show_user = long_style_options.key?(:show_user) ? long_style_options[:show_user] : true
    end

    def init_git_status(show_git)
      @show_git = show_git
      return {}.freeze unless show_git

      # stores git status information per directory
      Hash.new do |hash, key|
        path = File.absolute_path key.parent
        if hash.key? path
          hash[path]
        else
          hash[path] = Git.status(path)
        end
      end
    end

    def item_widths
      @contents.map { |item| Unicode::DisplayWidth.of(item.show) + @additional_chars_per_item }
    end

    def filter_hidden_contents
      @contents -= %w[. ..] unless @all
      @contents.keep_if { |x| !x.start_with? '.' } unless @all || @almost_all
    end

    def init_column_lengths
      return unless @long

      maxlink = maxuser = maxgroup = 0

      @contents.each do |c|
        maxlink = c.nlink if c.nlink > maxlink
        maxuser = c.owner.length if c.owner.length > maxuser
        maxgroup = c.group.length if c.group.length > maxgroup
      end

      @linklength = maxlink.digits.length
      @userlength = maxuser
      @grouplength = maxgroup
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
      size = Filesize.new(filesize).pretty.split
      size = "#{size[0][0..-4].rjust(4,' ')} #{size[1].ljust(3,' ')}"
      return size.colorize(@colors[:file_large])  if filesize >= 512 * (1024 ** 2)
      return size.colorize(@colors[:file_medium]) if filesize >= 128 * (1024 ** 2)

      size.colorize(@colors[:file_small])
    end

    def mtime_info(file_mtime)
      mtime = @time_style.start_with?('+') ? file_mtime.strftime(@time_style.delete_prefix('+')) : file_mtime.asctime
      now = Time.now
      return mtime.colorize(@colors[:hour_old]) if now - file_mtime < 60 * 60
      return mtime.colorize(@colors[:day_old])  if now - file_mtime < 24 * 60 * 60

      mtime.colorize(@colors[:no_modifier])
    end

    def git_info(content)
      return '' unless (status = @git_status[content])

      if content.directory?
        git_dir_info(content, status)
      else
        git_file_info(status[content.name])
      end
    end

    def git_file_info(status)
      return Git.colored_status_symbols(status, @colors) if status

      '  ✓ '
        .encode(Encoding.default_external, undef: :replace, replace: '=')
        .colorize(@colors[:unchanged])
    end

    def git_dir_info(content, status)
      modes = if content.path == '.'
                Set.new(status.values).flatten
              else
                status[content.name]
              end

      if modes.empty? && Dir.empty?(content.path)
        '    '
      else
        Git.colored_status_symbols(modes, @colors)
      end
    end

    def inode(content)
      return '' unless @show_inode

      content.stats.ino.to_s.rjust(10).colorize(@colors[:inode])
    end

    def long_info(content)
      return '' unless @long

      links = content.nlink.to_s.rjust(@linklength)

      line_array = [mode_info(content.stats)]
      line_array.push links if @hard_links_count
      line_array.push user_info(content) if @show_user
      line_array.push group_info(content.group) if @show_group
      line_array.concat [size_info(content.size), mtime_info(content.mtime)]
      line_array.join('   ')
    end

    def symlink_info(content)
      return '' unless @long && content.symlink?

      target = content.link_target.nil? ? '…' : content.link_target
      link_info = " ⇒ #{target}"
      if content.dead?
        "#{link_info} [Dead link]".colorize(@colors[:dead_link])
      else
        link_info.colorize(@colors[:link])
      end
    end

    def out_encode(str)
      str.encode(Encoding.default_external, undef: :replace, replace: '')
    end

    def fetch_string(content, key, color, increment)
      @count[increment] += 1
      value = increment == :folders ? @folders[key] : @files[key]
      logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..].to_i(16)].pack('U') }
      name = @hyperlink ? make_link(content) : content.show
      name += content.directory? && @indicator_style != 'none' ? '/' : ' '
      entry = "#{out_encode(logo)}  #{out_encode(name)}"
      entry = entry.bright if !content.directory? && content.executable?

      "#{inode(content)} #{long_info(content)} #{git_info(content)} #{entry.colorize(color)}#{symlink_info(content)}"
    end

    def ls_line(chunk, widths)
      padding = 0
      line = +''
      chunk.each_with_index do |content, i|
        entry = fetch_string(content, *options(content))
        line << (' ' * padding)
        line << '  ' << entry.encode(Encoding.default_external, undef: :replace)
        padding = widths[i] - Unicode::DisplayWidth.of(content.show) - @additional_chars_per_item
      end
      print line << "\n"
    end

    def file_color(file, key)
      color_key = case
                  when file.chardev?    then :chardev
                  when file.blockdev?   then :blockdev
                  when file.socket?     then :socket
                  when file.executable? then :executable_file
                  when @files.key?(key) then :recognized_file
                  else                       :unrecognized_file
                  end
      @colors[color_key]
    end

    def options(content)
      if content.directory?
        key = content.name.downcase.to_sym
        key = @folder_aliases[key] unless @folders.key? key
        key = :folder if key.nil?
        color = @colors[:dir]
        group = :folders
      else
        key = File.extname(content.name).delete_prefix('.').downcase.to_sym
        key = @file_aliases[key] unless @files.key? key
        color = file_color(content, key)
        group = @files.key?(key) ? :recognized_files : :unrecognized_files
        key = :file if key.nil?
      end

      [key, color, group]
    end

    def tree_contents(path)
      @contents = Dir.entries(path, encoding: ColorLS.file_encoding)

      filter_hidden_contents

      @contents.map! { |e| FileInfo.dir_entry(path, e, link_info: @long) }

      filter_contents if @show
      sort_contents   if @sort
      group_contents  if @group

      @contents
    end

    def tree_traverse(path, prespace, depth, indent)
      contents = tree_contents(path)
      contents.each do |content|
        icon = content == contents.last || content.directory? ? ' └──' : ' ├──'
        print tree_branch_preprint(prespace, indent, icon).colorize(@colors[:tree])
        print " #{fetch_string(content, *options(content))} \n"
        next unless content.directory?

        tree_traverse("#{path}/#{content}", prespace + indent, depth + 1, indent) if keep_going(depth)
      end
    end

    def keep_going(depth)
      @tree[:depth].nil? || depth < @tree[:depth]
    end

    def tree_branch_preprint(prespace, indent, prespace_icon)
      return prespace_icon if prespace.zero?

      (' │ ' * (prespace/indent)) + prespace_icon + ('─' * indent)
    end

    def make_link(content)
      uri = Addressable::URI.convert_path(File.absolute_path(content.path))
      "\033]8;;#{uri}\007#{content.show}\033]8;;\007"
    end
  end
end
