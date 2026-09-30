# -*- coding: utf-8 -*-
"""Los cuatro escenarios a 32x32, con los personajes de 32x32.

Por que 32 y no 16: los personajes que quedaron aprobados son de 32x32 con
pixel fino. Para que encajen en el escenario, el escenario tiene que ser de
la misma densidad. Dungeon Crawl Stone Soup es de 32x32 y es CC0, asi que
cumple las dos cosas: la medida y la licencia libre para publicar.

Trae 457 pisos y 368 muros, y hasta un tile de joyeria y piezas sueltas
(anillos, collares, montones de oro), que es justo lo que pide este juego.

Cada cuarto se arma con un plano de letras. Los obstaculos forman pasillos
y coberturas: un cuarto vacio no se juega.
"""
import os
import random
from PIL import Image, ImageEnhance, ImageFilter

T = 32
BASE = ("C:/Users/uriel/Downloads/Material videojuego/"
        "Dungeon Crawl Stone Soup Full/Dungeon Crawl Stone Soup Full")
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "escenarios32")
PERSONAJES = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "reparto")
DIANA = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                     "diana_det_frames", "01.png")


def pieza(ruta):
    """Carga un tile del pack. Devuelve None si no existe, para no tronar
    si un nombre cambio entre versiones."""
    f = os.path.join(BASE, *ruta.split("/"))
    if not os.path.exists(f):
        return None
    im = Image.open(f).convert("RGBA")
    if im.size != (T, T):
        lienzo = Image.new("RGBA", (T, T), (0, 0, 0, 0))
        lienzo.alpha_composite(im, (max(0, (T - im.width) // 2),
                                    max(0, T - im.height)))
        return lienzo
    return im


def varias(patron, cuantas):
    salida = []
    for i in range(cuantas):
        p = pieza(patron % i)
        if p is not None:
            salida.append(p)
    return salida


# --- pisos y muros por escenario
# Piso claro y muro oscuro. Al reves el cuarto se ve como un pozo: el ojo
# lee el piso como el fondo, y el fondo debe ser lo mas claro.
PISOS = {
    "joyeria": varias("dungeon/floor/white_marble_%d.png", 8),
    "bodega": varias("dungeon/floor/pebble_brown_%d_new.png", 9),
    "mina": varias("dungeon/floor/crystal_floor_%d.png", 6),
    "taller": varias("dungeon/floor/volcanic_floor_%d.png", 8)
    or varias("dungeon/floor/pebble_brown_%d_new.png", 9),
}
MUROS = {
    "joyeria": varias("dungeon/wall/brick_brown_%d.png", 8),
    "bodega": varias("dungeon/wall/brick_dark_%d.png", 8)
    or varias("dungeon/wall/brick_brown_%d.png", 8),
    "mina": varias("dungeon/wall/cobalt_rock_%d.png", 8)
    or varias("dungeon/wall/stone_dark_%d.png", 8),
    "taller": varias("dungeon/wall/stone_dark_%d.png", 8)
    or varias("dungeon/wall/brick_dark_%d.png", 8),
}

CAJA = pieza("dungeon/large_box.png")
COFRE = pieza("dungeon/chest.png")
ROCA = pieza("dungeon/boulder.png")
VITRINA = pieza("dungeon/shops/shop_jewellery.png")
PUERTA = pieza("dungeon/doors/closed_door.png")
ANILLO = pieza("item/ring/gold.png") or pieza("item/ring/brass.png")
COLLAR = pieza("item/amulet/cameo_orange.png")
ORO = pieza("item/gold/gold_pile_10.png") or pieza("item/gold/gold_pile.png")
REJA = pieza("dungeon/bars_red_1.png")
FUENTE = pieza("dungeon/blue_fountain.png")

CACHE = {}

PLANOS = {
    # La joyeria: vitrinas al fondo, piezas en exhibicion y la puerta.
    "joyeria": [
        "###############",
        "###############",
        "#..vvv...vvv..#",
        "#.............#",
        "#..a.......c..#",
        "#.............#",
        "#..v.......v..#",
        "#.............#",
        "#..c...x...a..#",
        "#.............#",
        "#......D......#",
        "###############",
    ],
    # La bodega: cajas apiladas que hacen de cobertura.
    "bodega": [
        "###############",
        "###############",
        "#.CC.....CC...#",
        "#.CC.....CC...#",
        "#.............#",
        "#....CC...C...#",
        "#....CC...C...#",
        "#.............#",
        "#.C.........C.#",
        "#.C.........C.#",
        "#.....x.......#",
        "###############",
    ],
    # La mina: rocas que estorban el paso y una fuente subterranea.
    "mina": [
        "###############",
        "###############",
        "#.R..........R#",
        "#....RR...R...#",
        "#.............#",
        "#..R....F.....#",
        "#.......F.....#",
        "#....R....RR..#",
        "#.............#",
        "#R...........R#",
        "#...x.........#",
        "###############",
    ],
    # El taller: rejas metalicas y cajas de piezas falsas.
    "taller": [
        "###############",
        "###############",
        "#.BBB.....BBB.#",
        "#.............#",
        "#..C.......C..#",
        "#.....BBB.....#",
        "#.............#",
        "#..C.......C..#",
        "#.BBB.....BBB.#",
        "#.............#",
        "#...x.........#",
        "###############",
    ],
}

PIEZAS = {
    "C": CAJA, "R": ROCA, "x": COFRE, "v": VITRINA, "D": PUERTA,
    "a": ANILLO, "c": COLLAR, "B": REJA, "F": FUENTE, "o": ORO,
}

HABITANTES = {
    "joyeria": [("02_don_aurelio", 3, 4), ("03_dona_chela", 10, 8)],
    "bodega": [("05_escarabajo_oxidado", 4, 8), ("06_polilla_de_hollin", 9, 3),
               ("07_vendedor_de_humo", 11, 6)],
    "mina": [("04_carbonel_duende", 3, 7), ("05_escarabajo_oxidado", 10, 4)],
    "taller": [("08_baron_oxido", 7, 3), ("05_escarabajo_oxidado", 4, 6)],
}


def sombra(ancho=20):
    im = Image.new("RGBA", (T, 8), (0, 0, 0, 0))
    px = im.load()
    for i, (a, alfa) in enumerate(((ancho - 6, 70), (ancho, 135),
                                   (ancho - 4, 95))):
        for j in range(a):
            px[T // 2 - a // 2 + j, 2 + i] = (14, 10, 20, alfa)
    return im


def cuarto(nombre, semilla=20221056):
    plano = PLANOS[nombre]
    rnd = random.Random(semilla)
    an, al = len(plano[0]), len(plano)
    im = Image.new("RGBA", (an * T, al * T), (18, 16, 24, 255))

    # Los tiles se aplanan una sola vez por escenario y se guardan, para no
    # repetir el trabajo en cada cuadro del cuarto.
    if nombre not in CACHE:
        # Los muros van con menos colores todavia que el piso: son lo que
        # mas superficie ocupa y lo que mas se nota si queda ruidoso.
        CACHE[nombre] = (aplanados(PISOS[nombre] or PISOS["bodega"], 8),
                         aplanados(MUROS[nombre] or MUROS["bodega"], 5))
    pisos, muros = CACHE[nombre]

    for y in range(al):
        for x in range(an):
            if plano[y][x] == "#":
                im.paste(rnd.choice(muros), (x * T, y * T))
            else:
                im.paste(rnd.choice(pisos), (x * T, y * T))

    # Los objetos van en su propia capa: el aplanado es solo para el piso y
    # los muros. Si se aplanan tambien los objetos, las joyas pierden el
    # dorado, que es justo lo que hay que ver.
    capa = Image.new("RGBA", im.size, (0, 0, 0, 0))
    for y, fila in enumerate(plano):
        for x, letra in enumerate(fila):
            p = PIEZAS.get(letra)
            if p is not None:
                capa.alpha_composite(p, (x * T, y * T))
    return im, capa


def paleta_comun(tiles, colores):
    """Saca una paleta unica a partir de todos los tiles del escenario.

    Si se aplana cada tile con su propia paleta, cada cuadro del piso queda
    con tonos distintos y el cuarto se ve manchado. Con una paleta comun
    todos comparten los mismos colores y se ve como un solo material.
    """
    montaje = Image.new("RGB", (T * len(tiles), T), (0, 0, 0))
    for i, t in enumerate(tiles):
        montaje.paste(t.convert("RGB"), (i * T, 0))
    montaje = montaje.filter(ImageFilter.ModeFilter(3))
    return montaje.quantize(colors=colores, method=Image.MEDIANCUT,
                            dither=Image.NONE)


def aplanar_tile(t, pal, saturacion=1.2):
    """Convierte un tile realista en pixel art plano.

    Se hace tile por tile y no sobre el cuarto entero: con el cuarto armado
    el filtro se corre de un cuadro al vecino y ensucia los bordes.

      1. Filtro de moda: cada pixel toma el color que mas se repite a su
         alrededor. Borra el ruido y deja manchas parejas.
      2. Reduccion a la paleta comun: aparecen zonas de color plano en vez
         de degradados.
      3. Un poco mas de saturacion, para que no quede apagado.
    """
    rgb = t.convert("RGB").filter(ImageFilter.ModeFilter(3))
    rgb = ImageEnhance.Color(rgb).enhance(saturacion)
    q = rgb.quantize(palette=pal, dither=Image.NONE).convert("RGBA")
    q.putalpha(t.getchannel("A"))
    return q


def aplanados(tiles, colores=10):
    if not tiles:
        return tiles
    pal = paleta_comun(tiles, colores)
    return [aplanar_tile(t, pal) for t in tiles]


def aplanar(im, colores=14, saturacion=1.3, brillo=1.1):
    """Convierte los tiles realistas en pixel art plano.

    Los tiles de Dungeon Crawl estan pintados con mucha textura y cientos de
    tonos; al lado de los personajes, que son planos y caricaturescos, se
    ven de otro juego. Aqui se hacen tres cosas:

      1. Filtro de moda: cada pixel toma el color que mas se repite a su
         alrededor. Eso borra el ruido y deja manchas parejas, que es como
         se pinta el pixel art a mano.
      2. Reduccion de paleta: de cientos de tonos a 18. Asi aparecen zonas
         de color plano en vez de degradados.
      3. Un poco mas de saturacion y brillo, para que no se vea apagado.
    """
    rgb = im.convert("RGB")
    rgb = rgb.filter(ImageFilter.ModeFilter(5))
    rgb = ImageEnhance.Color(rgb).enhance(saturacion)
    rgb = ImageEnhance.Brightness(rgb).enhance(brillo)
    rgb = rgb.quantize(colors=colores, method=Image.MEDIANCUT,
                       dither=Image.NONE).convert("RGB")
    plano = rgb.convert("RGBA")
    plano.putalpha(im.getchannel("A"))
    return plano


def poblar(im, nombre):
    """Diana al centro y los personajes que le tocan, cada uno con sombra."""
    def pegar(ruta, cx, cy):
        if not os.path.exists(ruta):
            return
        p = Image.open(ruta).convert("RGBA")
        im.alpha_composite(sombra(), (cx * T, cy * T + 26))
        im.alpha_composite(p, (cx * T, cy * T))

    an = len(PLANOS[nombre][0])
    al = len(PLANOS[nombre])
    pegar(DIANA, an // 2, al // 2)
    for quien, x, y in HABITANTES[nombre]:
        pegar(os.path.join(PERSONAJES, "%s_frames" % quien, "01.png"), x, y)
    return im


def penumbra(im, focos, fuerza):
    """Oscurece el cuarto y deja circulos de luz. Es lo que le da ambiente:
    un cuarto parejo se ve plano."""
    capa = Image.new("RGBA", im.size, (14, 10, 28, fuerza))
    px = capa.load()
    for cx, cy, radio in focos:
        for y in range(max(0, cy - radio), min(im.height, cy + radio)):
            for x in range(max(0, cx - radio), min(im.width, cx + radio)):
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if d < radio:
                    r, g, b, a = px[x, y]
                    px[x, y] = (r, g, b,
                                int(a * (1.0 - (1.0 - d / radio) * 0.9)))
    im.alpha_composite(capa)
    return im


LUZ = {
    "joyeria": (45, [(240, 190, 260), (120, 140, 150)]),
    "bodega": (100, [(240, 190, 230), (100, 120, 130), (380, 150, 120)]),
    "mina": (140, [(240, 190, 190), (150, 120, 110), (350, 240, 110)]),
    "taller": (95, [(240, 190, 240), (130, 110, 120), (360, 160, 120)]),
}


def main():
    os.makedirs(SALIDA, exist_ok=True)
    previas = []
    for nombre in ("joyeria", "bodega", "mina", "taller"):
        im, objetos = cuarto(nombre)
        im.alpha_composite(objetos)
        im = poblar(im, nombre)
        fuerza, focos = LUZ[nombre]
        im = penumbra(im, focos, fuerza)
        im.save(os.path.join(SALIDA, "cuarto_%s.png" % nombre))
        g = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
        g.convert("RGB").save(
            os.path.join(SALIDA, "cuarto_%s_grande.png" % nombre))
        previas.append(g.convert("RGB"))

    ancho = max(p.width for p in previas)
    alto = sum(p.height for p in previas) + 10 * (len(previas) + 1)
    lam = Image.new("RGB", (ancho, alto), (16, 14, 20))
    y = 10
    for p in previas:
        lam.paste(p, (0, y))
        y += p.height + 10
    lam.save(os.path.join(SALIDA, "00_escenarios32.png"))
    print("escenarios generados:", len(previas))


if __name__ == "__main__":
    main()
