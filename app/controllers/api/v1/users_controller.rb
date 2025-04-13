module Api
  module V1
    class UsersController < ApplicationController
      def create
        user = User.new(user_params)

        if user.save
          render json: {
            username: user.username,
            token: user.raw_token, # 生のtokenは最初の一度だけユーザーに対してのみ表示する
            webhook_url: user.webhook_url
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        user = User.find_by(username: params[:username])

        # 存在しない or トークンが違う → 匿名性を守るために一律404
        unless user&.authenticate_token(token_from_header)
          return head :not_found
        end

        # 削除前に webhook に通知（失敗しても続行）
        begin
          send_deletion_notice(user)
        rescue => e
          Rails.logger.warn("Failed to send deletion webhook for #{user.username}: #{e.message}")
        end

        # DeletedUser に記録を移す
        DeletedUser.create!(
          id: user.id,
          username: user.username,
          deleted_at: Time.current
        )

        # 本体を削除
        user.destroy!

        head :no_content
      end

      private

      def user_params
        params.permit(:username, :webhook_url)
      end

      def token_from_header
        request.authorization&.split("Token ")&.last
      end

      def send_deletion_notice(user)
        uri = URI.parse(user.webhook_url)
        payload = { text: "[pinghook] User @#{user.username} has been deleted." }.to_json
        headers = { "Content-Type" => "application/json" }

        tries = 0
        delay = 1

        begin
          response = Net::HTTP.post(uri, payload, headers)
          unless response.is_a?(Net::HTTPSuccess)
            raise "Webhook responded with #{response.code}"
          end
        rescue => e # retry with exponential backoff
          tries += 1
          if tries < 3
            sleep(delay)
            delay *= 2
            retry
          else
            Rails.logger.warn("Failed to send deletion webhook for #{user.username} after #{tries} tries: #{e.message}")
          end
        end
      end
    end
  end
end
