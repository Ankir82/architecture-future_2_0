
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "tcp://localhost:2375"
}

resource "docker_network" "app" {
  name = "${var.project_name}-network"
}

resource "docker_volume" "db_data" {
  name = "${var.project_name}-db-data"
}

# Nessie catalog

resource "docker_image" "catalog" {
  name = "projectnessie/nessie:latest"
}

resource "docker_container" "catalog" {
  name  = "${var.project_name}-catalog"
  image = docker_image.catalog.image_id

  ports {
    internal = 19120
    external = 19120
  }

  networks_advanced {
    name = docker_network.app.name
  }

  restart = "unless-stopped"
}

 # Storage

resource "docker_image" "storage" {
  name = "minio/minio:latest"
}

resource "docker_container" "storage" {
  name  = "${var.project_name}-storage"
  image = docker_image.storage.image_id

  env = [
    "MINIO_ROOT_USER=${var.minio_username}",
    "MINIO_ROOT_PASSWORD=${var.minio_password}",
    "MINIO_DOMAIN=${var.minio_domain}",
  ]

  ports {
    internal = 9001
    external = 9001
  }
  ports {
    internal = 9000
    external = 9000
  }

  networks_advanced {
    name = docker_network.app.name
  }

  command = [  "server", 
    "/data", 
    "--console-address", 
    ":9001" 
  ]

  restart = "unless-stopped"
}
 
 # Minio Client Container
resource "docker_image" "mc" {
  name = "minio/mc:latest"
}

resource "docker_container" "mc" {
  name  = "${var.project_name}-mc"
  image = docker_image.mc.image_id

  env = [
    "AWS_ACCESS_KEY_ID=admin",
    "AWS_SECRET_ACCESS_KEY=password",
    "AWS_REGION=us-east-1",
    "AWS_DEFAULT_REGION=us-east-1",
  ]

  entrypoint = ["/bin/sh", "-c", "until (/usr/bin/mc config host add minio http://storage:9000 admin password) do echo '...waiting...' && sleep 1; done; /usr/bin/mc rm -r --force minio/warehouse; /usr/bin/mc mb minio/warehouse; /usr/bin/mc policy set public minio/warehouse; tail -f /dev/null "]
  
  networks_advanced {
    name = docker_network.app.name
  }

  restart = "unless-stopped"
}


