# Agent Workspace Guide

## Repo shape

- This repo packages cpuminer-multi (a multi-threaded CPU miner) built from source; it does not use prebuilt release tarballs.
- `Dockerfile` compiles cpuminer-multi from the upstream GitHub repository (`tpruvot/cpuminer-multi`).
- The image has no entrypoint script; the `CMD` is `cpuminer --config=config.json` by default.
- `build.sh` builds the Docker image and optionally pushes to Docker Hub and GitHub Container Registry.

## Verification

- Primary checks are Docker-based:
  - `docker build . -t cniweb/cpuminer-multi:test --file Dockerfile`
  - `docker run --rm cniweb/cpuminer-multi:test cpuminer --version`
  - `docker run --rm cniweb/cpuminer-multi:test cpuminer --cputest`
- `./build.sh build-only` is the same build path CI uses on `main`; it exits before security checks or pushes.
- `./security-check.sh` defaults to image `cniweb/cpuminer-multi:test`; build that tag first or pass a different image name.

## Shell and runtime constraints

- The image runs as non-root `cpuminer` by default for security.
- Port `8080` is exposed as the expected non-privileged port.
- There is no `docker-entrypoint.sh` -- the binary runs directly via `CMD` or user-supplied command.

## Release/versioning

- cpuminer-multi version bumps must stay synchronized across files: `Dockerfile`, `build.sh`, `README.md`, and `CHANGELOG.md`.
- **Known issue:** Upstream tpruvot/cpuminer-multi is dormant since 2017; the last real release is `v1.3.1-multi`. The Dockerfile builds from the `linux` branch HEAD (no tag checkout) since later tags do not exist upstream.
- The release workflow (`.github/workflows/release-from-version.yml`) handles all four automatically: it updates version refs, and promotes `CHANGELOG.md` `## [Unreleased]` heading to `## [<version>] - <date>`. **The workflow fails fast if `CHANGELOG.md` has no `## [Unreleased]` section** -- add one with the release notes before triggering it.
- Prefer that workflow for releases: it updates version refs, commits, tags `vX.Y.Z`, and creates the GitHub release.

## CI

- `.github/workflows/docker-build.yml` runs on push and PR to `main`:
  - `validate` job: builds with `./build.sh build-only`, then runs `--version`, `--cputest`, and `security-check.sh` against it. Never pushes.
  - `docker` job (push events only, gated on `validate` passing): rebuilds, re-runs the same validation, then tags and pushes versioned + `latest` + commit-SHA tags to Docker Hub and GHCR, and generates a SLSA provenance attestation and SBOM.
- Snyk container scanning runs on push/PR to `main` and weekly via `snyk-container-analysis.yml`.
- Dependabot monitors Docker base images and GitHub Actions versions.