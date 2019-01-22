class Diff < ApplicationRecord
   belongs_to :page
   belongs_to :src_screenshot, class_name: "Screenshot"
   belongs_to :dest_screenshot, class_name: "Screenshot"
   serialize :coordinates, Hash
end
 