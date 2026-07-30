# Project Guidelines

## Code Style
- Keep Dockerfiles and shell scripts minimal and explicit.
- Preserve existing shell style (`set -eu`, POSIX-friendly syntax) in `*.sh` files.
- Prefer environment-driven runtime configuration over hardcoded values.

## Architecture
- This repository builds cpuminer-multi from source (git clone from `tpruvot/cpuminer-multi`) inside a Debian-based container image.
- Runtime:
  - Default image behavior: non-root `cpuminer` user, `CMD` runs `cpuminer --config=config.json`.
  - There is no entrypoint script; the binary runs directly via `CMD` or a user-supplied command.
- Key files:
  - `Dockerfile`: image definition — installs build deps, compiles from source, installs binary, removes build deps.
  - `build.sh`: build, tag, and push workflow.
  - `config.json`: default mining configuration.

## Build and Test
- Standard build: `docker build . -t cniweb/cpuminer-multi:test`
- Build helper: `./build.sh build-only`
- Validate image: `docker run --rm cniweb/cpuminer-multi:test cpuminer --version`
- Validate miner functionality: `docker run --rm cniweb/cpuminer-multi:test cpuminer --cputest`
- Security checks: `./security-check.sh`

## Conventions
- Keep cpuminer-multi version synchronized across all four files: `Dockerfile`, `build.sh`, `README.md`, and `CHANGELOG.md`. The release workflow handles all four automatically, promoting `CHANGELOG.md`'s `## [Unreleased]` section to a dated version heading; it fails if that section is missing, so add one before triggering a release.
- **Important:** Upstream tpruvot/cpuminer-multi is dormant since 2017 — the last real tag is `v1.3.1-multi`. The `Dockerfile` no longer runs `git checkout "$VERSION_TAG"` because the original `v1.3.7` tag never existed upstream. The build relies on the `linux` branch HEAD from `git clone -b linux`.
- Use port `8080` consistently.
- The image runs as a non-root `cpuminer` user by default for security.
- For releases, prefer workflow `.github/workflows/release-from-version.yml`.
- Do not duplicate long docs in instructions; reference:
  - `README.md` for runtime usage.
  - `AGENTS.md` for repo conventions, CI behavior, and known gotchas.
