# frozen_string_literal: true

module Stytch
  class RequestMagicLink < Dry::Operation
    include Dry::Monads[:result]

    def initialize(email:, organization_id:, session_token: nil)
      @email           = email
      @organization_id = organization_id
      @session_token   = session_token || ENV.fetch('SITYCH_SESSION')
    end

    def call
      user = step find_user_or_handle_absent

      member_result = step create_member(user: user)

      magic_link_result = step send_magic_link(email: user.email)

      update_user = step update_user_external_id(external_id: magic_link_result, user: user)

      Success(:sent)
    end

    private

    def update_user_external_id(external_id:, user:)
      user.update(external_id: external_id) ? Success(:ok) : Failure(:user_update_failed)
    end

    def find_user_or_handle_absent
      user = User.find_by(email: @email)
      unless user
        error = step Stytch::FindAndDeleteStytchMember.new(
          email: @email, 
          organization_id: @organization_id
          ).call
        return Failure(:user_not_found)
      end
      Success(user)
    end

    def create_member(user:)
      resp = StytchClient.organizations.members.create(
        organization_id: @organization_id,
        email_address: user.email,
        external_id: SecureRandom.random_number(10**6).to_s.rjust(6, '0'),
        method_options: StytchB2B::Organizations::Members::CreateRequestOptions.new(
          authorization: Stytch::MethodOptions::Authorization.new(session_token: @session_token)
        )
      )

      resp['status_code'] == 200 || resp['error_type'] == 'duplicate_member_email' ? Success(:ok) : Failure(resp)
    rescue => e
      Failure(e.message)
    end

    def send_magic_link(email:)
      resp = StytchClient.magic_links.email.login_or_signup(
        email_address: email,
        organization_id: @organization_id
      )

      resp['status_code'] == 200 ? Success(resp.dig("member", "external_id")) : Failure(resp)
    rescue => e
      Failure(e.message)
    end
  end
end
