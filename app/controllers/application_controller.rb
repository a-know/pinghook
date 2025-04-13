class ApplicationController < ActionController::API
  protected

  def token_from_header
    request.authorization&.split('Token ')&.last
  end
end
