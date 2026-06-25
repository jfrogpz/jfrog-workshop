# Local Environment Setup (Without Codespace)

> 🌐 [中文版](./SETUP_CN.md)

This guide is for participants who are not using GitHub Codespace. It explains how to set up the environment needed to complete the Workshop on your local machine.

> If you are using GitHub Codespace, skip this guide — the environment is automatically configured. Just open Copilot Chat and start the tasks.

---

## Tools to Install

### 1. Node.js (v18 or above)

Download and install from [nodejs.org](https://nodejs.org), or use a package manager:

```bash
# macOS (Homebrew)
brew install node

# Ubuntu / Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Verify:
```bash
node -v
npm -v
```

### 2. JFrog CLI

```bash
# macOS (Homebrew)
brew install jfrog-cli

# Linux / macOS (universal)
curl -fL https://install-cli.jfrog.io | sh
```

Verify:
```bash
jf -v
```

### 3. Clone the Repository

```bash
git clone https://github.com/jfrogpz/jfrog-workshop.git
cd jfrog-workshop
```

---

## Set Environment Variables

The instructor will provide the following information. Set the environment variables in your terminal before running any commands:

```bash
export JFROG_URL="https://yourcompany.jfrog.io"   # provided by instructor
export JFROG_TOKEN="your-access-token"             # generate after logging in to JFrog UI
```

To get a Token: log in to JFrog UI with the admin credentials provided by your instructor → click the avatar in the top-right corner → **Edit Profile** → **Access Tokens** → **Generate Token**.

> Note: Environment variables are lost when you open a new terminal. Add them to `~/.bashrc` or `~/.zshrc` to make them persistent.

---

## Completing Tasks Without AI Assistant

Codespace includes GitHub Copilot Chat, which automatically reads the task guide and provides step-by-step instructions.

If you don't have Copilot, read the same task guide directly:

**[.github/copilot-instructions.md](.github/copilot-instructions.md)**

This document contains detailed steps, commands, and success criteria for all 6 tasks — identical to what the AI assistant provides. Just read and follow in order.

---

## Sample Project Path

In Codespace, the project path is `/workspaces/jfrog-workshop/`. When working locally, replace it with your clone directory, e.g. `~/jfrog-workshop/`.

Wherever the docs or scripts reference `/workspaces/jfrog-workshop/`, substitute your local path:

```bash
# In Codespace
cd /workspaces/jfrog-workshop/npm-sample

# Locally, replace with
cd ~/jfrog-workshop/npm-sample
```
