# Agent Workspace Guide

## Repo shape

- This repo packages cpuminer-multi (a multi-threaded CPU miner) built from source; it does not use prebuilt release tarballs.
- `Dockerfile` compiles cpuminer-multi from the upstream GitHub repository (`tpruvot/cpuminer-multi`).
- The image has no entrypoint script; the `CMD` is `cpuminer --config=config.json` by default.
- `build.sh` builds the Docker image and optionally pushes to Docker Hub and GitHub Container Registry.
- The Dockerfile clones the floating upstream `linux` branch. `ARG VERSION_TAG` is currently metadata/build-argument compatibility only and does not select a source revision; reproducible changes require pinning a commit or tag.

## Verification

- Primary checks are Docker-based:
  - `docker build . -t cniweb/cpuminer-multi:test --file Dockerfile`
  - `docker run --rm cniweb/cpuminer-multi:test cpuminer --version`
  - `docker run --rm cniweb/cpuminer-multi:test cpuminer --cputest`
- `./build.sh build-only` is the same build path CI uses on `main`; it exits before security checks or pushes. Always pass `build-only` (`build.sh` uses `set -eu`, so a bare `./build.sh` fails on unbound `$1`; any other argument falls through to `security-check.sh` and registry pushes).
- `./security-check.sh` defaults to image `cniweb/cpuminer-multi:test`; build that tag first or pass a different image name. Note: CI validates the versioned tag `docker.io/cniweb/cpuminer-multi:<version-from-build.sh>` instead of `:test`, and invokes the binary via `--entrypoint cpuminer`.
- CI runs `security-check.sh` (non-root user, port, secrets placeholder, file ownership, binary `--version`) as its shell audit; there is no project unit-test or lint suite.
- `build.sh` coupling: CI extracts the version via `grep '^version=' build.sh`, so keep the exact `version="x"` format. `DOCKERFILE` env var overrides the Dockerfile variant.

## Shell and runtime constraints

- The image runs as non-root `cpuminer` by default for security.
- Port `8080` is exposed as the expected non-privileged port.
- There is no `docker-entrypoint.sh` -- the binary runs directly via `CMD` or user-supplied command.
- The default config is `/cpuminer/config.json`. Running without a command override may start mining and attempt external pool connectivity.
- Review compiler flags, including `-pg`, `-O2`, LTO, and hardcoded `make install -j 4`, before changing the build.

## Release/versioning

- cpuminer-multi version bumps must stay synchronized across files: `Dockerfile`, `build.sh`, `README.md`, and `CHANGELOG.md`.
- **Gap (2026-09-24):** `README.md` currently contains no version string, so the release workflow's `README.md` regex replacements are a no-op. Follow-up: add the expected `` `Dockerfile` currently uses cpuminer-multi `x` `` / `` `build.sh` currently tags/pushes `x` `` markers to `README.md` so the workflow has something to replace.
- **Known issue:** Upstream tpruvot/cpuminer-multi is dormant since 2017; the last real release is `v1.3.1-multi`. The Dockerfile builds from the `linux` branch HEAD (no tag checkout) since later tags do not exist upstream.
- The release workflow (`.github/workflows/release-from-version.yml`) handles all four automatically: it updates version refs, and promotes `CHANGELOG.md` `## [Unreleased]` heading to `## [<version>] - <date>`. **The workflow fails fast if `CHANGELOG.md` has no `## [Unreleased]` section** -- add one with the release notes before triggering it.
- Prefer that workflow for releases: it updates version refs, commits, tags `vX.Y.Z`, and creates the GitHub release.

## CI

- `.github/workflows/docker-build.yml` runs on push and PR to `main`:
  - `validate` job: builds with `./build.sh build-only`, then runs `--version`, `--cputest`, and `security-check.sh` against it. Never pushes.
  - `docker` job (push events only, gated on `validate` passing): rebuilds, re-runs the same validation, then tags and pushes versioned + `latest` + commit-SHA tags to Docker Hub and GHCR, and generates a SLSA provenance attestation and SBOM.
- Snyk container scanning runs on push/PR to `main` and weekly via `snyk-container-analysis.yml`.
- Dependabot monitors Docker base images and GitHub Actions versions.

## Lessons learned

- Append a dated bullet here after every non-trivial agent task (PR merge, release, build fix, doc correction). Keep each entry to cause → fix → rule. Cap at ~10 entries; archive older ones to `CHANGELOG.md` and cite a verifiable artifact (PR link, commit SHA, failing command) per entry.
- **2026-09-24 (PR merge, observed practice):** `gh pr view --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup` is the merge gate (`MERGEABLE` + `CLEAN` + required checks `SUCCESS`). Past merges use merge commits, so prefer `merge` method for Dependabot PRs to match history (`#25`, `#27`, `#29`).
- **2026-09-24 (push rejected):** Merging via GitHub web/API leaves local `main` behind. `git pull --rebase origin main` before `git push`; never force-push without explicit request.
- **2026-09-24 (local tooling):** `.serena/` is agent-local state and is now in `.gitignore`. Do not commit agent workspaces; if a new local tool directory appears, ignore it the same way.
- **2026-09-24 (AGENTS.md audit):** `AGENTS.md` and `.github/copilot-instructions.md` duplicate build/test/release guidance — keep both in sync when changing `Dockerfile`, `build.sh`, or workflows.
