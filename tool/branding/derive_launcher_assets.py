"""Dérivées techniques des icônes, à partir des deux sources officielles.

Usage, depuis la racine du dépôt (Python 3 + Pillow) :
    python tool/branding/derive_launcher_assets.py

Aucun redessin, aucune couleur nouvelle : `icone.png` est exactement
`logo.png` posé sur un dégradé horizontal (écart maximal : 2/255, vérifié
ci-dessous). Les dérivées ne font que recadrer, redimensionner, déplacer et
ajouter des marges :

- `icone_adaptive_foreground.png` : le wordmark de `logo.png`, recadré sur ses
  pixels visibles puis réduit pour tenir entièrement dans le cercle de 66 dp
  qu'Android garantit visible sous tous les masques (cercle, squircle,
  carré arrondi…), à la même place relative que dans `icone.png` ;
- `icone_adaptive_background.png` : le dégradé de `icone.png` (une ligne sans
  wordmark), étiré verticalement et posé sur les 72 dp visibles de l'icône
  adaptative, prolongé par ses couleurs de bord dans la marge de parallaxe ;
- `res/drawable-*/ic_stat_intellia.png` : la silhouette blanche du wordmark
  (canal alpha de `logo.png`) pour la petite icône de notification, qu'Android
  dessine d'une seule couleur.
"""

from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / "assets" / "branding"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

CANVAS = 1024
# Icône adaptative : 108 dp de calque, 72 dp visibles, 66 dp garantis.
VISIBLE = CANVAS * 72 / 108
SAFE_DIAMETER = CANVAS * 66 / 108
# Marge de sécurité dans le cercle, pour l'anticrénelage des masques.
SAFE_FILL = 0.96

NOTIFICATION_SIZES = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}


def main() -> None:
    logo = Image.open(BRANDING / "logo.png").convert("RGBA")
    icon = Image.open(BRANDING / "icone.png").convert("RGB")
    assert logo.size == icon.size, "logo.png et icone.png doivent partager leur canevas"
    width, height = icon.size

    # Le dégradé de l'icône : une ligne au-dessus du wordmark, identique sur
    # toute la hauteur (écart ≤ 1).
    gradient_row = icon.crop((0, 10, width, 11))
    rebuilt = gradient_row.resize((width, height), Image.NEAREST).convert("RGBA")
    rebuilt.alpha_composite(logo)
    difference = ImageChops.difference(rebuilt.convert("RGB"), icon)
    assert max(max(pixel) for pixel in difference.getdata()) <= 2, (
        "icone.png n'est plus logo.png sur son dégradé : revoir la dérivation"
    )

    bounds = logo.getchannel("A").getbbox()
    mark = logo.crop(bounds)
    mark_w, mark_h = mark.size

    # Premier plan : le plus grand wordmark inscrit dans le cercle garanti.
    aspect = mark_w / mark_h
    target_w = SAFE_DIAMETER * SAFE_FILL / (1 + 1 / aspect**2) ** 0.5
    scale = target_w / mark_w
    scaled = mark.resize((round(mark_w * scale), round(mark_h * scale)), Image.LANCZOS)
    # Même place relative que dans icone.png (centre du wordmark légèrement
    # au-dessus du centre), rapportée aux 72 dp visibles.
    center_x = (bounds[0] + bounds[2]) / 2 / width - 0.5
    center_y = (bounds[1] + bounds[3]) / 2 / height - 0.5
    x = round(CANVAS / 2 + center_x * VISIBLE - scaled.width / 2)
    y = round(CANVAS / 2 + center_y * VISIBLE - scaled.height / 2)
    foreground = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    foreground.alpha_composite(scaled, (x, y))
    foreground.save(BRANDING / "icone_adaptive_foreground.png", optimize=True)

    # Fond : le dégradé de l'icône sur la zone visible, bords prolongés.
    visible = round(VISIBLE)
    margin = (CANVAS - visible) // 2
    band = gradient_row.resize((visible, 1), Image.LANCZOS)
    row = Image.new("RGB", (CANVAS, 1), icon.getpixel((0, 10)))
    row.paste(Image.new("RGB", (CANVAS - margin - visible, 1), icon.getpixel((width - 1, 10))), (margin + visible, 0))
    row.paste(band, (margin, 0))
    background = row.resize((CANVAS, CANVAS), Image.NEAREST)
    background.save(BRANDING / "icone_adaptive_background.png", optimize=True)

    # Notification : silhouette blanche, 22 dp utiles sur 24.
    alpha = mark.getchannel("A")
    for density, size in NOTIFICATION_SIZES.items():
        live = size * 22 / 24
        s = live / mark_w
        glyph = alpha.resize((round(mark_w * s), max(1, round(mark_h * s))), Image.LANCZOS)
        silhouette = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        white = Image.new("RGBA", glyph.size, (255, 255, 255, 255))
        white.putalpha(glyph)
        silhouette.alpha_composite(
            white, ((size - glyph.width) // 2, (size - glyph.height) // 2)
        )
        target = RES / f"drawable-{density}" / "ic_stat_intellia.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        silhouette.save(target, optimize=True)

    print(f"wordmark {mark_w}×{mark_h} → premier plan {scaled.width}×{scaled.height} à ({x}, {y})")


if __name__ == "__main__":
    main()
