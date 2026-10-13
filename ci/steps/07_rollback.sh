#!/usr/bin/env bash
# Étape 07 — Rollback vers la dernière image stable (lancée seulement si l'étape 06 échoue)
# Codes retour : 0 = OK, 1 = aucune version stable disponible, 2 = la version stable ne démarre pas
set -u
source "$(dirname "$0")/../lib/common.sh"

if ! docker image inspect "$IMAGE_NAME:stable" >/dev/null 2>&1; then
    log_error "Aucune image $IMAGE_NAME:stable : rien vers quoi revenir (premier déploiement ?)"
    remove_container
    exit 1
fi

log_info "Redéploiement de $IMAGE_NAME:stable"
remove_container
if ! docker run -d --name "$APP_NAME" -p "$APP_PORT:$APP_PORT" "$IMAGE_NAME:stable" || ! wait_for_health; then
    log_error "La version stable ne démarre pas non plus"
    exit 2
fi

log_ok "Rollback réussi : $IMAGE_NAME:stable est en service"
exit 0
