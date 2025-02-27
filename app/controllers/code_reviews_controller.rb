class CodeReviewsController < ApplicationController
  def index
    @code_reviews = CodeReview.all
  end

  def new
    @code_review = CodeReview.new
  end

  def create
    puts "\n\n=== RECEIVED PARAMS ==="
    puts JSON.pretty_generate(params.to_unsafe_h)
    puts "======================="

    processed_params = code_review_params
    puts "\n=== PROCESSED PARAMS ==="
    puts JSON.pretty_generate(processed_params)
    puts "======================="

    @code_review = CodeReview.new(processed_params)
    puts "\n=== BEFORE SAVE ==="
    puts JSON.pretty_generate(@code_review.attributes)
    puts "======================="
    
    if @code_review.save
      saved_review = @code_review.reload
      puts "\n=== SAVED TO DATABASE ==="
      puts "ID: #{saved_review.id}"
      puts "Quality Scores: #{saved_review.quality_scores.inspect}"
      puts "Documentation Scores: #{saved_review.documentation_scores.inspect}"
      puts "Technical Scores: #{saved_review.technical_scores.inspect}"
      puts "Problem Solving Scores: #{saved_review.problem_solving_scores.inspect}"
      puts "Testing Scores: #{saved_review.testing_scores.inspect}"
      puts "======================="
      
      redirect_to @code_review, notice: 'Code review was successfully created.'
    else
      puts "\n=== SAVE FAILED ==="
      puts "Errors: #{@code_review.errors.full_messages}"
      puts "Current attributes: #{@code_review.attributes.inspect}"
      puts "======================="
      
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @code_review = CodeReview.find(params[:id])
  end

  def edit
    @code_review = CodeReview.find(params[:id])
    puts "\n=== LOADING EDIT FORM ==="
    puts "Quality Scores: #{@code_review.quality_scores.inspect}"
    puts "Documentation Scores: #{@code_review.documentation_scores.inspect}"
    puts "Technical Scores: #{@code_review.technical_scores.inspect}"
    puts "Problem Solving Scores: #{@code_review.problem_solving_scores.inspect}"
    puts "Testing Scores: #{@code_review.testing_scores.inspect}"
    puts "======================="
  end

  def update
    @code_review = CodeReview.find(params[:id])
    
    puts "\n=== UPDATE PARAMS ==="
    puts JSON.pretty_generate(params.to_unsafe_h)
    puts "======================="

    if @code_review.update(code_review_params)
      puts "\n=== UPDATED IN DATABASE ==="
      puts "ID: #{@code_review.id}"
      puts "Quality Scores: #{@code_review.quality_scores.inspect}"
      puts "Documentation Scores: #{@code_review.documentation_scores.inspect}"
      puts "Technical Scores: #{@code_review.technical_scores.inspect}"
      puts "Problem Solving Scores: #{@code_review.problem_solving_scores.inspect}"
      puts "Testing Scores: #{@code_review.testing_scores.inspect}"
      puts "======================="
      
      redirect_to @code_review, notice: 'Code review was successfully updated.'
    else
      puts "\n=== UPDATE FAILED ==="
      puts "Errors: #{@code_review.errors.full_messages}"
      puts "Current attributes: #{@code_review.attributes.inspect}"
      puts "======================="
      
      render :edit, status: :unprocessable_entity
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
    score_type = params[:score_type]
    score_field = params[:score_field]
    value = params[:value].to_i

    puts "\n=== UPDATING SCORE ==="
    puts "Type: #{score_type}"
    puts "Field: #{score_field}"
    puts "Value: #{value}"
    
    # Get current scores
    scores = @code_review.send(score_type) || {}
    # Update the specific score
    scores[score_field] = value
    # Update the attribute
    @code_review.send("#{score_type}=", scores)

    if @code_review.save
      puts "Updated successfully"
      puts "New scores: #{@code_review.send(score_type).inspect}"
      render json: { 
        success: true, 
        total_score: @code_review.calculate_total_score,
        section_score: @code_review.send("calculate_#{score_type.sub('_scores', '')}_score")
      }
    else
      puts "Update failed: #{@code_review.errors.full_messages}"
      render json: { success: false, errors: @code_review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def code_review_params
    params.require(:code_review).permit(
      :candidate_name,
      :submission_url,
      :reviewer_name,
      :non_working_solution,
      :overall_comments,
      quality_scores: [:code_clarity, :naming_conventions, :code_organization],
      documentation_scores: [:setup_instructions, :technical_decisions, :assumptions],
      technical_scores: [:solution_correctness, :error_handling, :language_usage],
      problem_solving_scores: [:completeness, :approach],
      testing_scores: [:coverage, :quality, :edge_cases]
    )
  end
end 