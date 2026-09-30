# -*- coding: utf-8 -*-
"""El reparto a 16x28, la densidad de pixel del tileset del juego.

Mismo molde que Diana: cabeza grande, contorno de un pixel, dos o tres tonos
por color y el rebote del cuerpo como motor de la caminata. Cada personaje
conserva lo que dice su ficha del libreto; a este tamano no cabe todo, asi
que se guarda lo que lo identifica de lejos y se suelta el resto.

La silueta base se comparte entre los cuatro humanos y solo cambian la
paleta y unas cuantas filas (sombrero, barba, capucha). Los que no son
humanos llevan su propio dibujo.
"""
import os
from PIL import Image

W, H = 16, 28
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reparto16")

CONTORNO = (26, 20, 30, 255)
BLANCO = (250, 248, 252, 255)
OJO = (34, 28, 38, 255)
ORO = (236, 184, 74, 255)

# Silueta comun. Las letras se traducen con la paleta de cada personaje:
#   p/P pelo o sombrero   s/S piel   b/B ropa   m/M detalle   n pantalon
#   t calzado   g dorado   e ojo   o contorno
BASE = [
    "                ",
    "     oooooo     ",
    "    oppppppo    ",
    "   oppppppppo   ",
    "   oppppppppo   ",
    "   opssssssPo   ",
    "   opsessesPo   ",
    "   opsessesPo   ",
    "   opssssssPo   ",
    "   opsssSsspo   ",
    "    osssssso    ",
    "   oppppppppo   ",
    "   obbbbbbbbo   ",
    "   obBmmmmbbo   ",
    "   obBmmmmbbo   ",
    "   obBmmmmbbo   ",
    "   obbmmmmbbo   ",
    "   obbMMMMbbo   ",
    "  osbbbbbbbbso  ",
    "  osobbbbbbso   ",
    "   onnnoonnno   ",
    "   onnnoonnno   ",
    "   otttoottto   ",
    "   oooooooooo   ",
    "                ",
    "                ",
    "                ",
    "                ",
]

# Los pies son lo unico que cambia entre cuadros; el resto es el rebote.
PIES = {
    0: ("otttoottto", "oooooooooo"),
    1: ("onnnoottto", "otttoooooo"),
    2: ("otttoottto", "oooooooooo"),
    3: ("otttoonnno", "oooooottto"),
}


def pintar(mapa, paleta, subir=0):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    for y, fila in enumerate(mapa):
        for x, letra in enumerate(fila[:W]):
            color = paleta.get(letra)
            if color is not None:
                destino = y - subir
                if 0 <= destino < H:
                    px[x, destino] = color
    return im


def paleta(pelo, pelo_luz, ropa, ropa_luz, detalle, detalle_som,
           pantalon, bota, piel=(242, 200, 164, 255),
           piel_som=(202, 152, 118, 255)):
    return {
        " ": None, "o": CONTORNO, "e": OJO, "g": ORO, "w": BLANCO,
        "p": pelo, "P": pelo_luz, "s": piel, "S": piel_som,
        "b": ropa, "B": ropa_luz, "m": detalle, "M": detalle_som,
        "n": pantalon, "t": bota,
    }


class Humano:
    """Un personaje humano: paleta propia y unas filas cambiadas."""

    def __init__(self, pal, cambios=None):
        self.pal = pal
        self.cambios = cambios or {}

    def cuadro(self, fase):
        mapa = list(BASE)
        for fila, texto in self.cambios.items():
            mapa[fila] = texto
        pie_a, pie_b = PIES[fase]
        mapa[22] = "   " + pie_a + "   "
        mapa[23] = "   " + pie_b + "   "
        return pintar(mapa, self.pal, subir=1 if fase in (1, 3) else 0)


# ------------------------------------------------------------- los humanos

# Don Aurelio: sombrero de palma de ala ancha y bigote blanco.
AURELIO = Humano(
    paleta(pelo=(222, 200, 142, 255), pelo_luz=(244, 226, 176, 255),
           ropa=(228, 216, 190, 255), ropa_luz=(248, 240, 222, 255),
           detalle=(122, 92, 58, 255), detalle_som=(92, 66, 40, 255),
           pantalon=(88, 84, 104, 255), bota=(96, 68, 46, 255)),
    {
        1: "    oooooooo    ",
        2: "   oPPPPPPPPo   ",
        3: "   opppppppppo  ",
        4: " ooppppppppppoo ",
        5: " oMMMMMMMMMMMMo ",
        6: "   ossssssso    ",
        7: "   osessesso    ",
        8: "   ossssssso    ",
        9: "   osMMMMMMso   ",
        10: "    osssssso    ",
        11: "   obbbbbbbbo   ",
    })

