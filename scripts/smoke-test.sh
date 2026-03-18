#!/bin/bash
set -euo pipefail

# Usage: smoke-test.sh <image-reference>
# Boots the given bootc container image in QEMU and verifies system health.
IMAGE="${1:?Usage: $0 <image-reference>}"

WORK_DIR="$(mktemp -d)"
QEMU_PID=""

cleanup() {
    local exit_code=$?
    if [[ -n "$QEMU_PID" ]]; then
        kill "$QEMU_PID" 2>/dev/null || true
    fi
    rm -rf "$WORK_DIR"
    exit "$exit_code"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1"
    exit 1
}

# Generate a throwaway ed25519 SSH keypair for this run
ssh-keygen -t ed25519 -f "${WORK_DIR}/smoke-key" -N "" -C "smoke-test" >/dev/null
PUBKEY="$(cat "${WORK_DIR}/smoke-key.pub")"

# Write a test-specific bootc-image-builder config with the generated public key
cat > "${WORK_DIR}/config.toml" <<EOF
[[customizations.user]]
name = "core"
groups = ["wheel"]
key = "${PUBKEY}"
EOF

# Convert the container image to a QCOW2 using bootc-image-builder
mkdir -p "${WORK_DIR}/output"
sudo podman run \
    --rm \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v "${WORK_DIR}/config.toml:/config.toml:ro" \
    -v "${WORK_DIR}/output:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type qcow2 \
    --use-librepo=True \
    "${IMAGE}"

QCOW2="${WORK_DIR}/output/qcow2/disk.qcow2"
if [[ ! -f "$QCOW2" ]]; then
    fail "No QCOW2 found at ${QCOW2} after image conversion"
fi

# Boot the QCOW2 with QEMU, forwarding host port 2222 to guest port 22
qemu-system-x86_64 \
    -m 4096 \
    -smp 2 \
    -drive "file=${QCOW2},format=qcow2" \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic &
QEMU_PID=$!

# Poll SSH on port 2222 with a 5-minute timeout
TIMEOUT=300
ELAPSED=0
echo "Waiting for SSH on port 2222 (timeout: ${TIMEOUT}s)..."
while ! ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -o BatchMode=yes \
        -i "${WORK_DIR}/smoke-key" \
        -p 2222 \
        core@localhost \
        true 2>/dev/null; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [[ $ELAPSED -ge $TIMEOUT ]]; then
        fail "SSH unreachable after ${TIMEOUT}s"
    fi
done

echo "SSH reachable after ${ELAPSED}s, checking system health..."

run_ssh() {
    ssh \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        -o BatchMode=yes \
        -i "${WORK_DIR}/smoke-key" \
        -p 2222 \
        core@localhost \
        "$@"
}

# Verify overall system state (running or degraded are both acceptable)
SYSTEM_STATUS="$(run_ssh 'systemctl is-system-running' 2>/dev/null || true)"
if [[ "$SYSTEM_STATUS" != "running" && "$SYSTEM_STATUS" != "degraded" ]]; then
    fail "systemctl is-system-running returned '${SYSTEM_STATUS}' (expected: running or degraded)"
fi

# Verify the display manager is active
LIGHTDM_STATUS="$(run_ssh 'systemctl is-active lightdm' 2>/dev/null || true)"
if [[ "$LIGHTDM_STATUS" != "active" ]]; then
    fail "lightdm not active (systemctl is-active returned: '${LIGHTDM_STATUS}')"
fi

echo "PASS"
