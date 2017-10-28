class String
  def colorize(color)
    self.color(color.to_sym)
  end

  def remove(pattern)
    gsub(pattern, '')
  end
end

class Hash
  def symbolize_keys
    new_hash = {}
    each_key do |key|
      new_hash[key.to_sym] = delete(key)
    end
    new_hash
  end
end

class Array
  def sum
    inject(:+)
  end
end
