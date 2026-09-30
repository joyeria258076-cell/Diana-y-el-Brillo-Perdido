# -*- coding: utf-8 -*-
"""Los escenarios de Diana y el Brillo Perdido.

Tiles de 32x32, la misma medida que los personajes. Eso es lo que hace que
Diana ocupe justo un cuadro de piso, como en los juegos de esta clase; con
tiles de 16 el personaje medía dos cuadros y el cuarto se veía chico a su
lado.

Cada escenario sale de su ficha en el libreto y se entrega en dos piezas:

  - Un atlas de tiles de 32x32. Los primeros cuatro son siempre los mismos:
    piso, dos variantes de piso y muro. Los demas son los objetos del lugar.
  - Un cuarto de muestra ya armado, con Diana adentro para ver la escala.

Escenarios, en orden de juego:
  0. Joyeria Diana Laura   - la tienda: tutorial, guardado y epilogo.
  1. Bodega del Proveedor  - estantes, tarimas, basculas y cadenas.
  2. Mina de Cuarzo        - galerias, vetas, rieles y vagonetas.
  3. Taller de Imitaciones - bandas, prensas, engranes y chimeneas.
"""
import os
from PIL import Image

T = 32
COLS = 5
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "escenarios")

RUTA_DIANA = ("C:/Users/uriel/Documents/Empresa UTHH/"
              "Mes 2 - Proyecto Joyeria Diana Laura/Diana-y-el-Brillo-Perdido/"
              "sprites/personajes/diseno/00_diana_frames/01.png")


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

    def salpicar(self, color, puntos):
        """Pixeles sueltos para que una superficie plana no se vea como
        una sabana de color."""
        for x, y in puntos:
            self.p(x, y, color)


def tonos(base):
    def esc(f):
        return (min(255, int(base[0] * f)), min(255, int(base[1] * f)),
                min(255, int(base[2] * f)), 255)
    return esc(0.6), esc(0.8), (base[0], base[1], base[2], 255), esc(1.2)


def muro(color_frente, color_tapa, detalle=None):
    """Muro con dos caras: la tapa de arriba, que es la que se ve desde la
    camara, y el frente, que es el que da al cuarto. Sin esa division los
    muros se ven como paredes planas."""
    pro, som, base, luz = tonos(color_frente)
    tpro, tsom, tapa, tluz = tonos(color_tapa)
    t = Tile(base)
    t.r(0, 0, T, 12, tapa)
    t.r(0, 0, T, 2, tluz)
    t.r(0, 10, T, 2, tpro)
    t.r(0, 12, T, 2, luz)
    t.r(0, T - 3, T, 3, pro)
    # Juntas de los bloques, alternadas como en un muro de verdad.
    t.r(0, 20, T, 1, som)
    t.r(15, 12, 1, 8, som)
    t.r(7, 21, 1, 11, som)
    t.r(23, 21, 1, 11, som)
    if detalle:
        detalle(t, (pro, som, base, luz))
    return t


# ---------------------------------------------------------------- la tienda

