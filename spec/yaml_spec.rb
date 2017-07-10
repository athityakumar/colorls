require 'spec_helper'

RSpec.describe 'Yaml files' do
  ::FILENAMES = {
    file_aliases:   :value,
    folder_aliases: :value,
    folders:        :key,
    files:          :key
  }.freeze

  let(:base_directory) { 'lib/yaml' }

  FILENAMES.each do |filename, sort_type|
    describe filename do
      let(:checker) { YamlSortChecker.new("#{base_directory}/#{filename}.yaml") }

      it 'is sorted correctly' do
        expect(checker.sorted?(sort_type)).to eq true
      end
    end
  end
end
