class CodeReviewsController < ApplicationController
  before_action :set_code_review, only: [:show, :edit, :update, :destroy]

  def index
    @code_reviews = CodeReview.all
  end

  def new
    @code_review = CodeReview.new
  end

  def create
    @code_review = CodeReview.new(code_review_params)
    
    if @code_review.save
      @code_review.analyze_repository
      redirect_to @code_review, notice: 'Code review was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @code_review = CodeReview.find(params[:id])
  end

  def edit
    Rails.logger.debug "\n=== LOADING EDIT FORM ==="
    Rails.logger.debug "Clarity Scores: #{@code_review.clarity_scores.inspect}"
    Rails.logger.debug "Architecture Scores: #{@code_review.architecture_scores.inspect}"
    Rails.logger.debug "Practices Scores: #{@code_review.practices_scores.inspect}"
    Rails.logger.debug "Problem Solving Scores: #{@code_review.problem_solving_scores.inspect}"
    Rails.logger.debug "Bonus Scores: #{@code_review.bonus_scores.inspect}"
  end

  def update
    respond_to do |format|
      if @code_review.update(code_review_params)
        format.html { redirect_to @code_review, notice: 'Code review was successfully updated.' }
        format.json { render :show, status: :ok, location: @code_review }
      else
        format.html { render :edit }
        format.json { render json: @code_review.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @code_review = CodeReview.find(params[:id])
    @code_review.destroy
    
    redirect_to code_reviews_path, notice: 'Code review was successfully deleted.'
  end

  def download
    @code_review = CodeReview.find(params[:id])
    # TODO: Implement download functionality
  end

  def analyze_submission
    begin
      submission_url = params.dig(:code_review, :submission_url)
      
      if submission_url.blank?
        render json: { error: "Submission URL is required" }, status: :unprocessable_entity
        return
      end

      analyzer = Ai::CodeReviewer.new(submission_url)
      analysis = analyzer.analyze
      
      puts "\n=== ANALYSIS RESULTS ==="
      puts JSON.pretty_generate(analysis)
      puts "======================="
      
      if analysis.present? && analysis[:quality_scores].present?
        render json: analysis
      else
        render json: { error: "Analysis failed to produce scores" }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("Analysis error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: "Analysis failed: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def update_score
    @code_review = CodeReview.find(params[:id])
    
    # Validate score_type parameter
    unless valid_score_type?(params[:score_type])
      render json: { error: "Invalid score type" }, status: :unprocessable_entity
      return
    end

    # Validate score_field parameter
    unless valid_score_field?(params[:score_type], params[:score_field])
      render json: { error: "Invalid score field" }, status: :unprocessable_entity
      return
    end

    value = params[:value].to_i
    
    # Update score using a safe method
    if update_score_safely(@code_review, params[:score_type], params[:score_field], value)
      render json: { 
        success: true, 
        total_score: @code_review.calculate_total_score,
        section_score: calculate_section_score(@code_review, params[:score_type])
      }
    else
      render json: { success: false, errors: @code_review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def valid_score_type?(score_type)
    VALID_SCORE_TYPES.include?(score_type)
  end

  def valid_score_field?(score_type, field)
    case score_type
    when 'quality_scores'
      CodeReview.permitted_quality_score_keys.include?(field)
    when 'documentation_scores'
      CodeReview.permitted_documentation_score_keys.include?(field)
    when 'technical_scores'
      CodeReview.permitted_technical_score_keys.include?(field)
    when 'problem_solving_scores'
      CodeReview.permitted_problem_solving_score_keys.include?(field)
    when 'testing_scores'
      CodeReview.permitted_testing_score_keys.include?(field)
    else
      false
    end
  end

  def update_score_safely(code_review, score_type, field, value)
    scores = code_review.public_send(score_type) || {}
    scores[field] = value
    code_review.public_send("#{score_type}=", scores)
    code_review.save
  end

  def calculate_section_score(code_review, score_type)
    case score_type
    when 'quality_scores'
      code_review.calculate_quality_score
    when 'documentation_scores'
      code_review.calculate_documentation_score
    when 'technical_scores'
      code_review.calculate_technical_score
    when 'problem_solving_scores'
      code_review.calculate_problem_solving_score
    when 'testing_scores'
      code_review.calculate_testing_bonus
    end
  end

  def code_review_params
    params.require(:code_review).permit(
      :repository_url,
      :candidate_name,
      :reviewer_name,
      :non_working_solution,
      :overall_comments,
      clarity_scores: [
        method_simplicity: [:score, :feedback],
        naming_conventions: [:score, :feedback],
        code_organization: [:score, :feedback],
        comments_quality: [:score, :feedback]
      ],
      architecture_scores: [
        separation_of_concerns: [:score, :feedback],
        file_organization: [:score, :feedback],
        dependency_management: [:score, :feedback],
        framework_usage: [:score, :feedback]
      ],
      practices_scores: [
        commit_quality: [:score, :feedback],
        basic_testing: [:score, :feedback],
        documentation: [:score, :feedback]
      ],
      problem_solving_scores: [
        solution_simplicity: [:score, :feedback],
        code_reuse: [:score, :feedback]
      ],
      bonus_scores: [
        advanced_testing: [:score, :feedback],
        security_practices: [:score, :feedback],
        performance_considerations: [:score, :feedback]
      ]
    )
  end

  def set_code_review
    @code_review = CodeReview.find(params[:id])
  end

  # Define valid score types and fields
  VALID_SCORE_TYPES = %w[
    quality_scores
    documentation_scores
    technical_scores
    problem_solving_scores
    testing_scores
  ].freeze

  PERMITTED_QUALITY_SCORES_KEYS = %w[
    code_clarity
    code_clarity_reason
    naming_conventions
    naming_conventions_reason
    code_organization
    code_organization_reason
  ].freeze

  PERMITTED_DOCUMENTATION_SCORES_KEYS = %w[
    setup_instructions
    setup_instructions_reason
    technical_decisions
    technical_decisions_reason
    assumptions
    assumptions_reason
  ].freeze

  PERMITTED_TECHNICAL_SCORES_KEYS = %w[
    solution_correctness
    solution_correctness_reason
    error_handling
    error_handling_reason
    language_usage
    language_usage_reason
  ].freeze

  PERMITTED_PROBLEM_SOLVING_SCORES_KEYS = %w[
    completeness
    completeness_reason
    approach
    approach_reason
  ].freeze

  PERMITTED_TESTING_SCORES_KEYS = %w[
    coverage
    coverage_reason
    quality
    quality_reason
    edge_cases
    edge_cases_reason
  ].freeze
end 