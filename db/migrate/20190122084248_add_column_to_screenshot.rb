class AddColumnToScreenshot < ActiveRecord::Migration[5.2]
  def change
  	remove_column :screenshots , :page_url
  	rename_column :screenshots , :gid, :sid	
  end
end
