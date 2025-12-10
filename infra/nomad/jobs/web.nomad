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
      driver = "docker"

      config {
        image   = "hq-dev:latest"
        ports   = ["http"]
        command = "pnpm"
        args    = ["--filter", "@hq/web", "dev"]

        # Mount source code for hot reload
        volumes = [
          "${var.project_dir}:/app",
        ]

        # Working directory
        work_dir = "/app"
      }

      env {
        NODE_ENV = "development"
        PORT     = "3000"
        # API URL for tRPC client
        NEXT_PUBLIC_API_URL = "http://localhost:3001"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "web"
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
