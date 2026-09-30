# -*- coding: utf-8 -*-
"""El reparto de Diana y el Brillo Perdido, en 32x32.

Cada personaje sigue su ficha de apariencia del libreto, al pie de la letra.
Todos comparten el mismo molde que Diana: silueta de cabeza redondeada fila
por fila, sombreado cel de cuatro tonos, contorno limpio de un pixel, luz
desde arriba a la izquierda y rebote de un pixel al caminar.

Una sola vista de frente que se voltea en espejo, como dice la propuesta.
"""
import os
from PIL import Image

W, H = 32, 32
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "reparto")

NEGRO = (30, 24, 34, 255)
BLANCO = (255, 255, 255, 255)
OJO = (36, 26, 40, 255)

PIEL_PRO = (168, 112, 88, 255)
PIEL_SOM = (206, 156, 122, 255)
PIEL = (242, 202, 168, 255)
PIEL_LUZ = (255, 232, 206, 255)

ORO_PRO = (146, 96, 24, 255)
ORO = (226, 172, 56, 255)
ORO_LUZ = (255, 226, 130, 255)

# Silueta de la cabeza, la misma que usa Diana.
CRANEO = {
    1: (11, 20), 2: (9, 22), 3: (8, 23), 4: (7, 24), 5: (7, 24),
    6: (6, 25), 7: (6, 25), 8: (6, 25), 9: (6, 25), 10: (6, 25),
    11: (6, 25), 12: (7, 24), 13: (8, 23), 14: (10, 21), 15: (12, 19),
}


class Lienzo:
    def __init__(self):
        self.im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.px = self.im.load()

    def r(self, x, y, w, h, c):
        for j in range(h):
            for i in range(w):
                if 0 <= x + i < W and 0 <= y + j < H:
                    self.px[x + i, y + j] = c

    def p(self, x, y, c):
        self.r(x, y, 1, 1, c)


def tonos(base):
    """Cuatro tonos de un color: sombra profunda, sombra, base y luz."""
    def esc(f):
        return (min(255, int(base[0] * f)), min(255, int(base[1] * f)),
                min(255, int(base[2] * f)), 255)
    return esc(0.55), esc(0.75), (base[0], base[1], base[2], 255), esc(1.28)


