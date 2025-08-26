#!/usr/bin/env bash
set -euo pipefail

# Locations
STANDALONE="/opt/daa/env/standalone/spacemacs"
CONFIG_DIR="/opt/daa/env/spacemacs"
TARGET="$HOME/.emacs.d"
DOTSPACEMACS="$HOME/.spacemacs"

# Clone Spacemacs repo if missing
if [ ! -d "$STANDALONE" ]; then
  echo "Cloning Spacemacs into $STANDALONE ..."
  git clone https://github.com/syl20bnr/spacemacs.git "$STANDALONE"
else
  echo "Spacemacs repo already present at $STANDALONE"
fi

# Symlink ~/.emacs.d -> standalone repo
ln -sfn "$STANDALONE" "$TARGET"
echo "Linked $TARGET -> $STANDALONE"

# Symlink ~/.spacemacs -> personal config
if [ -f "$CONFIG_DIR/dotspacemacs.el" ]; then
  ln -sfn "$CONFIG_DIR/dotspacemacs.el" "$DOTSPACEMACS"
  echo "Linked $DOTSPACEMACS -> $CONFIG_DIR/dotspacemacs.el"
else
  echo "WARNING: No $CONFIG_DIR/dotspacemacs.el found"
  echo "         Spacemacs will generate a default on first run."
fi

echo "Spacemacs deployment complete. Run 'emacs' to start."

