class AddToDiff < ActiveRecord::Migration[5.2]
  def change
  	add_column :diffs ,:percentage_diff ,:float
  end
end
