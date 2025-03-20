provider "kubernetes" {
  config_path = "single-server.rke2.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "single-server.rke2.yaml"
  }
}

resource "helm_release" "kyverno" {
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  namespace  = "kyverno"
  create_namespace = true

  values = [
    <<EOF
installCRDs: true
replicaCount: 1
EOF
  ]
}
