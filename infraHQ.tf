### provider.tf
provider "helm" {
  kubernetes {
    config_path = "single-server.rke2.yaml"  # Path to your kubeconfig
  }
}

provider "kubernetes" {
  config_path = "single-server.rke2.yaml"
}

### infrahq.tf
resource "helm_release" "infrahq" {
  name       = "infrahq"
  repository = "https://infrahq.github.io/helm-charts"
  chart      = "infra"
  namespace  = "infra"
  create_namespace = true

  values = [
    <<-EOF
    server:
      enabled: true
      extraArgs:
        - --domain=infrahq.yourdomain.com
      ingress:
        enabled: true
        hosts:
          - host: infrahq.yourdomain.com
            paths:
              - path: /
                pathType: ImplementationSpecific
        tls:
          - secretName: infrahq-tls
            hosts:
              - infrahq.yourdomain.com
    EOF
  ]
}

### ingress.tf (Optional: if you don’t have Ingress Controller)
resource "kubernetes_ingress_v1" "infrahq" {
  metadata {
    name      = "infrahq"
    namespace = "infra"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    rule {
      host = "infrahq.yourdomain.com"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "infrahq"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = ["infrahq.yourdomain.com"]
      secret_name = "infrahq-tls"
    }
  }
}

### rbac.tf (Optional: Add users and roles)
resource "kubernetes_role" "viewer" {
  metadata {
    name      = "viewer-role"
    namespace = "infra"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "deployments"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_role_binding" "viewer_binding" {
  metadata {
    name      = "viewer-binding"
    namespace = "infra"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.viewer.metadata[0].name
  }
  subject {
    kind      = "User"
    name      = "remote-user"
    api_group = "rbac.authorization.k8s.io"
  }
}

### outputs.tf
output "infra_url" {
  value = "https://infrahq.yourdomain.com"
}

output "kubeconfig_path" {
  value = "single-server.rke2.yaml"
}
