require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    it '有効なユーザーが作成できる' do
      user = User.create(
        username: 'a-know',
        webhook_url: 'https://hooks.slack.com/example'
      )
      expect(user).to be_valid
    end

    it 'username が3文字未満だと無効' do
      user = User.create(username: 'ok', webhook_url: 'https://hooks.slack.com/example')
      expect(user).not_to be_valid
    end

    it 'username が重複すると無効' do
      User.create(
        username: 'duplicate',
        webhook_url: 'https://hooks.slack.com/1'
      )

      user = User.create(
        username: 'duplicate',
        webhook_url: 'https://hooks.slack.com/2'
      )
      expect(user).not_to be_valid
    end

    it 'token_digest が生成されること' do
      user = User.create(
        username: 'secure',
        webhook_url: 'https://hooks.slack.com/secure'
      )
      expect(user.token_digest).to be_present
    end
  end

  describe '#authenticate_token' do
    it '正しい token で認証できる' do
      user = User.create(
        username: 'check',
        webhook_url: 'https://hooks.slack.com/check'
      )
      token = user.raw_token

      expect(user.authenticate_token(token)).to eq true
    end

    it '誤った token では認証できない' do
      user = User.create(
        username: 'fail',
        webhook_url: 'https://hooks.slack.com/fail'
      )

      expect(user.authenticate_token('wrong_token')).to eq false
    end
  end
end
