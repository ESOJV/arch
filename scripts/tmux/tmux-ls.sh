#!/usr/bin/env bash
# tmux-ls — interactive tmux session picker + project sessionizer.
#
#   * lists existing tmux sessions
#   * lists project directories (one level under the roots below)
#   * opening a directory creates (or reuses) a session NAMED AFTER that
#     directory, e.g. ~/project/zephyr-learn -> session "zephyr-learn"
#
# Works whether or not you're already inside tmux. Bound to the `tls` alias.
set -euo pipefail

# parent_dirs: their immediate children are each treated as a project.
# extra_dirs:  each is itself a single project entry.
parent_dirs=("$HOME/project")
extra_dirs=("$HOME/nix")

# Emit tab-delimited rows:  kind <tab> label <tab> payload
emit_dir() { local d="${1%/}"; printf 'dir\t   %s\t%s\n' "${d/#$HOME/\~}" "$d"; }

entries() {
  tmux list-sessions -F "sess"$'\t'"  #S"$'\t'"#S" 2>/dev/null || true
  fd --type d --min-depth 1 --max-depth 1 --absolute-path . "${parent_dirs[@]}" 2>/dev/null \
    | while read -r d; do emit_dir "$d"; done
  for d in "${extra_dirs[@]}"; do [ -d "$d" ] && emit_dir "$d"; done
}

choice="$(entries | fzf --reverse --height=45% \
  --delimiter='\t' --with-nth=2 \
  --prompt='session> ' \
  --preview='case {1} in
      sess) tmux list-windows -t {3} ;;
      dir)  ls -la {3} ;;
    esac')" || exit 0
[ -z "$choice" ] && exit 0

kind="$(cut -f1 <<<"$choice")"
payload="$(cut -f3 <<<"$choice")"

if [ "$kind" = "sess" ]; then
  name="$payload"; dir=""
else
  dir="$payload"
  # tmux uses '.' and ':' as target separators, so sanitize them out of names.
  name="$(basename "$dir" | tr '.:' '__')"
fi

tmux has-session -t "=$name" 2>/dev/null \
  || tmux new-session -d -s "$name" ${dir:+-c "$dir"}

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$name"
else
  tmux attach -t "=$name"
fi
