// Does not work in older versions of Terraform!
terraform {
  required_version = ">= 0.12"
}

// Configure the Google Cloud provider
data "google_client_config" "default" {}

provider "google" {
 credentials = file("gcpCreds.json")
 project     = var.project_id
}

// Get sensitive variable data from Google Secret Manager
data "google_secret_manager_secret_version" "root_pass" {
  provider  = google
  secret    = "root_pass"
}
data "google_secret_manager_secret_version" "database" {
  provider  = google
  secret    = "database"
}
data "google_secret_manager_secret_version" "db_user" {
  provider  = google
  secret    = "db_user"
}
data "google_secret_manager_secret_version" "db_user_pass" {
  provider  = google
  secret    = "db_user_pass"
}


//Configuring Kubernetes Provider
provider "kubernetes" {
  host                   = google_container_cluster.gke_cluster1.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke_cluster1.master_auth[0].cluster_ca_certificate)
}

//Creating First VPC Network
resource "google_compute_network" "vpc_network1" {
  name        = "prod-wp-env"
  description = "VPC Network for WordPress"
  project     = var.project_id
  auto_create_subnetworks = false
}

//Creating Subnetwork for First VPC
resource "google_compute_subnetwork" "subnetwork1" {
  name          = "wp-subnet"
  ip_cidr_range = "10.2.0.0/16"
  project       = var.project_id
  region        = var.region1
  network       = google_compute_network.vpc_network1.id

  depends_on = [
    google_compute_network.vpc_network1
  ]
}

//Creating Firewall for First VPC Network
resource "google_compute_firewall" "firewall1" {
  name    = "wp-firewall"
  network = google_compute_network.vpc_network1.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  source_tags = ["wp", "wordpress"]

  depends_on = [
    google_compute_network.vpc_network1
  ]
}

//Creating Second VPC Network
resource "google_compute_network" "vpc_network2" {
  name        = "prod-db-env"
  description = "VPC Network For dataBase"
  project     = var.project_id
  auto_create_subnetworks = false
}

//Creating Network For Second VPC
resource "google_compute_subnetwork" "subnetwork2" {
  name          = "db-subnet"
  ip_cidr_range = "10.4.0.0/16"
  project       = var.project_id
  region        = var.region2
  network       = google_compute_network.vpc_network2.id

  depends_on = [
    google_compute_network.vpc_network2
  ]
}

//Creating Firewall for Second VPC Network
resource "google_compute_firewall" "firewall2" {
  name    = "db-firewall"
  network = google_compute_network.vpc_network2.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "3306"]
  }

  source_tags = ["db", "database"]

  depends_on = [
    google_compute_network.vpc_network2
  ]
}

//VPC Network Peering1 
resource "google_compute_network_peering" "peering1" {
  name         = "wp-to-db"
  network      = google_compute_network.vpc_network1.id
  peer_network = google_compute_network.vpc_network2.id

  depends_on = [
    google_compute_network.vpc_network1,
    google_compute_network.vpc_network2
  ]
}

//VPC Network Peering2
resource "google_compute_network_peering" "peering2" {
  name         = "db-to-wp"
  network      = google_compute_network.vpc_network2.id
  peer_network = google_compute_network.vpc_network1.id

  depends_on = [
    google_compute_network.vpc_network1,
    google_compute_network.vpc_network2
  ]
}

//Configuring SQL Database instance
resource "google_sql_database_instance" "sqldb_Instance" {
  name             = "sql1"
  database_version = "MYSQL_5_6"
  region           = var.region2
  root_password    = data.google_secret_manager_secret_version.root_pass.secret_data

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "sqlnet"
        value = "0.0.0.0/0"
      }
    }
  }

  depends_on = [
    google_compute_subnetwork.subnetwork2
  ]
}

//Creating SQL Database
resource "google_sql_database" "sql_db" {
  name     = data.google_secret_manager_secret_version.database.secret_data
  instance = google_sql_database_instance.sqldb_Instance.name

  depends_on = [
    google_sql_database_instance.sqldb_Instance
  ]  
}

//Creating SQL Database User
resource "google_sql_user" "dbUser" {
  name     = data.google_secret_manager_secret_version.db_user.secret_data
  instance = google_sql_database_instance.sqldb_Instance.name
  password = data.google_secret_manager_secret_version.db_user_pass.secret_data

  depends_on = [
    google_sql_database_instance.sqldb_Instance
  ]
}

