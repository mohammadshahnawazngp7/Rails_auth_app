# frozen_string_literal: true
module Stytch
  class FindMember < Dry::Operation
    include Dry::Monads[:result]

    def initialize(email:, organization_ids: [], session_token: nil)
      @email            = email
      @organization_ids = organization_ids
      @session_token    = session_token || ENV.fetch('SITYCH_SESSION')
    end

    def call
      response = StytchClient.organizations.members.search(
          organization_ids: @organization_ids,
          method_options: StytchB2B::Organizations::Members::SearchRequestOptions.new(
            authorization: Stytch::MethodOptions::Authorization.new(session_token: @session_token)
          )
        )

      return Failure(:member_not_found) unless response['status_code'] == 200
      member = response.dig('members')&.select{ |member| member.dig('email_address') == @email }&.first
      member_id = member.dig("member_id")

      if member_id.present? && member.present?
        Success(
          member_id: member_id,
          member: member
        )
      else
        Failure(:member_not_found)
      end
    rescue => e
      Rails.logger.warn("Failed to find Stytch member for #{@email}: #{e.message}")
      Failure(:member_not_found)
    end
  end
end
