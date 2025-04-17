require 'rails_helper'

RSpec.describe "User Webhook Update API", type: :request do
  describe "PATCH /@:username" do
    let!(:user) do
      User.create!(
        username: "a-know",
        webhook_url: "https://hooks.slack.com/services/OLD/endpoint"
      )
    end

    let(:headers) do
      {
        "Authorization" => "Token #{user.raw_token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    it "updates the webhook_url successfully" do
      patch "/@#{user.username}",
        headers: headers,
        params: {
          webhook_url: "https://hooks.slack.com/services/NEW/endpoint"
        }.to_json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("updated")
      expect(json["webhook_url"]).to eq("https://hooks.slack.com/services/NEW/endpoint")
      expect(user.reload.webhook_url).to eq("https://hooks.slack.com/services/NEW/endpoint")
    end

    it "returns 400 if webhook_url is missing" do
      patch "/@#{user.username}",
        headers: headers,
        params: {}.to_json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Invalid or missing webhook_url")
    end

    it "returns 404 if token is invalid" do
      patch "/@#{user.username}",
        headers: {
          "Authorization" => "Token invalidtoken",
          "Content-Type" => "application/json"
        },
        params: {
          webhook_url: "https://example.com"
        }.to_json

      expect(response).to have_http_status(:not_found)
    end
  end
end
