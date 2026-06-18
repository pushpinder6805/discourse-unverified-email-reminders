# frozen_string_literal: true

class ::UnverifiedEmailReminder < ActiveRecord::Base
  self.table_name = "unverified_email_reminders"

  belongs_to :user
  belongs_to :last_sent_by, class_name: "User", optional: true

  validates :user_id, presence: true, uniqueness: true
  validates :sent_count, numericality: { greater_than_or_equal_to: 0 }
end
