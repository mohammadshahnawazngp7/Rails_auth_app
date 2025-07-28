module Stytch
  class FindAndDeleteStytchMember < Dry::Operation
    include Dry::Monads[:result]

    def initialize(email:, organization_id:, session_token: nil)
      @email           = email
      @organization_id = organization_id
      @session_token   = session_token || ENV.fetch('SITYCH_SESSION')
    end

    def call
      member_result = step Stytch::FindMember.new(
        email: @email, organization_ids: [@organization_id]
        ).call
      return Failure(:user_not_found) if member_result.failure?

      delete_result = step Stytch::DeleteMember.new(
        organization_id: @organization_id,
        member_id: member_result.value!.dig(:member_id),
        session_token: @session_token
      ).call
      return Failure(:user_deletion_faild) if delete_result.failure?

      Success(:deleted)
    end
  end
end
