class CreateBlockedRequestLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blocked_request_logs do |t|
      t.string :ip, null: false
      t.string :path
      t.string :reason, null: false
      t.string :user_agent
      t.timestamps
    end

    add_index :blocked_request_logs, :ip
    add_index :blocked_request_logs, :created_at
  end
end
