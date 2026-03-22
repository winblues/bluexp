container_engine := env_var_or_default("CONTAINER_ENGINE", "podman")

build:
  bluebuild build -B podman --tempdir /var/tmp recipes/recipe.yml

build-rpms:
  #!/bin/bash
  set -euo pipefail
  REPO="vendor/xfce-winxp-tc"

  if [[ ! -d "$REPO" ]]; then
    echo "error: ${REPO} not found — clone xfce-winxp-tc there first" >&2
    exit 1
  fi

  source files/xfce-winxp-tc.env
  git -C "$REPO" checkout "$XFCE_WINXP_TC_VERSION"

  {{container_engine}} build \
    -f files/scripts/packages/xfce-winxp-tc/Containerfile \
    -t xfce-winxp-tc-dev-image \
    files/scripts/packages/xfce-winxp-tc/

  cd "$REPO"
  {{container_engine}} run --rm \
    --volume "$PWD:/app:Z" \
    --workdir /app \
    xfce-winxp-tc-dev-image \
    bash /app/packaging/buildall.sh

update-build-deps:
  #!/bin/bash
  set -euo pipefail
  REPO="vendor/xfce-winxp-tc"
  DEPMAP="${REPO}/tools/bldutils/depmap/depmap.py"
  OUT="files/scripts/packages/xfce-winxp-tc/build-deps.txt"

  if [[ ! -d "$REPO" ]]; then
    echo "error: ${REPO} not found — clone xfce-winxp-tc there first" >&2
    exit 1
  fi

  source files/xfce-winxp-tc.env
  git -C "$REPO" checkout "$XFCE_WINXP_TC_VERSION"

  while IFS= read -r deps_file; do
    dir=$(dirname "$deps_file")
    first=$(head -1 "$deps_file")
    [[ ! "$first" =~ ^(bt|rt|bt,rt): ]] && deps_file="${dir}/${first}"
    python3 "$DEPMAP" "$deps_file" rpm 2>/dev/null || true
  done < <(find "$REPO" -name "deps" -not -path "*/.git/*") \
    | grep '^bt:' | sed 's/^bt://' | grep -v '^wintc-' | LC_ALL=C sort -u > "$OUT"

  echo "updated ${OUT}"

check-build-deps: update-build-deps
  #!/bin/bash
  set -euo pipefail
  if ! git diff --exit-code files/scripts/packages/xfce-winxp-tc/build-deps.txt > /dev/null; then
    echo "error: build-deps.txt is out of date — run 'just update-build-deps' and commit the result" >&2
    exit 1
  fi
  echo "build-deps.txt is up to date"

test-local:
  bluebuild rebase --tempdir /var/tmp recipes/recipe.yml

smoke-test:
  #!/bin/bash
  sudo podman pull ghcr.io/winblues/bluexp:latest
  bash scripts/smoke-test.sh ghcr.io/winblues/bluexp:latest

generate-iso:
  sudo bluebuild generate-iso --iso-name bluexp-latest.iso image ghcr.io/ledif/bluexp:latest

vm:
  #!/bin/bash
  mkdir output
  sudo podman pull ghcr.io/winblues/bluexp:latest
  sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v ./config.toml:/config.toml:ro \
    -v ./output:/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type qcow2 \
    --rootfs xfs \
    --use-librepo=True \
    ghcr.io/winblues/bluexp:latest
