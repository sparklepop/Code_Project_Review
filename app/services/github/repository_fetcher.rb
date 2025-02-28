# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'

module Github
  class RepositoryFetcher
    ALLOWED_EXTENSIONS = %w[.rb .js .py .java .go .cs .php .ts .jsx .tsx]
    TEST_PATHS = %w[/spec/ /test/ /features/]
    IGNORED_PATHS = %w[
      /db/schema.rb
      /config/routes.rb
      /bin/
      /vendor/
    ]
    MAX_FILES = {
      source: 20,
      test: 20
    }

    def initialize(url)
      @url = url
      @temp_dir = Dir.mktmpdir('code_reviewer_')
    end

    def fetch
      clone_repository
      read_repository_files
    ensure
      cleanup
    end

    private

    def clone_repository
      Rails.logger.debug "Cloning repository: #{@url}"
      system("git clone --depth 1 #{@url} #{@temp_dir}")
      raise GithubError, "Failed to clone repository" unless $?.success?
    end

    def read_repository_files
      {
        source_files: read_files_by_type(:source),
        test_files: read_files_by_type(:test)
      }
    end

    def read_files_by_type(type)
      files = {}
      matching_files = Dir.glob("#{@temp_dir}/**/*")
        .select { |f| File.file?(f) }
        .select { |f| should_analyze?(f, type) }
        .take(MAX_FILES[type])

      matching_files.each do |file_path|
        relative_path = file_path.sub("#{@temp_dir}/", '')
        Rails.logger.debug "Reading #{type} file: #{relative_path}"

        files[relative_path] = {
          content: File.read(file_path),
          size: File.size(file_path),
          path: relative_path
        }
      end

      Rails.logger.info "Successfully read #{files.size} #{type} files"
      files
    end

    def should_analyze?(file_path, type)
      extension = File.extname(file_path)
      relative_path = file_path.sub("#{@temp_dir}/", '')

      return false unless ALLOWED_EXTENSIONS.include?(extension)
      return false if File.size(file_path) > 500_000 # Skip files > 500KB
      return false if IGNORED_PATHS.any? { |ignored| relative_path.include?(ignored) }

      case type
      when :test
        TEST_PATHS.any? { |path| relative_path.include?(path) }
      when :source
        TEST_PATHS.none? { |path| relative_path.include?(path) }
      end
    end

    def cleanup
      FileUtils.remove_entry(@temp_dir) if @temp_dir
    rescue StandardError => e
      Rails.logger.error "Failed to cleanup temporary directory: #{e.message}"
    end
  end

  class GithubError < StandardError; end
end 