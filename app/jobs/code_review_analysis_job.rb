class CodeReviewAnalysisJob < ApplicationJob
  queue_as :default
  
  def perform(code_review)
    code_review.update!(status: :processing)
    github_service = nil
    
    begin
      github_service = Github::RepositoryService.new(
        code_review.repository_url,
        code_review.id
      )
      analyzer = Ai::CodeReviewer.new(github_service.fetch_repository)
      results = analyzer.analyze
      
      code_review.update!(
        status: :completed,
        scores: results
      )
    rescue => e
      code_review.update!(
        status: :failed,
        error_message: e.message
      )
    ensure
      github_service&.cleanup
    end
  end
end 