def tienda():
    pro, som, base, luz = tonos((216, 208, 198))      # loseta clara
    mpro, msom, mad, mluz = tonos((152, 106, 68))     # madera
    vidrio = (198, 226, 238, 255)
    vidrio_luz = (242, 252, 254, 255)
    oro = (228, 176, 60, 255)
    oro_luz = (252, 226, 140, 255)
    tiles = []

    piso = Tile(base)                                  # 0 loseta
    for x in (0, 16):
        piso.r(x, 0, 16, 1, luz)
        piso.r(x, 15, 16, 1, som)
    for y in (0, 16):
        piso.r(0, y, 1, 16, luz)
        piso.r(15, y, 1, 16, som)
    piso.r(16, 0, 1, T, luz)
    piso.r(0, 16, T, 1, luz)
    piso.r(31, 0, 1, T, som)
    piso.r(0, 31, T, 1, som)
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 loseta con rombo
    piso2.r(0, 0, T, 1, luz)
    piso2.r(0, 0, 1, T, luz)
    piso2.r(0, 31, T, 1, som)
    for i in range(8):
        piso2.r(16 - i, 8 + i, 1 + i * 2, 1, som)
    for i in range(8):
        piso2.r(9 + i, 16 + i, 15 - i * 2, 1, som)
    tiles.append(piso2)

    tapete = Tile((150, 82, 100, 255))                 # 2 tapete de entrada
    tapete.r(0, 0, T, 2, (184, 110, 128, 255))
    tapete.r(0, 30, T, 2, (118, 60, 78, 255))
    tapete.r(3, 3, 26, 26, (170, 96, 114, 255))
    tapete.r(6, 6, 20, 20, (150, 82, 100, 255))
    for x in range(2, 30, 4):
        tapete.p(x, 1, (206, 140, 154, 255))
    tiles.append(tapete)

    def moldura(t, c):
        pro2, som2, base2, luz2 = c
        t.r(0, 14, T, 2, mad)
        t.r(0, 14, T, 1, mluz)
    tiles.append(muro((196, 186, 176), (172, 162, 152), moldura))   # 3 muro

    mostrador = Tile((0, 0, 0, 0))                     # 4 mostrador
    mostrador.r(0, 4, T, 24, mad)
    mostrador.r(0, 4, T, 3, mluz)
    mostrador.r(0, 24, T, 4, mpro)
    mostrador.r(0, 12, T, 2, msom)
    for x in range(2, 30, 8):                          # vetas de la madera
        mostrador.r(x, 8, 5, 1, msom)
        mostrador.r(x + 2, 18, 5, 1, msom)
    mostrador.r(0, 27, T, 1, (86, 58, 36, 255))
    tiles.append(mostrador)

    vitrina = Tile((0, 0, 0, 0))                       # 5 vitrina con joyas
    vitrina.r(0, 0, T, 28, mad)
    vitrina.r(2, 2, 28, 20, vidrio)
    vitrina.r(2, 2, 28, 3, vidrio_luz)
    vitrina.r(2, 2, 3, 20, vidrio_luz)
    vitrina.r(6, 10, 7, 4, oro)                        # un anillo
    vitrina.r(6, 10, 3, 2, oro_luz)
    vitrina.r(18, 8, 4, 8, (230, 240, 248, 255))       # un collar
    vitrina.r(19, 16, 2, 2, (146, 210, 236, 255))
    vitrina.r(24, 12, 4, 4, oro)
    vitrina.r(0, 22, T, 6, mpro)
    vitrina.r(0, 26, T, 2, (86, 58, 36, 255))
    tiles.append(vitrina)

    espejo = Tile((0, 0, 0, 0))                        # 6 espejo de pared
    espejo.r(4, 0, 24, 28, oro)
    espejo.r(4, 0, 24, 2, oro_luz)
    espejo.r(6, 2, 20, 24, (176, 206, 222, 255))
    espejo.r(8, 4, 6, 16, (226, 240, 248, 255))
    espejo.r(16, 10, 4, 10, (208, 228, 238, 255))
    espejo.r(4, 26, 24, 2, (168, 122, 34, 255))
    tiles.append(espejo)

    aparador = Tile((0, 0, 0, 0))                      # 7 aparador a la calle
    aparador.r(0, 0, T, T, (112, 146, 166, 255))
    aparador.r(0, 0, T, 4, oro)
    aparador.r(0, 2, T, 2, (168, 122, 34, 255))
    for x in (4, 18):
        aparador.r(x, 8, 10, 20, (156, 190, 208, 255))
        aparador.r(x, 8, 4, 8, (216, 238, 246, 255))
    aparador.r(15, 6, 2, 26, (168, 122, 34, 255))
    tiles.append(aparador)

    planta = Tile((0, 0, 0, 0))                        # 8 maceta
    planta.r(9, 20, 14, 11, (156, 98, 70, 255))
    planta.r(9, 20, 14, 2, (192, 130, 96, 255))
    planta.r(9, 28, 14, 3, (118, 70, 48, 255))
    planta.r(7, 8, 18, 13, (78, 136, 82, 255))
    planta.r(9, 5, 14, 5, (102, 164, 98, 255))
    planta.r(11, 4, 8, 3, (136, 192, 122, 255))
    planta.r(12, 12, 6, 4, (60, 110, 66, 255))
    tiles.append(planta)

    return "tienda", tiles


