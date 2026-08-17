#!/usr/bin/env bash
#
# check_docker_image_data.sh
# Cross‑platform (Linux/macOS) script to inspect a Docker image's filesystem.
#
# Features:
#  - Creates a temporary container from a given image
#  - Exports its filesystem to a tarball
#  - Extracts the tarball into a directory for inspection
#  - Cleans up the container afterwards
#  - Optional "cleanup" mode to remove old temp containers and extracted dirs
#
# Make script executable: chmod +x check_docker_image_data.sh
#
# Usage:
#   ./check_docker_image_data.sh [IMAGE]
#   ./check_docker_image_data.sh cleanup
#
# Examples:
#   ./check_docker_image_data.sh
#   ./check_docker_image_data.sh username/flask-k8s-app:latest
#   ./check_docker_image_data.sh cleanup
#

set -euo pipefail

# If "cleanup" is passed as the first argument, run cleanup mode
if [[ "${1:-}" == "cleanup" ]]; then
  echo "Running cleanup: removing old temp containers and extracted filesystems..."

  # Remove containers whose names start with "tmp-inspect-"
  for name in $(docker ps -a --format '{{.Names}}' | grep '^tmp-inspect-' || true); do
    echo "Removing container: $name"
    docker rm -f "$name" >/dev/null 2>&1 || true
  done

  # Remove tar files and directories matching the pattern
  # Patterns:
  #   image-fs-tmp-inspect-*.tar
  #   image-fs-tmp-inspect-*
  shopt -s nullglob

  tar_files=(image-fs-tmp-inspect-*.tar)
  for f in "${tar_files[@]}"; do
    echo "Removing tar: $f"
    rm -f "$f"
  done

  # For directories, iterate over matches
  for d in $(ls -d image-fs-tmp-inspect-* 2>/dev/null || true); do
    echo "Removing directory: $d"
    rm -rf "$d"
  done

  echo "Cleanup complete."
  exit 0
fi

# Default image if not provided
IMAGE="${1:-username/flask-k8s-app:latest}"

# Generate unique names to avoid collisions
CONTAINER_NAME="tmp-inspect-$(date +%s)-$$"
TAR_FILE="image-fs-${CONTAINER_NAME}.tar"
EXTRACT_DIR="image-fs-${CONTAINER_NAME}"

cleanup_container() {
  # Remove container if it exists
  if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi
}

trap cleanup_container EXIT

echo "Using image: ${IMAGE}"
echo "Container name: ${CONTAINER_NAME}"
echo "Tar file: ${TAR_FILE}"
echo "Extract directory: ${EXTRACT_DIR}"

# Create (but don't start) a container from the image
docker create --name "${CONTAINER_NAME}" "${IMAGE}" >/dev/null

# Export its filesystem to a tar
docker export "${CONTAINER_NAME}" > "${TAR_FILE}"

# Extract and browse
mkdir -p "${EXTRACT_DIR}"
tar -xf "${TAR_FILE}" -C "${EXTRACT_DIR}"

echo "Filesystem extracted to: ${EXTRACT_DIR}"
echo "You can now inspect the contents, e.g.:"
echo "  ls -R \"${EXTRACT_DIR}\""
echo ""
echo "When done, you can either:"
echo "  - Manually remove this run's artifacts:"
echo "      rm -rf '${EXTRACT_DIR}' '${TAR_FILE}'"
echo "  - Or run full cleanup for all old runs:"
echo "      $0 cleanup"
echo ""
echo "Container will be removed automatically on exit."