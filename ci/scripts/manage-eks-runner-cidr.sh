#!/usr/bin/env bash

set -euo pipefail

MODE="${1:?Uso: manage-eks-runner-cidr.sh add|remove CLUSTER REGION [CIDR]}"
CLUSTER_NAME="${2:?Indica el nombre del clúster EKS}"
AWS_REGION="${3:?Indica la región AWS}"

get_cluster_config() {
  aws eks describe-cluster \
    --region "${AWS_REGION}" \
    --name "${CLUSTER_NAME}" \
    --query 'cluster.resourcesVpcConfig' \
    --output json
}

wait_for_update() {
  local update_id="$1"
  local attempt status

  for attempt in $(seq 1 60); do
    status="$(aws eks describe-update \
      --region "${AWS_REGION}" \
      --name "${CLUSTER_NAME}" \
      --update-id "${update_id}" \
      --query 'update.status' \
      --output text)"

    case "${status}" in
      Successful)
        echo "La actualización EKS terminó correctamente."
        return 0
        ;;
      Failed|Cancelled)
        aws eks describe-update \
          --region "${AWS_REGION}" \
          --name "${CLUSTER_NAME}" \
          --update-id "${update_id}" \
          --query 'update.errors' \
          --output json >&2
        return 1
        ;;
    esac

    if (( attempt == 60 )); then
      echo "La actualización EKS no terminó en diez minutos." >&2
      return 1
    fi
    sleep 10
  done
}

update_cluster_cidrs() {
  local cidrs="$1"
  local config public_access private_access update_config update_id

  config="$(get_cluster_config)"
  public_access="$(jq -c '.endpointPublicAccess' <<< "${config}")"
  private_access="$(jq -c '.endpointPrivateAccess' <<< "${config}")"
  update_config="$(jq -cn \
    --argjson public "${public_access}" \
    --argjson private "${private_access}" \
    --argjson cidrs "${cidrs}" \
    '{endpointPublicAccess:$public,endpointPrivateAccess:$private,publicAccessCidrs:$cidrs}')"

  update_id="$(aws eks update-cluster-config \
    --region "${AWS_REGION}" \
    --name "${CLUSTER_NAME}" \
    --resources-vpc-config "${update_config}" \
    --query 'update.id' \
    --output text)"
  wait_for_update "${update_id}"
}

case "${MODE}" in
  add)
    runner_ip="$(curl --fail --silent --show-error --ipv4 https://checkip.amazonaws.com | tr -d '[:space:]')"
    python3 -c 'import ipaddress,sys; ipaddress.IPv4Address(sys.argv[1])' "${runner_ip}"
    runner_cidr="${runner_ip}/32"
    echo "runner_cidr=${runner_cidr}" >> "${GITHUB_OUTPUT:?GitHub Actions debe definir GITHUB_OUTPUT}"

    current_config="$(get_cluster_config)"
    current_cidrs="$(jq -c '.publicAccessCidrs' <<< "${current_config}")"
    if jq --exit-status --arg cidr "${runner_cidr}" 'index($cidr) != null' \
      <<< "${current_cidrs}" >/dev/null; then
      echo "changed=false" >> "${GITHUB_OUTPUT}"
      echo "La IP del runner ya estaba autorizada; no se cambiará la lista."
      exit 0
    fi

    cidr_count="$(jq 'length' <<< "${current_cidrs}")"
    if (( cidr_count >= 40 )); then
      echo "El límite de 40 CIDR públicos de EKS impediría agregar el runner." >&2
      exit 1
    fi

    updated_cidrs="$(jq -c --arg cidr "${runner_cidr}" '. + [$cidr]' <<< "${current_cidrs}")"
    # Marcarlo antes de llamar AWS para que el paso always() intente limpiar
    # incluso cuando la solicitud falle después de haber sido aceptada.
    echo "changed=true" >> "${GITHUB_OUTPUT}"
    update_cluster_cidrs "${updated_cidrs}"
    ;;
  remove)
    runner_cidr="${4:?Indica el CIDR temporal que se retirará}"
    python3 -c 'import ipaddress,sys; parsed=ipaddress.ip_interface(sys.argv[1]); assert parsed.network.prefixlen == 32' "${runner_cidr}"
    current_config="$(get_cluster_config)"
    current_cidrs="$(jq -c '.publicAccessCidrs' <<< "${current_config}")"
    if ! jq --exit-status --arg cidr "${runner_cidr}" 'index($cidr) != null' \
      <<< "${current_cidrs}" >/dev/null; then
      echo "La IP temporal ya no está autorizada; no se requiere limpieza."
      exit 0
    fi

    restored_cidrs="$(jq -c --arg cidr "${runner_cidr}" '[.[] | select(. != $cidr)]' <<< "${current_cidrs}")"
    if [[ "${restored_cidrs}" == "[]" ]]; then
      echo "Se cancela la limpieza: dejar el endpoint sin CIDR autorizado lo bloquearía." >&2
      exit 1
    fi

    update_cluster_cidrs "${restored_cidrs}"
    ;;
  *)
    echo "Modo desconocido: ${MODE}. Usa add o remove." >&2
    exit 2
    ;;
esac
