# frozen_string_literal: true

class String
  def colorize(color)
    self.color(color)
  end

  def uniq
    chars.uniq.join
  end
end
