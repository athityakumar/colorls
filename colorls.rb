#!/usr/bin/env ruby

require 'colorize'
require 'yaml'
require 'facets'
require 'terminfo'

# Source for icons unicode: http://nerdfonts.com/
class ColorLS # rubocop:disable ClassLength
  def initialize(input = nil, report:, sort:, show:, one_per_line:)
    @input        = input || Dir.pwd
    @count        = { folders: 0, recognized_files: 0, unrecognized_files: 0 }
    @report       = report
    @sort         = sort
    @show         = show
    @one_per_line = one_per_line
    @screen_width = TermInfo.screen_size.last

    init_contents
    @max_widths = @contents.map(&:length)
    init_icons
  end

  def ls
    @contents = chunkify
    @max_widths = @contents.transpose.map { |c| c.map(&:length).max }
    @contents.each { |chunk| ls_line(chunk) }
    print "\n"
    display_report if @report

    true
  end

  private

  def init_contents
    @contents = Dir.entries(@input) - ['.', '..']

    filter_contents if @show
    sort_contents   if @sort

    @total_content_length = @contents.length
  end

  def filter_contents
    @contents.keep_if do |x|
      next Dir.exist?("#{@input}/#{x}") if @show == :dirs
      !Dir.exist?("#{@input}/#{x}")
    end
  end

  def sort_contents
    @contents.sort! { |a, b| cmp_by_dirs(a, b) }
  end

  def cmp_by_dirs(a, b)
    is_a_dir = Dir.exist?("#{@input}/#{a}")
    is_b_dir = Dir.exist?("#{@input}/#{b}")

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
    return @contents.zip if @one_per_line

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
    return false if @max_widths.sum + 6 * chunk_size > @screen_width
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

  def fetch_string(content, key, color, increment)
    @count[increment] += 1
    value = increment == :folders ? @folders[key] : @files[key]
    logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }

    "#{logo}  #{content}".colorize(color)
  end

  def load_from_yaml(filename, aliase = false)
    prog = $PROGRAM_NAME
    path = prog.include?('/colorls.rb') ? prog.gsub('/colorls.rb', '') : '.'
    yaml = YAML.safe_load(File.read("#{path}/#{filename}")).symbolize_keys
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

      print "  #{fetch_string(content, *options(content))}"
      print Dir.exist?("#{@input}/#{content}") ? '/'.colorize(:blue) : ' '
      print ' ' * (@max_widths[i] - content.length)
    end
  end

  def options(content)
    if Dir.exist?("#{@input}/#{content}")
      key = content.to_sym
      return %i[folder blue folders] unless @all_folders.include?(key)
      key = @folder_aliases[key] unless @folder_keys.include?(key)
      return [key, :blue, :folders]
    end

    key = content.split('.').last.downcase.to_sym

    return %i[file yellow unrecognized_files] unless @all_files.include?(key)

    key = @file_aliases[key] unless @file_keys.include?(key)
    [key, :green, :recognized_files]
  end
end

args             = *ARGV
opts             = {}

opts[:report]       = args.include?('-r') || args.include?('--report')
opts[:one_per_line] = args.include?('-1')

show_dirs_only   = args.include?('-d')  || args.include?('--dirs')
show_files_only  = args.include?('-f')  || args.include?('--files')
sort_dirs_first  = args.include?('-sd') || args.include?('--sort-dirs')
sort_files_first = args.include?('-sf') || args.include?('--sort-files')

if sort_dirs_first && sort_files_first
  STDERR.puts "\n  Restrain from using -sd and -sf flags together."
    .colorize(:red)
  return
end

if show_files_only && show_dirs_only
  STDERR.puts "\n  Restrain from using -d and -f flags together."
    .colorize(:red)
  return
end

opts[:sort] = if sort_files_first
                :files
              elsif sort_dirs_first
                :dirs
              end

opts[:show] = if show_files_only
                :files
              elsif show_dirs_only
                :dirs
              end

args.keep_if { |arg| !arg.start_with?('-') }

if args.empty?
  ColorLS.new(opts).ls
else
  args.each do |path|
    if Dir.exist?(path)
      ColorLS.new(path, opts).ls
    else
      next STDERR.puts "\n  Specified directory '#{path}' doesn't exist."
        .colorize(:red)
    end
  end
end

true
