class Api::V1::Oauth::DeviceTokenController < ApplicationController
  def create
    grant_type = params[:grant_type]

    unless grant_type == "urn:ietf:params:oauth:grant-type:device_code"
      render json: {
        error: "unsupported_grant_type",
        error_description: "Only device_code grant is supported at this endpoint"
      }, status: :bad_request
      return
    end

    device_code = params[:device_code]
    client_id = params[:client_id]
    client_secret = params[:client_secret]

    device_auth = Rails.cache.read("device_auth:#{device_code}")

    unless device_auth
      render json: {
        error: "invalid_grant",
        error_description: "Invalid or expired device_code"
      }, status: :bad_request
      return
    end

    unless device_auth[:client_id] == client_id
      render json: {
        error: "invalid_grant",
        error_description: "Client ID mismatch"
      }, status: :bad_request
      return
    end

    application = Doorkeeper::Application.find_by(uid: client_id)
    unless application && application.secret == client_secret
      render json: {
        error: "invalid_client",
        error_description: "Invalid client credentials"
      }, status: :unauthorized
      return
    end

    poll_mas_for_token(device_code, client_id, client_secret)
  end

  private

  def poll_mas_for_token(device_code, client_id, client_secret)
    mas_url = ENV["MAS_TOKEN_URL"] || "https://mas.tween.example/oauth2/token"

    response = Faraday.post(mas_url) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form({
        grant_type: "urn:ietf:params:oauth:grant-type:device_code",
        device_code: device_code,
        client_id: client_id,
        client_secret: client_secret
      })
    end

    unless response.success?
      json_response = JSON.parse(response.body) rescue {}

      case json_response["error"]
      when "authorization_pending"
        render json: {
          error: "authorization_pending",
          error_description: "User has not completed authorization yet"
        }, status: :bad_request
      when "slow_down"
        render json: {
          error: "slow_down",
          error_description: "Polling too frequently"
        }, status: :bad_request
      when "expired_token"
        render json: {
          error: "expired_token",
          error_description: "Device authorization has expired"
        }, status: :bad_request
      when "access_denied"
        render json: {
          error: "access_denied",
          error_description: "User denied authorization"
        }, status: :bad_request
      else
        render json: json_response, status: :bad_request
      end
      return
    end

    token_data = JSON.parse(response.body)

    mas_user_info = introspect_mas_token(token_data["access_token"])

    unless mas_user_info["active"]
      render json: {
        error: "invalid_grant",
        error_description: "Matrix token is not active"
      }, status: :bad_request
      return
    end

    render json: {
      access_token: token_data["access_token"],
      token_type: "Bearer",
      expires_in: token_data["expires_in"],
      refresh_token: token_data["refresh_token"],
      scope: token_data["scope"],
      user_id: mas_user_info["sub"],
      message: "Exchange this token for TEP using urn:ietf:params:oauth:grant-type:token-exchange"
    }, status: :ok
  rescue JSON::ParserError => e
    render json: {
      error: "server_error",
      error_description: "Invalid response from MAS"
    }, status: :internal_server_error
  end

  def introspect_mas_token(access_token)
    mas_introspection_url = ENV["MAS_INTROSPECTION_URL"] || "https://mas.tween.example/oauth2/introspect"
    mas_client_id = ENV["MAS_CLIENT_ID"] || "tmcp-server"
    mas_client_secret = ENV["MAS_CLIENT_SECRET"]

    response = Faraday.post(mas_introspection_url) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form({
        token: access_token,
        client_id: mas_client_id,
        client_secret: mas_client_secret
      })
    end

    JSON.parse(response.body)
  end
end
