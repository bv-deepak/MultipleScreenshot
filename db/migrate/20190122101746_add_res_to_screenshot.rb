class AddResToScreenshot < ActiveRecord::Migration[5.2]
  def change
  	add_column :screenshots , :resp_code, :int
  end
end
