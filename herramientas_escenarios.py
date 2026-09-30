# -*- coding: utf-8 -*-
"""Los escenarios de Diana y el Brillo Perdido.

Cada escenario sale de su ficha en el libreto. Se entrega en dos piezas:

  - Un atlas de tiles de 16x16, que es la medida que declara la propuesta.
    Los primeros ocho son siempre los mismos: pisos y muros. Los demas son
    los objetos propios del lugar.
  - Una vista previa de un cuarto ya armado con esos tiles, para ver como
    se siente el escenario antes de construirlo en Godot.

Escenarios, en orden de juego:
  0. Joyeria Diana Laura  - la tienda: tutorial, guardado y epilogo.
  1. Bodega del Proveedor - estantes, tarimas, basculas y cadenas.
  2. Mina de Cuarzo       - galerias, vetas de cuarzo, rieles y vagonetas.
  3. Taller de Imitaciones- bandas, prensas, engranes y chimeneas.
"""
import os
from PIL import Image

T = 16                      # lado del tile
COLS = 8                    # tiles por fila en el atlas
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "escenarios")


class Tile:
    def __init__(self, fondo=None):
        self.im = Image.new("RGBA", (T, T), fondo or (0, 0, 0, 0))
        self.px = self.im.load()

    def r(self, x, y, w, h, c):
        for j in range(h):
            for i in range(w):
                if 0 <= x + i < T and 0 <= y + j < T:
                    self.px[x + i, y + j] = c

    def p(self, x, y, c):
        self.r(x, y, 1, 1, c)

    def ruido(self, color, puntos):
        """Salpica pixeles sueltos: es lo que evita que un piso plano se
        vea como una sabana de color."""
        for x, y in puntos:
            self.p(x, y, color)


def tonos(base):
    def esc(f):
        return (min(255, int(base[0] * f)), min(255, int(base[1] * f)),
                min(255, int(base[2] * f)), 255)
    return esc(0.6), esc(0.8), (base[0], base[1], base[2], 255), esc(1.2)


# ---------------------------------------------------------------- la tienda

def tienda():
    """Local pequeno con vitrinas, espejos, mostrador de madera y el
    aparador hacia la calle."""
    pro, som, base, luz = tonos((214, 206, 196))     # loseta clara
    mpro, msom, mad, mluz = tonos((150, 104, 66))    # madera del mostrador
    vidrio = (196, 224, 236, 255)
    oro = (226, 172, 56, 255)
    tiles = []

    piso = Tile(base)                                 # 0 loseta
    piso.r(0, 0, T, 1, luz)
    piso.r(0, T - 1, T, 1, som)
    piso.r(7, 0, 1, T, som)
    piso.r(0, 7, T, 1, som)
    tiles.append(piso)

    piso2 = Tile(base)                                # 1 loseta con dibujo
    piso2.r(0, 0, T, 1, luz)
    piso2.r(0, 7, T, 1, som)
    piso2.r(7, 0, 1, T, som)
    piso2.r(10, 10, 4, 4, luz)
    tiles.append(piso2)

    alfombra = Tile((146, 78, 96, 255))               # 2 tapete de entrada
    alfombra.r(0, 0, T, 1, (178, 104, 120, 255))
    alfombra.r(2, 2, 12, 12, (166, 92, 110, 255))
    tiles.append(alfombra)

    pared = Tile((186, 176, 168, 255))                # 3 pared
    pared.r(0, 0, T, 2, (206, 198, 190, 255))
    pared.r(0, T - 2, T, 2, (150, 142, 136, 255))
    tiles.append(pared)

    zocalo = Tile((186, 176, 168, 255))               # 4 pared con zocalo
    zocalo.r(0, 10, T, 6, mad)
    zocalo.r(0, 10, T, 1, mluz)
    zocalo.r(0, 15, T, 1, mpro)
    tiles.append(zocalo)

    mostrador = Tile((0, 0, 0, 0))                    # 5 mostrador de madera
    mostrador.r(0, 2, T, 12, mad)
    mostrador.r(0, 2, T, 2, mluz)
    mostrador.r(0, 12, T, 2, mpro)
    mostrador.r(0, 6, T, 1, msom)
    tiles.append(mostrador)

    vitrina = Tile((0, 0, 0, 0))                      # 6 vitrina con joyas
    vitrina.r(0, 0, T, 14, mad)
    vitrina.r(1, 1, 14, 9, vidrio)
    vitrina.r(1, 1, 14, 1, (240, 250, 252, 255))
    vitrina.r(3, 6, 3, 2, oro)
    vitrina.r(9, 5, 2, 3, (226, 236, 244, 255))
    vitrina.r(0, 12, T, 2, mpro)
    tiles.append(vitrina)

    espejo = Tile((0, 0, 0, 0))                       # 7 espejo de pared
    espejo.r(2, 0, 12, 14, oro)
    espejo.r(3, 1, 10, 12, (176, 206, 220, 255))
    espejo.r(4, 2, 3, 8, (222, 238, 246, 255))
    tiles.append(espejo)

    aparador = Tile((0, 0, 0, 0))                     # 8 aparador a la calle
    aparador.r(0, 0, T, 16, (108, 140, 158, 255))
    aparador.r(0, 0, T, 2, oro)
    aparador.r(2, 3, 5, 10, (150, 184, 200, 255))
    aparador.r(2, 3, 2, 4, (208, 232, 240, 255))
    tiles.append(aparador)

    planta = Tile((0, 0, 0, 0))                       # 9 maceta
    planta.r(5, 10, 6, 5, (152, 96, 68, 255))
    planta.r(5, 10, 6, 1, (186, 126, 92, 255))
    planta.r(4, 4, 8, 6, (82, 140, 84, 255))
    planta.r(5, 3, 6, 3, (104, 166, 100, 255))
    planta.r(6, 3, 3, 2, (134, 190, 120, 255))
    tiles.append(planta)

    return "tienda", tiles, base


