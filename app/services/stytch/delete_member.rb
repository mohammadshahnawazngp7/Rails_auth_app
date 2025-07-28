# frozen_string_literal: true

module Stytch
  class DeleteMember < Dry::Operation
    include Dry::Monads[:result]

    def initialize(member_id:, organization_id:, session_token: nil)
      @member_id       = member_id
      @organization_id = organization_id
      @session_token   = session_token || ENV.fetch('SITYCH_SESSION')
    end

    def call
      options = ::Stytch::MethodOptions::Authorization.new(
        session_token: @session_token
      )

      request_opts = ::StytchB2B::Organizations::Members::DeleteRequestOptions.new(
        authorization: options
      )

      ::StytchClient.organizations.members.delete(
        organization_id: @organization_id,
        member_id: @member_id,
        method_options: request_opts
      )

      Success(:deleted)
    rescue => e
      Rails.logger.error("Failed to delete Stytch member: #{e.message}")
      Failure(e.message)
    end
  end
end
