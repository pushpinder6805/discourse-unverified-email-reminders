# frozen_string_literal: true

class CreateUnverifiedEmailReminders < ActiveRecord::Migration[7.0]
  def change
    create_table :unverified_email_reminders do |t|
      t.integer :user_id, null: false
      t.integer :sent_count, null: false, default: 0
      t.datetime :last_sent_at
      t.integer :last_sent_by_id
      t.datetime :last_automatic_sent_at
      t.text :last_error
      t.timestamps
    end

    add_index :unverified_email_reminders, :user_id, unique: true
    add_index :unverified_email_reminders, :last_sent_at
  end
end
