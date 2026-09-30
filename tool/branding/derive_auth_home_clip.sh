#!/usr/bin/env bash
# Dérive le clip de la traversée Authentification → Home (assets/branding/
# cinematic/auth_home_matter.mp4) à partir de la génération Higgsfield brute.
#
# Usage : bash tool/branding/derive_auth_home_clip.sh SOURCE.mp4 [SORTIE.mp4]
#
# SOURCE : la génération Higgsfield (modèle Wan 3.0, 9:16, 2 s, 480×854 H.264,
# 30 fps, job 0388c697, 29/09/2026, 2,0 crédits). Elle n'est pas versionnée
# (1,5 Mo) ; le résultat de ce script, lui, l'est (239 Ko).
#
# Ce que fait le traitement :
#   1. accélération ×2,5 : 2 s → 0,8 s (la traversée dure moins d'une seconde) ;
#   2. étalonnage vers le crème de l'accès (AuthExperienceColors.canvas
#      #FBF8F1) : la génération est beige, gains r 1,12 / g 1,17 / b 1,24 ;
#   3. fondu vers le crème #FBF8F1 sur les 0,24 dernières secondes : la
#      dernière image EST la surface du Home, elle disparaît dessous sans
#      raccord ;
#   4. 480×854, H.264 High, 30 fps, sans audio, bt709 tv, une image clé toutes
#      les 12 images.
# Le fondu d'entrée (0 → 110 ms) et l'émergence du Home restent en Flutter
# (AuthHomeMotion, HomeArrivalTransition).
#
# Le clip ne contient AUCUN logo, texte ni interface : le PASS, le prénom, la
# classe et le Home sont rendus par Flutter.
set -euo pipefail

SRC="${1:?usage: derive_auth_home_clip.sh SOURCE.mp4 [SORTIE.mp4]}"
OUT="${2:-assets/branding/cinematic/auth_home_matter.mp4}"
FFMPEG="${FFMPEG:-ffmpeg}"

"$FFMPEG" -hide_banner -loglevel error -y -i "$SRC" -an \
  -vf "setpts=0.4*PTS,fps=30,colorchannelmixer=rr=1.12:gg=1.17:bb=1.24,fade=t=out:st=0.56:d=0.24:color=0xFBF8F1,scale=480:854:out_color_matrix=bt709:out_range=tv,format=yuv420p" \
  -c:v libx264 -preset veryslow -crf 22 -g 12 -bf 0 \
  -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv \
  -movflags +faststart "$OUT"

echo "ok : $OUT ($(wc -c < "$OUT") octets)"
