# FinOpsly CLI

**See what a Terraform change actually costs — before it's merged.**

The FinOpsly CLI runs a targeted `terraform plan`, sends the result to your FI
Pulse backend, and prints back a cost breakdown and any policy findings —
right in your terminal or CI pipeline, no separate dashboard required.

## Features

- **Cost estimates on demand.** `finopsly estimate` shows a before/after/net
  monthly cost table for every changed resource in your Terraform plan.
- **Policy findings alongside cost.** Violations are grouped by resource, at
  whatever severity your organization has configured — block, warn, or info.
- **Built for CI.** Auto-detects GitHub Actions, authenticates via GitHub
  OIDC + a scoped access token, and exits non-zero when policy blocks a
  change — no separate CI-only binary or flags.
- **Accurate AMI-aware pricing.** Enriches `aws_instance` cost estimates with
  your AMI's actual OS and licensing details via AWS EC2 `DescribeImages`,
  using your local AWS credentials.
- **JSON output for tooling.** `--format json` for scripting, SARIF
  generation, or any other machine-readable pipeline step.

## Requirements

- [Terraform](https://www.terraform.io/) on your `PATH`, with `terraform init`
  already run in the directory you're estimating.
- An active FinOpsly account.

## Install

**Homebrew (macOS and Linux):**
```
brew install finopsly/cli/finopsly
```

**Chocolatey (Windows):**
```
choco install finopsly
```
Install a specific version with either package manager:
```
brew install finopsly/cli/finopsly@1.2.0
choco install finopsly --version=1.2.0
```

**Debian/Ubuntu (.deb) or Fedora/RHEL (.rpm):**
Download the matching package for your architecture from the
[latest release](https://github.com/finopsly/finopsly-pulse-cli/releases/latest)
and install it with `dpkg -i` or `rpm -i`.

**Install script (macOS, Linux, Windows):**
```
curl -fsSL https://raw.githubusercontent.com/finopsly/finopsly-pulse-cli/main/install.sh | sh
```
```
irm https://raw.githubusercontent.com/finopsly/finopsly-pulse-cli/main/install.ps1 | iex
```
Pass a version to install something other than latest, e.g. `sh -s -- v1.2.0`.

**Manual:** grab a binary directly from the
[releases page](https://github.com/finopsly/finopsly-pulse-cli/releases).

## Getting started

```
finopsly login
finopsly estimate
```

`login` opens a browser for sign-in (falls back to a device code if no
browser is available — pass `--device-code` to force it). Once signed in, run
`estimate` from any Terraform directory with a plan-able configuration.

## Commands

| Command | Description |
|---|---|
| `finopsly login` | Sign in via your organization's identity provider |
| `finopsly logout` | Clear the local session |
| `finopsly token set` | Store a long-lived `fp_sl_live_*` access token (for CI, or as an alternative to `login`) |
| `finopsly token clear` | Remove the stored access token |
| `finopsly estimate` | Run a cost + policy estimate against the current Terraform directory |
| `finopsly version` | Print the CLI version |

**`estimate` flags:**

| Flag | Description |
|---|---|
| `-d, --dir` | Terraform directory (default: current directory) |
| `-t, --target` | Target a specific resource, e.g. `aws_instance.web` |
| `-f, --format` | Output format: `text` or `json` (default: `text`) |
| `-r, --region` | AWS region for EC2 `DescribeImages` (default: `us-east-1`, or `AWS_REGION`) |
| `--discount` | Override your org's discount % for this run only |
| `--no-color` | Disable colored output (also honored via `NO_COLOR`) |

## CI/CD

The CLI auto-detects `GITHUB_ACTIONS=true` and authenticates via GitHub OIDC
plus a scoped access token — no interactive login step needed:

```yaml
permissions:
  id-token: write   # required for GitHub OIDC

steps:
  - uses: actions/checkout@v4
  - uses: hashicorp/setup-terraform@v3
  - run: terraform init
  - run: finopsly estimate --format json
    env:
      FINOPSLY_ACCESS_TOKEN: ${{ secrets.FINOPSLY_ACCESS_TOKEN }}
```

Your organization is resolved automatically from the access token — no org ID
needed. Exit codes: `0` success, `1` usage error, `2` Terraform error, `3` API
error, `4` auth error, `5` policy blocked.

## Configuration

Drop a `.finopsly/settings.json` in your project root to set defaults for the
whole team (currently: `discount_percent`). Environment variables:

| Variable | Purpose |
|---|---|
| `FINOPSLY_ACCESS_TOKEN` | `fp_sl_live_*` access token, mainly for CI |
| `FINOPSLY_DISCOUNT` | Default discount % (0–100) |
| `AWS_REGION` / `AWS_DEFAULT_REGION` | Region used for AMI enrichment |
| `NO_COLOR` | Disable colored output |

## Privacy and data

The CLI sends no telemetry by default. Running `estimate` sends the Terraform
plan data for that run — and nothing else — to the FinOpsly FI Pulse API. If
AMI enrichment applies, the `DescribeImages` call goes directly from your
machine to AWS; it is never routed through FinOpsly.

## License

Use of this software is governed by the [FinOpsly CLI End User License
Agreement](./LICENSE).

## Support

Questions or issues: [finopsly.com/support](https://finopsly.com/support).
