module ColorLS
  def self.load_from_yaml(filename, aliase=false)
    filepath = File.join(File.dirname(__FILE__),"../yaml/#{filename}")
    yaml     = YAML.safe_load(File.read(filepath)).symbolize_keys
    return yaml unless aliase
    yaml
      .to_a
      .map! { |k, v| [k, v.to_sym] }
      .to_h
  end
end
