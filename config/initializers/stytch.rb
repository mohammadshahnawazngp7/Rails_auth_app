require 'stytch'

StytchClient = StytchB2B::Client.new(
  project_id: ENV.fetch('STYTCH_PROJECT_ID'),
  secret: ENV.fetch('STYTCH_SECRET'),
  env: ENV.fetch('STYTCH_ENV').to_sym
)
