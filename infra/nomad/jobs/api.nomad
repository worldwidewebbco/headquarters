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
      driver = "raw_exec"

      config {
        command = "/bin/sh"
        args    = ["-c", "cd ${var.project_dir} && pnpm --filter @hq/api dev"]
      }

      env {
        NODE_ENV     = "development"
        DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/headquarters"
        PORT         = "3001"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name     = "api"
        port     = "http"
        provider = "nomad"

        check {
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
