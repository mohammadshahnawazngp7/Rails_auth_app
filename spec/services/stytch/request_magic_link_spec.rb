# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Stytch::RequestMagicLink do
  subject(:service) { described_class.new(email: email, organization_id: org_id, session_token: 'dummy-session') }

  let(:email) { 'user@example.com' }
  let(:org_id) { 'org-123' }
  let(:user) { instance_double(User, email: email, external_id: nil) }

  before do
    allow(SecureRandom).to receive(:random_number).and_return(123456)
    allow(user).to receive(:update).and_return(true)
  end

  context 'when everything succeeds' do
    before do
      allow(User).to receive(:find_by).with(email: email).and_return(user)

      allow(StytchClient.organizations.members).to receive(:create).and_return({
        'status_code' => 200
      })

      allow(StytchClient.magic_links.email).to receive(:login_or_signup).and_return({
        'status_code' => 200,
        'member' => { 'external_id' => 'external-123' }
      })
    end

    it 'returns Success(:sent)' do
      expect(user).to receive(:update).with(external_id: 'external-123').and_return(true)
      result = service.call
      inner = result.value!
      expect(inner).to be_success
      expect(inner.value!).to eq(:sent)
    end
  end

  context 'when user is not found' do
    before do
      allow(User).to receive(:find_by).with(email: email).and_return(nil)
      allow(Stytch::FindAndDeleteStytchMember).to receive_message_chain(:new, :call).and_return(Success(:ok))
    end

    it 'returns Failure(:user_not_found)' do
      expect(service.call).to eq(Dry::Monads::Failure(:user_not_found))
    end
  end

  context 'when member creation fails' do
    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(StytchClient.organizations.members).to receive(:create).and_return({ 'status_code' => 500 })
    end

    it 'returns Failure with member creation response' do
      result = service.call
      expect(result).to be_failure
      expect(result.failure).to eq({ 'status_code' => 500 })
    end
  end

  context 'when magic link sending fails' do
    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(StytchClient.organizations.members).to receive(:create).and_return({ 'status_code' => 200 })
      allow(StytchClient.magic_links.email).to receive(:login_or_signup).and_return({ 'status_code' => 401 })
    end

    it 'returns Failure with magic link error response' do
      result = service.call
      expect(result).to be_failure
      expect(result.failure).to eq({ 'status_code' => 401 })
    end
  end

  context 'when user update fails' do
    before do
      allow(User).to receive(:find_by).and_return(user)
      allow(StytchClient.organizations.members).to receive(:create).and_return({ 'status_code' => 200 })
      allow(StytchClient.magic_links.email).to receive(:login_or_signup).and_return({
        'status_code' => 200,
        'member' => { 'external_id' => 'external-123' }
      })
      allow(user).to receive(:update).and_return(false)
    end

    it 'returns Failure(:user_update_failed)' do
      result = service.call
      expect(result).to eq(Dry::Monads::Failure(:user_update_failed))
    end
  end
end
