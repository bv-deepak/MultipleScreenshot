class AddPageToScreenshot < ActiveRecord::Migration[5.2]
  def change
    add_reference :screenshots, :page, foreign_key: true
  end
end
