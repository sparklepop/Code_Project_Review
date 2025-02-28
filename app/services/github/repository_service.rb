module Github
  class RepositoryService
    REPOS_ROOT = Rails.root.join('storage', 'code_reviews', 'repositories')

    def initialize(repository_url, code_review_id)
      @repository_url = repository_url
      @code_review_id = code_review_id
      @repo_dir = build_repo_path
      FileUtils.mkdir_p(REPOS_ROOT)
    end
    
    def fetch_repository
      cleanup_existing_repo
      clone_repository
      @repo_dir
    end
    
    def cleanup
      return unless @repo_dir
      
      begin
        FileUtils.rm_rf(@repo_dir)
        Rails.logger.info "Cleaned up repository: #{@repo_dir}"
      rescue => e
        Rails.logger.error "Failed to cleanup repository #{@repo_dir}: #{e.message}"
      end
    end
    
    private
    
    def cleanup_existing_repo
      FileUtils.rm_rf(@repo_dir) if Dir.exist?(@repo_dir)
    end
    
    def clone_repository
      result = system("git clone --depth 1 #{@repository_url} #{@repo_dir} 2>&1")
      raise "Failed to clone repository: #{$?}" unless result
    end
    
    def build_repo_path
      owner, repo = parse_repo_details
      REPOS_ROOT.join(
        @code_review_id.to_s,
        "#{owner}_#{repo}_#{Time.current.to_i}"
      )
    end
    
    def parse_repo_details
      match = @repository_url.match(%r{github\.com/([^/]+)/([^/]+)})
      raise "Invalid GitHub URL" unless match
      [match[1], match[2].sub(/\.git\z/, '')]
    end
  end
end 