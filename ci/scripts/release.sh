#!/usr/bin/env bash
set -euo pipefail

IMAGE="$1"        # e.g. ghcr.io/org/myservice:sha123
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
NAMESPACE="app-prod"

echo "Applying image ${IMAGE} to deployment..."

kubectl --kubeconfig="${KUBECONFIG}" -n ${NAMESPACE} set image deployment/myservice myservice=${IMAGE} --record
kubectl --kubeconfig="${KUBECONFIG}" -n ${NAMESPACE} rollout status deployment/myservice --timeout=120s

