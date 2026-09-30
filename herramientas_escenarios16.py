# -*- coding: utf-8 -*-
"""Los cuatro escenarios a 16x16, con obstaculos.

Todo el material es CC0, asi que el juego se puede publicar sin problema:

  - DungeonTileset II (0x72): pisos, muros altos, cajas, columnas, agujeros,
    cofres y puertas.
  - Roguelike Indoors (Kenney): los muebles de la joyeria.
  - Los aparatos grises de Kenney hacen de maquinaria del taller.

Cada cuarto se define con un plano de letras. Los obstaculos no estan
puestos al azar: forman pasillos y coberturas, que es lo que hace que un
cuarto se juegue y no sea una cancha vacia.

  #  muro       .  piso        C  columna     c  caja
  h  agujero    x  cofre       D  puerta      p  antorcha
  m  mueble del escenario (cambia segun el lugar)
"""
import os
import random
from PIL import Image

T = 16
MAT = "C:/Users/uriel/Downloads/Material videojuego"
DUN = MAT + "/0x72_DungeonTilesetII_v1.7/0x72_DungeonTilesetII_v1.7"
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "escenarios16")
REPARTO = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "reparto16")


def marco(nombre):
    return Image.open(os.path.join(DUN, "frames", nombre)).convert("RGBA")


PISOS = [marco("floor_%d.png" % i) for i in range(1, 9)]
CAJA = marco("crate.png")
COLUMNA = marco("column.png")
COLUMNA_MURO = marco("column_wall.png")
AGUJERO = marco("hole.png")
COFRE = marco("chest_empty_open_anim_f0.png")
ESCALERA = marco("floor_ladder.png")
CALAVERA = marco("skull.png")

ALTOS = Image.open(os.path.join(DUN, "atlas_walls_high-16x32.png")).convert(
    "RGBA")
BAJOS = Image.open(os.path.join(DUN, "atlas_walls_low-16x16.png")).convert(
    "RGBA")
MURO_ARRIBA = ALTOS.crop((T, 0, T * 2, T * 2))
MURO_LADO = BAJOS.crop((0, T, T, T * 2))
MURO_ABAJO = BAJOS.crop((T, 0, T * 2, T))

# Muebles de Kenney (hoja con 1 pixel de separacion entre tiles).
KEN = Image.open(MAT + "/kenney_roguelike-indoors/Tilesheets/"
                       "roguelikeIndoor_transparent.png").convert("RGBA")


def ken(col, fila, ancho=1, alto=1):
    p = 17
    return KEN.crop((col * p, fila * p, col * p + T * ancho,
                     fila * p + T * alto))


MOSTRADOR = ken(0, 13)
VITRINA = ken(17, 9)
ESTANTE = ken(18, 11)
MESA = ken(4, 0)
SILLA = ken(0, 2)
PLANTA = ken(15, 0)

# Maquinaria del taller. Se probo el 16x16 Industrial Tileset, pero es de
# ciencia ficcion, en azul oscuro y rosa neon, y desentonaba con el resto;
# quedo descartado. En su lugar se usan los aparatos grises de Kenney, que
# comparten paleta con lo demas.
MAQUINA = ken(20, 13)
PRENSA = ken(21, 15)


PLANOS = {
    "tienda": [
        "########################",
        "########################",
        "#..mmmm......mmmm......#",
        "#......................#",
        "#..C................C..#",
        "#.....vvvv...vvvv......#",
        "#......................#",
        "#..x.....C......C....x.#",
        "#......................#",
        "#....ssss......ssss....#",
        "#......................#",
        "#..........DD..........#",
        "########################",
    ],
    "bodega": [
        "########################",
        "########################",
        "#.mmmm....mmmm....mmmm.#",
        "#......................#",
        "#..cc........cc........#",
        "#..cc...C....cc...C....#",
        "#.......................",
        "#....cc.......cc.....x.#",
        "#....cc.......cc.......#",
        "#......................#",
        "#..C................C..#",
        "#......................#",
        "########################",
    ],
    "mina": [
        "########################",
        "########################",
        "#.C..................C.#",
        "#.....hh........hh.....#",
        "#.....hh........hh.....#",
        "#..cc..................#",
        "#..........LL..........#",
        "#...............cc.....#",
        "#....hh.........hh.....#",
        "#....hh.........hh.....#",
        "#.C.................C..#",
        "#.........x............#",
        "########################",
    ],
    "taller": [
        "########################",
        "########################",
        "#.mmmmmm......mmmmmm...#",
        "#......................#",
        "#..C................C..#",
        "#....qqqq......qqqq....#",
        "#......................#",
        "#..cc.....C....C....cc.#",
        "#......................#",
        "#....qqqq......qqqq....#",
        "#......................#",
        "#.....x................#",
        "########################",
    ],
}

# Que mueble usa cada escenario para la letra m, y cual para q.
MUEBLES = {
    "tienda": MOSTRADOR,
    "bodega": ESTANTE,
    "mina": CAJA,
    "taller": PRENSA,
}


