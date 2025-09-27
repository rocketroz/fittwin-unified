#!/usr/bin/env zsh
# macOS: install Asciiville (Darwin .tgz + Install-bin.sh), then run a "FitTwin" ASCII morph+3D-yaw animation.
set -euo pipefail

APP_NAME="Asciiville"
REPO="doctorfree/Asciiville"
ANIM_DIR="${HOME}/.local/share/fittwin"
ANIM_NAME="fittwin_anim.zsh"
ANIM_PATH="${ANIM_DIR}/${ANIM_NAME}"
SLEEP="${SLEEP:-0.06}"

need() { command -v "$1" >/dev/null 2>&1; }
log()  { printf "\033[1;36m%s\033[0m\n" "$*"; }
warn() { printf "\033[1;33m%s\033[0m\n" "$*"; }
err()  { printf "\033[1;31m%s\033[0m\n" "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || err "This script targets macOS (Darwin)."

ensure_brew_and_figlet() {
  if ! need brew; then
    log "Installing Homebrew…"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -d "/opt/homebrew/bin" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      grep -q 'brew shellenv' "${ZDOTDIR:-$HOME}/.zprofile" 2>/dev/null || \
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${ZDOTDIR:-$HOME}/.zprofile"
    fi
  else
    # shellcheck disable=SC2046
    eval "$($(brew --prefix)/bin/brew shellenv 2>/dev/null || true)"
  fi
  brew list figlet &>/dev/null || brew install figlet
}

install_asciiville() {
  log "Installing ${APP_NAME} on macOS (Darwin .tgz + Install-bin.sh)…"

  local api tgz_url install_url tmp headers
  api="https://api.github.com/repos/${REPO}/releases"
  headers=(-H "Accept: application/vnd.github+json")
  [[ -n "${GITHUB_TOKEN:-}" ]] && headers+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

  log "Querying GitHub releases API… (set GITHUB_TOKEN to avoid rate limits)"
  local urls
  urls="$(curl -fsSL "${headers[@]}" "$api" \
    | grep -Eo '"browser_download_url":\s*"[^"]+"' \
    | awk -F\" '{print $4}')" || err "GitHub API unreachable."

  tgz_url="$(printf "%s\n" "$urls" | grep -Ei 'Asciiville_.*Darwin.*\.tgz$' | head -n1)"
  install_url="$(printf "%s\n" "$urls" | grep -E 'Install-bin\.sh$' | head -n1)"

  if [[ -z "${install_url:-}" ]]; then
    install_url="https://raw.githubusercontent.com/${REPO}/main/Install-bin.sh"
    log "Using Install-bin.sh from main branch."
  fi

  if [[ -z "${tgz_url:-}" ]]; then
    warn "Could not find Darwin .tgz via API; scraping public releases page…"
    local page
    page="$(curl -fsSL "https://github.com/${REPO}/releases")" || err "Cannot load releases page."
    tgz_url="$(printf "%s" "$page" | grep -Eo 'https://[^"]+Asciiville_[^"]+Darwin[^"]+\.tgz' | head -n1)"
  fi

  [[ -n "${tgz_url:-}" ]] || err "Still cannot locate a Darwin .tgz in releases."
  [[ -n "${install_url:-}" ]] || err "Still cannot locate Install-bin.sh."

  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

  log "Downloading assets:"
  tgz_name="$(basename "$tgz_url")"
  log " - ${tgz_name}"
  log " - $(basename "$install_url")"

  curl -fL "$tgz_url" -o "$tmp/${tgz_name}"
  curl -fL "$install_url" -o "$tmp/Install-bin.sh"
  chmod 755 "$tmp/Install-bin.sh"

  log "Running Install-bin.sh (sudo)…"
  sudo "$tmp/Install-bin.sh" "$tmp/${tgz_name}"

  need ascinit || err "ascinit not found after install."
  log "Initializing (ascinit)…"
  # Run as user (not sudo) per project guidance
  ascinit || warn "ascinit returned non-zero; proceeding."
}

write_animation() {
  mkdir -p "$ANIM_DIR"
  cat > "$ANIM_PATH" <<'EOF'
#!/usr/bin/env zsh
set -euo pipefail

cls() { printf "\033[2J\033[H"; }
hide() { printf "\033[?25l"; }
show() { printf "\033[?25h"; }
sleepf() { perl -e "select(undef,undef,undef,$SLEEP)" 2>/dev/null || sleep "${SLEEP:-0.06}"; }

big() { figlet -w 120 -f standard -- "$*"; }

pad_to_box() {
  awk -v H="$1" -v W="$2" '{
    l[NR]=$0; if (length($0)>max) max=length($0)
  } END {
    w=(W>max?W:max); h=(H>NR?H:NR);
    for(i=1;i<=h;i++){
      s=l[i]; if (s=="") s="";
      printf("%-*s\n", w, s);
    }
  }'
}

morph_frames() {
  local a="$1" b="$2" steps="$3"
  local tmpa tmpb
  tmpa="$(mktemp)"; tmpb="$(mktemp)"
  cp "$a" "$tmpa"; cp "$b" "$tmpb"

  local H W
  H="$(wc -l < "$tmpa" | tr -d ' ')"
  W="$(awk '{if (length($0)>m) m=length($0)} END{print m+0}' "$tmpa")"
  <"$tmpa" pad_to_box "$H" "$W" >"$tmpa.p"
  <"$tmpb" pad_to_box "$H" "$W" >"$tmpb.p"

  mapfile -t A < "$tmpa.p"
  mapfile -t B < "$tmpb.p"

  for s in $(seq 0 "$steps"); do
    cls; hide
    for i in $(seq 1 ${#A[@]}); do
      ai="$((i-1))"
      lineA="${A[$ai]}"
      lineB="${B[$ai]}"
      out=""
      for j in $(seq 1 ${#lineA}); do
        aj="$((j-1))"
        ca="${lineA:$aj:1}"
        cb="${lineB:$aj:1}"
        if [[ "$ca" == "$cb" ]]; then
          out+="$ca"
        else
          thresh=$(( (s*100)/steps ))
          r=$(( RANDOM % 100 ))
          if (( r < thresh )); then out+="$cb"; else out+="$ca"; fi
        fi
      done
      printf "%s\n" "$out"
    done
    sleepf
  done
  rm -f "$tmpa" "$tmpb" "$tmpa.p" "$tmpb.p"
  show
}

yaw_frames() {
  local text="$1" maxdeg="$2" steps="$3"
  typeset -a SIN
  SIN=(0 2 3 5 7 9 10 12 14 16 17 19 21 22 24 26 27 29 31 32 34 36 37 39 41 42 44 45 47 49 50 52 53 55 57 58 60 62 63 65 66 68 70 71 73 74 76 78 79 81 82 84 86 87 89 90)
  for step in $(seq 0 "$steps"); do
    deg=$(( (step*maxdeg)/steps ))
    pad=$(( SIN[deg<1?1:(deg>55?55:deg)+1] / 3 ))
    cls; hide
    scale=$(( 120 - (pad*2) ))
    figlet -w $(( scale < 40 ? 40 : scale )) -f standard -- "$text" \
      | sed "s/^/$(printf '%*s' $pad)/"
    sleepf
  done
  for step in $(seq "$steps" -1 0); do
    deg=$(( (step*maxdeg)/steps ))
    pad=$(( SIN[deg<1?1:(deg>55?55:deg)+1] / 3 ))
    cls; hide
    scale=$(( 120 - (pad*2) ))
    figlet -w $(( scale < 40 ? 40 : scale )) -f standard -- "$text" \
      | sed "s/^/$(printf '%*s' $pad)/"
    sleepf
  done
  show
}

main() {
  : ${SLEEP:=0.06}
  local tmpA tmpB
  tmpA="$(mktemp)"; tmpB="$(mktemp)"
  big "FIT"  > "$tmpA"
  big "TWIN" > "$tmpB"
  morph_frames "$tmpA" "$tmpB" 24
  yaw_frames "TWIN" 55 28
  printf "\n"; sleep 0.8; show
}
main "$@"
EOF
  chmod +x "$ANIM_PATH"
}

run_anim() {
  log "Running FitTwin animation…"
  export SLEEP
  zsh "$ANIM_PATH"
}

# ---- main ----
[[ "${1:-}" == "--help" ]] && { echo "Usage: $0 [--run] [--no-install]"; exit 0; }

if [[ "${1:-}" != "--no-install" ]]; then
  install_asciiville
fi
ensure_brew_and_figlet
write_animation
log "FitTwin animation created at: $ANIM_PATH"
[[ "${1:-}" == "--run" ]] && run_anim || log "Run it anytime with: zsh \"$ANIM_PATH\""
