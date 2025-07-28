# spec/services/stytch/delete_member_spec.rb
require 'rails_helper'
require 'dry/monads'
include Dry::Monads[:result]
RSpec.describe Stytch::DeleteMember do
  let(:member_id)       { 'member-123' }
  let(:organization_id) { 'org-456' }
  let(:session_token)   { 'dummy-session-token' }

  before do
    allow(::StytchClient).to receive_message_chain(:organizations, :members, :delete)
      .and_return(true)
  end

  context 'when delete is successful' do
    it 'returns Success' do
      result = described_class.new(
        member_id: member_id,
        organization_id: organization_id,
        session_token: session_token
      ).call

      inner = result.value!
      expect(inner).to be_success
      expect(inner.value!).to eq(:deleted)
    end
  end

  context 'when delete raises an error' do
    before do
      allow(::StytchClient).to receive_message_chain(:organizations, :members, :delete)
        .and_raise(StandardError.new('Some error'))
    end

    it 'returns Failure' do
      result = described_class.new(
        member_id: member_id,
        organization_id: organization_id,
        session_token: session_token
      ).call

      inner = result.value!
      expect(inner).to be_failure
      expect(inner.failure).to eq('Some error')
    end
  end
end
