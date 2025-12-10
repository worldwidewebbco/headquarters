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
      driver = "raw_exec"

      config {
        command = "/bin/sh"
        args    = ["-c", "cd ${var.project_dir} && pnpm --filter @hq/worker dev"]
      }

      env {
        NODE_ENV     = "development"
        DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/headquarters"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
