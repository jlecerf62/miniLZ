# Announcements email delivery for all admin users
#
# - Create an OCI Notifications (ONS) topic
# - Subscribe the tenancy Announcements Service to forward ALL announcements to the topic
# - Create one ONS EMAIL subscription per admin user (each recipient must confirm once)

resource "oci_ons_notification_topic" "announcements" {
  compartment_id = var.tenancy_ocid
  name           = "oci-announcements-topic"
  description    = "All OCI tenancy announcements forwarded to email subscribers"
}

# Forward all tenancy announcements to the ONS topic
resource "oci_announcements_service_announcement_subscription" "tenancy_announcements" {
  compartment_id = var.tenancy_ocid
  display_name   = "tenancy-announcements"
  ons_topic_id   = oci_ons_notification_topic.announcements.id
  preferred_language = "fr-FR"
  preferred_time_zone = "Europe/Brussels"
  # Optional: filtering_rules can be added to scope announcements; omitted to receive all
  # filtering_rules = jsonencode({
  #   filters = [
  #     { type = "COMPARTMENT_ID", value = var.tenancy_ocid }
  #   ]
  # })
}

# One email subscription per admin user
resource "oci_ons_subscription" "admins_email" {
  for_each = toset(var.admin_users)

  compartment_id = var.tenancy_ocid
  topic_id       = oci_ons_notification_topic.announcements.id
  protocol       = "EMAIL"
  endpoint       = each.value
}
