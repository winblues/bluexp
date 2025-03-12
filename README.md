# BlueXP

Testing ground for Fedora Atomic Xfce + [rozniak/xfce-winxp-tc](https://github.com/rozniak/xfce-winxp-tc).

![image](https://github.com/user-attachments/assets/67f17db7-629d-4abd-8b98-d517382357e5)

## Installation

> [!WARNING]  
> This project is in alpha and there are many rough edges. Please do not install this on a machine that you care about.

1. Install any Fedora Atomic edition using the normal ISO method. For an Xfce-specific ISO, you can use the one at https://github.com/winblues/vauxite.
2. Once booted, rebase to this image:
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/winblues/bluexp:latest
```
