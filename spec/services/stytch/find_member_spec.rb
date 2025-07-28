# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Stytch::FindMember, type: :service do
  let(:email) { 'test@example.com' }
  let(:organization_ids) { ['org-123'] }
  let(:session_token) { 'session-token' }

  let(:service) { described_class.new(email: email, organization_ids: organization_ids, session_token: session_token) }

  describe '#call' do
    context 'when member is found successfully' do
      let(:member_id) { 'member-456' }
      let(:member) do
        {
          'member_id' => member_id,
          'email_address' => email
        }
      end

      before do
        allow(StytchClient.organizations.members).to receive(:search)
          .with(
            organization_ids: organization_ids,
            method_options: instance_of(StytchB2B::Organizations::Members::SearchRequestOptions)
          ).and_return({
            'status_code' => 200,
            'members' => [member]
          })
      end

      it 'returns Success with member_id and member' do
        result = service.call
        expect(result).to be_success
        inner = result.value!
        expect(inner.value!).to eq(member_id: member['member_id'], member: member)
      end
    end

    context 'when no member is found in the response' do
      before do
        allow(StytchClient.organizations.members).to receive(:search).and_return({
          'status_code' => 200,
          'members' => []
        })
      end

      it 'returns Failure(:member_not_found)' do
        result = service.call
        inner = result.value!
        expect(inner).to be_failure
        expect(inner.failure).to eq(:member_not_found)
      end
    end

    context 'when status code is not 200' do
      before do
        allow(StytchClient.organizations.members).to receive(:search).and_return({
          'status_code' => 404
        })
      end

      it 'returns Failure(:member_not_found)' do
        result = service.call
        inner = result.value!
        expect(inner).to be_failure
        expect(inner.failure).to eq(:member_not_found)
      end
    end

    context 'when an exception is raised' do
      before do
        allow(StytchClient.organizations.members).to receive(:search).and_raise(StandardError.new('boom'))
      end

      it 'logs the error and returns Failure(:member_not_found)' do
        expect(Rails.logger).to receive(:warn).with(/Failed to find Stytch member for #{email}: boom/)
        result = service.call
        inner = result.value!
        expect(inner).to be_failure
        expect(inner.failure).to eq(:member_not_found)
      end
    end
  end
end
