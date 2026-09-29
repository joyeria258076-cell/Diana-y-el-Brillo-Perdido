# -*- coding: utf-8 -*-
"""Genera los frames de los personajes principales de "Diana y el Brillo Perdido".

Cada personaje queda en su propia carpeta con los cuadros numerados 01, 02, 03...
para que LibreSprite los ordene solo al importarlos como secuencia.
Lienzo de 32x32, pixel art a mano (sin filtros ni suavizado).
"""
import os
from PIL import Image

LADO = 32
DESTINO = os.path.join(
    r"C:\Users\uriel\Documents\Empresa UTHH\Mes 2 - Proyecto Joyeria Diana Laura",
    "Diana-y-el-Brillo-Perdido", "sprites", "personajes", "frames",
)

# ---------------------------------------------------------------- utilidades

class Lienzo:
    def __init__(self):
        self.im = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
        self.px = self.im.load()

    def p(self, x, y, c):
        if 0 <= x < LADO and 0 <= y < LADO and c is not None:
            self.px[x, y] = c

    def rect(self, x, y, w, h, c):
        for j in range(h):
            for i in range(w):
                self.p(x + i, y + j, c)

    def linea_h(self, x, y, w, c):
        self.rect(x, y, w, 1, c)

    def espejo_der(self):
        """Dibujamos la mitad izquierda y la reflejamos: asi el personaje sale simetrico."""
        for y in range(LADO):
            for x in range(LADO // 2):
                c = self.px[x, y]
                if c[3]:
                    self.px[LADO - 1 - x, y] = c


def sombra(l, cx, ancho, y):
    c = (0, 0, 0, 70)
    l.rect(cx - ancho // 2, y, ancho, 2, c)
    l.rect(cx - ancho // 2 - 1, y + 1, ancho + 2, 1, c)


def guardar(carpeta, numero, lienzo):
    ruta = os.path.join(DESTINO, carpeta)
    os.makedirs(ruta, exist_ok=True)
    lienzo.im.save(os.path.join(ruta, "%02d.png" % numero))


# ------------------------------------------------------------------- paletas

class P:
    piel = (240, 200, 168, 255)
    piel_som = (206, 160, 128, 255)
    pelo = (58, 38, 34, 255)
    pelo_luz = (92, 62, 52, 255)
    ojo = (34, 26, 30, 255)
    boca = (176, 96, 96, 255)

    diana_ropa = (216, 88, 116, 255)
    diana_ropa_som = (166, 58, 88, 255)
    diana_falda = (60, 60, 92, 255)
    diana_bota = (74, 52, 44, 255)
    oro = (246, 200, 86, 255)
    oro_som = (196, 148, 48, 255)
    vidrio = (168, 224, 244, 255)

    verde = (96, 160, 96, 255)
    verde_som = (62, 112, 66, 255)
    morado = (124, 92, 172, 255)
    morado_som = (86, 62, 124, 255)
    gris = (150, 150, 158, 255)
    gris_som = (104, 104, 114, 255)
    oxido = (168, 92, 48, 255)
    oxido_som = (120, 62, 32, 255)
    humo = (186, 186, 196, 255)
    negro = (38, 34, 40, 255)
    blanco = (244, 244, 248, 255)
    turquesa = (72, 190, 190, 255)
    turquesa_som = (44, 140, 148, 255)


# --------------------------------------------------------------- cuerpo base

def humano(paso, dy, pelo_c, pelo_luz_c, ropa, ropa_som, bajo, bajo_som,
           sombrero=None, accesorio=None, largo_pelo=0):
    """Cuerpo humano de frente. `paso` va de 0 a 3 y mueve piernas y brazos.

    dy desplaza todo el cuerpo hacia arriba o abajo para el rebote de la caminata.
    """
    l = Lienzo()
    sombra(l, 16, 12, 28)

    y = 6 + dy

    # cabeza
    l.rect(11, y, 10, 8, P.piel)
    l.rect(11, y + 7, 10, 1, P.piel_som)
    # pelo
    l.rect(10, y - 2, 12, 3, pelo_c)
    l.linea_h(11, y - 3, 10, pelo_c)
    l.rect(11, y - 2, 10, 1, pelo_luz_c)
    l.rect(10, y + 1, 2, 4 + largo_pelo, pelo_c)
    l.rect(20, y + 1, 2, 4 + largo_pelo, pelo_c)
    # cara
    l.rect(13, y + 3, 2, 2, P.ojo)
    l.rect(17, y + 3, 2, 2, P.ojo)
    l.p(13, y + 3, P.blanco)
    l.p(17, y + 3, P.blanco)
    l.linea_h(15, y + 6, 2, P.boca)

    if sombrero:
        l.rect(8, y - 4, 16, 2, sombrero)
        l.rect(11, y - 6, 10, 2, sombrero)

    # torso
    t = y + 8
    l.rect(11, t, 10, 7, ropa)
    l.rect(11, t + 6, 10, 1, ropa_som)
    l.rect(14, t, 4, 3, ropa_som)          # cuello / escote

    # brazos: se adelantan y atrasan con el paso
    balanceo = [0, -1, 0, 1][paso]
    l.rect(8, t + 1 + balanceo, 3, 6, ropa)
    l.rect(8, t + 6 + balanceo, 3, 2, P.piel)
    l.rect(21, t + 1 - balanceo, 3, 6, ropa)
    l.rect(21, t + 6 - balanceo, 3, 2, P.piel)

    # piernas
    b = t + 7
    izq, der = [(0, 0), (-1, 1), (0, 0), (1, -1)][paso]
    l.rect(12, b, 4, 5 + izq, bajo)
    l.rect(16, b, 4, 5 + der, bajo)
    l.rect(12, b + 5 + izq, 4, 2, bajo_som)
    l.rect(16, b + 5 + der, 4, 2, bajo_som)

    if accesorio:
        accesorio(l, t, balanceo)
    return l


# -------------------------------------------------------------- personajes

def lupa(l, t, balanceo):
    """La lupa de Diana, tomada con la mano derecha."""
    y = t + 4 - balanceo
    l.rect(23, y, 5, 1, P.oro)
    l.rect(23, y + 4, 5, 1, P.oro)
    l.rect(23, y + 1, 1, 3, P.oro)
    l.rect(27, y + 1, 1, 3, P.oro)
    l.rect(24, y + 1, 3, 3, P.vidrio)
    l.rect(24, y + 5, 2, 3, P.oro_som)


def libreta(l, t, balanceo):
    y = t + 3 + balanceo
    l.rect(5, y, 5, 6, P.blanco)
    l.rect(5, y, 1, 6, P.gris_som)


def bandeja(l, t, balanceo):
    y = t + 5 + balanceo
    l.rect(4, y, 7, 1, P.gris)
    l.p(6, y - 1, P.oro)
    l.p(8, y - 1, P.turquesa)


PERSONAJES = {
    # carpeta: (pelo, pelo_luz, ropa, ropa_som, bajo, bajo_som, sombrero, accesorio, largo)
    "01_diana": (P.pelo, P.pelo_luz, P.diana_ropa, P.diana_ropa_som,
                 P.diana_falda, P.diana_bota, None, lupa, 3),
    "02_don_aurelio": (P.gris, (190, 190, 196, 255), P.turquesa, P.turquesa_som,
                       (70, 64, 88, 255), (48, 44, 62, 255), (110, 82, 58, 255), libreta, 0),
    "03_dona_chela": ((120, 120, 128, 255), (170, 170, 176, 255), P.verde, P.verde_som,
                      (96, 72, 60, 255), (68, 50, 42, 255), None, bandeja, 2),
    "04_vendedor_de_humo": ((44, 44, 52, 255), (80, 80, 90, 255), P.humo, (132, 132, 144, 255),
                            (60, 60, 68, 255), (40, 40, 46, 255), (52, 48, 60, 255), None, 0),
    "05_baron_oxido": ((96, 52, 28, 255), (140, 84, 44, 255), P.oxido, P.oxido_som,
                       (74, 44, 30, 255), (52, 30, 20, 255), (92, 96, 104, 255), None, 0),
}


def carbonel(paso, dy):
    """Duende bajito: cabeza grande, gorro puntiagudo y cuerpo corto."""
    l = Lienzo()
    sombra(l, 16, 12, 28)
    y = 9 + dy
    # gorro
    l.rect(13, y - 6, 6, 2, P.morado_som)
    l.rect(11, y - 4, 10, 2, P.morado)
    l.rect(9, y - 2, 14, 2, P.morado_som)
    # cabeza
    l.rect(10, y, 12, 8, P.verde)
    l.rect(10, y + 7, 12, 1, P.verde_som)
    # orejas puntiagudas
    l.rect(8, y + 1, 2, 3, P.verde)
    l.rect(22, y + 1, 2, 3, P.verde)
    l.p(7, y + 2, P.verde_som)
    l.p(24, y + 2, P.verde_som)
    # cara
    l.rect(13, y + 3, 2, 2, P.ojo)
    l.rect(17, y + 3, 2, 2, P.ojo)
    l.p(13, y + 3, (250, 220, 120, 255))
    l.p(18, y + 3, (250, 220, 120, 255))
    l.linea_h(14, y + 6, 4, (52, 96, 52, 255))
    # cuerpo
    t = y + 8
    l.rect(11, t, 10, 5, P.morado)
    l.rect(11, t + 4, 10, 1, P.morado_som)
    balanceo = [0, -1, 0, 1][paso]
    l.rect(9, t + 1 + balanceo, 2, 4, P.verde)
    l.rect(21, t + 1 - balanceo, 2, 4, P.verde)
    izq, der = [(0, 0), (-1, 1), (0, 0), (1, -1)][paso]
    l.rect(12, t + 5, 3, 3 + izq, (70, 50, 40, 255))
    l.rect(17, t + 5, 3, 3 + der, (70, 50, 40, 255))
    return l


def quilate(paso, dy):
    """Colibri acompanante: el `paso` mueve las alas, no las patas."""
    l = Lienzo()
    sombra(l, 16, 8, 29)
    y = 10 + dy
    # cuerpo
    l.rect(13, y, 7, 8, P.turquesa)
    l.rect(13, y + 6, 7, 2, P.turquesa_som)
    l.rect(14, y + 1, 3, 4, (140, 226, 226, 255))
    # cabeza y pico
    l.rect(13, y - 4, 7, 5, P.turquesa)
    l.rect(14, y - 4, 5, 1, (140, 226, 226, 255))
    l.rect(20, y - 2, 5, 1, (60, 52, 48, 255))
    l.rect(15, y - 2, 2, 2, P.ojo)
    l.p(15, y - 2, P.blanco)
    # alas: abiertas, medias y pegadas
    abertura = [5, 2, 5, 2][paso]
    alto = [1, 4, 1, 4][paso]
    l.rect(13 - abertura, y - alto, abertura, 3, P.oro)
    l.rect(20, y - alto, abertura, 3, P.oro)
    l.rect(13 - abertura, y - alto + 2, abertura, 1, P.oro_som)
    l.rect(20, y - alto + 2, abertura, 1, P.oro_som)
    # cola
    l.rect(14, y + 8, 5, 2, P.turquesa_som)
    l.rect(15, y + 10, 3, 2, P.turquesa_som)
    return l


def escarabajo_oxido(paso, dy):
    """Enemigo basico: caparazon oxidado y patitas que se alternan."""
    l = Lienzo()
    sombra(l, 16, 12, 27)
    y = 12 + dy
    l.rect(10, y, 12, 9, P.oxido)
    l.rect(10, y + 7, 12, 2, P.oxido_som)
    l.rect(15, y, 2, 9, P.oxido_som)          # linea del caparazon
    l.rect(12, y + 1, 3, 3, (206, 132, 78, 255))
    # ojos
    l.rect(11, y - 2, 3, 3, P.negro)
    l.rect(18, y - 2, 3, 3, P.negro)
    l.p(12, y - 1, (250, 120, 90, 255))
    l.p(19, y - 1, (250, 120, 90, 255))
    # patas
    d = [0, 1, 0, -1][paso]
    for i, yy in enumerate((y + 2, y + 5, y + 8)):
        desfase = d if i % 2 == 0 else -d
        l.rect(6, yy + desfase, 4, 2, P.negro)
        l.rect(22, yy - desfase, 4, 2, P.negro)
    return l


def polilla(paso, dy):
    """Enemigo que vuela; las alas se abren y cierran."""
    l = Lienzo()
    y = 12 + dy
    abertura = [7, 4, 7, 4][paso]
    l.rect(16 - abertura - 4, y - 2, abertura, 7, (196, 188, 170, 255))
    l.rect(16 + 4, y - 2, abertura, 7, (196, 188, 170, 255))
    l.rect(16 - abertura - 4, y + 3, abertura, 2, (152, 144, 128, 255))
    l.rect(16 + 4, y + 3, abertura, 2, (152, 144, 128, 255))
    l.rect(13, y - 3, 6, 11, (110, 100, 88, 255))
    l.rect(13, y + 5, 6, 3, (80, 72, 64, 255))
    l.rect(14, y - 2, 2, 2, (250, 120, 90, 255))
    l.rect(17, y - 2, 2, 2, (250, 120, 90, 255))
    l.rect(12, y - 6, 1, 3, (80, 72, 64, 255))
    l.rect(19, y - 6, 1, 3, (80, 72, 64, 255))
    return l


ESPECIALES = {
    "06_carbonel_duende": carbonel,
    "07_quilate_colibri": quilate,
    "08_escarabajo_de_oxido": escarabajo_oxido,
    "09_polilla": polilla,
}

# Seis cuadros: dos de reposo (respiracion) y cuatro de caminata.
CICLO = [(0, 0), (0, 1), (0, 0), (1, -1), (2, 0), (3, -1)]


def main():
    os.makedirs(DESTINO, exist_ok=True)
    total = 0
    for carpeta, datos in PERSONAJES.items():
        pelo, pelo_luz, ropa, ropa_som, bajo, bajo_som, gorro, acc, largo = datos
        for n, (paso, dy) in enumerate(CICLO, start=1):
            guardar(carpeta, n, humano(paso, dy, pelo, pelo_luz, ropa, ropa_som,
                                       bajo, bajo_som, gorro, acc, largo))
            total += 1
    for carpeta, dibujo in ESPECIALES.items():
        for n, (paso, dy) in enumerate(CICLO, start=1):
            guardar(carpeta, n, dibujo(paso, dy))
            total += 1
    print("Cuadros generados:", total)


if __name__ == "__main__":
    main()
