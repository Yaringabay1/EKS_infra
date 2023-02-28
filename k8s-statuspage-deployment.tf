resource "kubernetes_deployment" "app-server" {
  metadata {
    name = "statuspage"
    labels = {
      test = "statuspage"
    }
  }
  spec {
    replicas = 3  

    selector {
      match_labels = {
        test = "statuspage"
      }
    }
  

    template {
      metadata {
        labels = {
          test = "statuspage"
        }
      }
    

      spec {
        container {
          image = "yaringabay1/app_60:latest"
          name  = "actual-cont-app"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
