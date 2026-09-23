class AddRequestMetadataToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :request_ip, :string
    add_column :versions, :request_path, :string
    add_index :versions, :whodunnit
    add_index :versions, :created_at
  end
end
