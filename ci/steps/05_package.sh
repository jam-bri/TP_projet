#!/usr/bin/env bash
# Étape 05 — Packaging de l'application en JAR exécutable
# Codes retour : 0 = OK, 1 = échec du packaging, 2 = JAR absent
set -u
source "$(dirname "$0")/../lib/common.sh"

# Les tests ont déjà été exécutés à l'étape 04 : on ne les relance pas
if ! run_maven package -DskipTests; then
    log_error "Échec du packaging"
    exit 1
fi

JAR_PATH="$SERVICE_DIR/target/$JAR_NAME"
if [[ ! -f "$JAR_PATH" ]]; then
    log_error "JAR introuvable : $JAR_PATH"
    exit 2
fi

log_ok "JAR produit : target/$JAR_NAME ($(du -h "$JAR_PATH" | cut -f1))"
exit 0
