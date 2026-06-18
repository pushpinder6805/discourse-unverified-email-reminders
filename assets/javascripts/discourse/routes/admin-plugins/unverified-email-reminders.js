import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsUnverifiedEmailRemindersRoute extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/discourse-unverified-email-reminders/reminders.json");
  }
}
