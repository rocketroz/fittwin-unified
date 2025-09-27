#!/bin/zsh

# 1) Track the portable, branch-owned config
mkdir -p .codex
cat > .codex/config.json <<'JSON'
{ "model":"gpt-5-codex", "auth":{"api_key_env":"OPENAI_API_KEY"},
  "retrieval":{"index":"rag.yaml"}, "limits":{"max_input_tokens":32000,"max_output_tokens":4000} }
JSON
[ -f .codex/rag.yaml ] || echo "# tracked RAG spec (no secrets)" > .codex/rag.yaml
git add .codex && git commit -m "track branch-scoped .codex (no secrets)"

# 2) Local overlay (ignored)
mkdir -p .codex.local
echo ".codex.local/" >> .git/info/exclude
cat > .codex.local/README.txt <<'TXT'
Put machine/account-specific bits here (paths, caches). Never commit.
Examples: .codex.local/paths.yaml, .codex.local/plugins.json
TXT

# 3) Direnv to load creds + merge overlay (no secrets committed)
cat > .envrc <<'RC'
source_env_if_exists() { [ -f "$1" ] && eval "$(direnv dotenv bash "$1")"; }
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"

# Per-branch creds outside git (adjust paths if you use ~/.proj-creds or ./.creds)
case "$branch" in
  acct1/*) source_env_if_exists "$HOME/.proj-creds/acct1.env" ;;
  acct2/*) source_env_if_exists "$HOME/.proj-creds/acct2.env" ;;
  acct3/*) source_env_if_exists "$HOME/.proj-creds/acct3.env" ;;
  *)       source_env_if_exists "$HOME/.proj-creds/default.env" ;;
esac

# Make overlay paths visible to your tooling (if it supports it)
export CODEX_OVERLAY_DIR="$PWD/.codex.local"
[ -f ./.env.shared ] && eval "$(direnv dotenv bash ./.env.shared)"
RC
direnv allow

# 4) (Optional) post-checkout nudge so you remember which creds/overlay are active
cat > .git/hooks/post-checkout <<'HOOK'
#!/usr/bin/env bash
b=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
echo "[codex] Branch '$b' → using overlay: .codex.local (if present)."
HOOK
chmod +x .git/hooks/post-checkout

# 5) Secret guard
cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
if git diff --cached | grep -E 'sk-[A-Za-z0-9]|OPENAI_API_KEY|AWS_SECRET|GH_TOKEN' >/dev/null; then
  echo "❌ Secret-like token found in staged changes. Keep secrets out of git."; exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit
