class CodeReviewsController < ApplicationController
  def index
    @code_reviews = CodeReview.all
  end

  def new
    @code_review = CodeReview.new
  end

  def create
    @code_review = CodeReview.new(code_review_params)
    
    if @code_review.save
      redirect_to @code_review, notice: 'Code review was successfully created.'
    else
      render :new
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