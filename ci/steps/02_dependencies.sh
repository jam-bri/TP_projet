#!/usr/bin/env bash
# Étape 02 — Résolution et téléchargement des dépendances Maven
# Codes retour : 0 = OK, 1 = échec de résolution des dépendances
set -u
source "$(dirname "$0")/../lib/common.sh"

# go-offline télécharge dans ~/.m2 toutes les dépendances et tous les plugins du projet.
# Un problème réseau ou une version introuvable est ainsi détecté ici, et non au milieu de la compilation.
if ! run_maven dependency:go-offline; then
    log_error "Impossible de résoudre les dépendances (réseau ou version introuvable ?)"
    exit 1
fi

log_ok "Dépendances résolues"
exit 0
