require 'securerandom'
require 'bcrypt'

class User < ApplicationRecord
  include BCrypt

  # トークンの元値（登録時に一度だけ生成・返す）
  attr_reader :raw_token

  # 登録前の準備
  before_validation :assign_uuid, on: :create
  before_validation :generate_token_digest, on: :create

  # バリデーション
  validates :username,
    presence: true,
    uniqueness: true,
    length: { minimum: 3 },
    format: {
      with: /\A[a-zA-Z0-9_\-]+\z/,
      message: "only allows letters, numbers, _ and -"
    }

  validates :webhook_url, presence: true
  validates :token_digest, presence: true, uniqueness: true

  # トークン照合（認証用）
  def authenticate_token(token)
    Password.new(token_digest).is_password?(token)
  end

  private

  def assign_uuid
    self.id ||= SecureRandom.uuid
  end

  def generate_token_digest
    @raw_token = "tk_#{SecureRandom.hex(16)}"
    self.token_digest = Password.create(@raw_token)
  end
end
