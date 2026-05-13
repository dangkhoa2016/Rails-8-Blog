class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string  :cloudinary_public_id
      t.string  :status, null: false, default: "draft"
      t.integer :comments_count, default: 0
      t.integer :impressions_count, default: 0
      t.datetime :published_at
      t.datetime :scheduled_at
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :posts, :status
    add_index :posts, :published_at
    add_index :posts, :discarded_at
  end
end
