#!/usr/bin/env bash
# Variables et fonctions partagées par l'orchestrateur et les étapes.

# Chemins calculés depuis l'emplacement de ce fichier (ci/lib/), donc indépendants
# du dossier depuis lequel on lance la pipeline.
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$CI_DIR/.." && pwd)"
SERVICE_DIR="$REPO_ROOT/services/service_employe"

APP_NAME="service-employe"
APP_PORT="${APP_PORT:-8081}"
JAR_NAME="service_employe-0.0.1-SNAPSHOT.jar"

log() {
    local level="$1"; shift
    printf '[%s] [%-5s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*"
}
log_info()  { log INFO  "$@"; }
log_warn()  { log WARN  "$@"; }
log_ok()    { log OK    "$@"; }
log_error() { log ERROR "$@" >&2; }

# Lance le Maven Wrapper dans le dossier du service.
# -B : mode batch (pas de couleurs ni d'interaction, logs lisibles)
# -ntp : n'affiche pas la progression des téléchargements
run_maven() {
    (cd "$SERVICE_DIR" && ./mvnw -B -ntp "$@")
}

IMAGE_NAME="$APP_NAME"
HEALTH_URL="http://localhost:${APP_PORT}/actuator/health"

# Attend que l'application réponde {"status":"UP"} (60 s max, un essai toutes les 2 s)
wait_for_health() {
    local timeout=60 elapsed=0
    log_info "Health check sur $HEALTH_URL (timeout ${timeout}s)"
    while (( elapsed < timeout )); do
        if curl -fs "$HEALTH_URL" | grep -q '"status":"UP"'; then
            log_ok "Application opérationnelle après ${elapsed}s"
            return 0
        fi
        sleep 2
        elapsed=$(( elapsed + 2 ))
    done
    log_error "L'application ne répond pas après ${timeout}s — derniers logs du conteneur :"
    docker logs --tail 30 "$APP_NAME" 2>&1
    return 1
}

# Supprime le conteneur courant s'il existe (rm -f arrête puis supprime)
remove_container() {
    docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
}
