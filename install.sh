#!/usr/bin/env bash
# Xenoglyph — SDDM Login: install.  ./install.sh
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[[ $EUID -eq 0 ]] || { echo "run with sudo: sudo ./install.sh" >&2; exit 1; }
DST=/usr/share/sddm/themes/xenoglyph
rm -rf "$DST"; mkdir -p "$DST"
for f in "$HERE"/* "$HERE"/.[!.]*; do
    [[ -e $f ]] || continue
    case ${f##*/} in README.md|LICENSE|install.sh|screenshots|.git) continue ;; esac
    cp -r "$f" "$DST"/
done
chmod -R a+rX "$DST"
found=0
for f in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
    if [[ -f $f ]] && grep -q '^Current=' "$f"; then sed -i 's/^Current=.*/Current=xenoglyph/' "$f"; found=1; fi
done
(( found )) || { mkdir -p /etc/sddm.conf.d; printf '[Theme]\nCurrent=xenoglyph\n' > /etc/sddm.conf.d/xenoglyph.conf; }
echo "Installed. Test without logging out: sddm-greeter-qt6 --test-mode --theme $DST"
