# VPC DOCUMENTATION
# https://cloud.google.com/vpc/docs/vpc

# GCLOUD CHEAT SHEET
# https://gist.github.com/pydevops/cffbd3c694d599c6ca18342d3625af97

# GCS BACKEND CONFIG
# https://www.terraform.io/docs/language/settings/backends/gcs.html


# GOOGLE PROJECT
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project
# https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
# terraform import google_project.gcp-adventure-02 gcp-adventure-02
resource "google_project" "gcp-adventure-02" {
  name                = "gcp-adventure-02"
  project_id          = "gcp-adventure-02"
  org_id              = "619061167434"
  auto_create_network = false
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
resource "google_project_service" "gcp_resource_manager_api" {
  project = "gcp-adventure-02"
  service = "cloudresourcemanager.googleapis.com"

  depends_on = [
    google_project.gcp-adventure-02
  ]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service
resource "google_project_service" "compute_service" {
  project = "gcp-adventure-02"
  service = "compute.googleapis.com"

  depends_on = [
    google_project.gcp-adventure-02
  ]
}

# VPC
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "vpc_network" {
  name                            = "gcp-adventure-02-network"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  depends_on = [
    google_project_service.compute_service
  ]
}

# PUBLIC SUBNET
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "public" {
  name                     = "public"
  region                   = "us-central1"
  ip_cidr_range            = "10.20.0.0/16"
  network                  = google_compute_network.vpc_network.self_link
  purpose                  = "PRIVATE"
  stack_type               = "IPV4_ONLY"
  private_ip_google_access = false 
}

# PRIVATE Subnet
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "private" {
  name                     = "private"
  region                   = "us-central1"
  ip_cidr_range            = "10.21.0.0/16"
  network                  = google_compute_network.vpc_network.self_link
  purpose                  = "PRIVATE"
  stack_type               = "IPV4_ONLY"
  private_ip_google_access = true 
}


# PUBLIC INTERNET ROUTE
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route
resource "google_compute_route" "public_internet_route" {
  name             = "public-internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
  tags             = ["public-internet"]
}


# PRIVATE INTERNET ROUTE
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route
resource "google_compute_route" "private_internet_route" {
  name             = "private-internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
  tags             = ["private-internet"]
}


# PUBLIC Firewall Rule
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "public_firewall" {
  name = "public-firewall"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["public-firewall"]
}


# PRIVATE Firewall Rule
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "private_firewall" {
  name = "private-firewall"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction = "INGRESS"
  source_ranges = ["10.20.0.0/16","10.21.0.0/16"]
  target_tags = ["private-firewall"]
}


# PUBLIC STATIC IP
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "public_instance_static_ip" {
  name = "public-instance-static-ip"
}


# PUBLIC VM INSTANCE
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
# Adding SSH Keys - https://stackoverflow.com/questions/38645002/how-to-add-an-ssh-key-to-an-gcp-instance-using-terraform
# https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/
resource "google_compute_instance" "public_instance" {
  name         = "public-instance"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["public-internet","public-firewall"]

  boot_disk {
    initialize_params {
      image = "centos-7-v20210420"
    }
  }

  # metadata_startup_script = file("filename.sh")

  metadata = {
      "ssh-keys" = "vgreen:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDC/gD4Muq+vdiyHoghzpFbANIjvdF/+XJFVD2JyuOToGVqeeYemWzufEPbVJHDE0yDPUtOizJ7aEji6DIiTLHdgDw8pDRcE5rXB5KuOQLQrCUXDeHi+wqjatpJMQzlzi5tsbm6kuFCajQ00vm4XY52EJZyO8lAhtgP8lDGMcIix+lM/qxfciC/5ifs0RUabbc/3wbaLwLxv2U413s5gUrBAqUPUp7ug6tKrqUO9BPTeTWR3ACkJBdswx5EyGU9IpT/TR9iXKo04184GXUPC1BZKnww6OsxL//N3OAelfA7PXiPBP3nVL9ifqv8nQc3BBDBzeOTGrCsyV2cg/bQHfLV/DLpagk/Nd5oeiMxZCZhwymIxFdZxB0WGjVan5qOv6DDKm2oLy4YHzNQy41W/OEcBqQ22Q7Q+UpA14AQ4riQKSZ+jNNUyx5zwta1+3FbbmbX5OaNJeumha5dWWZigabfrlds/r2mKQUPyPhVbs2X5HivtkjasU0HI1KPgHfqXQE= vgreen@MacBook-Pro.local"
    }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.public.self_link  

     access_config {
       network_tier = "PREMIUM"
       nat_ip = google_compute_address.public_instance_static_ip.address
     }
  }
}



# PRIVATE NAT ROUTER
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router#nested_advertised_ip_ranges
resource "google_compute_router" "private_interet_router" {
  name    = "private-internet-router"
  region  = "us-central1"
  network = google_compute_network.vpc_network.self_link
}


# PUBLIC STATIC IP
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address
resource "google_compute_address" "nat_gateway_static_ip" {
  count  = 2
  name   = "nat-gateway-static-ip-${count.index}"
  region = "us-central1"
}


# PRIVATE CLOUD NAT
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "private_nat" {
  name                               = "private-nat"
  router                             = google_compute_router.private_interet_router.name
  region                             = google_compute_router.private_interet_router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ips                            = google_compute_address.nat_gateway_static_ip.*.self_link

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}


# PRIVATE VM INSTANCE
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
# SSH Forwarding https://www.cloudsavvyit.com/25/what-is-ssh-agent-forwarding-and-how-do-you-use-it/
resource "google_compute_instance" "private_instance" {
  name         = "private-instance"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  tags = ["private-firewall","private-internet"]

  boot_disk {
    initialize_params {
      image = "centos-7-v20210420"
    }
  }

  # metadata_startup_script = file("filename.sh")

  metadata = {
      "ssh-keys" = "vgreen:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDC/gD4Muq+vdiyHoghzpFbANIjvdF/+XJFVD2JyuOToGVqeeYemWzufEPbVJHDE0yDPUtOizJ7aEji6DIiTLHdgDw8pDRcE5rXB5KuOQLQrCUXDeHi+wqjatpJMQzlzi5tsbm6kuFCajQ00vm4XY52EJZyO8lAhtgP8lDGMcIix+lM/qxfciC/5ifs0RUabbc/3wbaLwLxv2U413s5gUrBAqUPUp7ug6tKrqUO9BPTeTWR3ACkJBdswx5EyGU9IpT/TR9iXKo04184GXUPC1BZKnww6OsxL//N3OAelfA7PXiPBP3nVL9ifqv8nQc3BBDBzeOTGrCsyV2cg/bQHfLV/DLpagk/Nd5oeiMxZCZhwymIxFdZxB0WGjVan5qOv6DDKm2oLy4YHzNQy41W/OEcBqQ22Q7Q+UpA14AQ4riQKSZ+jNNUyx5zwta1+3FbbmbX5OaNJeumha5dWWZigabfrlds/r2mKQUPyPhVbs2X5HivtkjasU0HI1KPgHfqXQE= vgreen@MacBook-Pro.local"
   }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.private.self_link  
  }
}

output "public_ip_address" {
  value = google_compute_address.public_instance_static_ip.address
}

output "public_nat_ip_1" {
  value = google_compute_address.nat_gateway_static_ip[0].address
}

output "public_nat_ip_2" {
  value = google_compute_address.nat_gateway_static_ip[1].address
}

output "public_instance_internal_ip" {
  value = google_compute_instance.public_instance.network_interface.0.network_ip
}

output "public_instance_external_ip" {
  value = google_compute_instance.public_instance.network_interface.0.access_config.0.nat_ip
}

output "private_instance_internal_ip" {
  value = google_compute_instance.private_instance.network_interface.0.network_ip
}