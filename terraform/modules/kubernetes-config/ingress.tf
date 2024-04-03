resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "traefik" {
  depends_on = [kubernetes_namespace.traefik]
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = "26.0.0"
  namespace  = "traefik"
  timeout    = 900 # seconds
}

resource "kubectl_manifest" "ingress_api" {
  depends_on = [helm_release.traefik]
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: applications-backend-ingress
  namespace: applications
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    cert-manager.io/cluster-issuer: clusterissuer
    # For some reason, it was not possible to configure middleware for only one route
    traefik.ingress.kubernetes.io/router.middlewares: applications-backend-cors-middleware@kubernetescrd
spec:
  rules:
    - host: ${local.backend_fqdn}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8000
  tls:
    - secretName: backend-cert
      hosts:
        - ${local.backend_fqdn}
YAML
}

resource "kubectl_manifest" "ingress_api_cors_middleware" {
  depends_on = [helm_release.traefik, kubectl_manifest.ingress_api]
  yaml_body  = <<YAML
# Set up CORS middleware
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: backend-cors-middleware
  namespace: applications
spec:
  headers:
    accessControlAllowMethods:
      - "GET"
      - "OPTIONS"
      - "POST"
    accessControlAllowHeaders:
      - "*"
    accessControlAllowOriginList:
      - "https://${local.webapp_fqdn}"
    accessControlMaxAge: 86400 # How much will the preflight response (allowed methods and headers) be cached for, in seconds
    addVaryHeader: true # The browser caches what it knows about the API. It makes sense to let the browser know that the response may differ depending on the origin.
YAML
}

resource "kubectl_manifest" "ingress_others" {
  depends_on = [helm_release.traefik]
  yaml_body  = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: applications-ingress
  namespace: applications
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    cert-manager.io/cluster-issuer: clusterissuer
spec:
  rules:
    - host: ${local.webapp_fqdn}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-service
                port:
                  number: 80
  tls:
    - secretName: webapp-cert
      hosts:
        - ${local.webapp_fqdn}
YAML
}

data "kubernetes_service_v1" "traefik" {
  depends_on = [helm_release.traefik]
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
}

resource "digitalocean_record" "webapp" {
  domain = var.base_domain
  type   = "A"
  name   = var.webapp_subdomain
  value  = data.kubernetes_service_v1.traefik.status.0.load_balancer.0.ingress.0.ip
}

resource "digitalocean_record" "backend" {
  domain = var.base_domain
  type   = "A"
  name   = var.backend_subdomain
  value  = data.kubernetes_service_v1.traefik.status.0.load_balancer.0.ingress.0.ip
}
