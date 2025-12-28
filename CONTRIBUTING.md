# Contributing to the Git & GitHub Configurations Helper

Thank you for your interest in contributing to this repository. Its goal is to make it easy to consistently configure Git and GitHub (including multi-account setups) through scripts and documented workflows.

## Scope of this repository

This repo focuses on:

- Scripts and configuration files that help automate Git and GitHub setup (user.name, user.email, SSH keys, per-repo configs, etc.).
- Documentation that explains how to use those scripts safely.
- Examples of recommended Git workflows and configuration patterns.

It is **not** a general Git tutorial. Issues and PRs should be about the automation and configuration patterns provided here.

## Ways to contribute

- Report bugs, confusing behavior, or surprising side-effects of the scripts.
- Improve documentation (clarify steps, update screenshots or examples, add notes for different OSes or shells).
- Suggest safer defaults for Git configuration.
- Add focused scripts for common tasks (e.g., generating SSH keys, adding them to ssh-agent) with clear instructions and warnings.

## Getting started

1. Read the README and any linked guides in this repo.
2. Test the scripts on a **non-critical** machine or a fresh user account to understand their behavior.
3. Note any assumptions or preconditions that are not clearly stated and raise them as issues or address them in PRs.

## Guidelines for changes

- Be extremely cautious when changing scripts that modify user configuration (e.g. `~/.gitconfig`, SSH keys, global Git settings).
- Always document what a script will change before it is run.
- Prefer idempotent operations where possible (safe to re-run).
- Avoid destructive actions unless they are clearly documented and require explicit user confirmation.

## Testing your changes

Before submitting a pull request:

- Run the scripts you touched in a safe environment and verify:
  - Config files are updated as documented.
  - No unexpected files are overwritten or deleted.
- Update or add documentation to match new behavior.

## Reporting issues

When opening an issue, include:

- OS and shell (e.g. macOS + zsh).
- The exact command(s) you ran.
- Any relevant output, error messages, or logs.
- What you expected vs what actually happened.

Clear reports make it much easier to reproduce and fix problems.

By contributing to this repository, you help make Git & GitHub setup more repeatable and less error-prone for others.
