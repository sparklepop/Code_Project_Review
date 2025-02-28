# frozen_string_literal: true

module Ai
  class LanguageDetector
    LANGUAGE_EXTENSIONS = {
      ruby: %w[.rb .rake Gemfile Rakefile],
      javascript: %w[.js .jsx .ts .tsx],
      python: %w[.py],
      java: %w[.java],
      go: %w[.go],
      rust: %w[.rs],
      php: %w[.php],
      csharp: %w[.cs],
      # Add more languages as needed
    }.freeze

    def self.detect_languages(files)
      languages = files.each_with_object(Hash.new(0)) do |(path, _), counts|
        if (lang = language_from_path(path))
          counts[lang] += 1
        end
      end

      # Return languages sorted by frequency
      languages.sort_by { |_, count| -count }.map(&:first)
    end

    def self.language_from_path(path)
      ext = File.extname(path)
      filename = File.basename(path)

      LANGUAGE_EXTENSIONS.find do |lang, patterns|
        patterns.any? { |pattern| path.end_with?(pattern) || filename == pattern }
      end&.first
    end
  end
end 