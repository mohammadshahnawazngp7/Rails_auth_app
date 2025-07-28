class AuthController < ApplicationController
  before_action :check_and_verify_access_token, only: [:create]

  def create
    result = Stytch::SyncUserAndOrganization.new(
      token: params[:token]
    ).call

    case result
    when Dry::Monads::Success
      render json: { success: true, data: result.value! }
    when Dry::Monads::Failure
      if result.failure == :user_not_found
        render json: { error: 'User not found' }, status: :unprocessable_entity
      else
        render json: { error: result.failure }, status: :unprocessable_entity
      end
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def request_link
    result = Stytch::RequestMagicLink.new(
      email: params[:email],
      organization_id: params[:organization_id]
    ).call

    case result
    when Dry::Monads::Success
      render json: { message: 'Magic link sent' }
    when Dry::Monads::Failure
      if result.failure == :user_not_found
        render json: { error: 'User not found' }, status: :unprocessable_entity
      else
        render json: { error: result.failure }, status: :unprocessable_entity
      end
    end
  end

  private

  def check_and_verify_access_token
    if params[:access_token].blank? || params[:access_token] != ENV.fetch('SITYCH_ACCESS_TOKEN', 'testaccestoken')
      raise 'Access token mismatch or missing'
    end
  end
end
