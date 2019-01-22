class AddColumnToPages < ActiveRecord::Migration[5.2]
  def change
  	add_column :pages , :url , :string
  end
end
