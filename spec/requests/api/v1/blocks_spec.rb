require 'rails_helper'

RSpec.describe 'Blocks API', type: :request do
  let(:blocker) { User.create!(username: 'alice', webhook_url: 'https://hooks.slack.com/a') }
  let(:blocked) { User.create!(username: 'bob', webhook_url: 'https://hooks.slack.com/b') }
  let(:token)   { blocker.raw_token }

  describe 'POST /api/v1/users/@:username/blocks' do
    it 'blocks another user successfully' do
      post "/api/v1/users/@#{blocker.username}/blocks",
        headers: { 'Authorization' => "Token #{token}" },
        params: { block: blocked.username }

      expect(response).to have_http_status(:no_content)
      expect(blocker.blocked_users).to include(blocked)
    end

    it 'returns 404 if target user does not exist' do
      post "/api/v1/users/@#{blocker.username}/blocks",
        headers: { 'Authorization' => "Token #{token}" },
        params: { block: 'ghost' }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 if blocker username is invalid or token is wrong' do
      post "/api/v1/users/@ghost/blocks",
        headers: { 'Authorization' => "Token #{token}" },
        params: { block: blocked.username }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 204 if already blocked (idempotent)' do
      blocker.blocked_users << blocked

      post "/api/v1/users/@#{blocker.username}/blocks",
        headers: { 'Authorization' => "Token #{token}" },
        params: { block: blocked.username }

      expect(response).to have_http_status(:no_content)
    end
  end
end