# ------------------------------------------------------------- la bodega

def bodega():
    pro, som, base, luz = tonos((138, 122, 100))       # concreto
    cpro, csom, carton, cluz = tonos((180, 132, 82))   # cajas
    mpro, msom, mad, mluz = tonos((140, 100, 62))      # tarimas
    metal = (146, 146, 156, 255)
    metal_luz = (188, 188, 198, 255)
    tiles = []

    piso = Tile(base)                                  # 0 concreto
    piso.r(0, 0, T, 1, luz)
    piso.salpicar(som, [(4, 7), (18, 3), (11, 19), (26, 12), (6, 25),
                        (22, 27), (14, 9), (29, 20)])
    piso.salpicar(luz, [(16, 6), (8, 22), (24, 4)])
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 concreto agrietado
    piso2.r(0, 0, T, 1, luz)
    for i in range(14):
        piso2.p(6 + i, 10 + (i % 4), pro)
        piso2.p(6 + i, 11 + (i % 4), som)
    piso2.salpicar(som, [(20, 22), (25, 26), (9, 27)])
    tiles.append(piso2)

    tarima = Tile(base)                                # 2 tarima de madera
    for y in (2, 12, 22):
        tarima.r(0, y, T, 7, mad)
        tarima.r(0, y, T, 2, mluz)
        tarima.r(0, y + 5, T, 2, mpro)
        for x in range(3, 30, 9):
            tarima.r(x, y + 2, 6, 1, msom)
    tiles.append(tarima)

    def manchas(t, c):
        pro2, som2, base2, luz2 = c
        t.r(4, 18, 7, 5, som2)
        t.r(20, 24, 6, 4, som2)
    tiles.append(muro((112, 100, 86), (94, 84, 72), manchas))       # 3 muro

    estante = Tile((0, 0, 0, 0))                       # 4 estante alto
    estante.r(0, 0, T, T, mad)
    estante.r(0, 0, T, 2, mluz)
    estante.r(0, 0, 2, T, mluz)
    for y in (9, 20, 30):
        estante.r(0, y, T, 3, mpro)
        estante.r(0, y, T, 1, msom)
    estante.r(3, 2, 10, 7, carton)
    estante.r(3, 2, 10, 2, cluz)
    estante.r(15, 3, 8, 6, csom)
    estante.r(5, 13, 9, 7, carton)
    estante.r(5, 13, 9, 2, cluz)
    estante.r(18, 14, 10, 6, cpro)
    estante.r(4, 24, 12, 6, csom)
    estante.r(20, 25, 8, 5, carton)
    tiles.append(estante)

    caja = Tile((0, 0, 0, 0))                          # 5 caja de carton
    caja.r(2, 6, 28, 24, carton)
    caja.r(2, 6, 28, 4, cluz)
    caja.r(2, 26, 28, 4, cpro)
    caja.r(15, 6, 3, 24, csom)                         # cinta de union
    caja.r(2, 16, 28, 2, csom)
    caja.r(6, 20, 8, 4, cpro)                          # etiqueta
    caja.r(6, 20, 8, 1, (236, 226, 206, 255))
    tiles.append(caja)

    bascula = Tile((0, 0, 0, 0))                       # 6 bascula
    bascula.r(3, 18, 26, 12, metal)
    bascula.r(3, 18, 26, 2, metal_luz)
    bascula.r(3, 27, 26, 3, (98, 98, 108, 255))
    bascula.r(10, 6, 12, 12, metal)
    bascula.r(11, 7, 10, 9, (238, 242, 246, 255))
    bascula.r(15, 9, 2, 5, (200, 60, 60, 255))         # aguja
    bascula.r(13, 14, 6, 1, (140, 140, 150, 255))
    tiles.append(bascula)

    cadena = Tile((0, 0, 0, 0))                        # 7 cadena del techo
    for y in range(0, 24, 5):
        cadena.r(14, y, 5, 4, metal)
        cadena.r(15, y + 1, 3, 2, (96, 96, 106, 255))
        cadena.r(14, y, 5, 1, metal_luz)
    cadena.r(10, 23, 13, 4, (126, 126, 136, 255))      # gancho
    cadena.r(10, 23, 13, 1, metal_luz)
    cadena.r(14, 27, 5, 5, (110, 110, 120, 255))
    tiles.append(cadena)

    tina = Tile((0, 0, 0, 0))                          # 8 tina ultrasonica
    tina.r(0, 6, T, 24, metal)
    tina.r(0, 6, T, 3, metal_luz)
    tina.r(3, 11, 26, 14, (104, 184, 206, 255))
    tina.r(3, 11, 26, 2, (172, 228, 242, 255))
    tina.salpicar((236, 250, 252, 255),
                  [(7, 16), (12, 19), (18, 14), (23, 21), (9, 22), (25, 15)])
    tina.r(0, 26, T, 4, (92, 92, 102, 255))
    tiles.append(tina)

    return "bodega", tiles


