provider "kubernetes" {
    host = "https://localhost:6445"
}

data "template_file" "ingress" {
  template = "${file("${path.module}/kube/ingress-controller.yaml")}"
}

resource "null_resource" "ingress" {
  triggers = {
    manifest_sha1 = "${sha1("${data.template_file.ingress.rendered}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ./kube/ingress-controller.yaml"
  }
}

data "template_file" "dashboard" {
  template = "${file("${path.module}/kube/dashboard.yaml")}"
}

resource "null_resource" "dashboard" {
  triggers = {
    manifest_sha1 = "${sha1("${data.template_file.dashboard.rendered}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ./kube/dashboard.yaml"
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

provider "helm" {
  
  kubernetes {
    host = "https://localhost:6445"
  }

  install_tiller  = "true"
  service_account = "tiller"
  tiller_image    = "gcr.io/kubernetes-helm/tiller:v2.13.0"
}

resource "helm_release" "keycloak" {
  name = "keycloak"
  chart = "stable/keycloak"

  depends_on = ["null_resource.helm_init"]
}

resource "null_resource" "helm_init" {
  provisioner "local-exec" {
    command = "helm init"
  }
}

data "template_file" "keycloak" {
  template = "${file("${path.module}/kube/keycloak-ingress.yaml")}"
}

resource "null_resource" "keycloak" {
  triggers = {
    manifest_sha1 = "${sha1("${data.template_file.keycloak.rendered}")}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ./kube/keycloak-ingress.yaml"
  }
}