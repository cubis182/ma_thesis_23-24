#!/usr/bin/env ruby
require 'proiel'

tb = PROIEL::Treebank.new
Dir[File.join('vendor', 'proiel-treebank', '*.xml')].each do |filename|
  puts "Reading #{filename}..."
  tb.load_from_xml(filename)
end

tb.sources.each do |source|
  source.divs.each do |div|
    div.sentences.each do |sentence|
      sentence.tokens.each do |token|
        # Do something
      end
    end
  end
end