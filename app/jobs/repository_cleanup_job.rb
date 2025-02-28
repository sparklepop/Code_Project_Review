class RepositoryCleanupJob < ApplicationJob
  queue_as :maintenance
  
  REPO_MAX_AGE = 24.hours
  
  def perform
    Rails.logger.info "Starting code review repository cleanup..."
    
    cleanup_count = 0
    repo_root = Github::RepositoryService::REPOS_ROOT
    
    Dir.glob(repo_root.join('*', '*')).each do |repo_dir|
      next unless File.directory?(repo_dir)
      
      if repo_too_old?(repo_dir)
        begin
          FileUtils.rm_rf(File.dirname(repo_dir)) # Remove the entire code review directory
          cleanup_count += 1
          Rails.logger.info "Cleaned up code review repository: #{repo_dir}"
        rescue => e
          Rails.logger.error "Failed to cleanup repository #{repo_dir}: #{e.message}"
        end
      end
    end
    
    Rails.logger.info "Code review repository cleanup completed. Removed #{cleanup_count} repositories."
  end
  
  private
  
  def repo_too_old?(repo_dir)
    File.mtime(repo_dir) < REPO_MAX_AGE.ago
  end
end 