# ------------------------------------------------------------- la bodega

def bodega():
    """Almacen: pasillos entre estantes altos, cajas apiladas, tarimas,
    basculas y cadenas colgando del techo."""
    pro, som, base, luz = tonos((132, 116, 96))       # concreto
    cpro, csom, carton, cluz = tonos((176, 128, 78))  # cajas
    mpro, msom, mad, mluz = tonos((138, 98, 60))      # tarimas
    metal = (140, 140, 150, 255)
    tiles = []

    piso = Tile(base)                                  # 0 concreto
    piso.r(0, 0, T, 1, som)
    piso.ruido(som, [(3, 4), (11, 2), (6, 9), (13, 12), (2, 13)])
    piso.ruido(luz, [(8, 5), (4, 11)])
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 concreto con grieta
    piso2.r(0, 0, T, 1, som)
    for i in range(6):
        piso2.p(3 + i, 6 + (i % 3), pro)
    tiles.append(piso2)

    tarima = Tile(base)                                # 2 tarima de madera
    for y in (2, 7, 12):
        tarima.r(0, y, T, 3, mad)
        tarima.r(0, y, T, 1, mluz)
        tarima.r(0, y + 2, T, 1, mpro)
    tiles.append(tarima)

    pared = Tile((104, 94, 82, 255))                   # 3 pared de bodega
    pared.r(0, 0, T, 2, (126, 114, 100, 255))
    pared.r(0, T - 2, T, 2, (80, 72, 64, 255))
    pared.r(0, 7, T, 1, (88, 80, 70, 255))
    tiles.append(pared)

    estante = Tile((0, 0, 0, 0))                       # 4 estante alto
    estante.r(0, 0, T, 16, mad)
    estante.r(0, 0, T, 1, mluz)
    for y in (4, 9, 14):
        estante.r(0, y, T, 2, mpro)
    estante.r(2, 1, 5, 3, carton)
    estante.r(9, 6, 5, 3, carton)
    estante.r(3, 11, 6, 3, csom)
    tiles.append(estante)

    caja = Tile((0, 0, 0, 0))                          # 5 caja de carton
    caja.r(1, 3, 14, 12, carton)
    caja.r(1, 3, 14, 2, cluz)
    caja.r(1, 13, 14, 2, cpro)
    caja.r(7, 3, 2, 12, csom)
    caja.r(1, 8, 14, 1, csom)
    tiles.append(caja)

    bascula = Tile((0, 0, 0, 0))                       # 6 bascula
    bascula.r(2, 8, 12, 6, metal)
    bascula.r(2, 8, 12, 1, (176, 176, 186, 255))
    bascula.r(2, 13, 12, 1, (96, 96, 106, 255))
    bascula.r(5, 3, 6, 5, (176, 176, 186, 255))
    bascula.r(6, 4, 4, 3, (236, 240, 244, 255))
    bascula.p(8, 5, (200, 60, 60, 255))
    tiles.append(bascula)

    cadena = Tile((0, 0, 0, 0))                        # 7 cadena del techo
    for y in range(0, 14, 3):
        cadena.r(7, y, 2, 2, metal)
        cadena.p(7, y + 1, (96, 96, 106, 255))
    cadena.r(5, 13, 6, 3, (120, 120, 130, 255))        # gancho
    tiles.append(cadena)

    tina = Tile((0, 0, 0, 0))                          # 8 tina ultrasonica
    tina.r(0, 4, T, 11, metal)
    tina.r(0, 4, T, 2, (180, 180, 190, 255))
    tina.r(2, 6, 12, 6, (108, 186, 206, 255))
    tina.r(2, 6, 12, 1, (170, 226, 240, 255))
    tina.ruido((222, 244, 250, 255), [(4, 8), (7, 9), (10, 7), (12, 10)])
    tina.r(0, 13, T, 2, (96, 96, 106, 255))
    tiles.append(tina)

    niebla = Tile((0, 0, 0, 0))                        # 9 niebla del villano
    for x, y, w in ((1, 6, 6), (8, 4, 6), (4, 10, 8), (10, 11, 5)):
        niebla.r(x, y, w, 3, (176, 176, 186, 255))
        niebla.r(x, y, w - 1, 1, (206, 206, 214, 255))
    tiles.append(niebla)

    return "bodega", tiles, base


