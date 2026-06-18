# frozen_string_literal: true

module Jobs
  class SendUnverifiedEmailReminders < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      return unless SiteSetting.unverified_email_reminders_enabled
      return unless SiteSetting.unverified_email_reminders_automatic_enabled

      ::UnverifiedEmailReminders.send_due_reminders!(
        sent_by: Discourse.system_user,
        automatic: true,
      )
    end
  end
end
