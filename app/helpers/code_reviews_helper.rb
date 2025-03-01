module CodeReviewsHelper
  def assessment_level_class(level)
    case level.to_s.downcase
    when 'excellent'
      'bg-success text-white'
    when 'good'
      'bg-primary text-white'
    when 'fair'
      'bg-warning text-dark'
    when 'poor'
      'bg-danger text-white'
    else
      'bg-secondary text-white'
    end
  end

  def format_score(score, total = 115)
    "#{score.to_f.round(1)} / #{total}"
  end
end 