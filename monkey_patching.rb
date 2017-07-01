require 'colorize'

def print(input, color=:white)
  Kernel.print(input.to_s.colorize(color))
end

def puts(input, color=:white)
  Kernel.puts(input.to_s.colorize(color))
end
