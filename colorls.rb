require 'colorize'
require 'yaml'
require 'facets'
require 'terminfo'

# Source for icons unicode: http://nerdfonts.com/
class ColorLS
  def initialize(input)
    @input       = input || Dir.pwd
    @contents    = Dir.entries(@input) - ['.', '..']
    @count       = { folders: 0, recognized_files: 0, unrecognized_files: 0 }
    @formats     = load_from_yaml('formats.yaml').symbolize_keys
    @aliases     = load_from_yaml('aliases.yaml')
                   .to_a
                   .map! { |k, v| [k.to_sym, v.to_sym] }
                   .to_h
    @format_keys = @formats.keys
    @aliase_keys = @aliases.keys
  end

  def ls
    chunkify
    @contents.each { |chunk| ls_line(chunk) }
    display_report
  end

  private

  def chunkify
    @screen_width = TermInfo.screen_size.last
    @max_width    = @contents.map(&:length).max
    chunk_size    = @screen_width / @max_width
    chunk_size    = chunk_size - 1 while (chunk_size*(@max_width+16) > @screen_width)
    @contents     = @contents.each_slice(chunk_size).to_a
  end

  def display_report
    print "\n\nFound #{@contents.flatten.length} contents in directory "
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
    chunk.each do |content|
      print fetch_string(content, *options(content))
      print ' ' * (@max_width - content.length)
      print "\t\t"
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

ColorLS.new(ARGV[0]).ls
true
