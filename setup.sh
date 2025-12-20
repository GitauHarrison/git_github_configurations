#!/usr/bin/env bash
set -euo pipefail

echo "=== Git & GitHub configuration helper ==="
echo
echo "This script will run one of the setup scripts in this repo."
echo
echo "1) Configure a SINGLE GitHub account on this machine"
echo "2) Configure MULTIPLE GitHub accounts on this machine"
echo

read -rp "Choose 1 or 2 [1]: " CHOICE
CHOICE=${CHOICE:-1}

case "$CHOICE" in
  1)
    if [[ -x "./setup_github_single.sh" ]]; then
      ./setup_github_single.sh
    elif [[ -f "./setup_github_single.sh" ]]; then
      chmod +x ./setup_github_single.sh
      ./setup_github_single.sh
    else
      echo "Error: setup_github_single.sh not found in current directory."
      exit 1
    fi
    ;;
  2)
    if [[ -x "./setup_github_multi.sh" ]]; then
      ./setup_github_multi.sh
    elif [[ -f "./setup_github_multi.sh" ]]; then
      chmod +x ./setup_github_multi.sh
      ./setup_github_multi.sh
    else
      echo "Error: setup_github_multi.sh not found in current directory."
      exit 1
    fi
    ;;
  *)
    echo "Invalid choice. Please run ./setup.sh again and choose 1 or 2."
    exit 1
    ;;
esac