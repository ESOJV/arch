#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — bring up jose's Hyprland rice on a fresh EndeavourOS/Arch
# install, migrated 1:1 from the old NixOS + home-manager config.
#
# Usage (on the freshly installed machine, as user `jose`):
#   sudo pacman -S --needed git
#   git clone https://github.com/ESOJV/arch ~/arch
#   ~/arch/bootstrap.sh
#
# Safe to re-run — every step is idempotent (--needed, symlink -f, markers).
# Nothing here aborts the whole run on a single package miss; failures are
# collected and printed at the end so you can fix package names and re-run.
# =============================================================================
set -uo pipefail

REPO="$HOME/arch"
DOTS="$REPO"
FAILED=()

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*"; }
note() { printf '\033[1;34m  -\033[0m %s\n' "$*"; }

[[ -d "$DOTS" ]] || { warn "Expected dotfiles at $DOTS — clone the repo to ~/arch first."; exit 1; }
[[ $EUID -eq 0 ]] && { warn "Run as your normal user (not root); sudo is used where needed."; exit 1; }

# -----------------------------------------------------------------------------
# 0. Base system update + build prerequisites
# -----------------------------------------------------------------------------
log "Updating system & installing base-devel (needed for AUR builds)…"
sudo pacman -Syu --needed --noconfirm base-devel git

# -----------------------------------------------------------------------------
# 1. AUR helper (EndeavourOS ships yay; fall back to building paru)
# -----------------------------------------------------------------------------
if command -v yay >/dev/null 2>&1; then
  AUR=yay
elif command -v paru >/dev/null 2>&1; then
  AUR=paru
else
  log "No AUR helper found — building paru…"
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  ( cd "$tmp/paru-bin" && makepkg -si --noconfirm )
  rm -rf "$tmp"
  AUR=paru
fi
note "Using AUR helper: $AUR"

# -----------------------------------------------------------------------------
# 2. Official-repo packages (translated from home.nix + host configuration.nix)
# -----------------------------------------------------------------------------
PACMAN=(
  # --- Hyprland session + Wayland desktop pieces ---
  hyprland xdg-desktop-portal-hyprland hyprpolkitagent
  waybar wofi mako brightnessctl
  grim slurp wl-clipboard wtype cliphist
  qt5-wayland qt6-wayland polkit xdg-user-dirs
  # --- terminal / editors / CLI (home.nix) ---
  kitty bat btop fastfetch fzf tree tmux wget unzip ripgrep fd
  neovim emacs psmisc            # psmisc = killall
  git direnv expect socat
  # --- build / embedded toolchain (home.nix) ---
  cmake ninja ccache gdb strace gperf dfu-util rust-analyzer
  # --- disk / filesystem tools (home.nix) ---
  parted ntfs-3g exfatprogs dosfstools gptfdisk util-linux
  # --- audio: pipewire stack (host pipewire{alsa,pulse,jack}) ---
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
  pavucontrol easyeffects
  # --- file manager (host programs.thunar) ---
  thunar thunar-archive-plugin thunar-volman tumbler gvfs
  # --- Intel graphics / VAAPI (host hardware.graphics) ---
  mesa vulkan-intel intel-media-driver libva-utils intel-ucode
  # --- laptop/firmware/power (host: thermald, fwupd, tlp) ---
  thermald fwupd tlp
  # --- networking / ssh (host) ---
  networkmanager network-manager-applet openssh bluez bluez-utils blueman
  # --- browser + theming (home.nix firefox/gtk/cursor) ---
  firefox papirus-icon-theme
  # --- fonts (home.nix) ---
  ttf-jetbrains-mono-nerd ttf-font-awesome otf-font-awesome noto-fonts noto-fonts-emoji
  # --- GUI apps (native, per your choice) ---
  discord
)

log "Installing ${#PACMAN[@]} official-repo packages…"
for p in "${PACMAN[@]}"; do
  sudo pacman -S --needed --noconfirm "$p" || FAILED+=("pacman:$p")
done