# Dona Chela: canosa, lentes grandes y rebozo rosa sobre los hombros.
CHELA = Humano(
    paleta(pelo=(206, 202, 204, 255), pelo_luz=(236, 234, 236, 255),
           ropa=(198, 132, 148, 255), ropa_luz=(226, 168, 180, 255),
           detalle=(158, 188, 156, 255), detalle_som=(112, 140, 112, 255),
           pantalon=(104, 80, 64, 255), bota=(84, 60, 46, 255)),
    {
        6: "   opgggggppo   ",
        7: "   opgewegpPo   ",
        8: "   opgggggpPo   ",
        12: "   obbbbbbbbo   ",
        13: "  obbbbbbbbbbo  ",
        14: "   obBmmmmbbo   ",
    })

# Vendedor de Humo: capucha gris; de la cara solo se le ven los ojos.
HUMO = Humano(
    paleta(pelo=(122, 120, 132, 255), pelo_luz=(158, 156, 168, 255),
           ropa=(108, 106, 118, 255), ropa_luz=(140, 138, 150, 255),
           detalle=(88, 86, 98, 255), detalle_som=(66, 64, 76, 255),
           pantalon=(74, 72, 84, 255), bota=(58, 56, 66, 255)),
    {
        5: "   oppppppppo   ",
        6: "   opMMMMMMpo   ",
        7: "   opMgggMMpo   ",
        8: "   opMMMMMMpo   ",
        9: "   oppppppppo   ",
        10: "   oppppppppo   ",
        11: "  obbbbbbbbbbo  ",
    })

# Baron Oxido: alto y delgado, sombrero de copa y abrigo de cobre verdoso.
BARON = Humano(
    paleta(pelo=(74, 70, 68, 255), pelo_luz=(104, 100, 96, 255),
           ropa=(152, 106, 62, 255), ropa_luz=(188, 138, 88, 255),
           detalle=(104, 132, 104, 255), detalle_som=(74, 96, 76, 255),
           pantalon=(82, 90, 82, 255), bota=(62, 50, 40, 255)),
    {
        1: "    oppppppo    ",
        2: "    oppppppo    ",
        3: "    oPPPPPPo    ",
        4: "  oppppppppppo  ",
        5: "   ossssssso    ",
        6: "   opsegggspo   ",
        7: "   opsessesPo   ",
        9: "   opsMMMMspo   ",
        13: "   obBgmmgbbo   ",
        17: "   obbmmmmbbo   ",
    })


# ---------------------------------------------------------- los no humanos

def quilate(fase):
    """Colibri verde esmeralda con el pecho rubi. Flota y aletea; las alas
    cambian de tamano en cada cuadro."""
    flota = (0, -1, 0, 1)[fase]
    abierta = fase in (0, 2)
    verde = (52, 164, 108, 255)
    verde_luz = (92, 206, 142, 255)
    verde_som = (32, 112, 76, 255)
    rubi = (206, 58, 70, 255)
    pal = {" ": None, "o": CONTORNO, "e": OJO, "w": BLANCO, "g": ORO,
           "v": verde, "V": verde_luz, "d": verde_som, "r": rubi,
           "b": (72, 60, 54, 255)}
    if abierta:
        mapa = [
            "                ",
            "                ",
            "      oooo      ",
            "     oVVVVo     ",
            "    ovvewvvo    ",
            "    ovvvvvvobbb ",
            "     ovvvvo     ",
            "  gg ovvvvo gg  ",
            " ggg ovrrvo ggg ",
            "  gg ovrrvo gg  ",
            "     ovvvvo     ",
            "      oddo      ",
            "      oddo      ",
            "       oo       ",
        ]
    else:
        mapa = [
            "                ",
            "                ",
            "      oooo      ",
            "     oVVVVo     ",
            "    ovvewvvo    ",
            "    ovvvvvvobbb ",
            "    govvvvog    ",
            "    govvvvog    ",
            "    govrrvog    ",
            "     ovrrvo     ",
            "     ovvvvo     ",
            "      oddo      ",
            "      oddo      ",
            "       oo       ",
        ]
    mapa = ["                "] * 6 + mapa
    return pintar(mapa[:H], pal, subir=flota)


