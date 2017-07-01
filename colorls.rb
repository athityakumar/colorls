require 'yaml'
require 'facets'
require 'terminfo'

# Source for icons unicode: http://nerdfonts.com/
class ColorLS
  def initialize(input, report)
    @input        = input || Dir.pwd
    @contents     = Dir.entries(@input) - ['.', '..']
    @count        = {folders: 0, recognized_files: 0, unrecognized_files: 0}
    @report       = report
    @screen_width = TermInfo.screen_size.last
    @max_widths   = @contents.map(&:length)

    init_icons
  end

  def ls
    @contents = chunkify
    @contents.each { |chunk| ls_line(chunk) }
    print "\n"
    display_report if @report

    true
  end

  private

  def init_icons
    @formats     = load_from_yaml('formats.yaml').symbolize_keys
    @aliases     = load_from_yaml('aliases.yaml')
                   .to_a
                   .map! { |k, v| [k.to_sym, v.to_sym] }
                   .to_h
    @format_keys = @formats.keys
    @aliase_keys = @aliases.keys
  end

  def chunkify
    chunk_size = @contents.count
    chunk      = [@contents]

    until in_line(chunk_size)
      chunk_size -= 1
      chunk       = @contents.each_slice(chunk_size).to_a
      chunk.last += [''] * (chunk_size - chunk.last.count)
      @max_widths = chunk.transpose.map { |c| c.map(&:length).max }
    end

    chunk
  end

  def in_line(chunk_size)
    return false if @max_widths.sum + 6 * chunk_size > @screen_width
    true
  end

  def display_report
    print "\n   Found #{@contents.flatten.length} contents in directory "
      .colorize(:white)

    print File.expand_path(@input).to_s.colorize(:blue)

    puts  "\n\n\tFolders\t\t\t: #{@count[:folders]}"\
      "\n\tRecognized files\t: #{@count[:recognized_files]}"\
      "\n\tUnrecognized files\t: #{@count[:unrecognized_files]}"
      .colorize(:white)
  end

  def fetch_string(content, key, color, increment)
    @count[increment] += 1

    value = @formats[key]
    logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
    "#{logo}  #{content}".colorize(color)
  end

  def load_from_yaml(filename)
    prog = $PROGRAM_NAME
    path = prog.include?('/colorls.rb') ? prog.gsub('/colorls.rb', '') : '.'
    YAML.safe_load(File.read("#{path}/#{filename}"))
  end

  def ls_line(chunk)
    print "\n"
    chunk.each_with_index do |content, i|
      break if content.empty?

      print '   '
      print fetch_string(content, *options(content))
      print ' ' * (@max_widths[i] - content.length)
    end
  end

  def options(content)
    return %i[folder blue folders] if Dir.exist?("#{@input}/#{content}")

    all_keys = @format_keys + @aliase_keys
    key = content.split('.').last.downcase.to_sym

    return %i[file yellow unrecognized_files] unless all_keys.include?(key)

    key = @aliases[key] unless @format_keys.include?(key)
    [key, :green, :recognized_files]
  end
end

args = *ARGV

if args.include?('--report')
  report = true
  args.delete '--report'
else
  report = false
end

if args.empty?
  ColorLS.new(nil, report).ls
else
  args.each { |path| ColorLS.new(path, report).ls }
end

true
