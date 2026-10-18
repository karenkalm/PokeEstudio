"""Genera el favicon y los íconos de la versión web a partir del logotipo
original de PokéStudio (el mismo dibujo que `_LogoMarkPainter`).

Uso:  python tool/generate_web_icons.py   (requiere Pillow)
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "web"

RETRO_BROWN = (0x56, 0x3B, 0x2B, 255)
WARM_CREAM = (0xFF, 0xF7, 0xE8, 255)
SKY_BLUE = (0xBB, 0xDF, 0xFF, 255)
POKE_BLUE = (0x4B, 0x8F, 0xE8, 255)
WHITE = (255, 255, 255, 255)
POKE_RED = (0xE9, 0x4B, 0x4B, 255)
PIKACHU_YELLOW = (0xFF, 0xD9, 0x5A, 255)
GRASS_GREEN = (0x8B, 0xCF, 0x9B, 255)
SUPERSAMPLE = 4


def _with_alpha(color, alpha):
    return color[:3] + (int(255 * alpha),)


def _circle(draw, cx, cy, r, fill):
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)


def draw_mark(size: int, padding: float = 0.0, background=None) -> Image.Image:
    """Dibuja el logotipo en un lienzo cuadrado de `size` px.

    `padding` (0–0.5) deja margen alrededor (íconos "maskable")."""
    big = size * SUPERSAMPLE
    img = Image.new("RGBA", (big, big), background or (0, 0, 0, 0))
    inner = big * (1 - 2 * padding)
    ox = oy = big * padding
    s = inner

    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # Cuerpo.
    d.rounded_rectangle((ox, oy, ox + s, oy + s), radius=s * 0.26, fill=RETRO_BROWN)
    # Los detalles translúcidos van en su propia capa: ImageDraw reemplaza
    # los píxeles en vez de mezclarlos.
    glaze = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    g = ImageDraw.Draw(glaze)
    m = s * 0.06
    g.rounded_rectangle(
        (ox + m, oy + m, ox + s - m, oy + s - m),
        radius=s * 0.2,
        outline=_with_alpha(WARM_CREAM, 0.18),
        width=max(1, int(s * 0.035)),
    )
    # Lente.
    lx, ly = ox + s * 0.38, oy + s * 0.42
    _circle(d, lx, ly, s * 0.25, WARM_CREAM)
    # Degradado radial sencillo (cielo → azul).
    steps = 24
    for i in range(steps):
        t = i / (steps - 1)
        r = s * 0.185 * (1 - t * 0.85)
        color = tuple(int(POKE_BLUE[k] + (SKY_BLUE[k] - POKE_BLUE[k]) * t) for k in range(3)) + (255,)
        cx = lx - s * 0.03 * t
        cy = ly - s * 0.035 * t
        _circle(d, cx, cy, r, color)
    _circle(d, lx - s * 0.06, ly - s * 0.06, s * 0.05, WHITE)
    # Luces.
    for i, color in enumerate((POKE_RED, PIKACHU_YELLOW, GRASS_GREEN)):
        _circle(d, ox + s * 0.78, oy + s * (0.24 + i * 0.17), s * 0.06, color)
    # Rejilla pixel.
    for i in range(3):
        x = ox + s * (0.2 + i * 0.12)
        y = oy + s * 0.8
        g.rectangle((x, y, x + s * 0.07, y + s * 0.07), fill=_with_alpha(WARM_CREAM, 0.55))

    img = Image.alpha_composite(img, layer)
    img = Image.alpha_composite(img, glaze)
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    (WEB / "icons").mkdir(parents=True, exist_ok=True)
    draw_mark(64).save(WEB / "favicon.png")
    draw_mark(192).save(WEB / "icons" / "Icon-192.png")
    draw_mark(512).save(WEB / "icons" / "Icon-512.png")
    # Los "maskable" necesitan fondo y margen (zona segura del 80 %).
    draw_mark(192, padding=0.14, background=WARM_CREAM).save(WEB / "icons" / "Icon-maskable-192.png")
    draw_mark(512, padding=0.14, background=WARM_CREAM).save(WEB / "icons" / "Icon-maskable-512.png")
    print("Íconos web generados en", WEB)


if __name__ == "__main__":
    main()
