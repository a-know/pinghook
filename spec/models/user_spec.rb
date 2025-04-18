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

  describe 'username reservations' do
    it 'does not allow reserved usernames' do
      reserved = RESERVED_USERNAMES.first # 例: "admin"
      user = User.new(username: reserved, webhook_url: 'https://example.com/webhook')
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("is reserved and cannot be used")
    end

    it 'treats reserved usernames case-insensitively' do
      reserved = RESERVED_USERNAMES.first.upcase # 例: "ADMIN"
      user = User.new(username: reserved, webhook_url: 'https://example.com/webhook')
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("is reserved and cannot be used")
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

    it '無効なURL形式のwebhook_urlはエラーになる（ただの文字列）' do
      user = User.new(
        username: 'url-fail1',
        webhook_url: 'あいうえお'
      )
      expect(user).not_to be_valid
      expect(user.errors[:webhook_url]).to include("must be a valid URL")
    end

    it 'http/https以外のスキーム（ftpなど）はエラーになる' do
      user = User.new(
        username: 'url-fail2',
        webhook_url: 'ftp://example.com'
      )
      expect(user).not_to be_valid
      expect(user.errors[:webhook_url]).to include("must start with http:// or https://")
    end

    it 'スキームがないURLはエラーになる' do
      user = User.new(
        username: 'url-fail3',
        webhook_url: 'www.example.com'
      )
      expect(user).not_to be_valid
      expect(user.errors[:webhook_url]).to include("must start with http:// or https://")
    end

    it '空文字のwebhook_urlはエラーになる' do
      user = User.new(
        username: 'url-fail4',
        webhook_url: ''
      )
      expect(user).not_to be_valid
      expect(user.errors[:webhook_url]).to include("can't be blank", "must start with http:// or https://")
    end
  end

  describe 'blocking relationships' do
    let(:alice) { User.create!(username: 'alice', webhook_url: 'https://example.com/a') }
    let(:bob)   { User.create!(username: 'bob', webhook_url: 'https://example.com/b') }

    it 'can block another user' do
      alice.blocked_users << bob

      # ブロック対象としてbobが含まれていること
      expect(alice.blocked_users).to include(bob)

      # blocks中間テーブルにBlockレコードができていること
      expect(alice.blocks.first.blocked).to eq(bob)
    end

    it 'does not block users by default' do
      expect(alice.blocked_users).to be_empty
    end

    it 'prevents duplicate blocks' do
      alice.blocked_users << bob
      expect {
        alice.blocked_users << bob
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
