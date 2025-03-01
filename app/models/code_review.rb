class CodeReview < ApplicationRecord
  validates :repository_url, presence: true, format: { 
    with: %r{\Ahttps://github\.com/[^/]+/[^/]+(?:\.git)?\z},
    message: "must be a valid GitHub repository URL"
  }
  
  # Make these optional initially
  validates :candidate_name, presence: true, on: :update
  validates :reviewer_name, presence: true, on: :update
  validates :quality_scores, presence: true, on: :update

  # Add accessors for score attributes
  store_accessor :quality_scores, :code_clarity, :naming_conventions, :code_organization
  store_accessor :documentation_scores, :setup_instructions, :technical_decisions, :assumptions
  store_accessor :technical_scores, :solution_correctness, :error_handling, :language_usage
  store_accessor :problem_solving_scores, :completeness, :approach
  store_accessor :testing_scores, :coverage, :quality, :edge_cases

  # Store accessors for score components
  store_accessor :clarity_scores,
    :naming_conventions,
    :method_simplicity,
    :code_organization,
    :comments_quality

  store_accessor :architecture_scores,
    :separation_of_concerns,
    :file_organization,
    :dependency_management,
    :framework_usage

  store_accessor :practices_scores,
    :commit_quality,
    :basic_testing,
    :documentation

  store_accessor :problem_solving_scores,
    :solution_simplicity,
    :code_reuse

  store_accessor :bonus_scores,
    :advanced_testing,
    :security_practices,
    :performance_considerations

  # Initialize and convert scores before save
  before_validation :process_scores

  attribute :status, :integer, default: 0

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  # Score calculation methods
  def calculate_quality_score
    return 0 unless quality_scores
    quality_scores.values.map(&:to_i).sum
  end

  def calculate_documentation_score
    return 0 unless documentation_scores
    documentation_scores.values.map(&:to_i).sum
  end

  def calculate_technical_score
    return 0 unless technical_scores
    technical_scores.values.map(&:to_i).sum
  end

  def calculate_problem_solving_score
    return 0 unless problem_solving_scores
    problem_solving_scores.values.map(&:to_i).sum
  end

  def calculate_testing_bonus
    return 0 unless testing_scores
    testing_scores.values.map(&:to_i).sum
  end

  def calculate_total_score
    [
      calculate_clarity_score,
      calculate_architecture_score,
      calculate_practices_score,
      calculate_problem_solving_score,
      calculate_bonus_score
    ].sum
  end

  def assessment_level
    case calculate_total_score
    when 95..115 then "Outstanding - Strong Senior+ candidate"
    when 85..94 then "Excellent - Senior candidate"
    when 75..84 then "Good - Mid-level candidate"
    when 65..74 then "Fair - Junior candidate"
    else "Does not meet requirements"
    end
  end

  def self.permitted_quality_score_keys
    %w[code_clarity code_clarity_reason naming_conventions naming_conventions_reason code_organization code_organization_reason]
  end

  def self.permitted_documentation_score_keys
    %w[setup_instructions setup_instructions_reason technical_decisions technical_decisions_reason assumptions assumptions_reason]
  end

  def analyze_repository
    github_service = Github::RepositoryService.new(repository_url, id)
    
    begin
      update_column(:status, CodeReview.statuses[:processing])  # Skip validations
      analyzer = Ai::CodeReviewer.new(github_service.fetch_repository)
      results = analyzer.analyze
      
      update!(
        status: :completed,
        quality_scores: results[:quality_scores] || {},
        documentation_scores: results[:documentation_scores] || {},
        technical_scores: results[:technical_scores] || {},
        problem_solving_scores: results[:problem_solving_scores] || {},
        testing_scores: results[:testing_scores] || {}
      )
    rescue => e
      update_column(:status, CodeReview.statuses[:failed])  # Skip validations
      update_column(:error_message, e.message)
    ensure
      github_service&.cleanup
    end
  end

  private

  def process_scores
    puts "\nProcessing scores before validation:"
    puts "Before: #{attributes.slice(*score_attributes).inspect}"
    
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
      
      # Ensure all values are integers
      scores.transform_values! { |v| v.to_i }
      
      # Update the attribute
      send("#{attr}=", scores)
    end
    
    puts "After: #{attributes.slice(*score_attributes).inspect}"
  end

  def score_attributes
    %w[clarity_scores architecture_scores practices_scores problem_solving_scores bonus_scores]
  end

  def calculate_clarity_score
    clarity_scores.values.map(&:to_f).sum
  end

  def calculate_architecture_score
    architecture_scores.values.map(&:to_f).sum
  end

  def calculate_practices_score
    practices_scores.values.map(&:to_f).sum
  end

  def calculate_bonus_score
    bonus_scores.values.map(&:to_f).sum
  end
end 