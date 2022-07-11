terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.90.0"
    }
  }
}

## ============== Terraform_Provider =========================== ##
provider "google-beta" {
 credentials = file("test.json")
 project = "${var.credentials_google_project}"
 region = "${var.credentials_google_region}"
 zone = "${var.credentials_google_zone}"
}

## ============= SQL_CREATE_USER =========== ##
provider "google" {
 credentials = file("test.json")
 project = "${var.credentials_google_project}"
 region = "us-west3"
 zone = "${var.credentials_google_zone}"
}

## ============= SQL_CREATE_USER =========== ##
resource "google_sql_user" "users" {
  
  depends_on =  [google_sql_database_instance.main]

  name       = "gcp_finanto_user"
  instance   = google_sql_database_instance.main.name
  host       = "%"
  password   = "${var.sql_passwd}"
}

## ================ SQL_DB_INSTANCE ================ ##
resource "google_sql_database_instance" "main" {
  name             = "gcp-sql-instance-7"
  database_version = "MYSQL_8_0"
  region           = "us-west3"
  settings {
    tier = "db-f1-micro"
  }
}

## ================= GCP_COMPUTE_INTANCE ==================== ##
resource "google_compute_instance" "webserver" {
  depends_on = [google_sql_database_instance.main]
  
  name          = "${var.nome}"
  machine_type  = "${var.tipo_maquina}"
  zone          = "${var.zona}"

  boot_disk {
    initialize_params {
      image = "${var.imagem}"
    }
  }
  metadata_startup_script = "sudo apt update;wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -;sudo apt-get install gnupg;wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -;wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -;echo 'deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/5.0 main' | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list;sudo apt-get update;sudo apt-get install -y mongodb-org=5.0.9 mongodb-org-database=5.0.9 mongodb-org-server=5.0.9 mongodb-org-shell=5.0.9 mongodb-org-mongos=5.0.9 mongodb-org-tools=5.0.9;sudo rm -rf /tmp/mongodb-27017.sock;sudo sed -i 's_bindIp: 127.0.0.1_bindIp: 0.0.0.0_g'/etc/mongod.conf;sudo systemctl start mongod;sudo systemctl status mongod;"
  network_interface {
    network = "default"
    access_config {
    #    nat_ip = google_compute_address.static.address
    }
  }
}

## ===================== GCP_INSTANCE_FIREWALL_RULES ======================= ## 
resource "google_compute_firewall" "webfirewall" {
  depends_on = [google_sql_database_instance.main]

  name        = "${var.nome_fw}"
  network     = "default"
  allow {
    protocol  = "tcp"
    ports     = "${var.portas}"
  }
}