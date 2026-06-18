# frozen_string_literal: true

module ::Admin
  module Plugins
    class UnverifiedEmailRemindersController < ::Admin::AdminController
      requires_plugin ::UnverifiedEmailReminders::PLUGIN_NAME

      def index
        users =
          ::UnverifiedEmailReminders
            .candidate_users
            .limit(500)
            .select { |user| ::UnverifiedEmailReminders.eligible_user?(user) }
            .first(200)
        reminders = ::UnverifiedEmailReminder.where(user_id: users.map(&:id)).index_by(&:user_id)

        render json: {
          users: users.map { |user| serialize_user(user, reminders[user.id]) },
          settings: {
            automatic_enabled: SiteSetting.unverified_email_reminders_automatic_enabled,
            first_delay_days: SiteSetting.unverified_email_reminders_first_delay_days,
            repeat_after_days: SiteSetting.unverified_email_reminders_repeat_after_days,
            max_reminders: SiteSetting.unverified_email_reminders_max_reminders,
            batch_size: SiteSetting.unverified_email_reminders_batch_size,
          },
        }
      end

      def send_one
        user = ::User.find(params[:id])
        reminder = ::UnverifiedEmailReminders.send_activation_email!(user, sent_by: current_user)

        render json: success_json.merge(user: serialize_user(user.reload, reminder.reload))
      rescue ActiveRecord::RecordNotFound
        render_json_error("User not found.")
      rescue Discourse::InvalidParameters
        render_json_error("This user is not eligible for an activation reminder.")
      rescue ActiveRecord::RecordInvalid => e
        render_json_error(e.record.errors.full_messages.join(", "))
      end

      def send_bulk
        limit = params[:limit].presence&.to_i
        limit = SiteSetting.unverified_email_reminders_batch_size if limit.blank? || limit <= 0
        limit = [limit, SiteSetting.unverified_email_reminders_batch_size].min

        results =
          ::UnverifiedEmailReminders.send_due_reminders!(
            sent_by: current_user,
            automatic: true,
            limit: limit,
          )

        render json: success_json.merge(results: results)
      end

      private

      def serialize_user(user, reminder)
        {
          id: user.id,
          username: user.username,
          email: user.email,
          created_at: user.created_at,
          active: user.active?,
          approved: user.approved?,
          email_confirmed: user.email_confirmed?,
          sent_count: reminder&.sent_count.to_i,
          last_sent_at: reminder&.last_sent_at,
          last_sent_by_username: reminder&.last_sent_by&.username,
          last_automatic_sent_at: reminder&.last_automatic_sent_at,
          last_error: reminder&.last_error,
          can_send: ::UnverifiedEmailReminders.eligible_user?(user),
        }
      end
    end
  end
end
