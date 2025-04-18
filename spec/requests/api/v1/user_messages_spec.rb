require 'rails_helper'

RSpec.describe "UserMessages API", type: :request do
  let(:sender)    { User.create!(username: 'alice', webhook_url: 'https://hooks.slack.com/a') }
  let(:recipient) { User.create!(username: 'bob', webhook_url: 'https://hooks.slack.com/b') }
  let(:token)     { sender.raw_token }
  let(:headers)   { { 'Authorization' => "Token #{sender.raw_token}" } }

  before do
    sender
    recipient
    allow(Net::HTTP).to receive(:post).and_return(double(code: '200'))
  end

  describe 'POST /@#{recipient.username}' do
    let(:headers) { { 'Authorization' => "Token #{token}" } }

    it 'sends a message successfully to recipient and self' do
      post "/@#{recipient.username}",
        params: { from: sender.username, message: 'hello' },
        headers: headers

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json['status']).to eq('sent')
      expect(json['to']).to eq(recipient.username)
      expect(json['message_preview']).to eq('hello')

      expect(Net::HTTP).to have_received(:post).with(
        URI(recipient.webhook_url),
        json_matching_key('text'),
        hash_including("Content-Type" => "application/json")
      )

      expect(Net::HTTP).to have_received(:post).with(
        URI(sender.webhook_url),
        json_matching_key('text'),
        hash_including("Content-Type" => "application/json")
      )
    end

    it "returns 400 Bad Request when sending message to self" do
      post "/@#{sender.username}",
        headers: {
          "Authorization" => "Token #{token}"
        },
        params: {
          from: sender.username,
          message: "hello myself"
        }

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json["error"]).to eq("You cannot send a message to yourself.")
    end

    it 'returns 404 if recipient does not exist' do
      post "/@ghost",
        params: { from: sender.username, message: 'hi' },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 if token is invalid' do
      post "/@#{recipient.username}",
        params: { from: sender.username, message: 'hi' },
        headers: { 'Authorization' => 'Token invalid' }

      expect(response).to have_http_status(:not_found)
    end

    it 'skips delivery if recipient has blocked sender' do
      recipient.blocked_users << sender

      post "/@#{recipient.username}",
        params: { from: sender.username, message: 'yo' },
        headers: headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['status']).to eq('blocked')
      expect(json['to']).to eq(recipient.username)
      expect(json['message_preview']).to eq('yo')

      expect(Net::HTTP).to have_received(:post).with(
        URI(sender.webhook_url),
        anything,
        hash_including("Content-Type" => "application/json")
      )

      expect(Net::HTTP).not_to have_received(:post).with(
        URI(recipient.webhook_url),
        anything,
        anything
      )
    end

    it 'retries up to 3 times if webhook POST fails' do
      call_count = 0

      allow(Net::HTTP).to receive(:post) do
        call_count += 1
        raise 'Temporary failure' if call_count < 3
        double(code: '200')
      end
      allow_any_instance_of(Object).to receive(:sleep) # テスト時間を短縮するため、sleepを無効化

      expect {
        post "/@#{recipient.username}",
          params: { from: sender.username, message: 'retry me' },
          headers: headers
      }.not_to raise_error

      expect(call_count).to be >= 3
    end

    it 'updates sender last_sent_at' do
      freeze_time do
        post "/@#{recipient.username}",
          params: { from: sender.username, message: 'yo' },
          headers: headers

        expect(Net::HTTP).to have_received(:post).with(
          URI(recipient.webhook_url),
          json_matching_key('text'),
          hash_including("Content-Type" => "application/json")
        )

        sender.reload
        expect(sender.last_sent_at).to eq(Time.current)
      end
    end

    it 'uses correct payload format for Slack-like webhook' do
      recipient.update!(webhook_url: 'https://hooks.slack.com/services/abc123')

      post "/@#{recipient.username}",
        params: { from: sender.username, message: 'format check' },
        headers: headers

      expect(Net::HTTP).to have_received(:post).with(
        URI(recipient.webhook_url),
        json_matching_key('text'),
        hash_including("Content-Type" => "application/json")
      )
    end

    it 'uses correct payload format for Discord webhook' do
      recipient.update!(webhook_url: 'https://discord.com/api/webhooks/abc123')

      post "/@#{recipient.username}",
        params: { from: sender.username, message: 'format check' },
        headers: headers

      expect(Net::HTTP).to have_received(:post).with(
        URI(recipient.webhook_url),
        json_matching_key('content'),
        hash_including("Content-Type" => "application/json")
      )
    end
  end

  describe 'parameter validations' do
    let(:headers) { { 'Authorization' => "Token #{sender.raw_token}" } }

    it 'returns 400 if from is missing' do
      post "/@#{recipient.username}",
        params: { message: 'yo' },
        headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 if message is missing' do
      post "/@#{recipient.username}",
        params: { from: sender.username, to: recipient.username },
        headers: headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  def json_matching_key(expected_key)
    satisfy do |json_str|
      json = JSON.parse(json_str)
      json.key?(expected_key)
    end
  end
end
