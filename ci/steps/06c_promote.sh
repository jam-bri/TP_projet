#!/usr/bin/env bash
# Étape 06c — Promotion de l'image déployée en version stable (cible des futurs rollbacks)
# Codes retour : 0 = OK, 1 = échec du tag
set -u
source "$(dirname "$0")/../lib/common.sh"

TAG="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
if ! docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:stable"; then
    log_error "Impossible de taguer $IMAGE_NAME:$TAG en stable"
    exit 1
fi

log_ok "$IMAGE_NAME:$TAG promue en $IMAGE_NAME:stable"
exit 0
