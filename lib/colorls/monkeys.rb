class String
  def colorize(color)
    self.color(color.to_sym)
  end

  def remove(pattern)
    self.gsub(pattern, '')
  end
end

class Hash
  def symbolize_keys
    keys.each do |key|
      new_key = (key.to_sym rescue key.to_s.to_sym)
      self[new_key] = delete(key)
    end
    self
  end
end

class Array
  def sum
    self.inject(:+)
  end
end