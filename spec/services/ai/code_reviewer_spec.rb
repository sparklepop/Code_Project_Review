require 'rails_helper'

RSpec.describe Ai::CodeReviewer do
  let(:test_repo_path) { Rails.root.join('spec', 'fixtures', 'test_repo').to_s }
  let(:code_reviewer) { described_class.new(test_repo_path) }

  before(:each) do
    # Create test repo directory if it doesn't exist
    FileUtils.mkdir_p(test_repo_path)
  end

  after(:each) do
    # Clean up test repo directory after each test
    FileUtils.rm_rf(test_repo_path)
  end

  describe '#initialize' do
    it 'creates a new instance with a repo path' do
      expect(code_reviewer).to be_a(described_class)
      expect(code_reviewer.instance_variable_get(:@repo_path)).to eq(test_repo_path)
    end
  end

  describe '#analyze' do
    before do
      # Create test files
      FileUtils.mkdir_p(File.join(test_repo_path, 'app/models'))
      File.write(File.join(test_repo_path, 'app/models/user.rb'), <<~RUBY)
        class User < ApplicationRecord
          validates :name, presence: true
          
          def full_name
            "\#{first_name} \#{last_name}"
          end
        end
      RUBY

      FileUtils.mkdir_p(File.join(test_repo_path, 'spec/models'))
      File.write(File.join(test_repo_path, 'spec/models/user_spec.rb'), <<~RUBY)
        require 'rails_helper'

        RSpec.describe User do
          it 'validates presence of name' do
            user = User.new
            expect(user.valid?).to be false
          end
        end
      RUBY
    end

    it 'returns analysis results with all required sections' do
      results = code_reviewer.analyze

      expect(results).to include(
        :clarity_scores,
        :architecture_scores,
        :practices_scores,
        :problem_solving_scores,
        :bonus_scores
      )
    end

    it 'analyzes code clarity' do
      results = code_reviewer.analyze
      clarity_scores = results[:clarity_scores]

      expect(clarity_scores).to include(
        :naming_conventions,
        :method_simplicity,
        :code_organization,
        :comments_quality,
        :total_score
      )
    end

    it 'analyzes architecture' do
      results = code_reviewer.analyze
      architecture_scores = results[:architecture_scores]

      expect(architecture_scores).to include(
        :separation_of_concerns,
        :file_organization,
        :framework_usage,
        :total_score
      )
    end

    it 'analyzes testing practices' do
      results = code_reviewer.analyze
      bonus_scores = results[:bonus_scores]

      expect(bonus_scores).to include(
        :basic_testing,
        :test_coverage,
        :test_organization
      )

      expect(bonus_scores[:basic_testing][:score]).to be_between(0, 10)
      expect(bonus_scores[:test_coverage][:score]).to be_between(0, 10)
      expect(bonus_scores[:test_organization][:score]).to be_between(0, 10)
    end
  end

  describe '#analyze_bonus_points' do
    before do
      FileUtils.mkdir_p(File.join(test_repo_path, 'spec/models'))
      File.write(File.join(test_repo_path, 'spec/models/user_spec.rb'), <<~RUBY)
        require 'rails_helper'

        RSpec.describe User do
          let(:user) { build(:user) }

          describe 'validations' do
            it 'validates presence of name' do
              expect(user).to validate_presence_of(:name)
            end
          end

          describe '#full_name' do
            it 'returns the combined first and last name' do
              user.first_name = 'John'
              user.last_name = 'Doe'
              expect(user.full_name).to eq('John Doe')
            end
          end
        end
      RUBY
    end

    it 'correctly analyzes test files' do
      ruby_files = {}
      js_files = {}
      test_files = { 'spec/models/user_spec.rb' => File.read(File.join(test_repo_path, 'spec/models/user_spec.rb')) }

      results = code_reviewer.send(:analyze_bonus_points, ruby_files, js_files, test_files)
      
      # Debug output
      puts "Test file content:"
      puts test_files['spec/models/user_spec.rb']
      puts "\nResults:"
      puts results.inspect
      
      # Check metrics directly
      metrics = results[:details][:metrics]
      expect(metrics[:test_stats][:test_count]).to be > 0, "Expected to find tests but found none"
      expect(metrics[:test_stats][:assertions]).to be > 0, "Expected to find assertions but found none"
      
      # Original assertions
      expect(results[:basic_testing][:score]).to be > 0, "Expected basic testing score to be > 0, got #{results[:basic_testing][:score]}"
      expect(results[:test_coverage][:score]).to be > 0
      expect(results[:test_organization][:score]).to be > 0
      expect(results[:feedback]).to be_a(String)
      expect(results[:details]).to include(:issues, :good_examples, :metrics)
    end

    it 'handles empty test files gracefully' do
      results = code_reviewer.send(:analyze_bonus_points, {}, {}, {})
      
      expect(results[:basic_testing][:score]).to eq(0)
      expect(results[:test_coverage][:score]).to eq(0)
      expect(results[:test_organization][:score]).to eq(0)
      expect(results[:feedback]).to be_a(String)
      expect(results[:details]).to include(:issues, :good_examples, :metrics)
    end

    it 'handles nil test files gracefully' do
      results = code_reviewer.send(:analyze_bonus_points, nil, nil, nil)
      
      expect(results[:basic_testing][:score]).to eq(0)
      expect(results[:test_coverage][:score]).to eq(0)
      expect(results[:test_organization][:score]).to eq(0)
      expect(results[:feedback]).to be_a(String)
      expect(results[:details]).to include(:issues, :good_examples, :metrics)
    end

    it 'handles malformed test files gracefully' do
      test_files = { 'spec/models/broken_spec.rb' => 'invalid ruby code here' }
      results = code_reviewer.send(:analyze_bonus_points, {}, {}, test_files)
      
      expect(results[:basic_testing][:score]).to eq(0)
      expect(results[:test_coverage][:score]).to eq(0)
      expect(results[:test_organization][:score]).to eq(0)
      expect(results[:feedback]).to be_a(String)
      expect(results[:details]).to include(:issues, :good_examples, :metrics)
    end
  end

  describe '#calculate_basic_testing_score' do
    it 'handles nil metrics gracefully' do
      score = code_reviewer.send(:calculate_basic_testing_score, nil)
      expect(score).to eq(0)
    end

    it 'handles empty metrics gracefully' do
      score = code_reviewer.send(:calculate_basic_testing_score, {})
      expect(score).to eq(0)
    end

    it 'handles metrics without test_stats gracefully' do
      score = code_reviewer.send(:calculate_basic_testing_score, { other_key: 'value' })
      expect(score).to eq(0)
    end

    it 'calculates score correctly with valid metrics' do
      metrics = {
        test_stats: {
          test_count: 10,
          assertion_count: 20
        }
      }
      score = code_reviewer.send(:calculate_basic_testing_score, metrics)
      expect(score).to be_between(0, 10)
    end
  end

  describe '#detect_test_framework' do
    it 'correctly identifies RSpec files' do
      test_content = <<~RUBY
        require 'rails_helper'
        
        RSpec.describe User do
          it 'does something' do
          end
        end
      RUBY
      
      framework = code_reviewer.send(:detect_test_framework, 'spec/models/user_spec.rb', test_content)
      expect(framework).to eq(:rspec)
    end
  end

  describe '#analyze_bonus_points step by step' do
    let(:test_content) { <<~RUBY
      require 'rails_helper'

      RSpec.describe User do
        it 'validates presence of name' do
          expect(user).to validate_presence_of(:name)
        end
      end
    RUBY
    }

    let(:test_files) { { 'spec/models/user_spec.rb' => test_content } }

    it 'initializes metrics correctly' do
      results = code_reviewer.send(:analyze_bonus_points, {}, {}, test_files)
      expect(results[:details]).to be_a(Hash)
      expect(results[:details][:metrics]).to be_a(Hash)
      expect(results[:details][:metrics][:test_stats]).to be_a(Hash)
    end

    it 'detects the test framework correctly' do
      framework = code_reviewer.send(:detect_test_framework, 'spec/models/user_spec.rb', test_content)
      expect(framework).to eq(:rspec)
    end

    it 'analyzes RSpec tests correctly' do
      metrics = { test_stats: { test_count: 0, assertions: 0, test_files: 0 } }
      code_reviewer.send(:analyze_rspec_tests, 'spec/models/user_spec.rb', test_content, metrics, [], [])
      expect(metrics[:test_stats][:test_count]).to be > 0
    end
  end

  describe 'score calculations' do
    before do
      FileUtils.mkdir_p(File.join(test_repo_path, 'app/models'))
      File.write(File.join(test_repo_path, 'app/models/user.rb'), <<~RUBY)
        class User < ApplicationRecord
          validates :name, presence: true
          
          def full_name
            "\#{first_name} \#{last_name}"
          end
        end
      RUBY
    end

    it 'returns numeric values for all non-bonus categories' do
      results = code_reviewer.analyze
      
      puts "\nScore Results:"
      puts "Clarity: #{results[:clarity_scores][:total_score]}"
      puts "Architecture: #{results[:architecture_scores][:total_score]}"
      puts "Practices: #{results[:practices_scores][:total_score]}"
      puts "Problem Solving: #{results[:problem_solving_scores][:total_score]}"
      
      expect(results[:clarity_scores][:total_score]).to be_a(Numeric)
      expect(results[:architecture_scores][:total_score]).to be_a(Numeric)
      expect(results[:practices_scores][:total_score]).to be_a(Numeric)
      expect(results[:problem_solving_scores][:total_score]).to be_a(Numeric)
      
      # Verify individual clarity scores
      expect(results[:clarity_scores][:naming_conventions][:score]).to be_a(Numeric)
      expect(results[:clarity_scores][:method_simplicity][:score]).to be_a(Numeric)
      expect(results[:clarity_scores][:code_organization][:score]).to be_a(Numeric)
      expect(results[:clarity_scores][:comments_quality][:score]).to be_a(Numeric)
      
      # Verify individual architecture scores
      expect(results[:architecture_scores][:separation_of_concerns][:score]).to be_a(Numeric)
      expect(results[:architecture_scores][:file_organization][:score]).to be_a(Numeric)
      expect(results[:architecture_scores][:framework_usage][:score]).to be_a(Numeric)
    end
  end
end 