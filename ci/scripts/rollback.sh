#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
NAMESPACE="app-prod"
DEPLOYMENT="myservice"

# Strategy 1: kubectl rollout undo
echo "Undoing rollout for ${DEPLOYMENT} in ${NAMESPACE}..."
kubectl --kubeconfig="${KUBECONFIG}" -n ${NAMESPACE} rollout undo deployment/${DEPLOYMENT}

# Option: If using GitOps, create a commit to the gitops repo to restore previous image tag.
# (implement as needed)

