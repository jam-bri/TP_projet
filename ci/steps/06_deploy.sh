#!/usr/bin/env bash
# Étape 06 — Construction de l'image Docker et déploiement du conteneur
# Codes retour : 0 = OK, 1 = Docker indisponible, 2 = échec du build,
#                3 = échec du démarrage du conteneur, 4 = health check en échec
set -u
source "$(dirname "$0")/../lib/common.sh"

TAG="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"

if ! docker info >/dev/null 2>&1; then
    log_error "Docker n'est pas démarré (lance Docker Desktop)"
    exit 1
fi

log_info "Construction de l'image $IMAGE_NAME:$TAG"
if ! docker build -t "$IMAGE_NAME:$TAG" "$SERVICE_DIR"; then
    log_error "Échec du docker build"
    exit 2
fi

EXTRA_ARGS=()
# Test du rollback uniquement : FORCE_DEPLOY_FAILURE=1 bash ci/pipeline.sh
if [[ "${FORCE_DEPLOY_FAILURE:-0}" == "1" ]]; then
    log_warn "FORCE_DEPLOY_FAILURE=1 : l'application est lancée sur un mauvais port pour simuler une panne"
    EXTRA_ARGS=(-e SERVER_PORT=9999)
fi

log_info "Remplacement du conteneur $APP_NAME"
remove_container
if ! docker run -d --name "$APP_NAME" -p "$APP_PORT:$APP_PORT" "${EXTRA_ARGS[@]}" "$IMAGE_NAME:$TAG"; then
    log_error "Impossible de démarrer le conteneur (port $APP_PORT déjà utilisé ?)"
    exit 3
fi

if ! wait_for_health; then
    exit 4
fi

log_ok "Déployé : $IMAGE_NAME:$TAG sur http://localhost:$APP_PORT (en attente des tests d'intégration)"
exit 0