def carbonel(fase):
    """Duende de la mina: la mitad de alto que Diana, gorro puntiagudo
    caido, barba canosa y ojos grandes sensibles a la luz."""
    sube = 1 if fase in (1, 3) else 0
    pal = {" ": None, "o": CONTORNO, "e": OJO, "w": BLANCO, "g": ORO,
           "v": (122, 158, 114, 255), "V": (156, 194, 142, 255),
           "d": (84, 120, 84, 255),
           "a": (96, 106, 158, 255), "A": (132, 142, 194, 255),
           "c": (206, 208, 214, 255), "t": (92, 66, 48, 255)}
    mapa = [
        "                ",
        "                ",
        "                ",
        "          oaao  ",
        "        oaaaao  ",
        "      oaaaaao   ",
        "   oaaaaaaao    ",
        "  oAAAAAAAAAo   ",
        "  ovvvvvvvvvo   ",
        " oovvvvvvvvvoo  ",
        " ovwewvvwewvo   ",
        "  ovvvvvvvvo    ",
        "   occcccco     ",
        "  oaaccccaao    ",
        "  oaaacccaao    ",
        "  oaaaccaaao    ",
        "   oacccccao    ",
        "    occcco      ",
        "   otttoottt o  ",
        "   ooooooooo    ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
    ]
    return pintar(mapa, pal, subir=sube)


def escarabajo(fase):
    """Escarabajo Oxidado: caparazon cafe rojizo con manchas verdes y
    patitas que se alternan."""
    sube = 1 if fase in (1, 3) else 0
    paso = fase in (1, 3)
    pal = {" ": None, "o": CONTORNO, "e": (250, 140, 90, 255),
           "c": (168, 82, 54, 255), "C": (206, 118, 78, 255),
           "d": (112, 52, 32, 255), "v": (108, 132, 84, 255),
           "n": (46, 36, 34, 255)}
    mapa = [
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "      o    o    ",
        "      on  no    ",
        "      oooooo    ",
        "     onnnnnno   ",
        "    oneonnoeno  ",
        " n occdcccdcco  ",
        "  ooCCcccvcccdo ",
        " n occcdccccvco ",
        "  ooccvcdcccdco n",
        " n occcdcvcccco ",
        "  ooddcdcdddddo n",
        "   oddddddddo   ",
        "    oooooooo    ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
    ]
    if paso:
        mapa[10], mapa[12] = mapa[12], mapa[10]
        mapa[13], mapa[15] = mapa[15], mapa[13]
    return pintar(mapa, pal, subir=sube)


def polilla(fase):
    """Polilla de Hollin: alas grandes que se abren y cierran, cuerpo peludo
    y polvo negro cayendo.

    Se dibuja por codigo y no con un mapa de letras: las alas cambian de
    forma en cada cuadro y con rectangulos sale mas limpio.
    """
    flota = (0, -1, 0, 1)[fase]
    abierta = fase in (0, 2)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()

    ALA = (186, 182, 174, 255)
    ALA_LUZ = (218, 214, 206, 255)
    ALA_SOM = (130, 126, 118, 255)
    CUERPO = (98, 92, 88, 255)
    POLVO = (56, 52, 50, 255)

    def r(x, y, w, h, c):
        for j in range(h):
            for i in range(w):
                if 0 <= x + i < W and 0 <= y + j < H:
                    px[x + i, y + j] = c

    base = 8 + flota

    # Alas: cada fila se ensancha y luego se cierra, asi salen con forma
    # de ala y no como bloques.
    if abierta:
        forma = (2, 4, 6, 6, 5, 3)
    else:
        forma = (1, 2, 3, 3, 2, 1)
    for i, largo in enumerate(forma):
        y = base + i
        color = ALA_LUZ if i < 2 else (ALA if i < 4 else ALA_SOM)
        r(6 - largo, y, largo, 1, color)
        r(10, y, largo, 1, color)
        r(6 - largo - 1, y, 1, 1, CONTORNO)
        r(10 + largo, y, 1, 1, CONTORNO)
    r(6 - forma[0], base - 1, forma[0], 1, CONTORNO)
    r(10, base - 1, forma[0], 1, CONTORNO)
    r(6 - forma[-1], base + len(forma), forma[-1], 1, CONTORNO)
    r(10, base + len(forma), forma[-1], 1, CONTORNO)

    # Cuerpo: cabeza, torax peludo y abdomen con anillos.
    r(6, base - 3, 4, 12, CUERPO)
    r(5, base - 2, 1, 10, CONTORNO)
    r(10, base - 2, 1, 10, CONTORNO)
    r(6, base - 4, 4, 1, CONTORNO)
    r(6, base + 9, 4, 1, CONTORNO)
    r(6, base - 3, 2, 3, (140, 134, 126, 255))
    for y in (base + 1, base + 4, base + 7):
        r(6, y, 4, 1, (70, 66, 62, 255))

    # Ojos anaranjados y antenas.
    r(6, base - 2, 1, 2, (250, 140, 90, 255))
    r(9, base - 2, 1, 2, (250, 140, 90, 255))
    r(5, base - 8, 1, 4, CUERPO)
    r(10, base - 8, 1, 4, CUERPO)
    r(4, base - 9, 2, 1, CUERPO)
    r(10, base - 9, 2, 1, CUERPO)

    # El polvo negro que va soltando.
    for x, y in ((3, base + 9), (12, base + 8), (5, base + 12)):
        r(x, y, 1, 1, POLVO)
    return im