def contornear(l):
    original = l.im.copy().load()
    for y in range(H):
        for x in range(W):
            if original[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and original[nx, ny][3] == 255:
                    l.px[x, y] = NEGRO
                    break


def rostro(l, ojos_y=9, boca=(170, 92, 100, 255), rubor=None):
    """Ojos grandes con brillo, boca y rubor. Los mismos que los de Diana."""
    for x in (12, 18):
        l.r(x, ojos_y, 3, 4, OJO)
        l.r(x, ojos_y, 1, 1, BLANCO)
        l.p(x + 2, ojos_y + 3, BLANCO)
    if rubor:
        l.r(8, ojos_y + 3, 2, 2, rubor)
        l.r(22, ojos_y + 3, 2, 2, rubor)
    l.r(15, ojos_y + 5, 2, 1, boca)


# ----------------------------------------------------------------- humanos

class Humano:
    """Molde comun. Cada ficha cambia colores, estatura y accesorios."""

    def __init__(self, pelo, ropa, bajo, piel=PIEL, alto=0, ancho=0,
                 encima=None, debajo=None, sombrero=None, bigote=False,
                 rubor=None, cara=True, despues=None):
        self.pelo = tonos(pelo)
        self.ropa = tonos(ropa)
        self.bajo = tonos(bajo)
        self.piel = piel
        self.alto = alto        # positivo = mas bajito
        self.ancho = ancho      # negativo = mas delgado
        self.encima = encima
        self.debajo = debajo
        self.sombrero = sombrero
        self.bigote = bigote
        self.rubor = rubor
        self.cara = cara
        self.despues = despues

    def cabeza(self, l):
        pro, som, base, luz = self.pelo
        d = self.alto
        for y, (a, b) in CRANEO.items():
            l.r(a, y + d, b - a + 1, 1, self.piel)
        l.r(9, 7 + d, 5, 4, PIEL_LUZ)
        l.r(20, 8 + d, 3, 6, PIEL_SOM)
        l.r(21, 10 + d, 2, 3, PIEL_PRO)
        l.r(13, 15 + d, 6, 1, PIEL_SOM)

        l.r(11, 0 + d, 10, 1, som)
        l.r(9, 1 + d, 14, 2, base)
        l.r(7, 3 + d, 18, 3, base)
        l.r(6, 6 + d, 3, 7, base)
        l.r(23, 6 + d, 3, 7, base)
        l.r(10, 1 + d, 7, 2, luz)
        l.r(20, 4 + d, 5, 2, som)
        l.r(23, 9 + d, 3, 4, pro)

        if self.sombrero:
            self.sombrero(l, self)
        if self.cara:
            rostro(l, ojos_y=9 + d, rubor=self.rubor)
        if self.bigote:
            l.r(12, 14 + d, 8, 1, luz)
            l.r(13, 15 + d, 6, 1, base)

    def torso(self, l, balanceo=0):
        pro, som, base, luz = self.ropa
        d = self.alto
        a = 9 - self.ancho
        an = 14 + self.ancho * 2

        if self.debajo:
            self.debajo(l, self)

        l.r(a, 16 + d, an, 8, base)
        l.r(a, 22 + d, an, 2, som)
        l.r(a, 23 + d, an, 1, pro)
        l.r(a + 1, 17 + d, 2, 5, luz)
        l.r(a + an - 3, 17 + d, 3, 7, som)
        l.r(13, 16 + d, 6, 1, PIEL_PRO)

        if self.encima:
            self.encima(l, self)

        # Brazos: el hombro queda fijo y solo se mueve del codo para abajo.
        for x, ilum, sentido in ((a - 3, True, 1), (a + an, False, -1)):
            dy = balanceo * sentido
            l.r(x, 17 + d, 3, 3, luz if ilum else base)
            l.r(x, 20 + d + dy, 3, 1, som if ilum else pro)
            l.r(x, 21 + d + dy, 3, 3, self.piel if ilum else PIEL_SOM)
            if dy > 0:
                l.r(x, 20 + d, 3, 1, base if ilum else som)

    def piernas(self, l, izq, der):
        pro, som, base, luz = self.bajo
        d = self.alto
        for x, sube in ((11, izq), (17, der)):
            y = 24 + d - sube
            l.r(x, y, 4, 3, base)
            l.r(x, y + 2, 4, 1, som)
            l.r(x, y + 3, 4, 3, (112, 78, 56, 255))
            l.r(x, y + 5, 4, 1, (72, 48, 36, 255))

    def cuadro(self, fase):
        balanceo = {0: 0, 1: -1, 2: 0, 3: 1}[fase]
        cuerpo = Lienzo()
        self.torso(cuerpo, balanceo)
        self.cabeza(cuerpo)
        l = Lienzo()
        self.piernas(l, 1 if fase == 1 else 0, 1 if fase == 3 else 0)
        l.im.alpha_composite(cuerpo.im, (0, 0),
                             (0, 1 if fase in (1, 3) else 0, W, H))
        contornear(l)
        if self.despues:
            # Se dibuja despues del contorno para que no lleve borde negro:
            # el humo no tiene silueta definida.
            self.despues(l, self, fase)
        return l.im


# ------------------------------------------------- accesorios por ficha

def cara_mayor(l, p):
    """Rasgos de persona mayor: cejas pobladas, arrugas y mejillas hundidas.
    Sin esto, un abuelo y un joven se ven iguales a 32 pixeles."""
    d = p.alto
    pro, som, base, luz = p.pelo
    l.r(11, 8 + d, 4, 1, luz)                  # cejas
    l.r(18, 8 + d, 4, 1, luz)
    l.r(10, 13 + d, 2, 1, PIEL_PRO)            # arrugas de los pomulos
    l.r(20, 13 + d, 2, 1, PIEL_PRO)
    l.r(12, 7 + d, 3, 1, PIEL_SOM)             # linea de la frente
    l.r(18, 7 + d, 3, 1, PIEL_SOM)


def camisa_arremangada(l, p):
    """Don Aurelio: camisa de manga larga arremangada hasta el codo, con
    cuello, botones y el cinturon."""
    pro, som, base, luz = p.ropa
    d = p.alto
    l.r(14, 16 + d, 1, 6, som)                 # botonadura
    for y in (18, 20, 22):
        l.p(14, y + d, ORO_PRO)
    l.r(12, 16 + d, 2, 2, luz)                 # cuello
    l.r(16, 16 + d, 2, 2, som)
    l.r(9, 21 + d, 14, 2, (108, 78, 54, 255))  # cinturon
    l.r(14, 21 + d, 3, 2, ORO_PRO)             # hebilla
    l.r(10, 19 + d, 1, 3, som)                 # pliegues
    l.r(20, 18 + d, 1, 4, som)
    for x in (6, 23):                          # dobleces de las mangas
        l.r(x, 19 + d, 3, 1, luz)
        l.r(x, 20 + d, 3, 1, som)


def sombrero_palma(l, p):
    """Don Aurelio: sombrero de palma de ala ancha."""
    paja_pro, paja_som, paja, paja_luz = tonos((206, 176, 112))
    d = p.alto
    l.r(3, 5 + d, 26, 2, paja_som)
    l.r(4, 4 + d, 24, 1, paja)
    l.r(8, 1 + d, 16, 4, paja)
    l.r(9, 0 + d, 14, 1, paja_som)
    l.r(9, 1 + d, 7, 2, paja_luz)
    l.r(8, 4 + d, 16, 1, paja_pro)
    l.r(8, 3 + d, 16, 1, (118, 86, 58, 255))   # cinta
    # Trenzado de la palma: rayitas alternadas en la copa y el ala.
    for x in range(9, 23, 3):
        l.p(x, 2 + d, paja_pro)
        l.p(x + 1, 5 + d, paja_pro)
    for x in range(4, 28, 3):
        l.p(x, 6 + d, paja_pro)


def maletin(l, p):
    """Don Aurelio: el maletin de cuero con muestrarios."""
    cuero_pro, cuero_som, cuero, _ = tonos((132, 88, 54))
    d = p.alto
    l.r(24, 23 + d, 6, 6, cuero)
    l.r(24, 27 + d, 6, 2, cuero_som)
    l.r(25, 24 + d, 2, 2, (172, 124, 80, 255))
    l.r(26, 22 + d, 3, 1, cuero_pro)
    l.r(26, 25 + d, 1, 2, ORO)


def lentes_grandes(l, p):
    """Dona Chela: lentes grandes, lo que mas la distingue."""
    d = p.alto
    l.r(9, 8 + d, 6, 6, ORO_PRO)
    l.r(17, 8 + d, 6, 6, ORO_PRO)
    l.r(10, 9 + d, 4, 4, (198, 226, 236, 255))
    l.r(18, 9 + d, 4, 4, (198, 226, 236, 255))
    l.r(10, 9 + d, 2, 1, BLANCO)
    l.r(18, 9 + d, 2, 1, BLANCO)
    l.r(15, 10 + d, 2, 1, ORO_PRO)
    # Los ojos se pintan aqui, ya detras del cristal.
    for x in (11, 19):
        l.r(x, 10 + d, 2, 2, OJO)
    l.r(15, 14 + d, 2, 1, (170, 92, 100, 255))
    l.r(8, 12 + d, 2, 2, (232, 156, 152, 255))
    l.r(23, 12 + d, 2, 2, (232, 156, 152, 255))
    l.r(10, 15 + d, 3, 1, PIEL_PRO)              # arrugas
    l.r(19, 15 + d, 3, 1, PIEL_PRO)
    l.r(13, 7 + d, 3, 1, PIEL_SOM)


def blusa_bordada(l, p):
    """Dona Chela: blusa con flores bordadas, como las de la region."""
    pro, som, base, luz = p.ropa
    d = p.alto
    for x, y, c in ((11, 19, (226, 112, 128, 255)),
                    (15, 21, (240, 196, 92, 255)),
                    (19, 19, (140, 186, 150, 255))):
        l.r(x, y + d, 3, 3, c)
        l.p(x + 1, y + 1 + d, (250, 244, 232, 255))
        l.p(x + 1, y + d, c)
    l.r(10, 22 + d, 12, 1, som)


def trenza(l, p):
    """Dona Chela: el cabello canoso recogido en trenza, cayendo de un lado."""
    pro, som, base, luz = p.pelo
    d = p.alto
    for i, y in enumerate(range(13, 25, 3)):
        x = 24 if i % 2 == 0 else 25
        l.r(x, y + d, 3, 3, base if i % 2 == 0 else som)
        l.p(x, y + d, luz)
    l.r(25, 25 + d, 2, 1, (216, 132, 150, 255))   # liston


def rebozo_rosa(l, p):
    """Dona Chela: rebozo rosa sobre los hombros, con flecos."""
    pro, som, base, luz = tonos((216, 132, 150))
    d = p.alto
    l.r(7, 16 + d, 18, 4, base)
    l.r(7, 19 + d, 3, 6, som)
    l.r(22, 19 + d, 3, 6, pro)
    l.r(8, 16 + d, 6, 1, luz)
    # Franjas tejidas del rebozo y los flecos de la orilla.
    for y in (17, 19):
        for x in range(8, 24, 2):
            l.p(x, y + d, luz)
    for x in range(8, 24, 2):
        l.p(x, 20 + d, pro)
        l.p(x, 21 + d, som)


def libreta(l, p):
    """Dona Chela: la libreta de pagos del apartado."""
    d = p.alto
    l.r(24, 21 + d, 6, 7, (246, 242, 232, 255))
    l.r(24, 21 + d, 6, 1, (196, 190, 178, 255))
    l.r(24, 21 + d, 1, 7, (176, 84, 92, 255))
    for y in (23, 25, 27):
        l.r(26, y + d, 3, 1, (176, 170, 160, 255))


def capucha(l, p):
    """Vendedor de Humo: capucha de tela con la cara en sombra.

    La tela lleva pliegues y el borde cae en picos: sin eso, a 32 pixeles
    una capucha lisa se lee como casco de metal.
    """
    pro, som, base, luz = tonos((132, 128, 142))
    d = p.alto
    for y, (a, b) in CRANEO.items():
        if y <= 13:
            l.r(a - 1, y + d, b - a + 3, 1, base)
    l.r(9, 1 + d, 7, 3, luz)                   # luz de arriba
    l.r(20, 3 + d, 6, 10, som)                 # lado en sombra
    l.r(12, 2 + d, 1, 5, som)                  # pliegues de la tela
    l.r(17, 3 + d, 1, 4, som)
    l.r(9, 5 + d, 1, 6, luz)

    l.r(10, 8 + d, 12, 6, (44, 42, 52, 255))   # la cara, en sombra
    for x in (13, 17):
        l.r(x, 10 + d, 2, 2, (250, 232, 140, 255))

    # Borde de la capucha: cae parejo sobre los hombros, con su sombra.
    l.r(6, 13 + d, 20, 2, base)
    l.r(5, 15 + d, 22, 1, som)
    l.r(6, 16 + d, 20, 1, pro)
    # Pliegues de la tela que cuelga, y el cordon del cuello.
    for x in (8, 12, 19, 23):
        l.r(x, 14 + d, 1, 2, som)
    l.r(11, 16 + d, 10, 1, (98, 94, 108, 255))
    l.p(15, 17 + d, (172, 168, 182, 255))


def tunica(l, p):
    """Vendedor de Humo: tunica larga con pliegues y los bordes deshilachados.
    La tela cae hasta los pies, por eso casi no se le ven las piernas."""
    pro, som, base, luz = p.ropa
    d = p.alto
    # La tunica se dibuja fila por fila: angosta en los hombros y mas
    # ancha abajo. Un rectangulo se lee como monolito, no como tela.
    silueta = ((10, 21), (9, 22), (9, 22), (8, 23), (8, 23), (7, 24),
               (7, 24), (6, 25), (6, 25), (5, 26), (5, 26))
    for i, (a, b) in enumerate(silueta):
        y = 17 + d + i
        l.r(a, y, b - a + 1, 1, base)
        l.r(a, y, 2, 1, luz)
        l.r(b - 1, y, 2, 1, pro)
    for x in (12, 16, 20):                      # pliegues verticales
        l.r(x, 19 + d, 1, 8, som)
    # Orilla deshilachada, en picos desiguales.
    for i, x in enumerate(range(5, 27, 3)):
        l.r(x, 28 + d, 2, 1 + (i % 2), pro)


def anillo_alborada(l, p):
    """Vendedor de Humo: trae puesto el anillo robado y por eso le
    brilla la mano."""
    d = p.alto
    l.r(5, 22 + d, 3, 1, ORO)
    l.p(6, 21 + d, ORO_LUZ)
    l.p(5, 21 + d, BLANCO)


def humo_pies(l, p, fase=0):
    """Vendedor de Humo: jirones de humo a los costados de los pies.

    Van sueltos y a los lados, nunca formando una franja continua debajo:
    una franja recta se lee como plataforma. Ademas se pintan despues del
    contorno, porque el humo no tiene borde.
    """
    claro = (214, 214, 222, 255)
    medio = (176, 176, 188, 255)
    sube = 1 if fase in (1, 3) else 0
    jirones = ((3, 26, 3), (26, 25, 2), (5, 29, 2), (24, 28, 3))
    for x, y, w in jirones:
        l.r(x, y - sube, w, 2, medio)
        l.r(x, y - sube, w - 1, 1, claro)
    l.p(8, 27 - sube, medio)
    l.p(22, 26 - sube, medio)


def copa_abollada(l, p):
    """Baron Oxido: sombrero de copa desgastado y abollado."""
    pro, som, base, luz = tonos((84, 78, 74))
    d = p.alto
    l.r(3, 6 + d, 26, 2, som)                  # ala ancha
    l.r(4, 5 + d, 24, 1, base)
    l.r(9, 0 + d, 14, 6, base)                 # copa alta
    l.r(10, 0 + d, 5, 4, luz)
    l.r(20, 1 + d, 3, 5, som)
    l.r(9, 4 + d, 14, 2, (104, 130, 104, 255))  # cinta verde oxido
    l.r(15, 0 + d, 4, 1, pro)                  # la abolladura
    l.r(16, 1 + d, 2, 1, pro)


def monoculo(l, p):
    """Baron Oxido: monoculo estrellado en un ojo."""
    d = p.alto
    l.r(17, 8 + d, 6, 6, ORO_PRO)
    l.r(18, 9 + d, 4, 4, (206, 228, 232, 255))
    l.p(19, 10 + d, BLANCO)
    l.p(20, 11 + d, (140, 168, 176, 255))
    l.p(19, 12 + d, (140, 168, 176, 255))
    l.r(23, 11 + d, 2, 1, ORO_PRO)


def baston_niebla(l, p):
    """Baron Oxido: baston que termina en una piedra gris de la que
    sale la niebla."""
    d = p.alto
    l.r(28, 12 + d, 2, 17, (96, 74, 52, 255))
    l.r(28, 12 + d, 1, 17, (134, 104, 74, 255))
    l.r(27, 8 + d, 4, 4, (150, 150, 158, 255))
    l.r(27, 8 + d, 2, 2, (192, 192, 200, 255))
    l.r(26, 6 + d, 2, 2, (176, 176, 186, 255))
    l.r(29, 4 + d, 2, 2, (198, 198, 206, 255))


def abrigo_cobre(l, p):
    """Baron Oxido: abrigo largo de cobre verdoso, con solapas y las
    manchas de oxido que va dejando."""
    pro, som, base, luz = tonos((150, 106, 62))
    verde = (104, 132, 104, 255)
    d = p.alto
    l.r(9, 16 + d, 14, 13, base)
    l.r(9, 25 + d, 14, 4, som)
    l.r(10, 17 + d, 2, 8, luz)
    l.r(20, 17 + d, 3, 11, pro)
    l.r(12, 16 + d, 3, 6, som)
    l.r(17, 16 + d, 3, 6, pro)
    # Chaleco y corbatin: es un villano elegante, no un vagabundo.
    l.r(13, 16 + d, 6, 8, (74, 66, 58, 255))
    l.r(13, 16 + d, 6, 1, (98, 88, 76, 255))
    l.r(15, 16 + d, 2, 2, (146, 44, 56, 255))      # corbatin
    l.p(15, 17 + d, (190, 72, 84, 255))
    for y in (19, 21, 23):                          # botones dorados
        l.p(16, y + d, (226, 172, 56, 255))
    # Faldones del abrigo, abiertos abajo.
    l.r(9, 26 + d, 4, 3, pro)
    l.r(19, 26 + d, 4, 3, pro)
    for x, y in ((10, 22), (19, 20), (14, 27), (21, 24), (11, 19)):
        l.r(x, y + d, 2, 2, verde)                  # manchas de oxido
        l.p(x, y + d, (132, 162, 130, 255))


# ------------------------------------------------------------ no humanos

def quilate(fase):
    """Colibri de plumas verde esmeralda con el pecho color rubi.
    Las alas le dejan una estela dorada, que es su marca en el libreto."""
    l = Lienzo()
    flota = (0, -1, 0, 1)[fase]
    pro, som, base, luz = tonos((46, 168, 110))
    rubi_pro, rubi_som, rubi, rubi_luz = tonos((206, 54, 68))
    y = 12 + flota

    # Estela dorada, detras de las alas.
    largo = (8, 5, 8, 5)[fase]
    for lado in (-1, 1):
        x = 12 - largo if lado < 0 else 20
        l.r(x, y - 2, largo, 3, (250, 218, 140, 255))
        l.r(x, y, largo, 1, (226, 172, 56, 255))

    ancho = (6, 3, 6, 3)[fase]
    for lado in (-1, 1):
        x = 12 - ancho if lado < 0 else 20
        l.r(x, y - 4, ancho, 4, base)
        l.r(x, y - 1, ancho, 1, pro)

    for i, (a, b) in enumerate(((13, 18), (12, 19), (12, 19), (13, 18),
                                (13, 18), (14, 17))):
        l.r(a, y + i, b - a + 1, 1, base)
    l.r(13, y + 1, 2, 3, luz)
    l.r(14, y + 2, 4, 3, rubi)                 # pecho rubi
    l.r(14, y + 4, 4, 1, rubi_som)
    l.p(14, y + 2, rubi_luz)
    l.p(17, y + 3, rubi_pro)
    # Plumas del lomo: rayitas alternadas, no un bloque liso.
    for i, yy in enumerate((y + 1, y + 3, y + 5)):
        l.p(12 + (i % 2), yy, som)
        l.p(18 - (i % 2), yy, pro)
    # Cola en forma de gema facetada, que es como la describe la ficha.
    l.r(14, y + 6, 4, 2, som)
    l.r(13, y + 8, 6, 2, base)
    l.r(14, y + 10, 4, 2, som)
    l.r(15, y + 12, 2, 1, pro)
    l.p(14, y + 8, luz)
    l.p(17, y + 9, pro)

    l.r(12, y - 6, 8, 6, base)
    l.r(13, y - 7, 6, 1, base)
    l.r(13, y - 6, 4, 2, luz)
    l.r(18, y - 5, 2, 4, som)
    l.r(14, y - 4, 3, 3, OJO)
    l.p(14, y - 4, BLANCO)
    l.p(16, y - 2, BLANCO)                     # segundo brillo del ojo
    l.r(12, y - 2, 2, 1, som)                  # mejilla
    l.p(13, y - 6, luz)
    l.r(20, y - 3, 7, 1, (64, 54, 50, 255))
    l.r(20, y - 2, 4, 1, (48, 40, 38, 255))
    contornear(l)
    return l.im


def carbonel(fase):
    """Duende de la mina: la mitad del tamano de Diana, gorro puntiagudo
    caido, ropa remendada, farol viejo apagado y ojos grandes sensibles
    a la luz."""
    l = Lienzo()
    sube = 1 if fase in (1, 3) else 0
    pro, som, base, luz = tonos((124, 156, 116))
    tpro, tsom, tela, tluz = tonos((96, 106, 158))
    y = 11 - sube

    l.r(21, y - 6, 4, 2, tsom)
    l.r(17, y - 5, 6, 2, tela)
    l.r(12, y - 4, 8, 2, tsom)
    l.r(8, y - 2, 14, 2, tela)
    l.r(9, y - 2, 6, 1, tluz)

    l.r(9, y, 14, 9, base)
    l.r(9, y + 7, 14, 2, som)
    l.r(10, y + 1, 4, 3, luz)
    l.r(6, y + 1, 3, 4, base)
    l.r(23, y + 1, 3, 4, som)
    l.r(5, y + 2, 1, 2, som)
    l.r(26, y + 2, 1, 2, pro)

    for x in (11, 17):
        l.r(x, y + 2, 4, 4, OJO)
        l.r(x, y + 2, 2, 2, BLANCO)
        l.p(x + 1, y + 4, (250, 236, 170, 255))
    l.r(14, y + 7, 4, 1, pro)
    l.r(9, y + 2, 2, 2, PIEL_PRO)              # cejas pobladas
    l.r(21, y + 2, 2, 2, PIEL_PRO)

    t = y + 9
    l.r(11, t, 10, 5, tela)
    l.r(11, t + 3, 10, 2, tsom)
    l.r(12, t + 1, 2, 2, tluz)
    l.r(17, t + 1, 2, 2, tpro)                 # remiendo
    for x in (17, 19):                          # puntadas del remiendo
        l.p(x, t, (206, 206, 186, 255))
        l.p(x, t + 3, (206, 206, 186, 255))
    l.r(11, t + 3, 10, 1, (86, 70, 54, 255))   # cinturon
    l.r(15, t + 3, 2, 1, (198, 170, 90, 255))  # hebilla
    balanceo = (0, -1, 0, 1)[fase]
    l.r(8, t + 1 + balanceo, 3, 3, base)
    l.r(21, t + 1 - balanceo, 3, 3, som)
    izq, der = ((0, 0), (1, 0), (0, 0), (0, 1))[fase]
    l.r(12, t + 5 - izq, 3, 3, (86, 62, 46, 255))
    l.r(17, t + 5 - der, 3, 3, (86, 62, 46, 255))

    # Barba larga, encima del cuerpo: es lo que le da edad al duende.
    l.r(11, y + 8, 10, 3, (198, 200, 206, 255))
    l.r(12, y + 11, 8, 2, (168, 170, 178, 255))
    l.r(14, y + 13, 4, 2, (198, 200, 206, 255))
    l.r(12, y + 8, 4, 1, (228, 230, 234, 255))
    l.p(13, y + 12, (228, 230, 234, 255))

    contornear(l)
    return l.im


def escarabajo(fase):
    """Escarabajo Oxidado: del tamano de un gato, caparazon cafe rojizo
    con manchas verdes."""
    l = Lienzo()
    sube = 1 if fase in (1, 3) else 0
    pro, som, base, luz = tonos((162, 78, 52))
    verde = (108, 132, 84, 255)
    negro = (46, 36, 34, 255)
    y = 11 - sube

    d = (0, 1, 0, -1)[fase]
    for i, yy in enumerate((y + 4, y + 7, y + 10)):
        desfase = d if i % 2 == 0 else -d
        l.r(4, yy + desfase, 5, 2, negro)
        l.r(23, yy - desfase, 5, 2, negro)

    silueta = ((11, 20), (9, 22), (8, 23), (7, 24), (7, 24), (7, 24),
               (7, 24), (8, 23), (8, 23), (9, 22), (11, 20))
    for i, (a, b) in enumerate(silueta):
        l.r(a, y + i, b - a + 1, 1, base)
    l.r(15, y, 2, 11, som)
    l.r(9, y + 2, 4, 3, luz)
    l.r(8, y + 8, 16, 3, som)
    l.r(8, y + 10, 16, 1, pro)
    for x, yy in ((11, y + 3), (19, y + 5), (13, y + 7), (20, y + 2)):
        l.r(x, yy, 2, 2, verde)

    # Linea de union de los elitros y su brillo.
    l.r(10, y + 1, 2, 1, luz)
    l.r(20, y + 3, 2, 1, luz)
    l.r(14, y + 1, 1, 9, pro)
    l.r(17, y + 1, 1, 9, pro)

    l.r(12, y - 3, 8, 4, negro)
    l.r(13, y - 2, 2, 2, (250, 140, 90, 255))
    l.r(17, y - 2, 2, 2, (250, 140, 90, 255))
    l.p(13, y - 2, (255, 210, 160, 255))
    l.p(17, y - 2, (255, 210, 160, 255))
    l.r(13, y + 1, 2, 1, pro)                  # mandibulas
    l.r(17, y + 1, 2, 1, pro)
    l.r(11, y - 6, 1, 3, negro)
    l.r(20, y - 6, 1, 3, negro)
    l.r(10, y - 7, 2, 1, negro)
    l.r(20, y - 7, 2, 1, negro)
    contornear(l)
    return l.im


def polilla(fase):
    """Polilla de Hollin: gris, de alas grandes, va soltando polvo negro."""
    l = Lienzo()
    flota = (0, -1, 0, 1)[fase]
    pro, som, base, luz = tonos((168, 164, 158))
    cuerpo = (96, 90, 86, 255)
    y = 13 + flota

    abierta = fase in (0, 2)
    forma = (5, 8, 10, 10, 8, 5) if abierta else (3, 5, 6, 6, 5, 3)
    for i, largo in enumerate(forma):
        yy = y - 5 + i
        color = luz if i < 2 else (base if i < 4 else som)
        l.r(13 - largo, yy, largo, 1, color)
        l.r(19, yy, largo, 1, color)
    if abierta:
        # Ojos falsos de las alas y el patron de manchas: es lo que hace
        # que se lea como polilla y no como un pajaro gris.
        for lado, cx in ((-1, 7), (1, 23)):
            l.r(cx, y - 3, 3, 3, pro)
            l.r(cx + 1, y - 2, 1, 1, (232, 228, 220, 255))
            l.r(cx - lado, y + 1, 2, 1, som)
        for x in (5, 10, 22, 27):
            l.p(x, y - 4, som)
            l.p(x, y + 2, som)
    else:
        l.r(9, y - 2, 2, 2, pro)
        l.r(21, y - 2, 2, 2, pro)

    l.r(13, y - 6, 6, 14, cuerpo)
    l.r(13, y + 5, 6, 3, (64, 60, 56, 255))
    l.r(14, y - 5, 2, 5, (132, 126, 120, 255))
    # Pelusa del torax: pixeles sueltos saliendo del contorno.
    for x, yy in ((12, y - 5), (19, y - 4), (12, y - 3), (19, y - 6)):
        l.p(x, yy, (146, 140, 132, 255))
    for yy in (y - 1, y + 2, y + 5):
        l.r(13, yy, 6, 1, (72, 68, 64, 255))
    l.r(14, y - 5, 2, 2, (250, 140, 90, 255))
    l.r(17, y - 5, 2, 2, (250, 140, 90, 255))
    l.r(12, y - 10, 1, 4, cuerpo)
    l.r(19, y - 10, 1, 4, cuerpo)
    l.r(11, y - 11, 2, 1, cuerpo)
    l.r(19, y - 11, 2, 1, cuerpo)

    for x, yy in ((8, y + 7), (22, y + 6), (11, y + 9), (20, y + 9)):
        l.p(x, yy, (54, 50, 48, 255))
    contornear(l)
    return l.im


# ------------------------------------------------------------- el reparto

def aurelio_completo(l, p):
    """Camisa y cinturon primero, las arrugas van con la cara."""
    camisa_arremangada(l, p)


def chela_completo(l, p):
    """Primero el bordado de la blusa, luego el rebozo encima y al final
    la trenza, que cae sobre los dos."""
    blusa_bordada(l, p)
    rebozo_rosa(l, p)
    trenza(l, p)


def baron_completo(l, p):
    """El abrigo va primero y el monoculo encima, si no queda tapado."""
    abrigo_cobre(l, p)
    monoculo(l, p)


def reparto():
    aurelio = Humano(pelo=(228, 224, 222), ropa=(232, 220, 196),
                     bajo=(96, 92, 110), ancho=-1,
                     sombrero=sombrero_palma, bigote=True,
                     encima=camisa_arremangada)
    chela = Humano(pelo=(214, 210, 208), ropa=(178, 152, 190),
                   bajo=(108, 82, 66), alto=2, cara=False,
                   sombrero=lentes_grandes, encima=chela_completo)
    humo = Humano(pelo=(70, 70, 80), ropa=(112, 112, 122),
                  bajo=(72, 70, 80), piel=(206, 188, 180), cara=False,
                  sombrero=capucha, encima=tunica, despues=humo_pies)
    baron = Humano(pelo=(96, 88, 78), ropa=(150, 106, 62),
                   bajo=(84, 92, 84), alto=-1, ancho=-2,
                   sombrero=copa_abollada, bigote=True,
                   encima=baron_completo)

    return [
        ("01_quilate_colibri", quilate),
        ("02_don_aurelio", aurelio.cuadro),
        ("03_dona_chela", chela.cuadro),
        ("04_carbonel_duende", carbonel),
        ("05_escarabajo_oxidado", escarabajo),
        ("06_polilla_de_hollin", polilla),
        ("07_vendedor_de_humo", humo.cuadro),
        ("08_baron_oxido", baron.cuadro),
    ]


def main():
    os.makedirs(SALIDA, exist_ok=True)
    fichas = reparto()
    zoom = 7
    lamina = Image.new("RGB", (len(fichas) * (W * zoom + 10) + 10,
                               H * zoom + 20), (255, 255, 255))

    for i, (nombre, dibujo) in enumerate(fichas):
        cuadros = [dibujo(f) for f in range(4)]
        hoja = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
        carpeta = os.path.join(SALIDA, "%s_frames" % nombre)
        os.makedirs(carpeta, exist_ok=True)
        gif = []
        for j, im in enumerate(cuadros):
            hoja.paste(im, (j * W, 0), im)
            im.save(os.path.join(carpeta, "%02d.png" % (j + 1)))
            g = im.resize((W * 6, H * 6), Image.NEAREST)
            f = Image.new("RGB", g.size, (255, 255, 255))
            f.paste(g, (0, 0), g)
            gif.append(f)
        hoja.save(os.path.join(SALIDA, "%s.png" % nombre))
        gif[0].save(os.path.join(SALIDA, "%s.gif" % nombre), save_all=True,
                    append_images=gif[1:], duration=160, loop=0)
        g = cuadros[0].resize((W * zoom, H * zoom), Image.NEAREST)
        lamina.paste(g, (10 + i * (W * zoom + 10), 10), g)

    lamina.save(os.path.join(SALIDA, "00_reparto.png"))
    print("personajes generados:", len(fichas))


if __name__ == "__main__":
    main()
