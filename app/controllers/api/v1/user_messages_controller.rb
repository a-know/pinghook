require 'net/http'

module Api
  module V1
    class UserMessagesController < ApplicationController

      def create_short
        # `params[:username]` はルーティングから取得
        # 他は通常の `create` と同じ処理でOK
        params[:to] = params[:username]
        create
      end

      def create
        return head :bad_request unless params[:from].present? && params[:message].present?

        recipient = User.find_by(username: params[:username])
        sender    = User.find_by(username: params[:from])
        return head :not_found unless recipient && sender
        return head :not_found unless sender.authenticate_token(token_from_header)

        if sender.username == recipient.username
          return render json: {
            error: "You cannot send a message to yourself."
          }, status: :bad_request
        end

        # 送信者に送るメッセージ（純粋な送信内容のみ）
        body_for_sender = "[#{sender.username}] #{params[:message]}"
        payload_to_sender = format_payload(body_for_sender, sender.webhook_url)
        headers = { "Content-Type" => "application/json" }

        # 送信者自身にもコピー送信
        post_with_retries(
          URI(sender.webhook_url),
          payload_to_sender,
          headers
        )

        # 最終送信日時を更新
        sender.update!(last_sent_at: Time.current)

        # 宛先への送信は、ブロックされている場合はスキップ
        if recipient.blocked_users.include?(sender)
          render json: {
            status: "blocked",
            to: recipient.username,
            message_preview: params[:message].truncate(100)
          }, status: :ok
          return
        end

        # 宛先に送るメッセージ（返信/ブロックコマンドつき）
        body_for_recipient = build_message_body(sender, recipient, params[:message])
        payload_to_recipient = format_payload(body_for_recipient, recipient.webhook_url)

        # 宛先へPOST
        post_with_retries(
          URI(recipient.webhook_url),
          payload_to_recipient,
          headers
        )

        render json: {
          status: "sent",
          to: recipient.username,
          message_preview: params[:message].truncate(100)
        }, status: :created
      rescue URI::InvalidURIError, JSON::ParserError
        head :bad_request
      rescue => e
        Rails.logger.warn("Message delivery failed: #{e.message}")
        head :internal_server_error
      end

      def post_with_retries(uri, payload, headers, max_retries: 3)
        retries = 0
        begin
          Net::HTTP.post(uri, payload.to_json, headers)
        rescue => e
          retries += 1
          if retries <= max_retries
            sleep 2**retries
            retry
          else
            Rails.logger.warn("Webhook POST failed to #{uri}: #{e.message}")
          end
        end
      end

      private

      def detect_webhook_type(url)
        uri = URI.parse(url)
        host = uri.host

        if host.include?("slack.com") || host.include?("mattermost.com")
          :slack_like
        elsif host.include?("discord.com") || host.include?("discordapp.com")
          :discord
        else
          :unknown
        end
      rescue URI::InvalidURIError
        :unknown
      end

      def format_payload(body, webhook_url)
        case detect_webhook_type(webhook_url)
        when :discord
          { content: body }
        else # Slack, Mattermost, Rocket.Chat など
          { text: body }
        end
      end

      def build_message_body(sender, recipient, message)
        reply_command = <<~CURL.strip
          curl -X POST https://pinghook.onrender.com/@#{sender.username} \\
            -H "Content-Type: application/json" \\
            -H "Authorization: Token $PINGHOOK_USER_TOKEN" \\
            -d '{"from": "#{recipient.username}", "message": "your reply"}'
        CURL

        block_command = <<~CURL.strip
          curl -X POST https://pinghook.onrender.com/@#{recipient.username}/blocks \\
            -H "Content-Type: application/json" \\
            -H "Authorization: Token $PINGHOOK_USER_TOKEN" \\
            -d '{"block": "#{sender.username}"}'
        CURL

        <<~TEXT.strip
          [#{sender.username}] #{message}

          💬 To reply:
          #{reply_command}

          🚫 To block this sender:
          #{block_command}
        TEXT
      end
    end
  end
end
