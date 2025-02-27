require 'rails_helper'

RSpec.describe CodeReview do
  describe 'validations' do
    it { should validate_presence_of(:candidate_name) }
    it { should validate_presence_of(:submission_url) }
    it { should validate_presence_of(:reviewer_name) }
  end

  describe 'score calculations' do
    let(:code_review) do
      CodeReview.new(
        quality_scores: {
          code_clarity: 14,
          naming_conventions: 9,
          code_organization: 10
        },
        documentation_scores: {
          setup_instructions: 8,
          technical_decisions: 7,
          assumptions: 5
        },
        technical_scores: {
          solution_correctness: 14,
          error_handling: 5,
          language_usage: 5
        },
        problem_solving_scores: {
          completeness: 10,
          approach: 9
        },
        testing_scores: {
          coverage: 7,
          quality: 5,
          edge_cases: 3
        }
      )
    end

    it 'calculates quality score correctly' do
      expect(code_review.calculate_quality_score).to eq(33)
    end

    it 'calculates documentation score correctly' do
      expect(code_review.calculate_documentation_score).to eq(20)
    end

    it 'calculates technical score correctly' do
      expect(code_review.calculate_technical_score).to eq(24)
    end

    it 'calculates problem solving score correctly' do
      expect(code_review.calculate_problem_solving_score).to eq(19)
    end

    it 'calculates testing bonus correctly' do
      expect(code_review.calculate_testing_bonus).to eq(15)
    end

    it 'calculates total score correctly' do
      expect(code_review.calculate_total_score).to eq(111)
    end

    context 'when solution is non-working' do
      before { code_review.non_working_solution = true }

      it 'applies the non-working solution penalty' do
        expect(code_review.calculate_total_score).to eq(81)
      end
    end
  end

  describe '#assessment_level' do
    let(:code_review) { CodeReview.new }

    context 'with score >= 95' do
      before { allow(code_review).to receive(:calculate_total_score).and_return(95) }
      it { expect(code_review.assessment_level).to eq("Outstanding - Strong Senior+ candidate") }
    end

    context 'with score 85-94' do
      before { allow(code_review).to receive(:calculate_total_score).and_return(85) }
      it { expect(code_review.assessment_level).to eq("Excellent - Senior candidate") }
    end

    context 'with score 75-84' do
      before { allow(code_review).to receive(:calculate_total_score).and_return(75) }
      it { expect(code_review.assessment_level).to eq("Good - Mid-level candidate") }
    end

    context 'with score 65-74' do
      before { allow(code_review).to receive(:calculate_total_score).and_return(65) }
      it { expect(code_review.assessment_level).to eq("Fair - Junior candidate") }
    end

    context 'with score < 65' do
      before { allow(code_review).to receive(:calculate_total_score).and_return(64) }
      it { expect(code_review.assessment_level).to eq("Does not meet requirements") }
    end
  end
end 