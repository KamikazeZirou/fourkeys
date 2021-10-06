module "dashboard_service" {
  source                         = "./dashboard"
  google_project_id              = var.google_project_id
  google_region                  = var.google_region
  image_tag                      = var.image_tag
  fourkeys_service_account_email = google_service_account.fourkeys.email

  depends_on = [
    google_project_service.run_api
  ]
}