def sombra(fase, ancho_base=10):
    """La sombra va en su propio sprite, de 16x5."""
    im = Image.new("RGBA", (W, 5), (0, 0, 0, 0))
    px = im.load()
    encogida = 1 if fase in (1, 3) else 0
    anchos = (ancho_base - 4 - encogida, ancho_base - encogida * 2,
              ancho_base - 2 - encogida * 2)
    alfas = (70, 135, 95)
    for i, ancho in enumerate(anchos):
        y = 1 + i
        x = 8 - ancho // 2
        for j in range(max(0, ancho)):
            px[x + j, y] = (14, 10, 20, alfas[i])
    return im


FICHAS = [
    ("01_quilate_colibri", quilate, 6),
    ("02_don_aurelio", AURELIO.cuadro, 10),
    ("03_dona_chela", CHELA.cuadro, 10),
    ("04_carbonel_duende", carbonel, 9),
    ("05_escarabajo_oxidado", escarabajo, 12),
    ("06_polilla_de_hollin", polilla, 8),
    ("07_vendedor_de_humo", HUMO.cuadro, 11),
    ("08_baron_oxido", BARON.cuadro, 10),
]


def main():
    os.makedirs(SALIDA, exist_ok=True)
    zoom = 6
    lamina = Image.new("RGB", (len(FICHAS) * (W * zoom + 8) + 8,
                               (H + 4) * zoom + 16), (44, 40, 52))

    for i, (nombre, dibujo, ancho) in enumerate(FICHAS):
        cuadros = [dibujo(f) for f in range(4)]
        hoja = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
        sombras = Image.new("RGBA", (W * 4, 5), (0, 0, 0, 0))
        carpeta = os.path.join(SALIDA, "%s_frames" % nombre)
        os.makedirs(carpeta, exist_ok=True)
        gif = []
        for j, im in enumerate(cuadros):
            hoja.paste(im, (j * W, 0), im)
            sombras.paste(sombra(j, ancho), (j * W, 0))
            im.save(os.path.join(carpeta, "%02d.png" % (j + 1)))
            junto = Image.new("RGBA", (W, H + 4), (0, 0, 0, 0))
            junto.alpha_composite(sombra(j, ancho), (0, H - 5))
            junto.alpha_composite(im, (0, 0))
            g = junto.resize((W * zoom, (H + 4) * zoom), Image.NEAREST)
            f = Image.new("RGB", g.size, (44, 40, 52))
            f.paste(g, (0, 0), g)
            gif.append(f)
        hoja.save(os.path.join(SALIDA, "%s.png" % nombre))
        sombras.save(os.path.join(SALIDA, "%s_sombra.png" % nombre))
        gif[0].save(os.path.join(SALIDA, "%s.gif" % nombre), save_all=True,
                    append_images=gif[1:], duration=150, loop=0)

        junto = Image.new("RGBA", (W, H + 4), (0, 0, 0, 0))
        junto.alpha_composite(sombra(0, ancho), (0, H - 5))
        junto.alpha_composite(cuadros[0], (0, 0))
        g = junto.resize((W * zoom, (H + 4) * zoom), Image.NEAREST)
        lamina.paste(g, (8 + i * (W * zoom + 8), 8), g)

    lamina.save(os.path.join(SALIDA, "00_reparto16.png"))
    print("personajes generados:", len(FICHAS))


if __name__ == "__main__":
    main()
