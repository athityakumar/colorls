# frozen_string_literal: true

class String
  def colorize(color)
    self.color(color)
  end

  def uniq
    split('').uniq.join
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
