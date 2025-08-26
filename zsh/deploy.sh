#!/usr/bin/env bash
set -euo pipefail

# --- config ---
CUSTOM_ZSHRC="/opt/daa/env/zsh/.zshrc"
OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
P10K_DIR="$ZSH_CUSTOM_DIR/themes/powerlevel10k"

MARK_START="# >>> daa custom zshrc >>>"
MARK_END="# <<< daa custom zshrc <<<"

ts() { date +"%Y-%m-%d %H:%M:%S"; }
log() { printf "%s  %s\n" "$(ts)" "$*"; }

log "=== deploy: oh-my-zsh + powerlevel10k + custom .zshrc ==="
log "HOME: $HOME"
log "CUSTOM_ZSHRC: $CUSTOM_ZSHRC"
log "OMZ_DIR: $OMZ_DIR"
log "ZSH_CUSTOM_DIR: $ZSH_CUSTOM_DIR"
log "P10K_DIR: $P10K_DIR"
log "SHELL: ${SHELL:-unknown}"

# 0) sanity
[ -f "$CUSTOM_ZSHRC" ] || { log "ERROR: missing $CUSTOM_ZSHRC"; exit 2; }

# 1) install oh-my-zsh via official script (unattended; don’t chsh; don’t auto-run zsh)
if [ ! -d "$OMZ_DIR" ]; then
  log "Installing Oh My Zsh (official installer)..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh already present at $OMZ_DIR (skipping install)"
fi

# 2) install powerlevel10k with the exact command you specified
if [ ! -d "$P10K_DIR/.git" ]; then
  log "Cloning Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  log "Powerlevel10k already present at $P10K_DIR (skipping clone)"
fi

# 3) append source of your repo .zshrc to ~/.zshrc (idempotent: replace managed block if exists)
MAIN_ZSHRC="$HOME/.zshrc"
log "Ensuring $MAIN_ZSHRC sources $CUSTOM_ZSHRC"

# Create ~/.zshrc if missing
[ -f "$MAIN_ZSHRC" ] || : > "$MAIN_ZSHRC"

# Strip any previous managed block
awk -v start="$MARK_START" -v end="$MARK_END" '
  BEGIN{skip=0}
  index($0, start){skip=1; next}
  index($0, end){skip=0; next}
  skip==0{print}
' "$MAIN_ZSHRC" > "${MAIN_ZSHRC}.tmp"
mv "${MAIN_ZSHRC}.tmp" "$MAIN_ZSHRC"

# Append fresh managed block
{
  echo
  echo "$MARK_START"
  echo "# Auto-added by /opt/daa/env/zsh/deploy.sh on $(ts)"
  echo "if [ -r \"$CUSTOM_ZSHRC\" ]; then"
  echo "  source \"$CUSTOM_ZSHRC\""
  echo "fi"
  echo "$MARK_END"
} >> "$MAIN_ZSHRC"

log "Appended managed block to $MAIN_ZSHRC"

# 4) summary / debug
log "----- SUMMARY -----"
log "Oh My Zsh:  $OMZ_DIR  $([ -f \"$OMZ_DIR/oh-my-zsh.sh\" ] && echo '[OK]' || echo '[MISSING]')"
log "P10k theme: $P10K_DIR  $([ -f \"$P10K_DIR/powerlevel10k.zsh-theme\" ] && echo '[OK]' || echo '[MISSING]')"
log "Custom rc:  $CUSTOM_ZSHRC  $([ -f \"$CUSTOM_ZSHRC\" ] && echo '[OK]' || echo '[MISSING]')"
log "Main rc:    $MAIN_ZSHRC"
log "Tail of $MAIN_ZSHRC:"
tail -n 20 "$MAIN_ZSHRC" | sed 's/^/  /'

chsh -s $(which zsh)

log "=== Done. Open a new terminal (or run: exec zsh) ==="
