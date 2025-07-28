class Organization < ApplicationRecord
  has_and_belongs_to_many :users
  validates :name, :slug, presence: true
end
