require 'rails_helper'
require 'net/http'

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

  describe 'DELETE /api/v1/users/@:username' do
    let(:username) { 'delete-me' }
    let(:webhook_url) { 'https://hooks.slack.com/services/test/delete' }

    before do
      @user = User.new(username: username, webhook_url: webhook_url)
      @user.save! # token_digestが生成される
      @token = @user.raw_token
    end

    it '正しいトークンで削除できる（204）' do
      allow(Net::HTTP).to receive(:post).and_return(
        instance_double("Net::HTTPOK", is_a?: true) # 成功ステータスっぽいモック
      )

      delete "/api/v1/users/@#{username}",
        headers: { 'Authorization' => "Token #{@token}" }

      expect(response).to have_http_status(:no_content)
      expect(User.find_by(username: username)).to be_nil
      expect(DeletedUser.find_by(username: username)).not_to be_nil
    end

    it '存在しないユーザーを削除しようとすると404' do
      delete "/api/v1/users/@nonexistent",
        headers: { 'Authorization' => "Token #{@token}" }

      expect(response).to have_http_status(:not_found)
    end

    it 'トークンが間違っていると404' do
      delete "/api/v1/users/@#{username}",
        headers: { 'Authorization' => "Token wrongtoken" }

      expect(response).to have_http_status(:not_found)
      expect(User.find_by(username: username)).not_to be_nil
    end

    it 'webhook送信に失敗したときに3回リトライされる' do
      # `Net::HTTP.post` を常に例外を吐くようにモック
      allow(Net::HTTP).to receive(:post).and_raise(StandardError.new("simulated failure"))
      allow_any_instance_of(Object).to receive(:sleep) # テスト時間を短縮するため、sleepを無効化

      expect(Rails.logger).to receive(:warn).with(
        a_string_including("Failed to send deletion webhook for #{username}")
      )

      delete "/api/v1/users/@#{username}",
        headers: { 'Authorization' => "Token #{@token}" }

      expect(response).to have_http_status(:no_content)

      # 🔍 ここで3回リトライされたことを検証
      expect(Net::HTTP).to have_received(:post).exactly(3).times
    end
  end
end
