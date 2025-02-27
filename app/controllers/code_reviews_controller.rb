class CodeReviewsController < ApplicationController
  def index
    @code_reviews = CodeReview.all
  end

  def new
    @code_review = CodeReview.new
  end

  def create
    @code_review = CodeReview.new(code_review_params)
    
    Rails.logger.debug("Attempting to save code review with params: #{code_review_params.inspect}")
    
    if @code_review.save
      Rails.logger.info("Successfully saved code review ##{@code_review.id}")
      redirect_to @code_review, notice: 'Code review was successfully created.'
    else
      Rails.logger.error("Failed to save code review: #{@code_review.errors.full_messages}")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @code_review = CodeReview.find(params[:id])
  end

  def edit
    @code_review = CodeReview.find(params[:id])
  end

  def update
    @code_review = CodeReview.find(params[:id])
    
    if @code_review.update(code_review_params)
      redirect_to @code_review, notice: 'Code review was successfully updated.'
    else
      render :edit
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
      
      Rails.logger.debug "Received submission URL: #{submission_url}"
      
      if submission_url.blank?
        render json: { error: "Submission URL is required" }, status: :unprocessable_entity
        return
      end

      analyzer = Ai::CodeReviewer.new(submission_url)
      analysis = analyzer.analyze
      
      Rails.logger.debug "Analysis completed: #{analysis.inspect}"
      
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

  private

  def code_review_params
    params.require(:code_review).permit(
      :candidate_name,
      :submission_url,
      :reviewer_name,
      :non_working_solution,
      :overall_comments,
      quality_scores: {},
      documentation_scores: {},
      technical_scores: {},
      problem_solving_scores: {},
      testing_scores: {}
    )
  end
end 