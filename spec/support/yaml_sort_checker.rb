# frozen_string_literal: true

require 'yaml'
require 'open3' # workaround https://github.com/samg/diffy#119
require 'diffy'

# Check Yaml if Alphabetically sorted
class YamlSortChecker
  class NotSortedError < StandardError; end

  def initialize(filename)
    @yaml = YAML.load_file(filename)
  end

  def sorted?(type=:key)
    case type.to_sym
    when :key   then key_sorted?
    when :value then value_sorted?
    end

    true
  end

  private

  attr_reader :yaml

  def key_sorted?
    sorted_yaml = yaml.to_a.sort_by { |content| content[0].downcase }

    different_from_yaml? sorted_yaml
  end

  def value_sorted?
    sorted_yaml = yaml.to_a.sort_by do |content|
      [content[1].downcase, content[0].downcase]
    end

    different_from_yaml? sorted_yaml
  end

  def different_from_yaml?(sorted_yaml)
    actual_str   = enum_to_str(yaml)
    expected_str = enum_to_str(sorted_yaml)

    difference = Diffy::Diff.new(actual_str, expected_str).to_s

    return if difference.empty?

    raise NotSortedError, "\n#{difference}"
  end

  def enum_to_str(enum)
    enum.to_a.map { |x| x.join(' ') }.join("\n")
  end
end
