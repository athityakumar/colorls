# frozen_string_literal: true

module ColorLS
  class Yaml
    def initialize(filename)
      @filepath = File.join(File.dirname(__FILE__),"../yaml/#{filename}")
      @user_config_filepath = File.join(Dir.home, ".config/colorls/#{filename}")
    end

    def load(aliase: false)
      yaml = read_file(@filepath)
      if File.exist?(@user_config_filepath)
        user_config_yaml = read_file(@user_config_filepath)
        yaml = yaml.merge(user_config_yaml)
      end

      return yaml unless aliase

      yaml.to_a.map! { |k, v| v.include?('#') ? [k, v] : [k, v.to_sym] }.to_h
    end

    def read_file(filepath)
      ::YAML.safe_load(File.read(filepath, encoding: Encoding::UTF_8)).transform_keys!(&:to_sym)
    end
  end
end
