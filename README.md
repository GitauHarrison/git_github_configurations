# Git & GitHub Configuration Scripts

This repository contains small shell scripts that automate common Git and GitHub setup tasks on **macOS** and **Linux** without hardcoding any private details.

You can use them to:

- Configure your global Git identity (name, email, default branch).
- Generate and register SSH keys for GitHub.
- Configure `~/.ssh/config` so Git uses the right key automatically.
- Optionally configure multiple GitHub accounts (e.g. personal + work) on the same machine.
- Run everything through a simple entrypoint: `./setup.sh`.

All sensitive values (name, email, paths) are provided **via prompts** at runtime, not stored in the repo.


### Table Of Content

- [Git & GitHub Configuration Scripts](#git--github-configuration-scripts)
  - [Files in this repository](#files-in-this-repository)
    - [1. `setup_github_single.sh`](#1-setup_github_singlesh)
    - [2. `setup_github_multi.sh`](#2-setup_github_multish)
    - [3. `setup.sh`](#3-setupsh)
  - [Prerequisites](#prerequisites)
    - [Initial setup in this repository](#initial-setup-in-this-repository)
    - [Usage](#usage)
      - [Option A: Recommended – Use `setup.sh`](#option-a-recommended--use-setupsh)
      - [Option B: Run setup_github_single.sh directly](#option-b-run-setup_github_singlesh-directly)
      - [Option C: Run setup_github_multi.sh directly](#option-c-run-setup_github_multish-directly)
      - [Afterwards:](#afterwards)
      - [Security & privacy](#security--privacy)
      - [Limitations / Notes](#limitations--notes)
      - [Troubleshooting](#troubleshooting)
  - [Want to manually set up your git and GitHub configurations?](#want-to-manually-set-up-your-git-and-github-configurations)

---

## Files in this repository

### 1. `setup_github_single.sh`

**Purpose:**  
Automate Git & GitHub configuration for **one GitHub account** on the current machine.

**High‑level behavior:**

- Detects whether you’re on macOS or Linux.
- Prompts you for:
  - Git user name (e.g. `Your Name`)
  - Git email (e.g. `you@example.com`)
  - Default Git branch name (default: `main`)
- Configures global Git settings:
  - `user.name`
  - `user.email`
  - `init.defaultBranch`
  - Some sensible defaults like:
    - `pull.rebase = false`
    - `push.default = simple`
    - `color.ui = auto`
- Sets up a **single SSH key** for GitHub:
  - Uses `~/.ssh/id_ed25519` as the default key path.
  - Offers to:
    - Generate a new key if missing.
    - Overwrite an existing key (only if you confirm).
- Starts or reuses `ssh-agent` and adds your SSH key.
- Configures `~/.ssh/config` with a `Host github.com` entry:
  - Uses the configured key.
  - Enables `IdentitiesOnly` and `AddKeysToAgent`.
  - On macOS, also enables `UseKeychain` so your key passphrase can be stored in the system keychain.
- Optionally runs `gh auth login` (if GitHub CLI `gh` is installed).
- Prints your **public SSH key** so you can copy‑paste it into GitHub:
  - GitHub → Settings → SSH and GPG keys.

**When to use it:**

- You only use **one** GitHub account on this machine.
- You want a quick global setup without worrying about multiple identities.

---

### 2. `setup_github_multi.sh`

**Purpose:**  
Automate Git & GitHub configuration for **multiple GitHub accounts** on the same machine, for example:

- `personal`
- `work`
- `freelance`

Each account gets its **own SSH key, ssh Host alias, and per‑account Git config**.

**High‑level behavior:**

For each account you configure, the script:

1. Prompts for account details:
   - Short label (e.g. `personal`, `work`).
   - Git user name for that account.
   - Git email for that account.
   - Base directory where repos for that account will live (e.g. `~/work`, `~/personal`).

2. SSH key:
   - Suggests `~/.ssh/id_ed25519_<label>` (e.g. `id_ed25519_personal`) as the key path.
   - Generates an SSH key at that path if it doesn’t exist.
   - Adds the key to `ssh-agent`.

3. SSH host alias:
   - Creates a `Host` entry in `~/.ssh/config`, for example:
     - `Host github-personal`
     - `Host github-work`
   - Each alias:
     - Points to `HostName github.com`.
     - Uses the corresponding `IdentityFile`.
     - Enables `IdentitiesOnly` and `AddKeysToAgent`.
     - On macOS, also sets `UseKeychain yes`.

4. Per‑account Git config:
   - Writes a separate `~/.gitconfig-<label>`, e.g.:
     - `~/.gitconfig-personal`
     - `~/.gitconfig-work`
   - Each file defines:
     - `[user] name = ...`
     - `[user] email = ...`

5. Automatic account selection by directory:
   - Modifies your main `~/.gitconfig` to include per‑account configs via `includeIf`, for example:
     - When a repo is under `~/work/`, use `~/.gitconfig-work`.
     - When a repo is under `~/personal/`, use `~/.gitconfig-personal`.

6. Shows the public key:
   - Prints `${KEY_PATH}.pub` so you can add it to the correct GitHub account.

7. Explains how to clone:
   - Use the alias host, for example:
     - `git clone git@github-work:org/repo.git`
     - `git clone git@github-personal:me/repo.git`

**When to use it:**

- You have **more than one** GitHub account (e.g. company and personal).
- You want each repo to automatically use the correct name/email based on directory.

---

### 3. `setup.sh`

**Purpose:**  
A simple **wrapper / entrypoint** that you run after cloning the repo.

It:

- Prompts you to choose:
  - `1` – Configure a **single** GitHub account (`setup_github_single.sh`)
  - `2` – Configure **multiple** GitHub accounts (`setup_github_multi.sh`)
- Ensures the chosen script is executable.
- Runs the appropriate setup script.

This gives you a single command to remember:

```bash
./setup.sh
```

---

## Prerequisites

To use these scripts effectively, you should have:

- `Git` installed (git on the command line).
- `OpenSSH` installed (`ssh`, `ssh-keygen`, `ssh-agent`).
- Optional but recommended:
    - GitHub CLI (`gh`) if you want to use `gh auth login`.

These are available by default or easily installable on both macOS and most Linux distributions.



### Initial setup in this repository

After you clone this repo for the first time, mark the scripts as executable:
```bash
chmod +x setup.sh setup_github_single.sh setup_github_multi.sh
```
You should only need to do this once per clone.

### Usage

#### Option A: Recommended – Use `setup.sh`

This is the easiest and least error‑prone way.

1. Clone this repo:

    ```bash
    git clone git@github.com:GitauHarrison/git_github_configurations.git
    cd git_github_configurations
    ```

2. Run the wrapper:

    ```bash
    ./setup.sh
    ```

3. When prompted:
    - Choose:
        - 1 – Single GitHub account
        - Multiple GitHub accounts
    - Answer the questions:
        - Name, email
        - Default branch (for single account)
        - Number of accounts, labels, base directories (for multi‑account)
        - Whether to generate keys, overwrite existing keys, etc.

4. Follow the instructions printed by the script to:
    - Copy the public key(s).
    - Add them to the appropriate GitHub account(s) under:
        - GitHub → Settings → SSH and GPG keys.

After that, Git operations (`git pull`, `git push`) should work without repeatedly typing GitHub passwords.


#### Option B: Run setup_github_single.sh directly

If you know you only want a single account setup:

```bash
./setup_github_single.sh
```

You will be prompted for:

- Git name and email
- Default branch name
-  Whether to generate an SSH key (and whether to overwrite an existing one)
- Whether to run `gh auth login` (if `gh` is installed)

At the end, the script prints your public key (e.g. from `~/.ssh/id_ed25519.pub`); add that key to your GitHub account.


#### Option C: Run setup_github_multi.sh directly

If you want to configure multiple accounts on one machine:

```bash
./setup_github_multi.sh
```

You will be prompted for:

1. How many accounts you want to configure.
2. For each account:
    - Label (e.g. personal, work).
    - Git name and email.
    - Base directory for that account’s repos (e.g. `~/work`).
    - SSH key path (or accept default `~/.ssh/id_ed25519_<label>`).

The script will then:

- Generate keys if needed.
- Add Host `github-<label>` entries to `~/.ssh/config`.
- Write per‑account `~/.gitconfig-<label>` files.
- Add `includeIf` rules to `~/.gitconfig`.


#### Afterwards:

- Put repos for each account under the base directory you chose (e.g. `~/work/`, `~/personal/`).
- Clone using the host alias:

    ```bash
    # For work account
    git clone git@github-work:org/repo.git

    # For personal account
    git clone git@github-personal:me/repo.git
    ```

Git will automatically use the correct user name/email based on repo location.



#### Security & privacy

- **No secrets are hardcoded** in these scripts.
- All sensitive information (name, email, SSH key paths) is collected via interactive prompts.
- SSH keys are generated and stored under your home directory (e.g. `~/.ssh/`), not in the repo.
- If you enable keychain/ssh‑agent features:
    - macOS: your key passphrase can be stored in the system keychain.
    - Linux: your key is cached in memory for the life of the `ssh-agent` session.


#### Limitations / Notes

- Git does not automatically run scripts upon `git clone` for security reasons.
- You must explicitly run `./setup.sh` (or the individual scripts).
- If you rerun the scripts:
    - They will detect existing SSH keys and config entries.
    - You will be asked before overwriting keys.
    - Existing `Host` or `includeIf` entries are left in place if already present.
- You still need to add each generated public key to the corresponding GitHub account once.


#### Troubleshooting

- **Permission denied** (publickey) when pushing or pulling:
    - Make sure:
        - The correct SSH key is loaded: ssh-add -l.
        - The key’s public part is added to GitHub.
        - You’re using the right host (github.com, github-work, github-personal, etc.).
- **Script not executable**:
    - Run:

        ```bash
        chmod +x setup.sh setup_github_single.sh setup_github_multi.sh
        ```

- **Wrong Git identity in a repo (multi‑account)**:
    - Check where the repo lives:
        - It must be under the base directory you configured (~/work/, ~/personal/, etc.).
    - Run:
        ```bash
        git config user.name
        git config user.email
        ```

        to verify which identity is active.



By committing these scripts and this README to your repo, you can quickly bootstrap consistent Git and GitHub setup on any new Mac or Linux machine with just:

```bash
git clone <URL-of-this-repo>.git
cd <repo-directory>
./setup.sh
```

---

## Want to manually set up your git and GitHub configurations?

Learn how below:

- [Mac: Configure Your MacBook To Use More Than One GitHub Account](https://gist.github.com/BolderLearnerTechSchool/3d09b8301a9a956542846860d005f0ab)
- [Linux: Configure Your Computer To Use More Than One GitHub Account](https://gist.github.com/BolderLearnerTechSchool/0086026d177af7320a8fa3e707fb3f30)