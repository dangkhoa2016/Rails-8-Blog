class CreateSlidesAndSlideTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :slides do |t|
      t.references :post, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :slides, [ :post_id, :position ], unique: true

    create_table :slide_translations do |t|
      t.references :slide, null: false, foreign_key: true
      t.string :locale, null: false
      t.text :caption
      t.string :alt_text

      t.timestamps
    end

    add_index :slide_translations, [ :slide_id, :locale ], unique: true
  end
end
