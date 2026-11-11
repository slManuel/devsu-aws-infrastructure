# Infraestructura AWS para Devsu

Infraestructura declarativa para alojar la API Python en Amazon EKS en `us-east-2`.
La carpeta de la aplicación y los diagramas de trabajo se mantienen fuera de este
repositorio. Este repositorio todavía no se ha publicado con un commit.

## Estructura

```text
bootstrap/state/       Crea una vez el bucket versionado para el estado remoto
environments/ci/       Registra OIDC y el rol GitHub para publicar la imagen
environments/dev/      Une los módulos y configura el entorno de desarrollo
modules/network/       VPC, subredes públicas/privadas, rutas y NAT compartida
modules/ecr/           Repositorio privado de imágenes Docker
modules/eks/           Clúster EKS y grupo administrado de nodos EC2
modules/database/      PostgreSQL privado en RDS y su secreto administrado
modules/secrets/       Crea el contenedor vacío de Secrets Manager para la API
modules/github_actions/ Proveedor OIDC y rol de publicación limitado a main
kubernetes/dev/        ConfigMap, ExternalSecret, Deployment, Service e Ingress
.github/workflows/     Validación Terraform sin credenciales AWS
ci/                    Versión fijada de Checkov para el workflow
```

Los módulos `network`, `ecr`, `eks` y `database` pertenecen a esta primera base.
El clúster tiene dos nodos `t3a.small` bajo demanda, repartidos entre dos AZ, y
una sola NAT Gateway compartida para contener el costo. Esto permite que la API
tenga dos réplicas en nodos distintos, pero la NAT es un punto único de falla y
no se promete tolerancia a la caída de una AZ completa.

Los manifiestos de `kubernetes/dev/` esperan que External Secrets Operator esté
instalado y que el secreto `devsu/dev/api-runtime` se haya cargado manualmente en
Secrets Manager. Terraform crea solamente el contenedor vacío del secreto y
concede lectura al rol del operador; no guarda valores secretos en el estado.
Falta integrar el controlador y el AWS Load Balancer Controller antes de aplicar
esos manifiestos en un clúster.

## Requisitos locales

- Terraform `>= 1.10, < 2.0` (S3 usa bloqueo nativo con archivo `.tflock`).
- AWS CLI autenticado con un perfil o rol autorizado para administrar los
  recursos. No se guardan credenciales en Terraform ni en este repositorio.
- Los dos nodos `t3a.small` requieren cuatro vCPU On-Demand estándar. Verifica la
  cuota de la cuenta y región destino antes de aplicar; al revisar esta cuenta,
  la cuota aplicada era de cinco vCPU.

## Validación local

Desde la raíz del repositorio:

```bash
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/ci init -backend=false
terraform -chdir=environments/ci validate
terraform -chdir=bootstrap/state init -backend=false
terraform -chdir=bootstrap/state validate
terraform fmt -recursive -check
```

`init -backend=false` descarga proveedores para revisar la sintaxis sin conectarse
al backend remoto. `validate` no crea recursos. `terraform plan` sí consulta AWS y
requiere credenciales y los valores locales del entorno.

## GitHub Actions y publicación en ECR

El workflow `.github/workflows/terraform.yml` valida formato, Checkov y las
raíces Terraform en cada pull request y al actualizar `main`. No recibe
credenciales AWS y no ejecuta `plan` ni `apply`.

El workflow del repositorio de la API ejecuta estilo, Bandit, `pip-audit`,
pruebas, cobertura, construcción Docker y Trivy. Solo después de pasar todos los
controles en `main`, un trabajo separado solicita credenciales temporales a AWS
mediante GitHub OIDC y publica la imagen con etiqueta `git-<SHA completo>`.
El rol de IAM limita su confianza a la identidad inmutable del repositorio de la
API y a la rama `main`; sus permisos ECR solo permiten subir imágenes a ese
repositorio. No se guardan llaves IAM en GitHub. Después de aplicar
`environments/ci`, configura sus salidas `api_publisher_role_arn` y
`api_ecr_repository_url` como variables `AWS_ROLE_ARN` y `ECR_REPOSITORY_URI` en
los ajustes del repositorio de la API. Hasta que existan ambas variables, el job
de publicación queda omitido y siguen corriendo las validaciones; no se
requieren credenciales para probar el pipeline.

El workflow de la API construye y publica la imagen; los manifiestos de
`kubernetes/dev/` se aplican después de preparar el clúster y sus controladores.

Los workflows usan runners estándar de GitHub en repositorios públicos. No hay
cargos de AWS por CodeBuild ni por capacidad de cómputo dedicada para CI; ECR y
los recursos de la arquitectura sí pueden tener cargos propios. La aplicación
de Terraform queda como operación manual y revisada.

## Backend remoto de Terraform

El estado local solo se usa durante la creación inicial del bucket. Los archivos
de estado se excluyen de Git y se protegen como información sensible.

1. Elegir un nombre globalmente único en `bootstrap/state/terraform.tfvars`.
2. Inicializar con `terraform init -backend=false` y revisar el plan del
   bootstrap. Al aplicarlo, el bucket queda versionado, cifrado, sin acceso
   público y con HTTPS obligatorio; el estado inicial queda local.
3. Copiar `bootstrap/state/backend.hcl.example` como `backend.hcl`, completar el
   nombre del bucket y ejecutar `terraform init -migrate-state
   -backend-config=backend.hcl` desde `bootstrap/state`.
4. Inicializar `environments/ci` y `environments/dev` con sus propios ejemplos
   `backend.hcl`, usando una clave diferente para cada raíz.

Las claves son rutas de objetos S3, no carpetas reales: `devsu/bootstrap/state/terraform.tfstate`,
`devsu/ci/terraform.tfstate` y `devsu/dev/terraform.tfstate`. El backend usa
`use_lockfile = true`; no requiere DynamoDB. AWS recomienda versionar el estado
para poder recuperarlo ante errores. La identidad de ejecución necesita permisos
mínimos sobre cada prefijo y su archivo `.tflock`. Los archivos `backend.hcl`
con valores concretos no se publican.

## Antes de crear recursos

Completar localmente `environments/dev/terraform.tfvars` con el CIDR público de
administración permitido para conectarse al endpoint de Kubernetes, por ejemplo
`["203.0.113.10/32"]` reemplazando ese valor por la IP pública real. No usar
`0.0.0.0/0`. Confirmar cuota EC2, región, costos y el plan de Terraform antes de
cualquier `apply`. No usar este entorno para producción.
