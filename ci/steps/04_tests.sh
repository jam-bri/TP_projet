#!/usr/bin/env bash
# Étape 04 — Exécution des tests unitaires
# Codes retour : 0 = OK, 1 = au moins un test en échec
set -u
source "$(dirname "$0")/../lib/common.sh"

if ! run_maven test; then
    log_error "Des tests ont échoué — détails dans target/surefire-reports/"
    exit 1
fi

log_ok "Tous les tests passent"
exit 0
