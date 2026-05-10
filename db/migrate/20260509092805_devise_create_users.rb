# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Core
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :full_name
      t.string :role,               null: false, default: "reader"

      ## Cloudinary Avatar
      t.string :avatar_public_id

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count,      default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Lockable
      t.integer  :failed_attempts,  default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      ## JWT
      t.string   :jti,              null: false

      t.timestamps null: false
    end

    add_index :users, :email,               unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
    add_index :users, :jti,                  unique: true
  end
end
