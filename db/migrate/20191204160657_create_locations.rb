class CreateLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :locations do |t|
      t.string :insee_number, index: true, foreign_key: true
      t.string :locality
      t.references :localizable, polymorphic: true

      t.timestamps null: false
    end
  end
end
