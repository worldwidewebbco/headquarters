job "postgres" {
  datacenters = ["dc1"]
  type        = "service"

  group "postgres" {
    count = 1

    network {
      port "db" {
        static = 5432
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:16-alpine"
        ports = ["db"]

        # Persist data across restarts
        volumes = [
          "hq-postgres-data:/var/lib/postgresql/data",
        ]
      }

      env {
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "postgres"
        POSTGRES_DB       = "headquarters"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name     = "postgres"
        port     = "db"
        provider = "nomad"

        check {
          type     = "tcp"
          port     = "db"
          interval = "5s"
          timeout  = "2s"
        }
      }
    }
  }
}
