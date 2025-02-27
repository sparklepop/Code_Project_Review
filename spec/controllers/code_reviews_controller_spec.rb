require 'rails_helper'

RSpec.describe CodeReviewsController do
  describe 'GET #index' do
    it 'returns successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    let(:code_review) { create(:code_review, :outstanding) }

    it 'returns successful response' do
      get :show, params: { id: code_review.id }
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'returns successful response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        code_review: {
          candidate_name: 'John Doe',
          submission_url: 'https://github.com/johndoe/project',
          reviewer_name: 'Jane Smith',
          quality_scores: {
            code_clarity: 14,
            naming_conventions: 9,
            code_organization: 10
          }
        }
      }
    end

    context 'with valid params' do
      it 'creates a new code review' do
        expect {
          post :create, params: valid_params
        }.to change(CodeReview, :count).by(1)
      end

      it 'redirects to the created code review' do
        post :create, params: valid_params
        expect(response).to redirect_to(CodeReview.last)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        { code_review: { candidate_name: '' } }
      end

      it 'does not create a new code review' do
        expect {
          post :create, params: invalid_params
        }.not_to change(CodeReview, :count)
      end

      it 're-renders the new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end
end 