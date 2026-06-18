# discourse-unverified-email-reminders

This Discourse plugin helps admins resend verification emails to users who have not confirmed their account email.

## What it does

- Adds an admin page at `/admin/plugins/unverified-email-reminders`
- Lists real, non-staged, non-staff users whose email is still unconfirmed
- Lets staff resend the normal Discourse signup verification email to one user
- Can automatically resend verification reminders on a daily scheduled job
- Tracks resend count, last sent time, last sender, and last error in `unverified_email_reminders`

## Settings

- `unverified_email_reminders_enabled`
- `unverified_email_reminders_automatic_enabled`
- `unverified_email_reminders_first_delay_days`
- `unverified_email_reminders_repeat_after_days`
- `unverified_email_reminders_max_reminders`
- `unverified_email_reminders_batch_size`

Automatic reminders are disabled by default.

## Notes

The plugin uses Discourse's standard signup activation email token flow. It does not create a custom email template and does not change normal signup, login, or approval behavior.
