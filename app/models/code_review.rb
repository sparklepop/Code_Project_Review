class CodeReview < ApplicationRecord
  validates :repository_url, presence: true, format: { 
    with: %r{\Ahttps://github\.com/[^/]+/[^/]+(?:\.git)?\z},
    message: "must be a valid GitHub repository URL"
  }
  
  # Make these optional initially
  validates :candidate_name, presence: true, on: :update
  validates :reviewer_name, presence: true, on: :update

  # Store accessors for score components
  store_accessor :clarity_scores,
    :naming_conventions,
    :method_simplicity,
    :code_organization,
    :comments_quality,
    :category_total

  store_accessor :architecture_scores,
    :separation_of_concerns,
    :file_organization,
    :dependency_management,
    :framework_usage,
    :category_total

  store_accessor :practices_scores,
    :commit_quality,
    :basic_testing,
    :documentation,
    :category_total

  store_accessor :problem_solving_scores,
    :solution_simplicity,
    :code_reuse,
    :category_total

  store_accessor :bonus_scores,
    :advanced_testing,
    :security_practices,
    :performance_considerations,
    :category_total

  # Initialize and convert scores before save
  before_validation :process_scores

  attribute :status, :integer, default: 0

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  def analyze_repository
    github_service = Github::RepositoryService.new(repository_url, id)
    
    begin
      update_column(:status, CodeReview.statuses[:processing])
      analyzer = Ai::CodeReviewer.new(github_service.fetch_repository)
      results = analyzer.analyze
      
      # Format all individual scores to one decimal place
      [:clarity_scores, :architecture_scores, :practices_scores, :problem_solving_scores, :bonus_scores].each do |category|
        results[category].each do |key, value|
          if value.is_a?(Hash) && value["score"]
            value["score"] = format("%.1f", value["score"].to_f)
          end
        end
      end
      
      # Debug Problem Solving scores specifically
      Rails.logger.debug "\n=== Problem Solving Scores Before Update ==="
      Rails.logger.debug "Solution Simplicity: #{results.dig(:problem_solving_scores, :solution_simplicity, 'score')}"
      Rails.logger.debug "Code Reuse: #{results.dig(:problem_solving_scores, :code_reuse, 'score')}"
      Rails.logger.debug "Category Total: #{results.dig(:problem_solving_scores, :total_score)}"
      
      # Get category totals directly
      total = {
        clarity: results.dig(:clarity_scores, :total_score) || 0,
        architecture: results.dig(:architecture_scores, :total_score) || 0,
        practices: results.dig(:practices_scores, :total_score) || 0,
        problem_solving: results.dig(:problem_solving_scores, :total_score) || 0,
        bonus: results.dig(:bonus_scores, :total_score) || 0
      }
      
      final_total = total.values.sum
      
      # Store category totals in their respective score hashes
      results[:clarity_scores][:total_score] = format("%.1f", total[:clarity])
      results[:architecture_scores][:total_score] = format("%.1f", total[:architecture])
      results[:practices_scores][:total_score] = format("%.1f", total[:practices])
      results[:problem_solving_scores][:total_score] = format("%.1f", total[:problem_solving])
      results[:bonus_scores][:total_score] = format("%.1f", total[:bonus])
      
      result = update!(
        status: :completed,
        clarity_scores: results[:clarity_scores],
        architecture_scores: results[:architecture_scores],
        practices_scores: results[:practices_scores],
        problem_solving_scores: results[:problem_solving_scores],
        bonus_scores: results[:bonus_scores],
        total_score: format("%.1f", final_total),
        assessment_level: calculate_assessment_level(final_total)
      )
    rescue => e
      Rails.logger.error "\n=== Error in Analysis ==="
      Rails.logger.error e.message
      update_column(:status, CodeReview.statuses[:failed])
      update_column(:error_message, e.message)
    ensure
      github_service&.cleanup
    end
  end

  def formatted_score(score)
    return "0.0" if score.nil?
    format("%.1f", score.to_f)
  end

  def total_score
    score = self[:total_score].to_f - (non_working_solution? ? 30 : 0)
    format("%.1f", score)
  end

  private

  def process_scores
    score_attributes.each do |attr|
      current_scores = send(attr)
      
      # Convert the scores to a hash if needed
      scores = case current_scores
              when String
                JSON.parse(current_scores) rescue {}
              when ActionController::Parameters
                current_scores.to_unsafe_h
              when Hash
                current_scores
              else
                {}
              end
      
      # Don't transform the values, keep the structure
      send("#{attr}=", scores)
    end
  end

  def score_attributes
    %w[clarity_scores architecture_scores practices_scores problem_solving_scores bonus_scores]
  end

  def calculate_assessment_level(total)
    case total
    when 95..115 then "Outstanding - Strong Senior+ candidate"
    when 85..94 then "Excellent - Senior candidate"
    when 75..84 then "Good - Mid-level candidate"
    when 65..74 then "Fair - Junior candidate"
    else "Does not meet requirements"
    end
  end
end 