# -----------------------------------------------------------------------------
# 3. AUR packages
# -----------------------------------------------------------------------------
# Confident AUR names:
AUR_PKGS=(
  adw-gtk3                 # GTK3 theme (host gtk.theme)
  apple-cursor             # macOS cursor (home.pointerCursor)
  spotify                  # host allowUnfree app
  claude-code              # home.nix
  moonlight-qt             # home.nix (game streaming; AUR, not official repos)
)
# VERIFY these names before trusting them — they're the walker ecosystem + agents
# that weren't in nixpkgs. If a build fails it lands in the summary below.
# Check exact names with:  yay -Ss walker ; yay -Ss elephant ; yay -Ss awww ; yay -Ss codex
AUR_VERIFY=(
  walker-bin               # launcher (hypr: walker --gapplication-service / -m clipboard)
  elephant                 # walker data-provider backend (newer walker needs it)
  awww                     # wallpaper daemon (hypr: exec-once = awww-daemon)
  codex-bin                # OpenAI Codex CLI (you pinned 0.153.4 via overlay — AUR may differ)
)

log "Installing AUR packages…"
for p in "${AUR_PKGS[@]}" "${AUR_VERIFY[@]}"; do
  "$AUR" -S --needed --noconfirm "$p" || FAILED+=("aur:$p")
done

note "Not packaged anywhere — install manually after bootstrap:"
note "  herdr          (agent multiplexer)  — build from source / your own release"
note "  pi-coding-agent (pi)                 — BYOK agent, install per upstream"

# -----------------------------------------------------------------------------
# 4. Dotfile symlinks (replaces home-manager's out-of-store symlinks)
# -----------------------------------------------------------------------------
log "Linking dotfiles from $DOTS …"
mkdir -p "$HOME/.config/herdr"
link() {  # link <target> <linkname>
  ln -sfnT "$1" "$2" && note "$2 -> $1"
}
link "$DOTS/nvim"              "$HOME/.config/nvim"
link "$DOTS/kitty"             "$HOME/.config/kitty"
link "$DOTS/hypr"              "$HOME/.config/hypr"
link "$DOTS/tmux"              "$HOME/.config/tmux"
link "$DOTS/waybar"            "$HOME/.config/waybar"
link "$DOTS/wofi"              "$HOME/.config/wofi"
link "$DOTS/mako"              "$HOME/.config/mako"
link "$DOTS/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link "$DOTS/scripts"           "$HOME/scripts"
# bash (migrated from home.nix)
link "$DOTS/bash/bashrc"       "$HOME/.bashrc"
link "$DOTS/bash/bash_profile" "$HOME/.bash_profile"

# -----------------------------------------------------------------------------
# 5. GTK theming + cursor (home.nix gtk / pointerCursor / dconf)
# -----------------------------------------------------------------------------
log "Writing GTK theme + cursor settings…"
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
GTK_INI='[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=macOS
gtk-cursor-theme-size=24
gtk-font-name=JetBrainsMono Nerd Font Propo 11
gtk-application-prefer-dark-theme=1'
printf '%s\n' "$GTK_INI" > "$HOME/.config/gtk-3.0/settings.ini"
printf '%s\n' "$GTK_INI" > "$HOME/.config/gtk-4.0/settings.ini"

# Monochrome accent override (home.nix gtk3/gtk4 extraCss)
GTK_CSS='@define-color accent_color #efefef;
@define-color accent_bg_color #3a3a3a;
@define-color accent_fg_color #efefef;'
printf '%s\n' "$GTK_CSS" > "$HOME/.config/gtk-3.0/gtk.css"
printf '%s\n' "$GTK_CSS" > "$HOME/.config/gtk-4.0/gtk.css"

# libadwaita / GTK4 dark preference (home.nix dconf color-scheme)
command -v gsettings >/dev/null 2>&1 && \
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

