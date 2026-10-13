"""Serveur de webhook GitHub : lance la pipeline CI/CD à chaque push sur la branche surveillée.

Variables d'environnement :
  WEBHOOK_SECRET   secret partagé avec GitHub pour signer les requêtes
  WEBHOOK_BRANCH   branche surveillée ( final_code)
  WEBHOOK_PORT     port d'écoute local (9000)
  WEBHOOK_WORKDIR  clone dédié dans lequel la pipeline est exécutée (défaut : ../TP_projet_ci)
"""
import hashlib
import hmac
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

CI_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = CI_DIR.parent
SECRET = os.environ.get("WEBHOOK_SECRET", "").encode()
BRANCH = os.environ.get("WEBHOOK_BRANCH", "final_code")
PORT = int(os.environ.get("WEBHOOK_PORT", "9000"))
WORKDIR = Path(os.environ.get("WEBHOOK_WORKDIR", REPO_ROOT.parent / "TP_projet_ci"))

(CI_DIR / "logs").mkdir(exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)-5s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.FileHandler(CI_DIR / "logs" / "webhook.log", encoding="utf-8"),
              logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("webhook")

# Une seule pipeline à la fois : deux exécutions se disputeraient le conteneur et le port 8081
pipeline_lock = threading.Lock()

"""GitHub signe le corps de la requête avec HMAC-SHA256 et le secret partagé."""
def signature_valide(body: bytes, header: str) -> bool:
    attendu = "sha256=" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()
    # compare_digest : comparaison en temps constant, pour ne pas laisser deviner la signature
    return hmac.compare_digest(attendu, header)


def git(*args: str) -> None:
    subprocess.run(["git", *args], check=True)


def run_pipeline(sha: str) -> None:
    try:
        if not WORKDIR.exists():
            origin = subprocess.run(["git", "-C", str(REPO_ROOT), "remote", "get-url", "origin"],
                                    check=True, capture_output=True, text=True).stdout.strip()
            log.info("Clone de %s dans %s", origin, WORKDIR)
            git("clone", origin, str(WORKDIR))
        git("-C", str(WORKDIR), "fetch", "origin")
        git("-C", str(WORKDIR), "checkout", "--force", sha)

        log.info("Pipeline lancée pour %s (logs dans %s)", sha[:7], WORKDIR / "ci" / "logs")
        code = subprocess.run([shutil.which("bash") or "bash", "ci/pipeline.sh"], cwd=WORKDIR).returncode
        if code == 0:
            log.info("Pipeline %s : SUCCÈS", sha[:7])
        else:
            log.error("Pipeline %s : ÉCHEC (code %d)", sha[:7], code)
    except subprocess.CalledProcessError as e:
        log.error("Préparation du clone impossible : %s", e)
    finally:
        pipeline_lock.release()


class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/webhook":
            return self.reply(404, "Chemin inconnu")

        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if not signature_valide(body, self.headers.get("X-Hub-Signature-256", "")):
            log.warning("Signature invalide : requête rejetée")
            return self.reply(401, "Signature invalide")

        event = self.headers.get("X-GitHub-Event", "")
        if event == "ping":
            return self.reply(200, "pong")
        if event != "push":
            return self.reply(202, f"Événement {event} ignoré")

        payload = json.loads(body)
        ref, sha = payload.get("ref", ""), payload.get("after", "")
        if ref != f"refs/heads/{BRANCH}" or payload.get("deleted"):
            return self.reply(202, f"Push sur {ref} ignoré")
        # Le SHA est passé à git : on n'accepte qu'un hash valide (40 caractères hexadécimaux)
        if not re.fullmatch(r"[0-9a-f]{40}", sha):
            return self.reply(400, "Commit invalide")

        if not pipeline_lock.acquire(blocking=False):
            return self.reply(409, "Une pipeline est déjà en cours")
        # GitHub abandonne après 10 s : on répond tout de suite et la pipeline tourne en arrière-plan
        threading.Thread(target=run_pipeline, args=(sha,), daemon=True).start()
        self.reply(202, f"Pipeline lancée pour {sha[:7]}")

    def reply(self, code: int, message: str) -> None:
        log.info("%s %s -> %d %s", self.headers.get("X-GitHub-Event", "-"), self.path, code, message)
        data = message.encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass  # le log HTTP par défaut est remplacé par reply()


if __name__ == "__main__":
    if not SECRET:
        log.error("WEBHOOK_SECRET n'est pas défini : refus de démarrer sans vérification de signature")
        sys.exit(1)
    # 127.0.0.1 : seul le tunnel cloudflared (local) peut joindre le serveur, pas le réseau Wi-Fi
    server = ThreadingHTTPServer(("127.0.0.1", PORT), WebhookHandler)
    log.info("Écoute sur http://127.0.0.1:%d/webhook (branche %s, clone %s)", PORT, BRANCH, WORKDIR)
    server.serve_forever()