//Creating Container Cluster
resource "google_container_cluster" "gke_cluster1" {
  name     = "my-cluster"
  description = "My GKE Cluster"
  project = var.project_id
  location = var.region1
  network = google_compute_network.vpc_network1.name
  subnetwork = google_compute_subnetwork.subnetwork1.name
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [
    google_compute_subnetwork.subnetwork1
  ]
}

//Creating Node Pool For Container Cluster
resource "google_container_node_pool" "nodepool1" {
  name       = "my-node-pool"
  project    = var.project_id
  location   = var.region1
  cluster    = google_container_cluster.gke_cluster1.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  depends_on = [
    google_container_cluster.gke_cluster1
  ]
}

//Set Current Project in gcloud SDK
resource "null_resource" "set_gcloud_project" {
  provisioner "local-exec" {
    command = "gcloud config set project ${var.project_id}"
  }  
}

//Configure Kubectl with Our GCP K8s Cluster
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster1.name} --region ${google_container_cluster.gke_cluster1.location} --project ${google_container_cluster.gke_cluster1.project}"
  }  

  depends_on = [
    null_resource.set_gcloud_project,
    google_container_cluster.gke_cluster1
  ]
}

//WordPress Deployment
resource "kubernetes_deployment" "wp-dep" {
  metadata {
    name   = "wp-dep"
    labels = {
      env     = "Production"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        pod     = "wp"
        env     = "Production"
      }
    }

    template {
      metadata {
        labels = {
          pod     = "wp"
          env     = "Production"
        }
      }

      spec {
        container {
          image = "wordpress"
          name  = "wp-container"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = google_sql_database_instance.sqldb_Instance.ip_address.0.ip_address
          }
          env {
            name  = "WORDPRESS_DB_USER"
            value = data.google_secret_manager_secret_version.db_user.secret_data
          }
          env {
            name  = "WORDPRESS_DB_PASSWORD"
            value = data.google_secret_manager_secret_version.db_user_pass.secret_data
          }
          env{
            name  = "WORDPRESS_DB_NAME"
            value = data.google_secret_manager_secret_version.database.secret_data
          }
          env{
            name  = "WORDPRESS_TABLE_PREFIX"
            value = "wp_"
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [
    null_resource.set_gcloud_project,
    google_container_cluster.gke_cluster1,
    google_container_node_pool.nodepool1,
    null_resource.configure_kubectl
  ]
}

//Creating LoadBalancer Service
resource "kubernetes_service" "wpService" {
  metadata {
    name   = "wp-svc"
    labels = {
      env     = "Production" 
    }
  }  

  spec {
    type     = "LoadBalancer"
    selector = {
      pod = kubernetes_deployment.wp-dep.spec.0.selector.0.match_labels.pod
    }

    port {
      name = "wp-port"
      port = 80
    }
  }

  depends_on = [
    kubernetes_deployment.wp-dep,
  ]
}

//Outputs
output "wp_service_url" {
  value = kubernetes_service.wpService.status.0.load_balancer.0.ingress.0.ip

  depends_on = [
    kubernetes_service.wpService
  ]
}

output "db_host" {
  value = google_sql_database_instance.sqldb_Instance.ip_address.0.ip_address

  depends_on = [
    google_sql_database_instance.sqldb_Instance
  ]
}

output "database_name" {
  value = data.google_secret_manager_secret_version.database.secret_data

  depends_on = [
    google_sql_database_instance.sqldb_Instance
  ]
}

output "db_user_name" {
  value = data.google_secret_manager_secret_version.db_user.secret_data

  depends_on = [
    google_sql_database_instance.sqldb_Instance
  ]
}

output "db_user_passwd" {
  value = data.google_secret_manager_secret_version.db_user_pass.secret_data

  depends_on = [
    google_sql_database_instance.sqldb_Instance
  ]
}

//Open WordPress Site Automatically
resource "null_resource" "open_wp" {
  provisioner "local-exec" {
    command = "start chrome ${kubernetes_service.wpService.status.0.load_balancer.0.ingress.0.ip}" 
  }

  depends_on = [
    kubernetes_service.wpService
  ]
}
