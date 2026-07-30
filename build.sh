#!/bin/bash
set -eu

# Build script for cpuminer-multi Docker image
# Define image name, version and registries
image="cpuminer-multi"
version="1.3.7"
registries=("docker.io" "ghcr.io")

# Support for Dockerfile variant
DOCKERFILE="${DOCKERFILE:-Dockerfile}"

echo "Building cpuminer-multi Docker image..."
echo "Version: $version"
echo "Dockerfile: $DOCKERFILE"
echo

# Build the image with security improvements
docker build . \
    --file "$DOCKERFILE" \
    --build-arg VERSION_TAG="v$version" \
    --tag "${registries[0]}/cniweb/$image:$version" \
    --tag "${registries[0]}/cniweb/$image:latest"

# Check if the command was successful
if [ $? -ne 0 ]; then
  echo "Docker build failed!"
  exit 1
fi

echo "Docker build succeeded!"

# Check if we should only build (for CI/CD usage)
if [ "$1" = "build-only" ]; then
  echo "Build-only mode: skipping security check and push to registries"
  exit 0
fi

# Run security check if available
if [ -f "security-check.sh" ]; then
    echo "Running security check..."
    ./security-check.sh
fi

# Tag and push the images
for registry in "${registries[@]}"; do
  echo "Tagging and pushing to $registry..."
  docker tag "${registries[0]}/cniweb/$image:$version" "$registry/cniweb/$image:$version"
  docker tag "${registries[0]}/cniweb/$image:$version" "$registry/cniweb/$image:latest"

  # Push both versioned and latest tags
  docker push "$registry/cniweb/$image:$version"
  docker push "$registry/cniweb/$image:latest"
done

echo "All builds and pushes completed successfully!"