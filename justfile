build:
  bluebuild build -B podman --tempdir /var/tmp recipes/recipe.yml

test-local:
  bluebuild rebase --tempdir /var/tmp recipes/recipe.yml

test-smoke:
  #!/bin/bash
  podman pull ghcr.io/winblues/bluexp:latest
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
     --use-librepo=True \
    ghcr.io/winblues/bluexp:latest
