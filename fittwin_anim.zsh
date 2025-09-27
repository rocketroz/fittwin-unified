#!/usr/bin/env zsh
set -euo pipefail

cls() { printf "\033[2J\033[H"; }
hide() { printf "\033[?25l"; }
show() { printf "\033[?25h"; }
sleepf(){ perl -e "select(undef,undef,undef,$SLEEP)" 2>/dev/null || sleep "${SLEEP:-0.06}"; }
big(){ figlet -w 120 -f standard -- "$*"; }

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

  # zsh-native: read files into arrays (one line per element)
  typeset -a A B
  A=("${(@f)$(< "$tmpa.p")}")
  B=("${(@f)$(< "$tmpb.p")}")

  for ((s=0; s<=steps; s++)); do
    cls; hide
    for ((i=1; i<=${#A}; i++)); do
      local lineA="${A[i]}" lineB="${B[i]}" out=""
      local len=${#lineA}
      for ((j=0; j<len; j++)); do
        local ca="${lineA:j:1}" cb="${lineB:j:1}"
        if [[ "$ca" == "$cb" ]]; then
          out+="$ca"
        else
          local thresh=$(( (s*100)/steps ))
          local r=$(( RANDOM % 100 ))
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
  for ((step=0; step<=steps; step++)); do
    local deg=$(( (step*maxdeg)/steps ))
    local idx=$(( deg<1 ? 1 : (deg>55 ? 55 : deg)+1 ))
    local pad=$(( SIN[idx] / 3 ))
    cls; hide
    local scale=$(( 120 - (pad*2) ))
    figlet -w $(( scale < 40 ? 40 : scale )) -f standard -- "$text" \
      | sed "s/^/$(printf '%*s' $pad)/"
    sleepf
  done
  for ((step=steps; step>=0; step--)); do
    local deg=$(( (step*maxdeg)/steps ))
    local idx=$(( deg<1 ? 1 : (deg>55 ? 55 : deg)+1 ))
    local pad=$(( SIN[idx] / 3 ))
    cls; hide
    local scale=$(( 120 - (pad*2) ))
    figlet -w $(( scale < 40 ? 40 : scale )) -f standard -- "$text" \
      | sed "s/^/$(printf '%*s' $pad)/"
    sleepf
  done
  show
}

main() {
  : ${SLEEP:=0.06}
  local A B
  A="$(mktemp)"; B="$(mktemp)"
  big "FIT"  > "$A"
  big "TWIN" > "$B"
  morph_frames "$A" "$B" 24
  yaw_frames "TWIN" 55 28
  printf "\n"; sleep 0.8; show
}
main "$@"
