class Unionchange < ApplicationRecord
  belongs_to :page
  serialize :coordinates, Hash
end
