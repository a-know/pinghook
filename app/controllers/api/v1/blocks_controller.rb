module Api
  module V1
    class BlocksController < ApplicationController
      def create
        blocker = User.find_by(username: params[:username])
        return head :not_found unless blocker&.authenticate_token(token_from_header)

        blocked = User.find_by(username: params[:block])
        return head :not_found unless blocked

        if blocker.blocked_users.include?(blocked)
          head :no_content # already blocked, idempotent
        else
          blocker.blocked_users << blocked
          head :no_content
        end
      rescue ActiveRecord::RecordInvalid
        head :unprocessable_entity
      end

      private

      def token_from_header
        request.authorization&.split('Token ')&.last
      end
    end
  end
end
