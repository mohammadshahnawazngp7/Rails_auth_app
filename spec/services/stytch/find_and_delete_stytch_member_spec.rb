require 'rails_helper'
require 'dry/monads'
RSpec.describe Stytch::FindAndDeleteStytchMember do
include Dry::Monads[:result]
  let(:email)           { 'test@example.com' }
  let(:organization_id) { 'org-123' }
  let(:session_token)   { 'fake-token' }
  let(:member_id)       { 'member-456' }

  subject do
    described_class.new(
      email: email,
      organization_id: organization_id,
      session_token: session_token
    )
  end

  describe '#call' do
    context 'when find and delete both succeed' do
      before do
      	allow_any_instance_of(described_class).to receive(:step) do |_, monad|
			    monad
			  end
        allow(Stytch::FindMember).to receive(:new)
				  .with(email: email, organization_ids: [organization_id])
				  .and_return(double(call: Success({ member_id: member_id })))

				allow(Stytch::DeleteMember).to receive(:new)
				  .with(organization_id: organization_id,
				        member_id: member_id,
				        session_token: session_token)
				  .and_return(double(call: Success(:deleted))
				 )
      end

      it 'returns Success(:deleted)' do
			  result = subject.call
			  expect(result).to be_success
			  inner = result.value!
			  expect(inner).to be_success
			  expect(inner.value!).to eq(:deleted)
			end
    end

    context 'when member is not found' do
      before do
        allow(Stytch::FindMember).to receive(:new)
          .and_return(double(call: Dry::Monads::Failure(:not_found)))
      end

      it 'returns Failure(:user_not_found)' do
        result = subject.call
        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context 'when delete fails' do
		  before do
		    allow_any_instance_of(described_class).to receive(:step) { |_, monad| monad }

		    allow(Stytch::FindMember).to receive(:new)
		      .and_return(double(call: Success({ member_id: member_id })))

		    allow(Stytch::DeleteMember).to receive(:new)
		      .and_return(double(call: Failure(:api_error)))
		  end

		  it 'returns Failure(:user_deletion_faild)' do
		    result = subject.call
		    expect(result).to be_success
		    inner = result.value!
		    expect(inner).to be_failure
		    expect(inner.failure).to eq(:user_deletion_faild)
		  end
		end
  end
end
