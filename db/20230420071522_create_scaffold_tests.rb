class CreateScaffoldTests < ActiveRecord::Migration[7.0]
  def change
    create_table :scaffold_tests do |t|

      t.timestamps
    end
  end
end
