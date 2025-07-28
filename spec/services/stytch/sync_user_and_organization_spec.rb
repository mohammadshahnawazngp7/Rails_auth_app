# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Stytch::SyncUserAndOrganization, type: :operation do
  let(:token) { 'valid-magic-token' }
  let(:operation) { described_class.new(token:) }

  let(:email) { 'test@example.com' }
  let(:session_token) { 'session-abc' }
  let(:org_data) do
    {
      'organization_id' => 'org-123',
      'organization' => {
        'organization_slug' => 'test-org',
        'organization_name' => 'Test Organization'
      }
    }
  end

  let(:auth_response) do
    {
      'status_code' => 200,
      'member' => { 'email_address' => email },
      'session_token' => session_token
    }.merge(org_data)
  end

  before do
    allow(StytchClient).to receive_message_chain(:magic_links, :authenticate)
      .with(magic_links_token: token)
      .and_return(auth_response)
  end

  context 'when user exists' do
    let!(:user) { create(:user, email:) }

    it 'updates session token and returns success' do
      result = operation.call
      expect(result).to be_success
      inner = result.value!
      expect(inner).to be_success
      returned_user = inner.value!
      expect(returned_user.id).to eq(user.id)
      expect(returned_user.email).to eq(user.email)
      expect(returned_user.temp_session_token).to eq(session_token)
    end
  end

  context 'when user does not exist' do
    it 'returns failure for missing user' do
      result = operation.call
      expect(result).to be_failure
      expect(result.failure).to eq(:user_not_found)
    end
  end

  context 'when stytch authentication fails' do
    before do
      allow(StytchClient).to receive_message_chain(:magic_links, :authenticate)
        .and_return({ 'status_code' => 401 })
    end

    it 'returns failure for bad token' do
      result = operation.call
      expect(result).to be_failure
    end
  end

  context 'when organization creation fails' do
    let!(:user) { create(:user, email:) }

    before do
      allow(Organization).to receive(:find_or_create_by!).and_raise(StandardError.new('DB error'))
    end

    it 'returns failure' do
      result = operation.call
      expect(result).to be_failure
      expect(result.failure).to eq('DB error')
    end
  end

  context 'when org-user association fails' do
    let!(:user) { create(:user, email:) }

    before do
      allow_any_instance_of(Organization).to receive(:users).and_raise(StandardError.new('Association error'))
    end

    it 'returns failure' do
      result = operation.call
      expect(result).to be_failure
      expect(result.failure).to eq('Association error')
    end
  end
end
