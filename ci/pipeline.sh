#!/usr/bin/env bash
# Orchestrateur de la pipeline CI/CD du service_entreprise.
# Lance chaque étape de ci/steps/ dans l'ordre et s'arrête au premier échec.
set -uo pipefail

source "$(dirname "$0")/lib/common.sh"

LOG_DIR="$CI_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/pipeline_$(date '+%Y%m%d_%H%M%S').log"

STEPS=(
    01_manifest.sh
    02_dependencies.sh
    03_compile.sh
    04_tests.sh
    05_package.sh
    06_deploy.sh
    06b_integration.sh
    06c_promote.sh
)

run_step() {
    local step="$1"
    local start=$SECONDS
    log_info "===== Début de l'étape $step ====="
    bash "$CI_DIR/steps/$step"
    local code=$?
    local duration=$(( SECONDS - start ))
    if (( code == 0 )); then
        log_ok "===== Étape $step réussie (${duration}s) ====="
    else
        log_error "===== Étape $step échouée avec le code $code (${duration}s) ====="
    fi
    return "$code"
}

main() {
    log_info "Démarrage de la pipeline — log : $LOG_FILE"
    local step
    for step in "${STEPS[@]}"; do
        run_step "$step" || {
            local code=$?
            log_error "Pipeline interrompue à l'étape $step"
            if [[ "$step" == 06* ]]; then
                log_warn "Déploiement en échec : lancement du rollback"
                run_step 07_rollback.sh || log_error "Rollback impossible : le service n'est plus disponible"
            fi
            return "$code"
        }
    done
    log_ok "Pipeline terminée avec succès"
}

# Tout ce que main affiche (stdout et stderr) va à la fois dans le terminal et dans le log
main 2>&1 | tee -a "$LOG_FILE"
exit "${PIPESTATUS[0]}"
