data "google_project" "google" {
  project_id = var.google_project_id
  provider = google-beta
}

resource "google_cloud_run_service" "dashboard" {
  provider = google-beta

  name     = "fourkeys-grafana-dashboard"
  location = var.google_region

  template {
    spec {
      containers {
        ports {
          container_port = 3000
        }
        image = "gcr.io/${var.google_project_id}/fourkeys-grafana-dashboard${var.image_tag}"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
        env {
          name  = "GF_SECURITY_ADMIN_USER"
          value = "taro.ando"
        }
        env {
          name = "GF_SECURITY_ADMIN_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.dashboard.secret_id
              key = "latest"
            }
          }
        }
      }
      service_account_name = var.fourkeys_service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  metadata {
    labels = {"created_by":"fourkeys"}
    annotations = {
      generated-by = "magic-modules"
      "run.googleapis.com/launch-stage" = "BETA"
    }
  }
  autogenerate_revision_name = true

  depends_on = [google_secret_manager_secret_version.dashboard]
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  provider = google-beta

  location = var.google_region
  project  = var.google_project_id
  service  = "fourkeys-grafana-dashboard"

  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.dashboard]
}

resource "google_secret_manager_secret" "dashboard" {
  provider = google-beta

  secret_id = "fourkeys-grafana-dashboard"
  replication {
    automatic = true
  }
  labels = {"created_by":"fourkeys"}
}

# resource "random_id" "dashboard_random_value" {
  # byte_length = "20"
# }

resource "google_secret_manager_secret_version" "dashboard" {
  provider = google-beta

  secret      = google_secret_manager_secret.dashboard.id
  secret_data = var.password
}

resource "google_secret_manager_secret_iam_member" "dashboard" {
  provider = google-beta
  
  secret_id = google_secret_manager_secret.dashboard.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.fourkeys_service_account_email}"
  depends_on = [google_secret_manager_secret.dashboard]
}