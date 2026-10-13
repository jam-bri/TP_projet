#!/usr/bin/env bash
# Étape 06b (R&D) — Tests d'intégration Postman exécutés par Newman contre le conteneur déployé
# Codes retour : 0 = OK, 1 = collection absente, 2 = au moins un test d'intégration en échec
set -u
source "$(dirname "$0")/../lib/common.sh"

NEWMAN_IMAGE="postman/newman:6.1.3-alpine"
COLLECTION="postman/employe.postman_collection.json"

if [[ ! -f "$CI_DIR/$COLLECTION" ]]; then
    log_error "Collection Postman absente : ci/$COLLECTION"
    exit 1
fi

# Sous Git Bash, Docker (programme Windows) attend un chemin C:/... pour le volume
HOST_CI_DIR="$CI_DIR"
command -v cygpath >/dev/null && HOST_CI_DIR="$(cygpath -m "$CI_DIR")"

# host.docker.internal = la machine hôte vue depuis un conteneur :
# Newman appelle l'application par son port publié, comme un vrai client.
log_info "Exécution de la collection $COLLECTION avec $NEWMAN_IMAGE"
if ! MSYS_NO_PATHCONV=1 docker run --rm \
        --add-host=host.docker.internal:host-gateway \
        -v "$HOST_CI_DIR:/etc/newman" \
        "$NEWMAN_IMAGE" run "$COLLECTION" \
        --env-var "baseUrl=http://host.docker.internal:$APP_PORT" \
        --reporters cli,junit \
        --reporter-junit-export "logs/newman_$(date '+%Y%m%d_%H%M%S').xml"; then
    log_error "Des tests d'intégration ont échoué"
    exit 2
fi

log_ok "Tests d'intégration réussis"
exit 0
