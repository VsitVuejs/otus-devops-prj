resource "kubernetes_deployment" "database" {
  metadata {
    name = "mongodb"

    labels = {
      pod = "mongodb"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        pod = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          pod = "mongodb"
        }
      }

      spec {
        container {
          image = "mongo:3.2"
          name  = "mongodb"

          port {
            container_port = 27017
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "database" {
    metadata {
        name = "mongodb"
    }

    spec {
        selector = {
            pod = kubernetes_deployment.database.metadata[0].labels.pod
        }

        port {
            port        = 27017
        }
    }
}