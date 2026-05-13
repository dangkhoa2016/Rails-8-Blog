class CreateImpressionsTable < ActiveRecord::Migration[8.1]
  def change
    create_table :impressions do |t|
      t.string   :impressionable_type
      t.integer  :impressionable_id
      t.integer  :user_id
      t.string   :controller_name
      t.string   :action_name
      t.string   :view_name
      t.string   :request_hash
      t.string   :ip_address
      t.string   :session_hash
      t.text     :message
      t.text     :referrer
      t.text     :params
      t.timestamps
    end
    add_index :impressions, [ :impressionable_type, :impressionable_id ], name: "index_impressions_on_impressionable"
    add_index :impressions, :user_id
  end
end
