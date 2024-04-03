resource "kubectl_manifest" "webapp_deployment" {
  depends_on = [kubernetes_namespace.applications, kubernetes_secret_v1.dockerconfigjson_ghcr]
    yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-service
  namespace: applications
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: web-service
      app.kubernetes.io/part-of: app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: web-service
        app.kubernetes.io/part-of: app
    spec:
      containers:
        - name: web
          image: ghcr.io/managed-prototypes/helloworld-fullstack-k8s-webapp:main
          imagePullPolicy: IfNotPresent
          # resources:
          #   limits:
          #     memory: 512Mi
          #     cpu: "0.5"
          #   requests:
          #     memory: 128Mi
          #     cpu: "0.2"
          ports:
            - containerPort: 80
          env:
            - name: WEBAPP_BACKEND_URL
              value: "https://${local.backend_fqdn}"
            - name: WEBAPP_ALLOW_INDEXING
              value: "true"
      imagePullSecrets:
        - name: dockerconfigjson-ghcr
YAML
}

resource "kubectl_manifest" "webapp_service" {
  depends_on = [kubectl_manifest.webapp_deployment]
    yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  namespace: applications
  name: web-service
spec:
  selector:
    app.kubernetes.io/name: web-service
    app.kubernetes.io/part-of: app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
YAML
}
