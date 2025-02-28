require 'rails_helper'

RSpec.describe Github::RepositoryFetcher do
  describe '#fetch' do
    let(:fetcher) { described_class.new("https://github.com/example/repo") }
    let(:mock_client) { instance_double(Octokit::Client) }
    let(:mock_repo) { double(default_branch: 'main') }
    let(:mock_tree) { double(tree: [
      double(type: 'blob', path: 'README.md', size: 100),
      double(type: 'blob', path: 'app/models/user.rb', size: 200)
    ]) }
    let(:mock_content) { double(content: Base64.encode64('file content')) }

    before do
      allow(Octokit::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:user)
      allow(mock_client).to receive(:repository).and_return(mock_repo)
      allow(mock_client).to receive(:tree).and_return(mock_tree)
      allow(mock_client).to receive(:contents).and_return(mock_content)
    end

    it 'fetches repository contents' do
      result = fetcher.fetch
      expect(result.keys).to include('README.md', 'app/models/user.rb')
      expect(result['README.md'][:content]).to eq('file content')
    end
  end
end 