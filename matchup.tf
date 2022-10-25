data "aws_ecr_image" "matchup_image" {
  repository_name = "matchup"
  image_tag       = "latest"
}

resource "kubernetes_namespace" "matchup" {
  metadata {
    name = "matchup"
  }
}

/* Deployment */
resource "kubernetes_deployment" "matchup" {
  metadata {
    name      = "matchup"
    namespace = "matchup"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "matchup"
      }
    }
    template {
      metadata {
        labels = {
          app = "matchup"
        }
      }
      spec {
        container {
          image = "${aws_ecr_repository.matchup_ecr.repository_url}:latest"
          name  = "matchup"
          port {
            container_port = 3000
          }
        }
      }
    }
  }
}

/* Service */
resource "kubernetes_service" "matchup-lb" {
  metadata {
    name      = "matchup-lb"
    namespace = "matchup"
  }
  spec {
    selector = {
      "app" = "matchup"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}