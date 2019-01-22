class CreateScreenshots < ActiveRecord::Migration[5.2]
  def change
    create_table :screenshots do |t|
      t.references :blog, foreign_key: true
      t.references :snapshot, foreign_key: true
      t.string :gid
      t.string :page_url

      t.timestamps
    end
  end
end
