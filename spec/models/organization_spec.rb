require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it 'has a many-to-many relationship with users' do
      assoc = described_class.reflect_on_association(:users)
      expect(assoc.macro).to eq(:has_and_belongs_to_many)
    end
  end

  describe 'validations' do
    subject { described_class.new(name: 'Org Name', slug: 'org-slug', organization_id: 'org-1') }

    it 'is valid with name, slug, and organization_id' do
      expect(subject).to be_valid
    end

    it 'is invalid without a name' do
      subject.name = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a slug' do
      subject.slug = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:slug]).to include("can't be blank")
    end
  end

  describe 'user associations' do
    let(:org) { Organization.create!(name: 'Test Org', slug: 'test-org', organization_id: 'org-123') }
    let(:user) { create(:user) }

    it 'can be associated with users' do
      org.users << user
      expect(org.users).to include(user)
    end

    it 'raises RecordNotUnique when associating the same user twice' do
      org.users << user
      expect {
        org.users << user
      }.to raise_error(ActiveRecord::RecordNotUnique)
      expect(org.users.count).to eq(1)
    end
  end
end