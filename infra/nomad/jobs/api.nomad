variable "project_dir" {
  type    = string
  default = ""
}

job "api" {
  datacenters = ["dc1"]
  type        = "service"

  group "api" {
    count = 1

    network {
      port "http" {
        static = 3001
      }
    }

    task "api" {
      driver = "docker"

      config {
        image   = "hq-dev:latest"
        ports   = ["http"]
        command = "pnpm"
        args    = ["--filter", "@hq/api", "dev"]

        # Mount source code for hot reload
        volumes = [
          "${var.project_dir}:/app",
        ]

        # Working directory
        work_dir = "/app"
      }

      env {
        NODE_ENV     = "development"
        DATABASE_URL = "postgresql://postgres:postgres@host.docker.internal:5432/headquarters"
        PORT         = "3001"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "api"
        port = "http"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
