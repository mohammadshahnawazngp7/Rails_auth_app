# frozen_string_literal: true

module Stytch
  class SyncUserAndOrganization < Dry::Operation
    include Dry::Monads[:result]

    def initialize(token:)
      @token = token
    end

    def call
      ApplicationRecord.transaction do
        resp = step get_auth_detils
        user = step find_user_or_handle_absent(resp: resp)
        org = step create_or_update_org(org: resp.dig('organization'), org_id: resp.dig('organization_id'))
        data = step build_relation_org_user(org: org, user: user)
        Success(user)
      end
    end

    private

    def find_user_or_handle_absent(resp:)
      user = User.find_by(email: resp.dig("member", "email_address"))
      if user
        user.update(temp_session_token: resp.dig('session_token'))
        Success(user)
      else
        Failure(:user_not_found)
      end
    end

    def get_auth_detils
      resp = StytchClient.magic_links.authenticate(magic_links_token: @token)

      resp['status_code'] == 200 ? Success(resp) : Failure(resp)
    rescue => e
      Failure(e.message)
    end

    def create_or_update_org(org:, org_id:)
      organization_id = org_id
      slug            = org.dig('organization_slug')
      name            = org.dig('organization_name')
      org             = Organization.find_or_create_by!(slug:, name:, organization_id:)
      Success(org)
    rescue => e
      Failure(e.message)
    end

    def build_relation_org_user(org:, user:)
      org.users << user
      Success(user)
    rescue => e
      Failure(e.message)
    end
  end
end
