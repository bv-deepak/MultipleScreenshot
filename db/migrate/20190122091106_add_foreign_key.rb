class AddForeignKey < ActiveRecord::Migration[5.2]
  def change
  	remove_column :diffs, :src_sid
  	remove_column :diffs, :dest_sid
  	add_column :diffs, :src_screenshot_id, :bigint
  	add_column :diffs, :dest_screenshot_id, :bigint 
  	add_foreign_key :diffs, :screenshots, column: :src_screenshot_id, primary_key: :id
  	add_foreign_key :diffs, :screenshots, column: :dest_screenshot_id, primary_key: :id 
  end
end
