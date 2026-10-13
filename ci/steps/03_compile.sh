#!/usr/bin/env bash
# Étape 03 — Compilation du code source
# Codes retour : 0 = OK, 1 = erreur de compilation, 2 = classes compilées absentes
set -u
source "$(dirname "$0")/../lib/common.sh"

# clean supprime target/ pour éviter de réutiliser d'anciennes classes compilées
if ! run_maven clean compile; then
    log_error "Erreur de compilation"
    exit 1
fi

if [[ ! -d "$SERVICE_DIR/target/classes" ]]; then
    log_error "Dossier target/classes absent après la compilation"
    exit 2
fi

log_ok "Compilation réussie"
exit 0
