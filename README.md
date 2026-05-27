# C/C++test AI Agent Skills Demo

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Workflow](#workflow)
- [Project layout](#project-layout)
- [Using project with C/C++test Professional](#using-project-with-cctest-professional)

## Overview

This repository is an example C++ project that demonstrates how the Parasoft C/C++test AI agent skills can be used to automatically fix static analysis violations inside a GitHub CI/CD pipeline.

The key idea is that when a pull request is created, the pipeline runs C/C++test, detects violations, and then invokes an AI coding agent (OpenAI Codex, or others) equipped with C/C++test skills and MCP tools to automatically fix the violations, commit the fixes to a new branch, and open a new pull request.

The C/C++test AI Agent skills used in this project are taken from the [parasoft/cpptest-ai-agent-skills](https://github.com/parasoft/cpptest-ai-agent-skills) repository.

## Prerequisites

The CI/CD pipeline requires a GitHub self-hosted runner configured and connected to the repository. The runner must have the following components available:

- **Parasoft C/C++test Standard** — installed, configured, and licensed
  - Expected installation path: `/opt/parasoft/cpptest`
  - The following directories should be on `$PATH` so that `cpptestcli` and `cpptesttrace` are accessible to the pipeline:
    - `/opt/parasoft/cpptest`
    - `/opt/parasoft/cpptest/bin`
- **GitHub CLI** - installed
- **AI coding agent** — OpenAI Codex CLI, authorized and ready to use
- **C/C++ toolchain** — GNU GCC compiler and `make` build tool

> **Note:** If your C/C++test installation path or AI agent setup differs from the defaults, update the configuration in [.github/workflows/cpptest-autofix-github.yml](.github/workflows/cpptest-autofix-github.yml), [.github/workflows/cpptest-agent-run.sh](.github/workflows/cpptest-agent-run.sh), and [cpptest-analyze.sh](cpptest-analyze.sh) accordingly.

> **Tip:** Consider using a Docker container as your GitHub self-hosted runner with C/C++test and the AI agent pre-installed. An example Dockerfile is available in the `devcontainer` folder of the [parasoft/cpptest-ai-agent-skills](https://github.com/parasoft/cpptest-ai-agent-skills) repository.

## Workflow

### 1. Preparation
1. Fork or copy this repository.
2. Set up and connect a GitHub self-hosted runner: **Settings > Actions > Runners**. See also [Prerequisites](#prerequisites) above.
3. Enable the following option in your repository: **Settings > Actions > General > Allow GitHub Actions to create and approve pull requests**.
4. Clone the repository to your local machine.

### 2. Introducing a Code Change
1. Create a `feature` branch in the local repository.
2. Introduce a change to the source code.
3. Push the branch to the remote GitHub repository.
4. Open a pull request on GitHub to merge your `feature` branch into your default branch (`master` or `main`).

### 3. CI/CD Pipeline Execution
Opening a pull request triggers the workflow defined in [.github/workflows/cpptest-autofix-github.yml](.github/workflows/cpptest-autofix-github.yml):

1. The project is built.
2. C/C++test runs static analysis and archives the reports as build artifacts.
3. If violations are found, the AI Autofix step is triggered:
   - A new `autofix/pr-<number>/<timestamp>` branch is created.
   - The AI agent processes violations rule by rule.
   - Each fix is verified by running [cpptest-analyze.sh](cpptest-analyze.sh).
   - Verified fixes are committed to the `autofix` branch (one commit per rule).
   - The `autofix` branch is pushed to the remote repository.
   - A pull request from `autofix` into your `feature` branch is opened, and a comment with links is posted on the original PR.

### 4. Reviewing the Autofix Pull Request
1. Review the changes proposed in the `autofix` branch.
2. Merge the `autofix` branch into your `feature` branch.
3. Verify that the pipeline passes on the updated `feature` branch.
4. Merge the `feature` branch into your default branch (`master` or `main`).

## Project layout

The repository is structured as follows, highlighting the key files related to C/C++test AI agent skills configuration:

```
<PROJECT_DIR>
  .agents/skills/
    cpptest-fix-all-violations/
      SKILL.md                    # AI agent skill: fix all violations in the project
    cpptest-fix-one-violation/
      SKILL.md                    # AI agent skill: fix a single known violation
  .github/workflows/
    cpptest-agent-prompt.md       # Prompt passed to the AI agent
    cpptest-agent-run.sh          # Script that invokes the AI agent
    cpptest-autofix-github.yml    # GitHub build pipeline
  include/
    *.hxx 
  *.cxx
  AGENTS.md                       # Agent instructions for this repository
  cpptest-analyze.sh              # Script for running C/C++test analysis
  Makefile
```

## Using project with C/C++test Professional

This project is configured for C/C++test Standard. To use it with C/C++test Professional, review and update both the local analysis command (`cpptest-analyze.sh`) and the GitHub workflow configuration (`.github/workflows/cpptest-autofix-github.yml`) so they match your installation and project layout.

Update `cpptest-analyze.sh` so its `cpptestcli` command invocation matches your C/C++test Professional setup. In particular, verify the workspace location, test configuration, report directory, and analysis input file. For example:
```bash
cpptestcli -data ../workspace -config "builtin://Recommended Rules" -report "reports" -bdf "cpptestscan.bdf"
```

Review the `Run C/C++test` step in `.github/workflows/cpptest-autofix-github.yml` and adjust the `run-cpptest-action` inputs for C/C++test Professional. This typically includes settings such as the analysis input, workspace location, and any additional parameters required by your environment. See [Customizing the Action to Run C/C++test Professional](https://github.com/parasoft/run-cpptest-action#customizing-the-action-to-run-cctest-professional) for details.
