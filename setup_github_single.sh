#!/usr/bin/env bash
set -euo pipefail

echo "=== Git & GitHub single-account setup ==="

# Detect OS
UNAME_OUT="$(uname -s)"
case "${UNAME_OUT}" in
    Darwin*) OS="macos" ;;
    Linux*)  OS="linux" ;;
    *)       OS="other" ;;
esac

# --- Git identity ---
read -rp "Git user name (e.g. Your Name): " GIT_NAME
read -rp "Git email (e.g. you@example.com): " GIT_EMAIL

read -rp "Default git branch name [main]: " GIT_BRANCH
GIT_BRANCH=${GIT_BRANCH:-main}

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch "$GIT_BRANCH"

echo "Configured git user.name, user.email, and init.defaultBranch."

# Optional: some sensible defaults
git config --global pull.rebase false
git config --global push.default simple
git config --global color.ui auto

# --- SSH key for GitHub ---
mkdir -p "$HOME/.ssh"
DEFAULT_KEY="$HOME/.ssh/id_ed25519"

echo
echo "SSH key setup for GitHub"
echo "Default key path: $DEFAULT_KEY"

read -rp "Generate a new SSH key at this path if it doesn't exist? [Y/n]: " GEN_KEY
GEN_KEY=${GEN_KEY:-Y}

if [[ "$GEN_KEY" =~ ^[Yy]$ ]]; then
  if [[ -f "$DEFAULT_KEY" ]]; then
    echo "Key $DEFAULT_KEY already exists."
    read -rp "Overwrite it with a new key? [y/N]: " OVERWRITE
    OVERWRITE=${OVERWRITE:-N}
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
      ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$DEFAULT_KEY"
    else
      echo "Keeping existing key."
    fi
  else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$DEFAULT_KEY"
  fi
else
  echo "Skipping key generation."
fi

# --- ssh-agent & config ---
echo
echo "Configuring ssh-agent and ~/.ssh/config for GitHub..."

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi

# Try adding key (ignore failures if key not present)
if [[ -f "$DEFAULT_KEY" ]]; then
  ssh-add "$DEFAULT_KEY" || true
fi

SSH_CONFIG="$HOME/.ssh/config"
touch "$SSH_CONFIG"

if ! grep -qE '^Host github\.com(\s|$)' "$SSH_CONFIG"; then
  {
    echo ""
    echo "Host github.com"
    echo "  HostName github.com"
    echo "  User git"
    echo "  IdentityFile $DEFAULT_KEY"
    echo "  IdentitiesOnly yes"
    echo "  AddKeysToAgent yes"
  } >> "$SSH_CONFIG"

  if [[ "$OS" == "macos" ]]; then
    # macOS-specific option to store passphrase in keychain
    {
      echo "  UseKeychain yes"
    } >> "$SSH_CONFIG"
  fi

  echo "Added github.com entry to $SSH_CONFIG"
else
  echo "github.com already configured in $SSH_CONFIG; left as-is."
fi

# --- Git credential helper (optional) ---
if [[ "$OS" == "macos" ]]; then
  if command -v git-credential-osxkeychain >/dev/null 2>&1; then
    git config --global credential.helper osxkeychain
    echo "Configured git credential.helper=osxkeychain for macOS."
  fi
fi

# --- Optional: authenticate via GitHub CLI if available ---
if command -v gh >/dev/null 2>&1; then
  echo
  read -rp "Run 'gh auth login' now to authorize GitHub via browser? [y/N]: " DO_GH
  DO_GH=${DO_GH:-N}
  if [[ "$DO_GH" =~ ^[Yy]$ ]]; then
    gh auth login
  else
    echo "Skipping gh auth login."
  fi
else
  echo
  echo "GitHub CLI ('gh') not found; skipping GitHub CLI auth."
fi

# --- Final info ---
if [[ -f "$DEFAULT_KEY.pub" ]]; then
  echo
  echo "Your SSH public key (add this to GitHub > Settings > SSH and GPG keys):"
  echo "---------------------------------------------------------------------"
  cat "$DEFAULT_KEY.pub"
  echo "---------------------------------------------------------------------"
else
  echo
  echo "No public key found at $DEFAULT_KEY.pub."
  echo "If you generated a key with a different path, add its .pub to GitHub."
fi

echo
echo "Single-account Git & GitHub setup complete."