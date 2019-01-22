class Screenshot < ApplicationRecord 
  belongs_to :blog
  belongs_to :snapshot, optional: true
  belongs_to :page 
end
