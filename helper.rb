module ColorLS
  class Helper
    def ls
      @contents.each do |chunk|
        next end_multiple_results if chunk.empty?

        chunk.each do |content|
          opts = process_content(content)
          next print opts if opts.is_a?(String)
          show(content, *opts)
        end
        print "\n"
      end
    end

    def display_report
      total = @count.values.transpose[@index].sum

      print "\nFound #{total} contents in directory "
      print File.expand_path(@inputs[@index] || Dir.pwd).to_s, :blue

      puts  "\n\n\tFolders\t\t\t: #{@count[:folders][@index]}"\
        "\n\tRecognized files\t: #{@count[:recognized_files][@index]}"\
        "\n\tUnrecognized files\t: #{@count[:unrecognized_files][@index]}\n"
    end

    private

    def process_content(content)
      abs_path = "#{@inputs[@index] || Dir.pwd}/#{content}"
      dir_exists = Dir.exist?(abs_path) || %w[. ..].include?(content)
      file_exists = File.exist?(abs_path)

      return "#{content} \t" unless dir_exists || file_exists
      return %i[folder blue folders] if dir_exists

      key = content.split('.').last.downcase.to_sym
      return %i[file yellow unrecognized_files] unless @all_keys.include?(key)

      key = @aliases[key] unless @format_keys.include?(key)
      [key, :green, :recognized_files]
    end

    def end_multiple_results
      puts "\n\t"
      display_report
      @index += 1
    end

    def show(content, key, color, increment)
      @count[increment][@index] += 1

      value = @formats[key]
      logo  = value
              .gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
      print "#{logo}  #{content} \t", color
    end
  end
end