def cuarto(nombre, semilla=20221056):
    plano = PLANOS[nombre]
    rnd = random.Random(semilla)
    an, al = len(plano[0]), len(plano)
    im = Image.new("RGBA", (an * T, al * T), (20, 18, 26, 255))

    # Piso con variantes, para que no se note el patron.
    for y in range(2, al - 1):
        for x in range(1, an - 1):
            im.paste(rnd.choice(PISOS), (x * T, y * T))

    # Muros.
    for x in range(an):
        im.paste(MURO_ARRIBA, (x * T, 0), MURO_ARRIBA)
        im.paste(MURO_ABAJO, (x * T, (al - 1) * T), MURO_ABAJO)
    for y in range(2, al):
        im.paste(MURO_LADO, (0, y * T), MURO_LADO)
        im.paste(MURO_LADO, ((an - 1) * T, y * T), MURO_LADO)

    piezas = {
        "C": COLUMNA, "c": CAJA, "h": AGUJERO, "x": COFRE,
        "L": ESCALERA, "s": SILLA, "v": VITRINA,
        "m": MUEBLES[nombre], "q": MAQUINA,
    }
    for y, fila in enumerate(plano):
        for x, letra in enumerate(fila):
            pieza = piezas.get(letra)
            if pieza is not None:
                im.alpha_composite(pieza, (x * T, y * T))
            elif letra == "D":
                im.alpha_composite(marco("doors_leaf_closed.png"),
                                   (x * T, (y - 1) * T))
    return im


def penumbra(im, focos, fuerza=120):
    """Oscurece el cuarto y deja circulos de luz. Un cuarto parejo se ve
    plano; con zonas oscuras y focos se ve como escenario de juego."""
    capa = Image.new("RGBA", im.size, (16, 12, 30, fuerza))
    px = capa.load()
    for cx, cy, radio in focos:
        for y in range(max(0, cy - radio), min(im.height, cy + radio)):
            for x in range(max(0, cx - radio), min(im.width, cx + radio)):
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if d < radio:
                    caida = 1.0 - d / radio
                    r, g, b, a = px[x, y]
                    px[x, y] = (r, g, b, int(a * (1.0 - caida * 0.9)))
    im.alpha_composite(capa)
    return im


LUZ = {
    "tienda": (60, [(200, 100, 190), (110, 60, 90)]),
    "bodega": (110, [(190, 120, 150), (60, 70, 80), (330, 90, 80)]),
    "mina": (150, [(190, 110, 120), (90, 60, 60), (300, 140, 70)]),
    "taller": (105, [(190, 110, 160), (110, 90, 70), (280, 90, 70)]),
}

HABITANTES = {
    "tienda": ["02_don_aurelio", "03_dona_chela"],
    "bodega": ["05_escarabajo_oxidado", "06_polilla_de_hollin",
               "07_vendedor_de_humo"],
    "mina": ["04_carbonel_duende", "05_escarabajo_oxidado"],
    "taller": ["08_baron_oxido", "05_escarabajo_oxidado"],
}

SITIOS = [(5, 4), (17, 4), (9, 8), (14, 7), (6, 9)]


def poblar(im, nombre):
    """Mete a Diana al centro y a los personajes que le tocan al escenario,
    cada uno con su sombra."""
    def pegar(carpeta, cx, cy, ancho=10):
        marco_p = os.path.join(carpeta, "01.png")
        if not os.path.exists(marco_p):
            return
        p = Image.open(marco_p).convert("RGBA")
        s = Image.new("RGBA", (16, 5), (0, 0, 0, 0))
        spx = s.load()
        for i, (a, alfa) in enumerate(((ancho - 4, 70), (ancho, 135),
                                       (ancho - 2, 95))):
            for j in range(a):
                spx[8 - a // 2 + j, 1 + i] = (14, 10, 20, alfa)
        im.alpha_composite(s, (cx * T, cy * T + 23))
        im.alpha_composite(p, (cx * T, cy * T - 12))

    base = os.path.dirname(REPARTO)
    pegar(os.path.join(base, "diana16_frames"), 11, 7)
    for i, quien in enumerate(HABITANTES[nombre]):
        x, y = SITIOS[i]
        pegar(os.path.join(REPARTO, "%s_frames" % quien), x, y)
    return im


def main():
    os.makedirs(SALIDA, exist_ok=True)
    previas = []
    for nombre in ("tienda", "bodega", "mina", "taller"):
        im = cuarto(nombre)
        im = poblar(im, nombre)
        fuerza, focos = LUZ[nombre]
        im = penumbra(im, focos, fuerza)
        im.save(os.path.join(SALIDA, "cuarto_%s.png" % nombre))
        zoom = 3
        g = im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)
        g.convert("RGB").save(
            os.path.join(SALIDA, "cuarto_%s_grande.png" % nombre))
        previas.append(g.convert("RGB"))

    ancho = max(p.width for p in previas)
    alto = sum(p.height for p in previas) + 10 * (len(previas) + 1)
    lam = Image.new("RGB", (ancho, alto), (18, 16, 22))
    y = 10
    for p in previas:
        lam.paste(p, (0, y))
        y += p.height + 10
    lam.save(os.path.join(SALIDA, "00_escenarios16.png"))
    print("escenarios generados:", len(previas))


if __name__ == "__main__":
    main()
