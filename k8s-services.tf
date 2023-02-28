resource "kubernetes_service_v1" "app-server-service" {
  metadata {
    name = "statuspage-service"
  }
  spec {
    selector = {
      test = kubernetes_deployment.app-server.metadata.0.labels.test
    }
    port {
      port = 5678
    }
  }
}
