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

      private

      def user_params
        params.permit(:username, :webhook_url)
      end
    end
  end
end
