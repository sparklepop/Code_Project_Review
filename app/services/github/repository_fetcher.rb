# frozen_string_literal: true

module Github
  class RepositoryFetcher
    def initialize(url)
      @url = url
      @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      validate_token!
    end

    def self.validate_token
      client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      client.user
      true
    rescue Octokit::Unauthorized
      false
    end

    def fetch
      owner, repo = parse_github_url
      fetch_repository_contents(owner, repo)
    rescue Octokit::Error => e
      Rails.logger.error("GitHub API error: #{e.message}")
      raise GithubError, "Failed to fetch repository: #{e.message}"
    end

    private

    def validate_token!
      unless ENV['GITHUB_ACCESS_TOKEN']
        raise GithubError, "GitHub access token not configured"
      end

      begin
        @client.user
      rescue Octokit::Unauthorized
        raise GithubError, "Invalid GitHub access token"
      rescue Octokit::Error => e
        raise GithubError, "GitHub API error: #{e.message}"
      end
    end

    def parse_github_url
      # Handle both HTTPS and SSH URLs
      # https://github.com/username/repo
      # git@github.com:username/repo.git
      if @url.include?('github.com')
        path = @url.split('github.com').last.delete_prefix('/').delete_prefix(':')
        owner, repo = path.split('/')
        repo = repo&.delete_suffix('.git')
        [owner, repo]
      else
        raise GithubError, "Invalid GitHub URL format"
      end
    end

    def fetch_repository_contents(owner, repo)
      # Get the default branch
      repository = @client.repository("#{owner}/#{repo}")
      default_branch = repository.default_branch

      # Get the tree with all files
      tree = @client.tree("#{owner}/#{repo}", default_branch, recursive: true)
      
      # Fetch content for each file
      tree.tree.each_with_object({}) do |item, files|
        next unless item.type == 'blob'
        
        begin
          content = @client.contents("#{owner}/#{repo}", path: item.path)
          files[item.path] = {
            content: Base64.decode64(content.content),
            size: item.size,
            path: item.path
          }
        rescue Octokit::Error => e
          Rails.logger.warn("Failed to fetch #{item.path}: #{e.message}")
          next
        end
      end
    end
  end

  class GithubError < StandardError; end
end 