# resource "google_project_service" "activated_apis" {
#   for_each = toset([
#     "artifactregistry.googleapis.com",
#     "cloudbuild.googleapis.com",
#     "run.googleapis.com",
#     "logging.googleapis.com",
#   ])
#   service            = each.value
#   disable_on_destroy = false
# }


# data "google_artifact_registry_repository" "tds_workshop_repo" {
#   location      = var.region
#   repository_id = "tds-workshop"
# }


# data "google_artifact_registry_docker_image" "tds_example_image" {
#   location      = data.google_artifact_registry_repository.tds_workshop_repo.location
#   repository_id = data.google_artifact_registry_repository.tds_workshop_repo.repository_id
#   image_name    = "example:latest"
# }


# resource "google_cloud_run_v2_service" "default" {
#   name                = "example-test"
#   location            = var.region
#   client              = "terraform"
#   deletion_protection = false

#   template {
#     containers {
#       name  = "example-test"
#       image = data.google_artifact_registry_docker_image.tds_example_image.self_link # Container image built from your function in the previous step.
#     }
#   }
# }

# # To make the service publicly accessible, add an IAM policy
# resource "google_cloud_run_v2_service_iam_binding" "public_access" {
#   project  = google_cloud_run_v2_service.default.project
#   location = google_cloud_run_v2_service.default.location
#   name     = google_cloud_run_v2_service.default.name

#   role    = "roles/run.invoker"
#   members = ["allUsers", ]
# }
#

resource "google_storage_bucket" "bucket" {
  name     = "${var.project_id}-gcf-source"  # Every bucket name must be globally unique
  location = var.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "function-source.zip"  # Add path to the zipped function source code
}

resource "google_cloudfunctions2_function" "function" {
  name = "gcf-function"
  location = "europe-west6"
  description = "a new function"

  build_config {
    runtime = "python312"
    entry_point = "hello_world_get"  # Set the entry point

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
    automatic_update_policy {}
  }

  service_config {
    max_instance_count  = 3
    min_instance_count = 1
  }
}
