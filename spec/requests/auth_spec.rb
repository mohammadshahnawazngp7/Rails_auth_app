require 'swagger_helper'

RSpec.describe 'auth_request', type: :request do

  path '/auth/request_link' do
    post 'Send Magic Link if user exists' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          organization_id: { type: :string }
        },
        required: ['email', 'organization_id']
      }

      response '200', 'Magic link sent' do
        let(:email) { Faker::Internet.email }

        before do
          Organization.create!(name: 'Test Org', slug: 'test-org', organization_id: 'org-123')
          User.create!(email: email)
          allow(Stytch::RequestMagicLink).to receive(:new).and_return(
            double(call: Dry::Monads::Success(:sent))
          )
        end

        let(:payload) { { email: email, organization_id: 'org-123' } }
        run_test!
      end

      response '422', 'User not allowed' do
        let(:payload) { { email: 'not@found.com', organization_id: 'org-123' } }
        run_test!
      end

      response '422', 'Error occurred' do
        let(:payload) { { email: nil, organization_id: 'org-123' } }
        run_test!
      end
    end
  end
end
