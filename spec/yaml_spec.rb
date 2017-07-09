require 'spec_helper'
require 'support/yaml_sort_checker.rb'

RSpec.describe 'Yaml files' do
  let(:base_directory) { 'lib/yaml' }

  describe 'file_aliases.yaml' do
    let(:checker) { YamlSortChecker.new("#{base_directory}/file_aliases.yaml") }

    it 'is sorted correctly' do
      expect(checker.sorted?(:value)).to eq true
    end
  end

  describe 'folder_aliases.yaml' do
    let(:checker) { YamlSortChecker.new("#{base_directory}/folder_aliases.yaml") }

    it 'is sorted correctly' do
      expect(checker.sorted?(:value)).to eq true
    end
  end

  describe 'folders.yaml' do
    let(:checker) { YamlSortChecker.new("#{base_directory}/folders.yaml") }

    it 'is sorted correctly' do
      expect(checker.sorted?).to eq true
    end
  end

  describe 'files.yaml' do
    let(:checker) { YamlSortChecker.new("#{base_directory}/files.yaml") }

    it 'is sorted correctly' do
      expect(checker.sorted?).to eq true
    end
  end
end
