# Update README for Dynamic Hostname and User Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the project's README.md to reflect the new dynamic hostname and user detection in the Nix configuration.

**Architecture:** Documentation update to simplify setup instructions and explain the requirement for the `--impure` flag.

**Tech Stack:** Markdown

---

### Task 1: Update Requirements and Setup Sections

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current README.md**

Run: `cat README.md`

- [ ] **Step 2: Apply the updates to README.md**

```markdown
# dotfiles
My MacOS initial setup and dotfiles configuration

### Requirements:
1. [Install Nix](https://zero-to-nix.com/start/install/)
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install macos
```
2. [Install Nix darwin](https://github.com/LnL7/nix-darwin)
- Setup
```bash
mkdir -p ~/.config/nix-darwin
cp flake.nix ~/.config/nix-darwin/
cd ~/.config/nix-darwin
```
- Install
```bash
# The configuration now auto-detects your hostname and user.
# The --impure flag is required for environment variable detection.
nix run nix-darwin -- switch --flake . --impure
```

### How to
- Rebuild / Switch
```bash
darwin-rebuild switch --flake . --impure
```
- Manual Override (if auto-detect fails or for specific host)
```bash
darwin-rebuild switch --flake .#MT --impure
```

### Note on Dynamic Configuration
The `flake.nix` now uses:
- `HOSTNAME` environment variable for the machine name (falls back to `MT`).
- `SUDO_USER` or `USER` environment variable for the primary user (falls back to `tamnm`).
Use the `--impure` flag with `nix` commands to enable this detection.

### Common Error
... (rest of the file)
```

- [ ] **Step 3: Verify the changes**

Run: `cat README.md` and check that the instructions are simplified and accurate.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: update README for dynamic hostname/user detection"
```
