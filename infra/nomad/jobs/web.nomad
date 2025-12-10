variable "project_dir" {
  type    = string
  default = ""
}

job "web" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      port "http" {
        static = 3000
      }
    }

    task "web" {
      driver = "raw_exec"

      config {
        command = "/bin/sh"
        args    = ["-c", "cd ${var.project_dir} && pnpm --filter @hq/web dev"]
      }

      env {
        NODE_ENV            = "development"
        PORT                = "3000"
        NEXT_PUBLIC_API_URL = "http://localhost:3001"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name     = "web"
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
