variable "server_port" {
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

# VPC
resource "google_compute_network" "tds_vpc_network" {
  name                    = "tds-vpc-network"
  auto_create_subnetworks = true
}

# Firewall rule to allow web traffic
resource "google_compute_firewall" "tds_firewall_rule" {
  name    = "tds-firewall-rule"
  network = google_compute_network.tds_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = [var.server_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"] # Apply this rule to instances with this tag
}

# This template defines the configuration for each instance in our group.
resource "google_compute_instance_template" "tds_template" {
  name         = "tds-template"
  machine_type = "e2-micro"
  tags         = ["terraform-example", "web-server"] # Add `web-server tag, so firewall rule is applied

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = google_compute_network.tds_vpc_network.name
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
      nohup busybox httpd -f -p ${var.server_port} -h /var/www/html &
    EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Use the given template to create a group of identical instances, as needed (or as configured)
resource "google_compute_instance_group_manager" "tds_instance_group_manager" {
  name               = "tds-instance-group-manager"
  base_instance_name = "tds-instance"
  zone               = "europe-west10-a" # Represents Berlin
  version {
    instance_template = google_compute_instance_template.tds_template.self_link_unique
  }
  target_size = 2 # Creates 2 instances
  named_port {
    name = "http"
    port = var.server_port
  }
}

# Load Balancer uses this to to verify that our instances are healthy, and which to route traffic to
resource "google_compute_health_check" "tds_healthcheck" {
  name                = "tds-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port = var.server_port
  }
}

# The backend service directs traffic to our instance group.
resource "google_compute_backend_service" "tds_backend_service" {
  name          = "tds-backend-service"
  health_checks = [google_compute_health_check.tds_healthcheck.id]
  backend {
    group = google_compute_instance_group_manager.tds_instance_group_manager.instance_group
  }

  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL" # Because we want to load balance external traffic i.e. traffic originating from outside the VPC.
  timeout_sec           = 10
}

# Maps the incoming requests to the target backend service based on some rule/logic. Inspects the
# requested URL and decides which backend service should handle it
#
# In more complex applications, `path_matcher` and `host_rule` blocks allow different routing logic
# For example, you could route requests for domain.com/api/* to a different
# backend service and domain.com/static/* to a S3 bucket.
resource "google_compute_url_map" "tds_default_url_map" {
  name            = "tds-default-url-map"
  default_service = google_compute_backend_service.tds_backend_service.id
}


# This uses the URL map to route requests.
resource "google_compute_target_http_proxy" "tds_http_proxy" {
  name    = "tds-http-load-balancer-proxy"
  url_map = google_compute_url_map.tds_default_url_map.id
}

# Public-facing entry point of the entire load balancing setup.
# Has a public, static IP address and listens for traffic on a specific port.
resource "google_compute_global_forwarding_rule" "tds_http_forwarding_rule" {
  name                  = "tds-http-content-forwarding-rule"
  target                = google_compute_target_http_proxy.tds_http_proxy.id
  port_range            = var.server_port
  load_balancing_scheme = "EXTERNAL"
}

output "load_balancer_ip" {
  description = "The public IP address of the load balancer."
  value       = google_compute_global_forwarding_rule.tds_http_forwarding_rule.ip_address
}
