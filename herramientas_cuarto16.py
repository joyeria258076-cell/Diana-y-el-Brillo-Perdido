# -*- coding: utf-8 -*-
"""Un cuarto armado con el DungeonTileset II (0x72), que es CC0.

La idea es probar si Diana, redibujada a 16x28, encaja de verdad dentro de
un escenario hecho con tiles de 16x16. Es la unica forma de saberlo: verla
parada ahi dentro.

Detalles que le dan el aire de los juegos de esta clase:
  - Muros altos de 16x32 arriba, para que se vea la pared con altura y no
    una linea plana.
  - Piso con variantes salteadas, para que no se note el patron repetido.
  - Antorchas que iluminan, y el resto del cuarto en penumbra.
"""
import os
import random
from PIL import Image

T = 16
BASE = ("C:/Users/uriel/Downloads/Material videojuego/"
        "0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7")
SALIDA = os.path.dirname(os.path.abspath(__file__))

PISOS = Image.open(os.path.join(BASE, "atlas_floor-16x16.png")).convert("RGBA")
ALTOS = Image.open(
    os.path.join(BASE, "atlas_walls_high-16x32.png")).convert("RGBA")
BAJOS = Image.open(
    os.path.join(BASE, "atlas_walls_low-16x16.png")).convert("RGBA")


def tile(hoja, col, fila, ancho=1, alto=1, celda=T, celda_alto=None):
    celda_alto = celda_alto or celda
    return hoja.crop((col * celda, fila * celda_alto,
                      (col + ancho) * celda, (fila + alto) * celda_alto))


# Piso: tres variantes normales y tres picadas, para salpicar.
PISO = [tile(PISOS, c, f) for c, f in ((0, 0), (1, 0), (2, 0))]
PISO_ROTO = [tile(PISOS, c, f) for c, f in ((0, 1), (1, 1), (2, 1))]

# Muros. El de arriba mide 16x32: la cara de ladrillo mas su remate.
MURO_ARRIBA = tile(ALTOS, 1, 0, celda=T, celda_alto=T * 2)
MURO_ESQ_IZQ = tile(ALTOS, 0, 0, celda=T, celda_alto=T * 2)
MURO_ESQ_DER = tile(ALTOS, 0, 0, celda=T, celda_alto=T * 2).transpose(
    Image.FLIP_LEFT_RIGHT)
MURO_LADO = tile(BAJOS, 0, 1)
MURO_ABAJO = tile(BAJOS, 1, 0)

ANCHO, ALTO = 24, 14


def cuarto(semilla=20221056):
    rnd = random.Random(semilla)
    im = Image.new("RGBA", (ANCHO * T, ALTO * T), (22, 20, 28, 255))

    # Piso con variantes salteadas.
    for y in range(2, ALTO - 1):
        for x in range(1, ANCHO - 1):
            elegido = rnd.choice(PISO if rnd.random() > 0.12 else PISO_ROTO)
            im.paste(elegido, (x * T, y * T))

    # Muro de arriba: alto, ocupa dos filas de tiles.
    for x in range(ANCHO):
        im.paste(MURO_ARRIBA, (x * T, 0), MURO_ARRIBA)
    im.paste(MURO_ESQ_IZQ, (0, 0), MURO_ESQ_IZQ)
    im.paste(MURO_ESQ_DER, ((ANCHO - 1) * T, 0), MURO_ESQ_DER)

    # Muros de los lados y de abajo.
    for y in range(2, ALTO):
        im.paste(MURO_LADO, (0, y * T), MURO_LADO)
        im.paste(MURO_LADO, ((ANCHO - 1) * T, y * T), MURO_LADO)
    for x in range(ANCHO):
        im.paste(MURO_ABAJO, (x * T, (ALTO - 1) * T), MURO_ABAJO)

    return im


def penumbra(im, focos):
    """Oscurece el cuarto y deja circulos de luz donde hay antorchas.

    Es lo que mas cambia la sensacion: un cuarto parejo se ve plano, uno con
    zonas oscuras y focos de luz se ve como escenario de juego.
    """
    oscuro = Image.new("RGBA", im.size, (18, 14, 32, 130))
    luz = oscuro.load()
    for cx, cy, radio in focos:
        for y in range(max(0, cy - radio), min(im.height, cy + radio)):
            for x in range(max(0, cx - radio), min(im.width, cx + radio)):
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if d < radio:
                    caida = 1.0 - (d / radio)
                    r, g, b, a = luz[x, y]
                    luz[x, y] = (r, g, b, int(a * (1.0 - caida * 0.95)))
    im.alpha_composite(oscuro)
    return im


def main():
    im = cuarto()

    # Diana, a la misma densidad de pixel que el tileset.
    diana = os.path.join(SALIDA, "diana16_frames", "01.png")
    sombra = os.path.join(SALIDA, "diana16_sombra.png")
    if os.path.exists(diana):
        d = Image.open(diana).convert("RGBA")
        s = Image.open(sombra).convert("RGBA").crop((0, 0, T, 5))
        px = (ANCHO // 2) * T
        py = (ALTO // 2) * T
        im.alpha_composite(s, (px, py + 23))
        im.alpha_composite(d, (px, py))

    im = penumbra(im, [((ANCHO // 2) * T + 8, (ALTO // 2) * T + 14, 110),
                       (5 * T, 4 * T, 70), ((ANCHO - 6) * T, 4 * T, 70)])

    im.save(os.path.join(SALIDA, "cuarto_0x72.png"))
    zoom = 3
    g = im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)
    g.convert("RGB").save(os.path.join(SALIDA, "cuarto_0x72_grande.png"))
    print("listo")


if __name__ == "__main__":
    main()
