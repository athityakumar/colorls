# frozen_string_literal: true

module ColorLS
  class Yaml
    def initialize(filename)
      @filepath = File.join(File.dirname(__FILE__),"../yaml/#{filename}")
      @user_config_filepath = File.join(Dir.home, ".config/colorls/#{filename}")
    end

    def deep_transform_key_vals_in_object(object, &block)
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          result[yield(key)] = deep_transform_key_vals_in_object(value, &block)
        end
      when Array
        object.map { |e| deep_transform_key_vals_in_object(e, &block) }
      else
        yield object
      end
    end

    def load(aliase: false)
      yaml = read_file(@filepath)
      if File.exist?(@user_config_filepath)
        user_config_yaml = read_file(@user_config_filepath)
        yaml = yaml.merge(user_config_yaml)
      end

      return yaml unless aliase

      deep_transform_key_vals_in_object(yaml.to_a, &:to_sym).to_h
    end

    def read_file(filepath)
      ::YAML.safe_load(File.read(filepath)).symbolize_keys
    end
  end
end
