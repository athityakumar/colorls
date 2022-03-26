# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ColorLS::Yaml do
  filenames = {
    file_aliases: :value,
    folder_aliases: :value,
    folders: :key,
    files: :key
  }.freeze

  let(:base_directory) { 'lib/yaml' }

  filenames.each do |filename, sort_type|
    describe filename do
      let(:checker) { YamlSortChecker.new("#{base_directory}/#{filename}.yaml") }

      it 'is sorted correctly' do
        expect(checker.sorted?(sort_type)).to be true
      end
    end
  end
end