# -----------------------------------------------------------------------------
# 6. Firefox policy (home.nix programs.firefox extensions + prefs)
# -----------------------------------------------------------------------------
log "Installing Firefox enterprise policy (extensions + prefs)…"
sudo mkdir -p /etc/firefox/policies
sudo tee /etc/firefox/policies/policies.json >/dev/null <<'JSON'
{
  "policies": {
    "ExtensionSettings": {
      "uBlock0@raymondhill.net": {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
        "installation_mode": "force_installed"
      },
      "{446900e4-71c2-419f-a6a7-df9c091e268b}": {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi",
        "installation_mode": "force_installed"
      },
      "{d7742d87-e61d-4b78-b8a1-b469842139fa}": {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi",
        "installation_mode": "force_installed"
      },
      "addon@darkreader.org": {
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi",
        "installation_mode": "force_installed"
      }
    },
    "Preferences": {
      "browser.aboutConfig.showWarning": { "Value": false, "Status": "user" },
      "browser.startup.page": { "Value": 3, "Status": "user" },
      "ui.systemUsesDarkTheme": { "Value": 1, "Status": "user" },
      "browser.newtabpage.activity-stream.showSponsored": { "Value": false, "Status": "user" },
      "browser.newtabpage.activity-stream.showSponsoredTopSites": { "Value": false, "Status": "user" },
      "widget.wayland.fractional-scale.enabled": { "Value": false, "Status": "user" }
    }
  }
}
JSON

# -----------------------------------------------------------------------------
# 7. System services + groups
# -----------------------------------------------------------------------------
log "Enabling system services…"
sudo systemctl enable --now NetworkManager.service      || FAILED+=("svc:NetworkManager")
sudo systemctl enable --now bluetooth.service           || FAILED+=("svc:bluetooth")
sudo systemctl enable --now thermald.service            || FAILED+=("svc:thermald")
sudo systemctl enable --now fwupd.service               || true
sudo systemctl enable --now sshd.service                || FAILED+=("svc:sshd")
# TLP conflicts with power-profiles-daemon — mask the latter (host config).
sudo systemctl mask power-profiles-daemon.service 2>/dev/null || true
sudo systemctl enable --now tlp.service                 || FAILED+=("svc:tlp")

log "Adding $USER to groups (video input dialout wheel networkmanager)…"
sudo usermod -aG wheel,network,video,input,dialout "$USER" 2>/dev/null || true

# -----------------------------------------------------------------------------
# 8. TTY1 autologin -> Hyprland (your chosen greeter: none)
# -----------------------------------------------------------------------------
log "Configuring getty autologin on tty1 (.bash_profile exec's Hyprland)…"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
sudo systemctl daemon-reload

# -----------------------------------------------------------------------------
# 9. OpenSSH hardening (host: key-only, no root) + restore your keys
# -----------------------------------------------------------------------------
if [[ -d "$HOME/.ssh" ]]; then
  chmod 700 "$HOME/.ssh"; chmod 600 "$HOME/.ssh/"* 2>/dev/null || true
fi
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf >/dev/null <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sudo systemctl try-reload-or-restart sshd.service 2>/dev/null || true

# -----------------------------------------------------------------------------
# Done — summary
# -----------------------------------------------------------------------------
echo
log "Bootstrap complete."
echo
warn "Hyprland config note (not a blocker):"
note "Arch ships Hyprland 0.55+, which deprecated hyprlang in favor of Lua. Your"
note "hypr/hyprland.conf STILL LOADS (hyprlang has a 1-2 release grace period) and"
note "already uses the 0.53+ v3 window-rule syntax, so expect it to just work."
note "Test with: Hyprland   |   Convert to Lua later with hyprconf2lua (see MIGRATION.md)."
echo
note "Copy your SSH private keys into ~/.ssh manually (not in the repo)."
note "Set your password: passwd"
note "Flatpak apps (orca-slicer, bambu-studio) if needed:"
note "  sudo pacman -S --needed flatpak && flatpak install flathub com.softfever3d.orca-slicer com.bambulab.BambuStudio"
echo
if ((${#FAILED[@]})); then
  warn "These items failed (fix names / investigate, then re-run — it's idempotent):"
  for f in "${FAILED[@]}"; do note "$f"; done
else
  log "No failures. Reboot and you should land straight in Hyprland on tty1."
fi
