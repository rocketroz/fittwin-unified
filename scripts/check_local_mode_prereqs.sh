#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PASS_ICON="[OK]"
FAIL_ICON="[ERR]"
WARN_ICON="[WARN]"
EXIT_CODE=0
AUTO_INSTALL=0
HAS_BREW=0

usage() {
  cat <<'EOF'
Usage: scripts/check_local_mode_prereqs.sh [--install]

Checks FitTwin local-mode prerequisites.
  --install   Attempt to install/boot missing dependencies (Homebrew/macOS).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      AUTO_INSTALL=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if command -v brew >/dev/null 2>&1; then
  HAS_BREW=1
fi

auto_install_package() {
  local install_cmd="$1"
  local label="$2"
  if (( ! AUTO_INSTALL )); then
    return 1
  fi
  if (( HAS_BREW == 0 )); then
    echo "$FAIL_ICON Cannot auto-install $label because Homebrew is missing."
    EXIT_CODE=1
    return 1
  fi
  echo "$WARN_ICON Installing $label via: $install_cmd"
  if ! eval "$install_cmd"; then
    echo "$FAIL_ICON Auto-install failed for $label. Install manually and rerun."
    EXIT_CODE=1
    return 1
  fi
  return 0
}

require_cmd() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$FAIL_ICON missing '$cmd'. Install via: $hint"
    EXIT_CODE=1
    return 1
  fi
  return 0
}

require_cmd_auto() {
  local cmd="$1"
  local install_cmd="$2"
  local label="${3:-$cmd}"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  echo "$WARN_ICON missing '$cmd'."
  if auto_install_package "$install_cmd" "$label"; then
    if command -v "$cmd" >/dev/null 2>&1; then
      return 0
    fi
  fi
  echo "$FAIL_ICON Install '$label' manually via: $install_cmd"
  EXIT_CODE=1
  return 1
}

check_node() {
  if ! require_cmd node "https://nodejs.org/ (use nvm or fnm for Node 20.x)"; then
    return
  fi
  local version
  version="$(node -v | tr -d 'v')"
  local major="${version%%.*}"
  if (( major < 20 )); then
    echo "$FAIL_ICON Node $version detected. Install Node >= 20.11 (Next.js 14 requirement)."
    EXIT_CODE=1
  else
    echo "$PASS_ICON Node $(node -v)"
  fi
}

check_npm() {
  if ! require_cmd npm "bundled with Node; reinstall Node 20.x"; then
    return
  fi
  local version
  version="$(npm -v)"
  local major="${version%%.*}"
  if (( major < 10 )); then
    echo "$FAIL_ICON npm $version detected. Upgrade to npm >= 10 (bundled with Node 20)."
    EXIT_CODE=1
  else
    echo "$PASS_ICON npm $version"
  fi
}

check_direnv() {
  if ! require_cmd_auto direnv "brew install direnv" "direnv"; then
    return
  fi
  if direnv status | grep -q "Found RC allowed"; then
    echo "$PASS_ICON direnv configured (allow file detected)."
  else
    echo "$WARN_ICON direnv installed but '.envrc' not allowed yet. Run: direnv allow ."
  fi
}

ensure_libpq_tools() {
  if command -v pg_isready >/dev/null 2>&1 && command -v psql >/dev/null 2>&1; then
    return
  fi
  echo "$WARN_ICON libpq CLI tools missing."
  if auto_install_package "brew install libpq && brew link --force libpq" "libpq tools"; then
    return
  fi
  echo "$FAIL_ICON Install libpq manually: brew install libpq && brew link --force libpq"
  EXIT_CODE=1
}

check_helper_tools() {
  require_cmd_auto lsof "brew install lsof" "lsof"
  require_cmd pkill "preinstalled on macOS (procps on Linux)."
  ensure_libpq_tools
}

check_docker() {
  local require_docker="${START_DOCKER:-1}"
  if [[ "$require_docker" == "0" ]]; then
    echo "$WARN_ICON START_DOCKER=0, skipping Docker check."
    return
  fi
  if ! command -v docker >/dev/null 2>&1; then
    auto_install_package "brew install --cask docker" "Docker Desktop" || true
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "$FAIL_ICON docker CLI missing. Install Docker Desktop (brew install --cask docker)."
    EXIT_CODE=1
    return
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "$WARN_ICON docker installed but daemon not running."
    if (( AUTO_INSTALL )); then
      open -a Docker >/dev/null 2>&1 || true
      sleep 5
    fi
    if ! docker info >/dev/null 2>&1; then
      echo "$FAIL_ICON Start Docker Desktop, then rerun."
      EXIT_CODE=1
      return
    fi
  fi
  echo "$PASS_ICON docker daemon reachable."
}

check_postgres_port() {
  local port="${POSTGRES_PORT:-54322}"
  if pg_isready -q -h "${POSTGRES_HOST:-localhost}" -p "$port" >/dev/null 2>&1; then
    echo "$PASS_ICON Postgres reachable on port $port."
    return
  fi

  echo "$WARN_ICON No Postgres accepting connections on port $port."
  if (( AUTO_INSTALL )); then
    echo "$WARN_ICON Bootstrapping Postgres via scripts/setup_postgres_test_db.sh..."
    if START_DOCKER="${START_DOCKER:-1}" ./scripts/setup_postgres_test_db.sh; then
      if pg_isready -q -h "${POSTGRES_HOST:-localhost}" -p "$port" >/dev/null 2>&1; then
        echo "$PASS_ICON Local Postgres container initialized."
        return
      fi
    fi
    echo "$FAIL_ICON Automatic Postgres bootstrap failed. Start your own database and rerun."
    EXIT_CODE=1
  else
    echo "$WARN_ICON Run 'START_DOCKER=1 ./scripts/setup_postgres_test_db.sh' or point DATABASE_URL at an existing instance."
    EXIT_CODE=1
  fi
}

echo "=== FitTwin local-mode prerequisite check ==="
check_node
check_npm
check_direnv
check_helper_tools
check_docker
check_postgres_port

if (( EXIT_CODE == 0 )); then
  echo
  echo "$PASS_ICON All required tools are present. You can run:"
  cat <<'EOF'
  direnv allow .
  npm install
  START_DOCKER=1 ./scripts/setup_postgres_test_db.sh   # or START_DOCKER=0 if you already run Postgres
  export DATABASE_MODE=local
  npm run dev:stack
EOF
else
  echo
  if (( AUTO_INSTALL )); then
    echo "$FAIL_ICON Missing prerequisites remain after attempted fixes. Resolve the errors above and rerun."
  else
    echo "$FAIL_ICON Missing prerequisites detected. Install the tools above or rerun with '--install' to auto-fix."
  fi
fi

exit "$EXIT_CODE"
