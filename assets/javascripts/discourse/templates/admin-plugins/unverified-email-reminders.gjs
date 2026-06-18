import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

const API_ROOT = "/admin/plugins/discourse-unverified-email-reminders/reminders";

export default class AdminPluginsUnverifiedEmailReminders extends Component {
  @tracked users = this.args.model?.users ?? [];
  @tracked settings = this.args.model?.settings ?? {};
  @tracked isSendingBulk = false;

  async refreshUsers() {
    const response = await ajax(`${API_ROOT}.json`);
    this.users = response.users ?? [];
    this.settings = response.settings ?? {};
  }

  @action
  async send(user) {
    this.users = this.users.map((item) =>
      item.id === user.id ? { ...item, isSending: true } : item
    );

    try {
      const response = await ajax(`${API_ROOT}/${user.id}/send`, {
        type: "POST",
      });

      this.users = this.users.map((item) =>
        item.id === user.id ? response.user : item
      );
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.users = this.users.map((item) =>
        item.id === user.id ? { ...item, isSending: false } : item
      );
    }
  }

  @action
  async sendDue() {
    this.isSendingBulk = true;

    try {
      await ajax(`${API_ROOT}/send-bulk`, { type: "POST" });
      await this.refreshUsers();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSendingBulk = false;
    }
  }

  <template>
    <div class="unverified-email-reminders admin-detail">
      <DPageSubheader
        @titleLabel={{i18n "admin.plugins.unverified_email_reminders.title"}}
        @descriptionLabel={{i18n "admin.plugins.unverified_email_reminders.subtitle"}}
      />

      <div class="admin-controls">
        <DButton
          @action={{this.sendDue}}
          @disabled={{this.isSendingBulk}}
          @label={{if
            this.isSendingBulk
            "admin.plugins.unverified_email_reminders.sending"
            "admin.plugins.unverified_email_reminders.send_due"
          }}
          class="btn-primary"
        />
      </div>

      {{#if this.users.length}}
        <table class="table">
          <thead>
            <tr>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.username"}}</th>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.email"}}</th>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.created_at"}}</th>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.sent_count"}}</th>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.last_sent_at"}}</th>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.status"}}</th>
              <th>{{i18n "admin.plugins.unverified_email_reminders.columns.actions"}}</th>
            </tr>
          </thead>

          <tbody>
            {{#each this.users as |user|}}
              <tr>
                <td>{{user.username}}</td>
                <td>{{user.email}}</td>
                <td>{{user.created_at}}</td>
                <td>{{user.sent_count}}</td>
                <td>{{if
                    user.last_sent_at
                    user.last_sent_at
                    (i18n "admin.plugins.unverified_email_reminders.never")
                  }}</td>
                <td>
                  {{#if user.last_error}}
                    {{i18n "admin.plugins.unverified_email_reminders.status.error"}}
                  {{else if user.sent_count}}
                    {{i18n "admin.plugins.unverified_email_reminders.status.sent"}}
                  {{else}}
                    {{i18n "admin.plugins.unverified_email_reminders.status.ready"}}
                  {{/if}}
                </td>
                <td>
                  <DButton
                    @action={{fn this.send user}}
                    @disabled={{user.isSending}}
                    @label={{if
                      user.isSending
                      "admin.plugins.unverified_email_reminders.sending"
                      "admin.plugins.unverified_email_reminders.send"
                    }}
                    class="btn-primary"
                  />
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <p>{{i18n "admin.plugins.unverified_email_reminders.empty"}}</p>
      {{/if}}
    </div>
  </template>
}
