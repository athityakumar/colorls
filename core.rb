module ColorLS
  class Core < Helper
    def initialize(*input)
      @index        = 0
      @inputs       = init_input(input)
      @inputs_count = @inputs.count.zero? ? 1 : @inputs.count
      @count        = init_count
      @contents     = query(input)
      @report       = true
      init_icons
    end

    def ls
      print "\n"

      super

      display_report if @report
      true
    end

    private

    def query(input)
      `ls #{input.join(' ')}`
        .split("\n")
        .map { |x| x.split(' ') }
        .to_a
    end

    def init_count
      {
        folders: [0] * @inputs_count,
        recognized_files: [0] * @inputs_count,
        unrecognized_files: [0] * @inputs_count
      }
    end

    def init_icons
      @formats = load_from_yaml('formats.yaml').symbolize_keys
      @aliases = load_from_yaml('aliases.yaml')
                 .to_a
                 .map! { |k, v| [k.to_sym, v.to_sym] }
                 .to_h
      @format_keys  = @formats.keys
      @aliase_keys  = @aliases.keys
      @all_keys     = @format_keys + @aliase_keys
    end

    def init_input(input)
      return [] if input.empty?

      input = input.sort!
      return input[1..-1] if input.first.start_with?('-')
      input
    end

    def load_from_yaml(filename)
      prog = $PROGRAM_NAME
      path = prog.include?('/colorls.rb') ? prog.gsub('/colorls.rb', '') : '.'
      YAML.safe_load(File.read("#{path}/#{filename}"))
    end
  end
end
