# frozen_string_literal: true

# Ensure GitHub access token is configured
if Rails.env.development? || Rails.env.test?
  unless ENV['GITHUB_ACCESS_TOKEN']
    warn 'WARNING: GITHUB_ACCESS_TOKEN is not set. GitHub API access will be limited.'
  end
end 