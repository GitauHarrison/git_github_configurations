#!/usr/bin/env bash
set -euo pipefail

echo "=== Git & GitHub multi-account setup ==="

# Detect OS
UNAME_OUT="$(uname -s)"
case "${UNAME_OUT}" in
    Darwin*) OS="macos" ;;
    Linux*)  OS="linux" ;;
    *)       OS="other" ;;
esac

mkdir -p "$HOME/.ssh"
SSH_CONFIG="$HOME/.ssh/config"
touch "$SSH_CONFIG"

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi

read -rp "How many GitHub accounts do you want to configure? " ACCOUNT_COUNT

if ! [[ "$ACCOUNT_COUNT" =~ ^[0-9]+$ ]] || [[ "$ACCOUNT_COUNT" -le 0 ]]; then
  echo "Please enter a positive integer."
  exit 1
fi

for ((i=1; i<=ACCOUNT_COUNT; i++)); do
  echo
  echo "=== Account #$i ==="

  read -rp "Short account label (e.g. personal, work): " LABEL
  LABEL="${LABEL// /-}"  # replace spaces with dashes

  read -rp "Git user name for '$LABEL' (e.g. Your Name): " GIT_NAME
  read -rp "Git email for '$LABEL' (e.g. you+${LABEL}@example.com): " GIT_EMAIL

  # Where repos for this account live (for includeIf)
  read -rp "Base directory where '$LABEL' repos will live (e.g. \$HOME/work): " BASE_DIR
  # Expand leading ~ if present.
  BASE_DIR="${BASE_DIR/#\~/$HOME}"

  # SSH key path
  DEFAULT_KEY="$HOME/.ssh/id_ed25519_${LABEL}"
  read -rp "SSH key path for '$LABEL' [$DEFAULT_KEY]: " KEY_PATH
  KEY_PATH=${KEY_PATH:-$DEFAULT_KEY}

  # Generate key if missing
  if [[ -f "$KEY_PATH" ]]; then
    echo "SSH key $KEY_PATH already exists; not overwriting."
  else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH"
  fi

  # Add to ssh-agent (ignore errors)
  ssh-add "$KEY_PATH" || true

  # SSH host alias
  HOST_ALIAS="github-${LABEL}"

  if ! grep -qE "^Host ${HOST_ALIAS}(\s|\$)" "$SSH_CONFIG"; then
    {
      echo ""
      echo "Host ${HOST_ALIAS}"
      echo "  HostName github.com"
      echo "  User git"
      echo "  IdentityFile ${KEY_PATH}"
      echo "  IdentitiesOnly yes"
      echo "  AddKeysToAgent yes"
    } >> "$SSH_CONFIG"

    if [[ "$OS" == "macos" ]]; then
      {
        echo "  UseKeychain yes"
      } >> "$SSH_CONFIG"
    fi

    echo "Added Host '${HOST_ALIAS}' to $SSH_CONFIG"
  else
    echo "Host '${HOST_ALIAS}' already exists in $SSH_CONFIG; left as-is."
  fi

  # Per-account gitconfig
  ACCOUNT_GITCONFIG="$HOME/.gitconfig-${LABEL}"

  cat > "$ACCOUNT_GITCONFIG" <<EOF
[user]
  name = ${GIT_NAME}
  email = ${GIT_EMAIL}
EOF

  echo "Wrote per-account gitconfig: $ACCOUNT_GITCONFIG"

  # includeIf for this account in main ~/.gitconfig
  GITCONFIG_MAIN="$HOME/.gitconfig"
  touch "$GITCONFIG_MAIN"

  if ! grep -q "gitdir:${BASE_DIR}/" "$GITCONFIG_MAIN"; then
    {
      echo ""
      echo "[includeIf \"gitdir:${BASE_DIR}/\"]"
      echo "  path = ${ACCOUNT_GITCONFIG}"
    } >> "$GITCONFIG_MAIN"

    echo "Added includeIf for '$LABEL' repos under ${BASE_DIR}/ to $GITCONFIG_MAIN"
  else
    echo "An includeIf for gitdir:${BASE_DIR}/ already exists in $GITCONFIG_MAIN; left as-is."
  fi

  # Show public key so user can add it to the right GitHub account
  if [[ -f "${KEY_PATH}.pub" ]]; then
    echo
    echo "Public SSH key for account '$LABEL' (add to the matching GitHub account):"
    echo "---------------------------------------------------------------------"
    cat "${KEY_PATH}.pub"
    echo "---------------------------------------------------------------------"
  else
    echo "No public key found at ${KEY_PATH}.pub"
  fi

  echo
  echo "For account '$LABEL':"
  echo "  - Place its repos under: ${BASE_DIR}/"
  echo "  - Clone using: git clone git@${HOST_ALIAS}:<owner>/<repo>.git"
done

echo
echo "Multi-account Git & GitHub setup complete."
echo "Remember to add each public key to its corresponding GitHub account."