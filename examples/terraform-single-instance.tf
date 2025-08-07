variable "server-port" {
  type    = string
  default = "8080"
}

resource "google_project_service" "activated_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "logging.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}


resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network"
  auto_create_subnetworks = true
}



# Create a Firewall Rule to Allow HTTP on port 8080
# This firewall rule allows incoming traffic on TCP port 8080.
resource "google_compute_firewall" "firewall-rule" {
  name    = "terraform-example-firewall-rule"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = [var.server-port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"] # Apply this rule to instances with this tag
}


resource "google_compute_instance" "example" {
  name         = "example"
  machine_type = "e2-micro"
  zone         = "europe-west10-a" # Represents Berlin

  tags = ["terraform-example", "web-server"] # Add `web-server tag, so firewall rule is applied

  boot_disk {
    initialize_params {
      # We are using a Debian 11 image from Google's image project.
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    # This block assigns a public IP address to the instance, so it can be accessed from the internet.
    access_config {

    }
  }

  # This startup script will run when the instance is first created.
  metadata_startup_script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y busybox
      mkdir -p /var/www/html
      echo "Hello, World from my dumb web server!" > /var/www/html/index.html
      nohup busybox httpd -f -p ${var.server-port} -h /var/www/html &
    EOF
}

output "instance_ip" {
  description = "The external IP address of the GCE instance."
  value       = "${google_compute_instance.example.network_interface[0].access_config[0].nat_ip}:${var.server-port}"
}


# ----------------
# A single compute instance with name = 'tds', with a tag "easy"
#
###
