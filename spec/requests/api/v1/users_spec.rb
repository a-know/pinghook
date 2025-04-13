require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe 'POST /api/v1/users' do
    let(:valid_params) do
      {
        username: 'ko-hi',
        webhook_url: 'https://hooks.slack.com/valid'
      }
    end

    it 'ユーザーが登録できる' do
      post '/api/v1/users', params: valid_params

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['username']).to eq('ko-hi')
      expect(json['token']).to start_with('tk_')
      expect(json['webhook_url']).to eq(valid_params[:webhook_url])
    end

    it 'バリデーションエラー時に 422 が返る' do
      invalid_params = valid_params.merge(username: 'ab') # 3文字未満

      post '/api/v1/users', params: invalid_params

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to include(/Username/)
    end
  end
end
