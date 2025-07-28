require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has a many-to-many relationship with organizations' do
      association = described_class.reflect_on_association(:organizations)
      expect(association.macro).to eq(:has_and_belongs_to_many)
    end
  end

  describe 'validations' do
    it 'is valid with a unique email' do
      user = User.new(email: 'unique@example.com')
      expect(user).to be_valid
    end

    it 'is invalid without an email' do
      user = User.new(email: nil)
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email' do
      User.create!(email: 'dup@example.com')
      user = User.new(email: 'dup@example.com')
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'organization assignment' do
    it 'can be associated with organizations' do
      user = User.create!(email: 'assoc@example.com')
      org = Organization.create!(slug: 'test-org', name: 'Test Org', organization_id: 'org-1')

      # Associate and verify
      user.organizations << org
      expect(user.organizations).to include(org)
    end

    it 'raises a RecordNotUnique error for duplicate associations' do
		  user = User.create!(email: 'dupassoc@example.com')
		  org = Organization.create!(slug: 'test-org2', name: 'Test Org 2', organization_id: 'org-2')

		  user.organizations << org
		  expect {
		    user.organizations << org
		  }.to raise_error(ActiveRecord::RecordNotUnique)
		  expect(user.organizations.count).to eq(1)
		end
  end
end
