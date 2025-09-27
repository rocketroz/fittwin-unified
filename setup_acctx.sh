#!/usr/bin/env bash
# setup_acctx.sh — run from your repo root (bash/zsh)

# Script to consume multiple Codex accounts and handle git accordingly

set -euo pipefail

REPO_ROOT="$(pwd)"
CREDS_DIR="$HOME/.proj-creds"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "==> sanity checks"
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ Not inside a git repo"; exit 1
fi

echo "==> create tracked .codex/ (no secrets)"
mkdir -p .codex
if [ ! -f .codex/config.json ]; then
  cat > .codex/config.json <<'JSON'
{
  "project": "demo",
  "model": "gpt-5-codex",
  "endpoints": { "responses": "https://api.openai.com/v1/responses" },
  "auth": { "api_key_env": "OPENAI_API_KEY" },
  "limits": { "max_input_tokens": 32000, "max_output_tokens": 4000 },
  "retrieval": { "index": "rag.yaml" }
}
JSON
fi
[ -f .codex/rag.yaml ] || echo "# add file paths to include in retrieval context" > .codex/rag.yaml

echo "==> ignore only local envs; keep .codex tracked"
# keep secrets out of git; still branch-map creds via direnv/keychain
grep -qxF ".env.local" .gitignore 2>/dev/null || echo ".env.local" >> .gitignore
grep -qxF ".env.*.local" .gitignore 2>/dev/null || echo ".env.*.local" >> .gitignore

echo "==> optional shared (non-secret) env defaults"
if [ ! -f .env.shared ]; then
  cat > .env.shared <<'ENV'
# shared non-secret defaults (committed)
MODEL_OVERRIDES=gpt-5-codex
OPENAI_BASE_URL=https://api.openai.com/v1
LOG_LEVEL=info
ENV
  git add .env.shared >/dev/null 2>&1 || true
fi
if [ ! -f .env.example ]; then
  cat > .env.example <<'ENV'
# copy to ~/.proj-creds/acctX.env and fill values there; do not commit secrets
OPENAI_API_KEY=__SET_ME__
OPENAI_ORG_ID=__SET_ME__
CODEX_PROJECT_ID=__SET_ME__
ENV
fi

echo "==> create per-account creds folder outside repo: $CREDS_DIR"
mkdir -p "$CREDS_DIR"
for A in acct1 acct2 acct3 default; do
  [ -f "$CREDS_DIR/$A.env" ] || cat > "$CREDS_DIR/$A.env" <<ENV
# $A credentials (not in git)
# Fill and 'source $CREDS_DIR/$A.env' if not using direnv
export OPENAI_API_KEY="sk-REPLACE-$A"
export OPENAI_ORG_ID="org_REPLACE_$A"
export CODEX_PROJECT_ID="proj_REPLACE_$A"
ENV
done

echo "==> direnv setup (.envrc tracked; no secrets)"
if [ ! -f .envrc ]; then
  cat > .envrc <<'RC'
# Requires 'direnv' and its stdlib (dotenv)
source_env_if_exists() {
  [ -f "$1" ] && eval "$(direnv dotenv bash "$1")"
}
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
case "$branch" in
  acct1/*) source_env_if_exists "$HOME/.proj-creds/acct1.env" ;;
  acct2/*) source_env_if_exists "$HOME/.proj-creds/acct2.env" ;;
  acct3/*) source_env_if_exists "$HOME/.proj-creds/acct3.env" ;;
  *)       source_env_if_exists "$HOME/.proj-creds/default.env" ;;
esac
# Always load shared non-secrets if present
[ -f ./.env.shared ] && eval "$(direnv dotenv bash ./.env.shared)"
RC
fi

echo "==> git hook: post-checkout reminder (optional quality-of-life)"
mkdir -p "$HOOKS_DIR"
cat > "$HOOKS_DIR/post-checkout" <<'HOOK'
#!/usr/bin/env bash
b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
case "$b" in
  acct1/*) src="$HOME/.proj-creds/acct1.env" ;;
  acct2/*) src="$HOME/.proj-creds/acct2.env" ;;
  acct3/*) src="$HOME/.proj-creds/acct3.env" ;;
  *)       src="$HOME/.proj-creds/default.env" ;;
esac
[ -f "$src" ] && echo "[acctx] Branch '$b' → using $src (direnv will auto-load if enabled)."
HOOK
chmod +x "$HOOKS_DIR/post-checkout"

echo "==> git hook: pre-commit secret guard"
cat > "$HOOKS_DIR/pre-commit" <<'HOOK'
#!/usr/bin/env bash
if git diff --cached | grep -E 'sk-[A-Za-z0-9]|OPENAI_API_KEY|AWS_SECRET|GH_TOKEN' >/dev/null; then
  echo "❌ Secret-like token found in staged changes. Keep secrets outside git."
  exit 1
fi
HOOK
chmod +x "$HOOKS_DIR/pre-commit"

echo "==> optional Makefile targets (fast switch helpers)"
if [ ! -f Makefile ]; then
  cat > Makefile <<'MK'
acct1:
	@git switch -C acct1/$(or $(b),work) || git switch acct1/$(or $(b),work); echo "acct1/* branch active"
acct2:
	@git switch -C acct2/$(or $(b),work) || git switch acct2/$(or $(b),work); echo "acct2/* branch active"
acct3:
	@git switch -C acct3/$(or $(b),work) || git switch acct3/$(or $(b),work); echo "acct3/* branch active"
MK
fi

echo "==> done."

echo ""
echo "=== NEXT STEPS ==="
echo "1) Install direnv (once):   brew install direnv   && echo 'eval \"\$(direnv hook zsh)\"' >> ~/.zshrc"
echo "   Then in this repo:       direnv allow"
echo "2) Put real keys in:        $CREDS_DIR/acct1.env  (and acct2.env/acct3.env as needed)."
echo "3) Create/use branches:     git switch -c acct1/feature-x   # auto-loads acct1.env"
echo "                            git switch -c acct2/feature-y   # auto-loads acct2.env"
echo "4) Keep .codex/ per-branch: edit/commit .codex/* on each branch (no secrets inside)."
echo "5) Verify load:             echo \$OPENAI_API_KEY   # should reflect the branch’s env"
echo ""
echo "Tips:"
echo "- Use 'make acct1' or 'make acct2' to jump into namespaced branches."
echo "- Secrets stay out of git; .codex is tracked and will swap with branch."
