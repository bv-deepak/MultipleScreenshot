class CreateDiffs < ActiveRecord::Migration[5.2]
  def change
    create_table :diffs do |t|
      t.references :page
      t.text :coordinates
      t.string :diff_image_path
      t.string :src_sid
      t.string :dest_sid

      t.timestamps
    end
  end
end
