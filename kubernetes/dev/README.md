# Manifiestos Kubernetes de desarrollo

Esta base publica dos réplicas de la API detrás de un `Service` interno y un
`Ingress` para AWS Load Balancer Controller. Las réplicas usan readiness,
liveness y startup probes; el `PodDisruptionBudget` evita que una interrupción
voluntaria quite las dos réplicas al mismo tiempo. Las reglas de distribución
solicitan una réplica por nodo y AZ.

Antes de aplicar:

1. Instalar External Secrets Operator y AWS Load Balancer Controller en EKS.
2. Crear el valor JSON del secreto `devsu/dev/api-runtime` en Secrets Manager,
   usando un usuario PostgreSQL de aplicación con permisos limitados. Debe incluir
   `DJANGO_SECRET_KEY` y `DATABASE_URL`; este último apunta al RDS privado.
3. Sincronizar el repo de ECR real y el SHA de la imagen en `kustomization.yaml`.
4. Reemplazar `api.example.com` en ConfigMap e Ingress por un dominio real y
   añadir HTTPS/ACM cuando se conozca el dominio y el certificado.
5. Verificar que el contenedor desplegado incluya el health check y que la cuota
   EC2 permita cuatro vCPU antes de crear el clúster.

No hay un objeto Kubernetes `Secret` con texto plano en Git. `ExternalSecret`
solicita que el operador genere `devsu-api-runtime` a partir de Secrets Manager.
El valor de `DATABASE_URL` no debe contener las credenciales maestras de RDS.
