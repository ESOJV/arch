# NixOS → EndeavourOS migration runbook

Framework 13 (Intel Meteor Lake / Arc). Goal: same Hyprland rice, no Nix.
This repo (`github.com/ESOJV/arch`) is a standalone, Nix-free dotfiles + setup
repo: portable app configs at the top level (`hypr/`, `waybar/`, …), the bash
config migrated out of the old `home.nix` (`bash/`), and `bootstrap.sh` which
installs/links everything on a fresh machine.

## 0. Back up first (from the current NixOS install)
- Push this repo: `git -C ~/arch add -A && git -C ~/arch commit -m init && git -C ~/arch push -u origin main`
- Copy OFF-machine (NOT in git): `~/.ssh/` private keys, `~/Downloads`, `~/notes`,
  `~/project`, `~/pi`. Firefox logins are in Bitwarden, so those come back on sign-in.
- Record disk UUIDs if dual-booting: `lsblk -f`.

## 1. Flash the EndeavourOS USB (isohybrid → dd)
```bash
sudo umount /dev/sdX* 2>/dev/null
sudo dd if=~/Downloads/EndeavourOS_Titan-Nova-*.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
sync
```
Replace `/dev/sdX` with the USB device from `lsblk` (the ~29 GB USB disk, NOT the
931 GB `nvme0n1` system disk).

## 2. Install EndeavourOS
1. Boot the USB (disable Secure Boot in BIOS if it won't boot).
2. In the Calamares online installer:
   - Desktop: **"No desktop (base)"** — you bring your own Hyprland.
   - Bootloader: **systemd-boot** (UEFI; matches your old setup).
   - Filesystem: ext4 (what you had) or btrfs for snapshots.
   - User: `jose`, hostname `framework-13`.
3. Reboot into the new system.

## 3. Bootstrap the rice
```bash
sudo pacman -Syu --needed git
git clone https://github.com/ESOJV/arch ~/arch
~/arch/bootstrap.sh
```
Installs all packages (repo + AUR), links every dotfile, writes GTK/cursor/Firefox
settings, enables services (pipewire, tlp, bluetooth, sshd, thermald, fwupd), and
sets up TTY1 autologin → Hyprland. Idempotent — safe to re-run.

## 4. Post-bootstrap
- `passwd` — set a real password.
- Copy SSH private keys back into `~/.ssh` (`chmod 600`).
- Reboot → you should land straight in Hyprland on tty1.

## Known gotchas (read before cursing)

### Hyprland: hyprlang → Lua (NOT a blocker)
Hyprland 0.55+ deprecated the old hyprlang config language in favor of Lua
(`~/.config/hypr/hyprland.lua`). **Your `hypr/hyprland.conf` still loads** — if no
`hyprland.lua` exists, Hyprland falls back to the `.conf`, and hyprlang is kept for
~1–2 releases after 0.55 before removal. Your config already uses the newer 0.53+
v3 window-rule block syntax, so expect it to work as-is. Launch `Hyprland` once and
read any parse warnings.
- Convert to Lua when you're ready: the official **`hyprconf2lua`** converter
  auto-translates ~97% of a `hyprland.conf`. See the announcement
  <https://hypr.land/news/26_lua/> and the wiki's config pages.
- Watch item: named v3 window rules (`name = …` inside the block) have had edge-case
  bugs upstream; if a rule (e.g. the Spotify/Nvim scratchpads) misbehaves, that's the
  first place to look.

### walker / elephant / awww (AUR, names unverified)
These weren't in nixpkgs but ARE in the AUR under names that vary. `bootstrap.sh`
tries `walker-bin`, `elephant`, `awww`, `codex-bin` and REPORTS failures instead of
aborting. Verify + fix:
```bash
yay -Ss walker ; yay -Ss elephant ; yay -Ss awww ; yay -Ss codex
```
Then re-run the script or `yay -S <correct-name>`.

### Not packaged anywhere
`herdr` and `pi-coding-agent` (`pi`) have no repo/AUR package — install from upstream
after bootstrap.

### Framework specifics
- `fwupdmgr get-updates && fwupdmgr update` — pull Framework firmware early.
- Fingerprint reader (if used): `sudo pacman -S fprintd && fprintd-enroll`.
- TLP is enabled; power-profiles-daemon is masked (don't run both).
- Suspend-then-hibernate (your old 45-min setup) isn't configured by the script. To
  restore: set `HibernateDelaySec=45min` in `/etc/systemd/sleep.conf` and add a
  `resume=` kernel param pointing at your swap. Add only if you want hibernation back.

### Flatpak apps
OrcaSlicer / BambuStudio run via flatpak (aliases in `bash/bashrc`):
```bash
sudo pacman -S flatpak
flatpak install flathub com.softfever3d.orca-slicer com.bambulab.BambuStudio
```

## What maps where (NixOS → Arch)
| NixOS / home-manager                | Arch equivalent                         |
|-------------------------------------|-----------------------------------------|
| `home.packages`                     | `pacman`/AUR list in `bootstrap.sh`     |
| `home.file.*` out-of-store symlinks | `ln -sfnT` in bootstrap step 4          |
| `programs.bash.initExtra/aliases`   | `bash/bashrc`                           |
| `programs.bash.profileExtra`        | `bash/bash_profile` (tty1 exec Hyprland)|
| `programs.firefox.policies`         | `/etc/firefox/policies/policies.json`   |
| `gtk` / `home.pointerCursor`        | `~/.config/gtk-{3,4}.0` + gsettings     |
| `services.*` (host config)          | `systemctl enable` in bootstrap step 7  |
| `services.displayManager.ly`        | getty autologin → Hyprland (step 8)     |
| `nixos-rebuild switch`              | `sudo pacman -Syu` + re-run bootstrap   |
