# frozen_string_literal: true

# name: discourse-unverified-email-reminders
# about: Resend verification emails to users who have not confirmed their account.
# version: 0.1
# authors: raza
# url: https://github.com/pushpinder6805/discourse-unverified-email-reminders

enabled_site_setting :unverified_email_reminders_enabled

after_initialize do
  module ::UnverifiedEmailReminders
    PLUGIN_NAME = "discourse-unverified-email-reminders"

    def self.log(message)
      Rails.logger.warn("[discourse-unverified-email-reminders] #{message}")
    end

    def self.candidate_users
      ::User
        .real
        .not_staged
        .where(active: false, admin: false, moderator: false)
        .order(created_at: :asc)
    end

    def self.eligible_user?(user)
      SiteSetting.unverified_email_reminders_enabled &&
        user.present? &&
        !user.staged? &&
        !user.admin? &&
        !user.moderator? &&
        user.email.present? &&
        !user.email_confirmed?
    end

    def self.due_for_automatic_reminder?(user, reminder)
      return false unless eligible_user?(user)

      reminder ||= ::UnverifiedEmailReminder.find_or_initialize_by(user_id: user.id)
      return false if reminder.sent_count.to_i >= SiteSetting.unverified_email_reminders_max_reminders

      wait_days =
        reminder.last_sent_at.present? ?
          SiteSetting.unverified_email_reminders_repeat_after_days :
          SiteSetting.unverified_email_reminders_first_delay_days

      comparison_time = reminder.last_sent_at || user.created_at
      comparison_time <= wait_days.days.ago
    end

    def self.send_activation_email!(user, sent_by: nil, automatic: false)
      raise Discourse::InvalidParameters.new(:user_id) unless eligible_user?(user)

      email_token = user.email_tokens.create!(email: user.email, scope: ::EmailToken.scopes[:signup])
      ::EmailToken.enqueue_signup_email(email_token, to_address: user.email)

      reminder = ::UnverifiedEmailReminder.find_or_initialize_by(user_id: user.id)
      reminder.sent_count = reminder.sent_count.to_i + 1
      reminder.last_sent_at = Time.zone.now
      reminder.last_sent_by = sent_by
      reminder.last_automatic_sent_at = reminder.last_sent_at if automatic
      reminder.last_error = nil
      reminder.save!

      log(
        "Sent activation reminder user_id=#{user.id} username=#{user.username} automatic=#{automatic}",
      )

      reminder
    end

    def self.send_due_reminders!(sent_by: nil, automatic: true, limit: nil)
      return { sent: 0, skipped: 0, failed: 0 } unless SiteSetting.unverified_email_reminders_enabled

      limit ||= SiteSetting.unverified_email_reminders_batch_size
      results = { sent: 0, skipped: 0, failed: 0 }

      candidate_users.limit(limit * 5).each do |user|
        break if results[:sent] >= limit

        reminder = ::UnverifiedEmailReminder.find_or_initialize_by(user_id: user.id)

        unless automatic ? due_for_automatic_reminder?(user, reminder) : eligible_user?(user)
          results[:skipped] += 1
          next
        end

        send_activation_email!(user, sent_by: sent_by, automatic: automatic)
        results[:sent] += 1
      rescue => e
        results[:failed] += 1
        reminder ||= ::UnverifiedEmailReminder.find_or_initialize_by(user_id: user.id)
        reminder.last_error = e.message
        reminder.save! if reminder.changed?
        log("Failed activation reminder user_id=#{user&.id} error=#{e.class}: #{e.message}")
      end

      results
    end
  end

  require_relative "app/models/unverified_email_reminder"
  require_relative "app/controllers/admin/plugins/unverified_email_reminders_controller"
  require_relative "app/jobs/scheduled/send_unverified_email_reminders"

  add_admin_route "admin.plugins.unverified_email_reminders.title", "unverified-email-reminders"

  Discourse::Application.routes.append do
    get "/admin/plugins/discourse-unverified-email-reminders/reminders.json" =>
          "admin/plugins/unverified_email_reminders#index"
    post "/admin/plugins/discourse-unverified-email-reminders/reminders/send-bulk" =>
           "admin/plugins/unverified_email_reminders#send_bulk"
    post "/admin/plugins/discourse-unverified-email-reminders/reminders/:id/send" =>
           "admin/plugins/unverified_email_reminders#send_one"
    get "/admin/plugins/unverified-email-reminders" => "admin/plugins#index",
        constraints: StaffConstraint.new
  end
end
