resource "google_project_service" "activated_apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "logging.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}


data "google_artifact_registry_repository" "tds-workshop-repo" {
  location      = var.region
  repository_id = "tds-workshop-repo"
}


data "google_artifact_registry_docker_image" "tds-example-image" {
  location      = data.google_artifact_registry_repository.tds-workshop-repo.location
  repository_id = data.google_artifact_registry_repository.tds-workshop-repo.repository_id
  image_name    = "example:latest"
}


resource "google_cloud_run_v2_service" "default" {
  name                = "example-test"
  location            = var.region
  client              = "terraform"
  deletion_protection = false

  template {
    containers {
      name  = "example-test"
      image = data.google_artifact_registry_docker_image.tds-example-image.self_link # Container image built from your function in the previous step.
    }
  }
}


resource "google_cloud_run_v2_service_iam_member" "noauth" {
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