# --------------------------------------------------------------- la mina

def mina():
    pro, som, base, luz = tonos((88, 80, 92))          # roca
    cuarzo = (152, 226, 238, 255)
    cuarzo_luz = (222, 248, 252, 255)
    madera = (122, 88, 56, 255)
    madera_luz = (158, 118, 78, 255)
    metal = (132, 132, 142, 255)
    tiles = []

    piso = Tile(base)                                  # 0 roca
    piso.salpicar(som, [(5, 6), (17, 10), (9, 21), (26, 16), (13, 27),
                        (21, 4), (29, 25), (3, 14)])
    piso.salpicar(luz, [(20, 8), (7, 18), (25, 29)])
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 roca con gravilla
    for x, y in ((7, 8), (19, 12), (11, 24), (24, 20), (15, 5), (5, 27)):
        piso2.r(x, y, 3, 2, pro)
        piso2.p(x, y, som)
    piso2.salpicar(som, [(13, 16), (27, 9), (9, 13)])
    tiles.append(piso2)

    veta = Tile(base)                                  # 2 veta de cuarzo
    for i, (x, y) in enumerate(((4, 8), (10, 14), (16, 9), (21, 18),
                                (26, 12), (13, 24), (7, 22))):
        veta.r(x, y, 5, 4, cuarzo)
        veta.r(x, y, 3, 2, cuarzo_luz)
        veta.r(x + 1, y + 3, 3, 1, (96, 172, 190, 255))
    tiles.append(veta)

    def vetita(t, c):
        t.r(6, 18, 5, 3, cuarzo)
        t.r(6, 18, 3, 2, cuarzo_luz)
        t.r(22, 25, 4, 3, cuarzo)
    tiles.append(muro((66, 60, 76), (50, 46, 60), vetita))          # 3 muro

    viga = Tile((0, 0, 0, 0))                          # 4 viga de sosten
    viga.r(0, 0, T, 8, madera)
    viga.r(0, 0, T, 2, madera_luz)
    viga.r(0, 6, T, 2, (86, 60, 38, 255))
    viga.r(2, 8, 6, 24, madera)
    viga.r(24, 8, 6, 24, madera)
    viga.r(2, 8, 2, 24, madera_luz)
    viga.r(24, 8, 2, 24, madera_luz)
    for y in range(12, 30, 6):
        viga.r(2, y, 6, 1, (86, 60, 38, 255))
        viga.r(24, y, 6, 1, (86, 60, 38, 255))
    tiles.append(viga)

    riel = Tile(base)                                  # 5 rieles
    for x in range(2, 30, 10):
        riel.r(x, 6, 7, 20, madera)
        riel.r(x, 6, 7, 2, madera_luz)
    riel.r(0, 9, T, 4, metal)
    riel.r(0, 22, T, 4, metal)
    riel.r(0, 9, T, 1, (180, 180, 190, 255))
    riel.r(0, 22, T, 1, (180, 180, 190, 255))
    riel.r(0, 12, T, 1, (84, 84, 94, 255))
    riel.r(0, 25, T, 1, (84, 84, 94, 255))
    tiles.append(riel)

    vagoneta = Tile((0, 0, 0, 0))                      # 6 vagoneta
    vagoneta.r(2, 6, 28, 18, metal)
    vagoneta.r(2, 6, 28, 3, (180, 180, 190, 255))
    vagoneta.r(2, 20, 28, 4, (92, 92, 102, 255))
    vagoneta.r(5, 9, 22, 9, (58, 54, 64, 255))
    vagoneta.r(7, 11, 8, 5, (110, 92, 70, 255))        # mineral adentro
    vagoneta.r(17, 12, 7, 4, (128, 108, 82, 255))
    for x in (4, 22):                                  # ruedas
        vagoneta.r(x, 24, 7, 7, (74, 74, 84, 255))
        vagoneta.r(x + 2, 26, 3, 3, (48, 48, 58, 255))
    tiles.append(vagoneta)

    estalactita = Tile((0, 0, 0, 0))                   # 7 estalactitas
    for x, largo in ((4, 18), (14, 26), (24, 14)):
        for i in range(largo):
            ancho = max(1, 6 - i // 4)
            estalactita.r(x, i, ancho, 1, base)
            estalactita.p(x, i, luz)
            if i > largo - 4:
                estalactita.p(x, i, som)
    tiles.append(estalactita)

    agua = Tile((0, 0, 0, 0))                          # 8 rio subterraneo
    agua.r(0, 0, T, T, (48, 92, 126, 255))
    agua.r(0, 0, T, 3, (70, 126, 164, 255))
    for x, y, w in ((4, 8, 9), (18, 14, 8), (9, 22, 11), (22, 26, 7)):
        agua.r(x, y, w, 2, (120, 182, 212, 255))
        agua.r(x + 1, y + 1, w - 2, 1, (166, 214, 236, 255))
    tiles.append(agua)

    return "mina", tiles


# -------------------------------------------------------------- el taller

def taller():
    pro, som, base, luz = tonos((96, 100, 96))         # placa metalica
    cobre = (172, 112, 64, 255)
    cobre_luz = (212, 152, 96, 255)
    cobre_som = (114, 70, 38, 255)
    verde = (98, 132, 106, 255)
    laton = (220, 182, 92, 255)
    laton_luz = (248, 222, 148, 255)
    metal = (128, 128, 138, 255)
    tiles = []

    piso = Tile(base)                                  # 0 placa remachada
    piso.r(0, 0, T, 2, luz)
    piso.r(0, 0, 2, T, luz)
    piso.r(0, T - 2, T, 2, pro)
    piso.r(T - 2, 0, 2, T, pro)
    for x, y in ((5, 5), (25, 5), (5, 25), (25, 25)):
        piso.r(x, y, 3, 3, som)
        piso.p(x, y, luz)
    tiles.append(piso)

    piso2 = Tile(base)                                 # 1 placa oxidada
    piso2.r(0, 0, T, 2, luz)
    piso2.r(0, 0, 2, T, luz)
    piso2.r(8, 10, 11, 8, verde)
    piso2.r(8, 10, 5, 3, (124, 158, 130, 255))
    piso2.r(20, 20, 8, 6, cobre_som)
    piso2.salpicar(verde, [(6, 24), (26, 8), (14, 26)])
    tiles.append(piso2)

    rejilla = Tile((78, 82, 80, 255))                  # 2 pasarela de rejilla
    for x in range(0, T, 8):
        rejilla.r(x, 0, 4, T, (110, 114, 110, 255))
        rejilla.r(x, 0, 1, T, (134, 138, 134, 255))
    for y in range(0, T, 8):
        rejilla.r(0, y, T, 4, (98, 102, 100, 255))
        rejilla.r(0, y, T, 1, (126, 130, 126, 255))
    tiles.append(rejilla)

    def oxido(t, c):
        t.r(5, 16, 9, 6, verde)
        t.r(22, 24, 7, 5, verde)
        t.r(5, 16, 4, 2, (124, 158, 130, 255))
    tiles.append(muro((82, 88, 84), (66, 72, 68), oxido))           # 3 muro

    banda = Tile((0, 0, 0, 0))                         # 4 banda con piezas
    banda.r(0, 6, T, 22, (60, 56, 60, 255))
    banda.r(0, 6, T, 3, (88, 84, 88, 255))
    banda.r(0, 24, T, 4, (42, 40, 44, 255))
    for x in range(2, 32, 6):
        banda.r(x, 10, 3, 14, (78, 74, 78, 255))
    banda.r(8, 13, 9, 8, laton)                        # pieza de laton
    banda.r(8, 13, 9, 2, laton_luz)
    banda.r(8, 19, 9, 2, (150, 122, 58, 255))
    banda.r(22, 15, 6, 6, laton)
    banda.r(22, 15, 6, 2, laton_luz)
    tiles.append(banda)

    engrane = Tile((0, 0, 0, 0))                       # 5 engrane
    engrane.r(6, 6, 20, 20, cobre)
    engrane.r(8, 8, 16, 16, cobre_luz)
    engrane.r(12, 12, 8, 8, cobre_som)
    engrane.r(14, 14, 4, 4, (68, 60, 56, 255))
    for x, y, w, h in ((13, 0, 6, 8), (13, 24, 6, 8),
                       (0, 13, 8, 6), (24, 13, 8, 6)):
        engrane.r(x, y, w, h, cobre)
        engrane.r(x, y, w if h > w else 2, 2 if h > w else h, cobre_luz)
    for x, y in ((3, 3), (25, 3), (3, 25), (25, 25)):
        engrane.r(x, y, 5, 5, cobre_som)
    tiles.append(engrane)

    prensa = Tile((0, 0, 0, 0))                        # 6 prensa de moldes
    prensa.r(0, 0, T, 12, metal)
    prensa.r(0, 0, T, 3, (170, 170, 180, 255))
    prensa.r(0, 9, T, 3, (88, 88, 98, 255))
    prensa.r(5, 12, 8, 8, (96, 96, 106, 255))
    prensa.r(19, 12, 8, 8, (96, 96, 106, 255))
    prensa.r(8, 20, 16, 8, (64, 64, 74, 255))
    prensa.r(8, 20, 16, 2, (110, 110, 120, 255))
    prensa.r(4, 28, 24, 4, cobre_som)
    tiles.append(prensa)

    chimenea = Tile((0, 0, 0, 0))                      # 7 chimenea
    chimenea.r(6, 8, 20, 24, cobre)
    chimenea.r(6, 8, 20, 3, cobre_luz)
    chimenea.r(6, 18, 20, 4, cobre_som)
    chimenea.r(6, 28, 20, 4, cobre_som)
    chimenea.r(8, 0, 16, 8, (152, 152, 162, 255))
    chimenea.r(10, 0, 12, 3, (196, 196, 206, 255))
    chimenea.r(8, 6, 16, 2, (104, 104, 114, 255))
    for x in (9, 21):
        chimenea.r(x, 12, 3, 3, verde)
    tiles.append(chimenea)

    molde = Tile((0, 0, 0, 0))                         # 8 mesa de moldes
    molde.r(0, 8, T, 20, (90, 82, 72, 255))
    molde.r(0, 8, T, 3, (118, 108, 96, 255))
    molde.r(0, 24, T, 4, (64, 58, 52, 255))
    molde.r(4, 13, 9, 9, laton)
    molde.r(4, 13, 9, 2, laton_luz)
    molde.r(18, 13, 9, 9, (160, 134, 70, 255))
    molde.r(18, 13, 9, 2, (196, 168, 96, 255))
    molde.r(6, 15, 5, 5, (150, 120, 56, 255))
    tiles.append(molde)

    return "taller", tiles


# ------------------------------------------------------- armado y salida

def atlas(tiles):
    filas = (len(tiles) + COLS - 1) // COLS
    im = Image.new("RGBA", (COLS * T, filas * T), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        im.paste(t.im, ((i % COLS) * T, (i // COLS) * T))
    return im


# Planos de los cuartos. Cada caracter es un tile:
#   #  muro    .  piso    ,  piso variante    digito = ese tile del atlas
# Son mas anchos que altos porque la pantalla del juego es apaisada.
PLANOS = {
    "tienda": [
        "#####################",
        "#5555555...5555555..#",
        "#...................#",
        "#6.................6#",
        "#.......,,,,,.......#",
        "#...4444.....4444...#",
        "#8......,,,,,......8#",
        "#.......22222.......#",
        "#########7777########",
    ],
    "bodega": [
        "#####################",
        "#44444....44444.....#",
        "#...................#",
        "#..5....7....5....7.#",
        "#..222222...222222..#",
        "#...................#",
        "#.....5.......5.....#",
        "#6................88#",
        "#####################",
    ],
    "mina": [
        "#####################",
        "#777...........777..#",
        "#.....2.....2.......#",
        "#4.................4#",
        "#5555555555555555555#",
        "#.....6........,....#",
        "#..2...............2#",
        "#88888.......2......#",
        "#####################",
    ],
    "taller": [
        "#####################",
        "#5...77777777....5..#",
        "#...................#",
        "#..44444444444......#",
        "#...................#",
        "#2222.......2222....#",
        "#8...............8..#",
        "#....6666666........#",
        "#####################",
    ],
}


def cuarto(nombre, tiles):
    """Arma el cuarto de muestra y pone a Diana adentro, para la escala."""
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
                im.paste(tiles[0].im, (x * T, y * T))
                t = tiles[int(letra)]
            im.paste(t.im, (x * T, y * T), t.im)

    if os.path.exists(RUTA_DIANA):
        d = Image.open(RUTA_DIANA).convert("RGBA")
        im.paste(d, (im.width // 2 - 16, im.height // 2 - 16), d)
    return im


def main():
    os.makedirs(SALIDA, exist_ok=True)
    previas = []
    for hacer in (tienda, bodega, mina, taller):
        nombre, tiles = hacer()
        atlas(tiles).save(os.path.join(SALIDA, "tileset_%s.png" % nombre))

        vista = cuarto(nombre, tiles)
        zoom = 2
        g = vista.resize((vista.width * zoom, vista.height * zoom),
                         Image.NEAREST)
        fondo = Image.new("RGB", (g.width + 20, g.height + 20), (22, 20, 26))
        fondo.paste(g, (10, 10), g)
        fondo.save(os.path.join(SALIDA, "cuarto_%s.png" % nombre))
        previas.append(fondo)

        a = atlas(tiles)
        z = 5
        ga = a.resize((a.width * z, a.height * z), Image.NEAREST)
        fa = Image.new("RGB", (ga.width + 20, ga.height + 20), (240, 240, 244))
        fa.paste(ga, (10, 10), ga)
        fa.save(os.path.join(SALIDA, "tileset_%s_grande.png" % nombre))

    ancho = max(f.width for f in previas)
    alto = sum(f.height for f in previas) + 10 * (len(previas) + 1)
    lam = Image.new("RGB", (ancho, alto), (22, 20, 26))
    y = 10
    for f in previas:
        lam.paste(f, (0, y))
        y += f.height + 10
    lam.save(os.path.join(SALIDA, "00_escenarios.png"))
    print("escenarios generados:", len(previas))


if __name__ == "__main__":
    main()