# --------------------------------------------------------------- la mina

def mina():
    """Mina abandonada: galerias, vetas de cuarzo que alumbran, vagonetas
    sobre rieles, estalactitas y el rio subterraneo."""
    pro, som, base, luz = tonos((84, 76, 88))          # roca
    cuarzo = (150, 224, 236, 255)
    cuarzo_luz = (216, 246, 250, 255)
    madera = (118, 84, 54, 255)
    metal = (128, 128, 138, 255)
    tiles = []

    piso = Tile(base)                                  # 0 roca
    piso.ruido(som, [(2, 3), (9, 5), (5, 11), (13, 8), (7, 14)])
    piso.ruido(luz, [(11, 2), (3, 8)])
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 roca con gravilla
    piso2.ruido(pro, [(4, 4), (10, 6), (6, 12), (12, 11), (2, 9)])
    piso2.r(6, 6, 3, 2, som)
    tiles.append(piso2)

    veta = Tile(base)                                  # 2 veta de cuarzo
    for i in range(5):
        veta.r(3 + i * 2, 4 + (i % 3) * 2, 3, 2, cuarzo)
        veta.p(3 + i * 2, 4 + (i % 3) * 2, cuarzo_luz)
    tiles.append(veta)

    pared = Tile((58, 52, 66, 255))                    # 3 pared de mina
    pared.r(0, 0, T, 2, (76, 68, 84, 255))
    pared.r(0, T - 2, T, 2, (42, 38, 50, 255))
    pared.ruido((48, 44, 56, 255), [(3, 5), (10, 8), (6, 11)])
    tiles.append(pared)

    viga = Tile((0, 0, 0, 0))                          # 4 viga de madera
    viga.r(0, 0, T, 4, madera)
    viga.r(0, 0, T, 1, (152, 112, 74, 255))
    viga.r(1, 4, 3, 12, madera)
    viga.r(12, 4, 3, 12, madera)
    viga.r(1, 4, 1, 12, (152, 112, 74, 255))
    tiles.append(viga)

    riel = Tile(base)                                  # 5 rieles
    riel.r(0, 5, T, 2, metal)
    riel.r(0, 10, T, 2, metal)
    riel.r(0, 5, T, 1, (168, 168, 178, 255))
    riel.r(0, 10, T, 1, (168, 168, 178, 255))
    for x in (2, 8, 14):
        riel.r(x, 4, 2, 9, madera)
    tiles.append(riel)

    vagoneta = Tile((0, 0, 0, 0))                      # 6 vagoneta
    vagoneta.r(1, 3, 14, 9, metal)
    vagoneta.r(1, 3, 14, 2, (168, 168, 178, 255))
    vagoneta.r(1, 10, 14, 2, (88, 88, 98, 255))
    vagoneta.r(3, 5, 10, 4, (64, 60, 70, 255))
    vagoneta.r(2, 12, 4, 3, (72, 72, 82, 255))
    vagoneta.r(10, 12, 4, 3, (72, 72, 82, 255))
    tiles.append(vagoneta)

    estalactita = Tile((0, 0, 0, 0))                   # 7 estalactitas
    for x, largo in ((2, 9), (7, 13), (12, 7)):
        for i in range(largo):
            ancho = max(1, 3 - i // 4)
            estalactita.r(x, i, ancho, 1, base)
            estalactita.p(x, i, luz)
    tiles.append(estalactita)

    agua = Tile((0, 0, 0, 0))                          # 8 rio subterraneo
    agua.r(0, 0, T, T, (52, 96, 128, 255))
    agua.r(0, 0, T, 2, (72, 126, 162, 255))
    agua.ruido((126, 186, 214, 255),
               [(3, 4), (4, 4), (9, 7), (10, 7), (6, 11), (12, 13)])
    tiles.append(agua)

    oscuro = Tile((0, 0, 0, 0))                        # 9 zona sin luz
    oscuro.r(0, 0, T, T, (18, 16, 26, 255))
    tiles.append(oscuro)

    return "mina", tiles, base


# -------------------------------------------------------------- el taller

def taller():
    """Taller de imitaciones: bandas transportadoras, prensas, moldes,
    engranes y chimeneas. Todo en verdes y cobrizos por el oxido."""
    pro, som, base, luz = tonos((92, 96, 92))          # piso metalico
    cobre = (168, 108, 62, 255)
    cobre_luz = (206, 146, 92, 255)
    cobre_som = (112, 68, 38, 255)
    verde = (96, 128, 104, 255)
    laton = (216, 178, 88, 255)
    metal = (124, 124, 134, 255)
    tiles = []

    piso = Tile(base)                                  # 0 placa metalica
    piso.r(0, 0, T, 1, luz)
    piso.r(0, T - 1, T, 1, pro)
    piso.r(0, 0, 1, T, luz)
    for x, y in ((3, 3), (12, 3), (3, 12), (12, 12)):
        piso.r(x, y, 2, 2, som)                        # remaches
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 placa oxidada
    piso2.r(0, 0, T, 1, luz)
    piso2.r(4, 5, 5, 4, verde)
    piso2.r(10, 10, 4, 3, cobre_som)
    tiles.append(piso2)

    rejilla = Tile((72, 76, 74, 255))                  # 2 pasarela de rejilla
    for x in range(0, T, 4):
        rejilla.r(x, 0, 2, T, (104, 108, 104, 255))
    for y in range(0, T, 4):
        rejilla.r(0, y, T, 2, (92, 96, 94, 255))
    tiles.append(rejilla)

    pared = Tile((74, 80, 76, 255))                    # 3 pared del taller
    pared.r(0, 0, T, 2, (94, 100, 96, 255))
    pared.r(0, T - 2, T, 2, (56, 62, 58, 255))
    pared.r(2, 5, 5, 4, verde)
    tiles.append(pared)

    banda = Tile((0, 0, 0, 0))                         # 4 banda transportadora
    banda.r(0, 3, T, 10, (58, 54, 58, 255))
    banda.r(0, 3, T, 2, (84, 80, 84, 255))
    banda.r(0, 11, T, 2, (40, 38, 42, 255))
    for x in range(1, T, 4):
        banda.r(x, 5, 2, 6, (74, 70, 74, 255))
    banda.r(5, 6, 4, 3, laton)                         # pieza de laton
    banda.r(5, 6, 4, 1, (244, 216, 140, 255))
    tiles.append(banda)

    engrane = Tile((0, 0, 0, 0))                       # 5 engrane
    engrane.r(3, 3, 10, 10, cobre)
    engrane.r(4, 4, 8, 8, cobre_luz)
    engrane.r(6, 6, 4, 4, cobre_som)
    for x, y in ((7, 0), (7, 13), (0, 7), (13, 7)):
        engrane.r(x, y, 2, 3 if x == 7 else 3, cobre)
    for x, y in ((1, 1), (12, 1), (1, 12), (12, 12)):
        engrane.r(x, y, 3, 3, cobre_som)
    tiles.append(engrane)

    prensa = Tile((0, 0, 0, 0))                        # 6 prensa de moldes
    prensa.r(0, 0, T, 6, metal)
    prensa.r(0, 0, T, 2, (162, 162, 172, 255))
    prensa.r(2, 6, 12, 3, (88, 88, 98, 255))
    prensa.r(6, 9, 4, 5, (64, 64, 74, 255))
    prensa.r(3, 13, 10, 3, cobre_som)
    tiles.append(prensa)

    chimenea = Tile((0, 0, 0, 0))                      # 7 chimenea
    chimenea.r(3, 4, 10, 12, cobre)
    chimenea.r(3, 4, 10, 2, cobre_luz)
    chimenea.r(3, 9, 10, 2, cobre_som)
    chimenea.r(4, 0, 8, 4, (146, 146, 156, 255))
    chimenea.r(5, 0, 6, 2, (186, 186, 196, 255))
    tiles.append(chimenea)

    molde = Tile((0, 0, 0, 0))                         # 8 mesa de moldes
    molde.r(0, 4, T, 10, (86, 78, 70, 255))
    molde.r(0, 4, T, 2, (112, 102, 92, 255))
    molde.r(2, 7, 4, 4, laton)
    molde.r(9, 7, 4, 4, (156, 132, 68, 255))
    molde.r(0, 12, T, 2, (62, 56, 50, 255))
    tiles.append(molde)

    chatarra = Tile((0, 0, 0, 0))                      # 9 chatarra
    chatarra.r(1, 9, 7, 5, cobre_som)
    chatarra.r(8, 7, 6, 7, verde)
    chatarra.r(4, 6, 5, 4, metal)
    chatarra.r(4, 6, 5, 1, (166, 166, 176, 255))
    chatarra.r(2, 13, 12, 2, (66, 62, 58, 255))
    tiles.append(chatarra)

    return "taller", tiles, base


# ------------------------------------------------------- armado y salida

def atlas(tiles):
    filas = (len(tiles) + COLS - 1) // COLS
    im = Image.new("RGBA", (COLS * T, filas * T), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        im.paste(t.im, ((i % COLS) * T, (i // COLS) * T))
    return im


# Plano de cada cuarto de muestra. Cada caracter es un tile:
#   #  pared      .  piso        ,  piso variante
#   Un digito es el indice de ese tile dentro del atlas del escenario.
# Los objetos van pegados a los muros y agrupados, como en un lugar real,
# en vez de salpicados al azar.
PLANOS = {
    # La tienda: vitrinas al fondo, mostrador al centro, aparador a la calle.
    "tienda": [
        "###############",
        "#66666...66666#",
        "#.............#",
        "#7...........7#",
        "#.....,,,.....#",
        "#..555...555..#",
        "#9....,,,....9#",
        "#....22222....#",
        "#####8888######",
    ],
    # La bodega: pasillos entre estantes altos, tarimas y la tina al fondo.
    "bodega": [
        "###############",
        "#4444...4444..#",
        "#.............#",
        "#...5.....5...#",
        "#..222...222..#",
        "#.7.........7.#",
        "#.....5.......#",
        "#6..........88#",
        "###############",
    ],
    # La mina: rieles cruzando, vetas que alumbran y el rio al fondo.
    "mina": [
        "###############",
        "#77.........77#",
        "#....2...2....#",
        "#4...........4#",
        "#5555555555555#",
        "#....6........#",
        "#2..........99#",
        "#8888.....2...#",
        "###############",
    ],
    # El taller: la banda cruzando, engranes en la pared y las prensas.
    "taller": [
        "###############",
        "#5..7777777..5#",
        "#.............#",
        "#..44444444...#",
        "#.............#",
        "#2222.....2222#",
        "#8..........8.#",
        "#9...66666...9#",
        "###############",
    ],
}

RUTA_DIANA = ("C:/Users/uriel/Documents/Empresa UTHH/"
              "Mes 2 - Proyecto Joyeria Diana Laura/Diana-y-el-Brillo-Perdido/"
              "sprites/personajes/diseno/00_diana_frames/01.png")


def cuarto(nombre, tiles):
    """Arma el cuarto de muestra y le pone a Diana encima, para la escala."""
    plano = PLANOS[nombre]
    an, al = len(plano[0]), len(plano)
    im = Image.new("RGBA", (an * T, al * T), (0, 0, 0, 0))
    for y, fila in enumerate(plano):
        for x, letra in enumerate(fila):
            if letra == "#":
                t = tiles[3]
            elif letra == ",":
                t = tiles[1]
            elif letra == ".":
                t = tiles[0]
            else:
                # Debajo de cada objeto va el piso, para que no quede hueco.
                im.paste(tiles[0].im, (x * T, y * T))
                t = tiles[int(letra)]
            im.paste(t.im, (x * T, y * T), t.im)

    # Diana al centro: sin una figura conocida no se aprecia el tamano.
    if os.path.exists(RUTA_DIANA):
        d = Image.open(RUTA_DIANA).convert("RGBA")
        im.paste(d, (im.width // 2 - 16, im.height // 2 - 8), d)
    return im


TITULOS = {
    "tienda": "Joyeria Diana Laura",
    "bodega": "Bodega del Proveedor",
    "mina": "Mina de Cuarzo",
    "taller": "Taller de Imitaciones",
}


def main():
    os.makedirs(SALIDA, exist_ok=True)
    previas = []
    for hacer in (tienda, bodega, mina, taller):
        nombre, tiles, _ = hacer()
        atlas(tiles).save(os.path.join(SALIDA, "tileset_%s.png" % nombre))

        vista = cuarto(nombre, tiles)
        zoom = 3
        g = vista.resize((vista.width * zoom, vista.height * zoom),
                         Image.NEAREST)
        fondo = Image.new("RGB", (g.width + 20, g.height + 20), (24, 22, 28))
        fondo.paste(g, (10, 10), g)
        fondo.save(os.path.join(SALIDA, "cuarto_%s.png" % nombre))
        previas.append((nombre, fondo))

        # El atlas ampliado, para revisarlo tile por tile.
        a = atlas(tiles)
        z = 8
        ga = a.resize((a.width * z, a.height * z), Image.NEAREST)
        fa = Image.new("RGB", (ga.width + 20, ga.height + 20), (240, 240, 244))
        fa.paste(ga, (10, 10), ga)
        fa.save(os.path.join(SALIDA, "tileset_%s_grande.png" % nombre))

    # Lamina con los cuatro cuartos, uno debajo de otro.
    ancho = max(f.width for _, f in previas)
    alto = sum(f.height for _, f in previas) + 10 * (len(previas) + 1)
    lam = Image.new("RGB", (ancho, alto), (24, 22, 28))
    y = 10
    for _, f in previas:
        lam.paste(f, (0, y))
        y += f.height + 10
    lam.save(os.path.join(SALIDA, "00_escenarios.png"))
    print("escenarios generados:", len(previas))


if __name__ == "__main__":
    main()
