variable "project_dir" {
  type    = string
  default = ""
}

job "worker" {
  datacenters = ["dc1"]
  type        = "service"

  group "worker" {
    count = 1

    task "worker" {
      driver = "docker"

      config {
        image   = "hq-dev:latest"
        command = "pnpm"
        args    = ["--filter", "@hq/worker", "dev"]

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
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
