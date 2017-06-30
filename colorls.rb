require 'colorize'
require 'yaml'
require 'facets'
require 'terminfo'

def print(input, color=:white)
  Kernel.print(input.to_s.colorize(color))
end

def puts(input, color=:white)
  Kernel.puts(input.to_s.colorize(color))
end

# Source for icons unicode: http://nerdfonts.com/
class ColorLS
  def initialize(*inputs)
    inputs = inputs.sort
    @inputs = inputs.first.start_with?('-') ? inputs[1..-1] : inputs
    @inputs_count = @inputs.count == 0 ? 1 : @inputs.count
    @count       = { 
      folders: [0]*@inputs_count,
      recognized_files: [0]*@inputs_count,
      unrecognized_files: [0]*@inputs_count
    }
    @contents    = `ls #{inputs.join(' ')}`.split("\n").map { |x| x.split(' ') }.to_a
    @formats     = load_from_yaml('formats.yaml').symbolize_keys
    @aliases     = load_from_yaml('aliases.yaml')
                   .to_a
                   .map! { |k, v| [k.to_sym, v.to_sym] }
                   .to_h
    @format_keys = @formats.keys
    @aliase_keys = @aliases.keys
    @all_keys    = @format_keys + @aliase_keys
  end

  def ls
    print "\n"
    i = 0

    @contents.each do |chunk|
      if chunk.empty?
        puts "\n\t"
        display_report i
        i += 1
      else       
        chunk.each do |content|
          input = @inputs[i] || Dir.pwd
          if Dir.exist?("#{input}/#{content}") || %w[. ..].include?(content)
            show(content, :folder, :blue, :folders, i)
          elsif File.exist?("#{input}/#{content}")
            key = content.split('.').last.downcase.to_sym

            if !@all_keys.include?(key)
              show(content, :file, :yellow, :unrecognized_files, i)
            else
              key = @aliases[key] unless @format_keys.include?(key)
              show(content, key, :green, :recognized_files, i)
            end
          else
            print "#{content} \t"
          end
        end
        print "\n"
      end
    end

    display_report i
    true
  end

  private

  def display_report(i)
    total = @count.values.transpose[i].sum
    print "\nFound #{total} contents in directory "

    print File.expand_path(@inputs[i] || Dir.pwd).to_s, :blue

    puts  "\n\n\tFolders\t\t\t: #{@count[:folders][i]}"\
      "\n\tRecognized files\t: #{@count[:recognized_files][i]}"\
      "\n\tUnrecognized files\t: #{@count[:unrecognized_files][i]}\n"
  end

  def show(content, key, color, increment, i)
    @count[increment][i] += 1
    value = @formats[key]
    logo  = value.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
    print "#{logo}  #{content} \t", color
  end

  def load_from_yaml(filename)
    prog = $PROGRAM_NAME
    path = prog.include?('/colorls.rb') ? prog.gsub('/colorls.rb', '') : '.'
    YAML.safe_load(File.read("#{path}/#{filename}"))
  end
end

ColorLS.new(*ARGV).ls
true
