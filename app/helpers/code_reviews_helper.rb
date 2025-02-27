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
end 