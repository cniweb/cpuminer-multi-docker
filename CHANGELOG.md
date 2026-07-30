# Changelog

All notable changes to this Docker packaging project are documented here.

## [Unreleased]

## [1.3.1-multi] - 2026-07-30

### Fixed
- Removed broken `git checkout "$VERSION_TAG"` — tag `v1.3.7` never existed upstream
- Aligned version to last upstream release `v1.3.1-multi` (2017-01-26)
- Project now builds from linux branch HEAD (upstream is dormant since 2017)

## [1.3.7] - 2025-06-11
- Initial Docker image with standard CI/CD pipeline, SBOM and provenance attestation, multi-registry publishing.