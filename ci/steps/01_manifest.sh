#!/usr/bin/env bash
# Étape 01 — Vérification de l'état du projet et du manifeste (pom.xml)
# Codes retour : 0 = OK, 1 = fichier manquant, 2 = pom.xml invalide
set -u
source "$(dirname "$0")/../lib/common.sh"

log_info "Commit : $(git -C "$REPO_ROOT" rev-parse --short HEAD) sur la branche $(git -C "$REPO_ROOT" branch --show-current)"
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain -- "$SERVICE_DIR")" ]]; then
    log_warn "Modifications non commitées dans le service (le build ne correspond pas exactement au commit)"
fi

for f in pom.xml mvnw .mvn/wrapper/maven-wrapper.properties src/main/resources/application.properties; do
    if [[ ! -f "$SERVICE_DIR/$f" ]]; then
        log_error "Fichier manquant : $f"
        exit 1
    fi
done
log_info "Fichiers essentiels présents"

if ! run_maven validate; then
    log_error "Le pom.xml est invalide (mvn validate a échoué)"
    exit 2
fi

log_ok "Manifeste valide"
exit 0
