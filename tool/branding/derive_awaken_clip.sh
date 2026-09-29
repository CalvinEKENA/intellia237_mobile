#!/usr/bin/env bash
# Dérive le clip du lancement INTELLIA AWAKENS (assets/branding/cinematic/
# splash_awaken_e.mp4) à partir de la génération Higgsfield brute.
#
# Usage : bash tool/branding/derive_awaken_clip.sh SOURCE.mp4 [SORTIE.mp4]
#
# SOURCE : la génération « V1 » (Higgsfield, modèle Wan 3.0, 9:16, 3 s,
# 720×1280 H.264, sans étiquette colorimétrique, job 7fea0137, 29/09/2026).
# Elle n'est pas versionnée (3,4 Mo, non retenue telle quelle) ; le résultat
# de ce script, lui, l'est (357 Ko).
#
# Ce que fait le traitement « E » (validé sur TECNO CL6k) : il ne garde que la
# STRUCTURE FINE du clip (arêtes et reflets du verre) posée sur le dégradé de
# marque, et supprime la teinte grise et l'assombrissement de la génération :
#   1. passe-haut : image − flou gaussien (σ = 28 px), gain 1,07 ;
#   2. base : le dégradé de marque de BrandLaunchPalette (mint → surface
#      #F2F9FC → pervenche, diagonale) ;
#   3. flou léger (σ ≈ 2,3 px à 720 px, ≈ 1,4 px à l'écran) qui dissout les
#      arêtes en forme de lettres ;
#   4. 540×960, H.264 High, 30 fps, 2,5 s, sans audio, bt709 tv, une image clé
#      toutes les 15 images.
# Le voile 45 %, le centre calme 50 %, l'échelle 1,10 et les fondus restent en
# Flutter (LaunchMatter, LaunchMotion.matterPresence).
#
# Le clip ne contient AUCUN logo, texte ni interface : le logo officiel
# (assets/branding/logo.png), le Pass et tout texte sont rendus par Flutter.
set -euo pipefail

SRC="${1:?usage: derive_awaken_clip.sh SOURCE.mp4 [SORTIE.mp4]}"
OUT="${2:-assets/branding/cinematic/splash_awaken_e.mp4}"
FFMPEG="${FFMPEG:-ffmpeg}"

GRAPH="$(mktemp)"
trap 'rm -f "$GRAPH"' EXIT

# Dégradé de marque : mint #F6FFF8 → surface #F2F9FC → pervenche #E7F0FF, sur la
# diagonale (t = (x·L + y·H) / (L² + H²)), comme BrandLaunchPalette.backdrop.
cat > "$GRAPH" <<'FILTER'
[0:v]scale=in_color_matrix=bt709:in_range=tv,format=gbrp,split[a][b];
[b]gblur=sigma=28:steps=3[low];
[a][low]blend=all_expr='clip(A-B+128,0,255)'[d];
nullsrc=s=720x1280:r=30,format=gbrp,geq=r='st(0,(X*720+Y*1280)/2156800);if(lt(ld(0),0.5),246-4*ld(0)/0.5,242-11*(ld(0)-0.5)/0.5)':g='st(0,(X*720+Y*1280)/2156800);if(lt(ld(0),0.5),255-6*ld(0)/0.5,249-9*(ld(0)-0.5)/0.5)':b='st(0,(X*720+Y*1280)/2156800);if(lt(ld(0),0.5),248+4*ld(0)/0.5,252+3*(ld(0)-0.5)/0.5)'[base];
[base][d]blend=all_expr='clip(A+1.07*(B-128),0,255)':shortest=1[hp];
[hp]gblur=sigma=2.3:steps=2,scale=540:960:flags=lanczos:out_color_matrix=bt709:out_range=tv,format=yuv420p[out]
FILTER

"$FFMPEG" -hide_banner -loglevel error -y -i "$SRC" \
  -filter_complex_script "$GRAPH" -map "[out]" -t 2.5 -r 30 \
  -c:v libx264 -preset slow -crf 20 -profile:v high -level 3.1 -pix_fmt yuv420p \
  -g 15 -keyint_min 15 -sc_threshold 0 -bf 2 \
  -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv \
  -movflags +faststart -an "$OUT"

echo "ok : $OUT ($(wc -c < "$OUT") octets)"
