class CreateUnionchanges < ActiveRecord::Migration[5.2]
  def change
    create_table :unionchanges do |t|
      t.references :page, foreign_key: true
      t.text :coordinates

      t.timestamps
    end
  end
end
