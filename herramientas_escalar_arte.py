# -*- coding: utf-8 -*-
"""Deja el arte al tamano con el que entra al juego.

Dos cosas:

  1. Recorta de verdad. El recorte anterior se guiaba por el primer pixel
     con algo de opacidad, y las lineas sueltas de la cuadricula que el
     JPEG dejo lo enganaban. Aqui una fila solo cuenta si tiene varios
     pixeles opacos, asi la basura no manda.

  2. Escala al alto final. Los cuartos miden alrededor de 1300 pixeles de
     ancho y se usan tal cual; los personajes se bajan a una altura fija
     para que todos queden a la misma escala entre si y dentro del cuarto.
"""
import os
from PIL import Image

JUEGO = ("C:/Users/uriel/Documents/Empresa UTHH/"
         "Mes 2 - Proyecto Joyeria Diana Laura/Diana-y-el-Brillo-Perdido")
PERS = JUEGO + "/sprites/personajes"

# Altura final de cada quien, en pixeles. Las diferencias salen del
# libreto: Chela es bajita, Carbonel mide la mitad que Diana, el Baron es
# alto y delgado, y el Golem es el mas corpulento.
ALTURAS = {
    "diana": 104,
    "don_aurelio": 100,
    "dona_chela": 92,
    "baron_oxido": 112,
    "vendedor_de_humo": 116,
    "carbonel": 78,
    "golem_de_carbon": 126,
    "escarabajo": 62,
    "polilla": 58,
    "quilate": 54,
}


def recortar_firme(im, minimo=4):
    """Recorta ignorando filas y columnas con muy pocos pixeles opacos:
    esas son restos de la cuadricula, no parte del dibujo."""
    px = im.load()
    an, al = im.size
    filas = []
    for y in range(al):
        cuenta = sum(1 for x in range(an) if px[x, y][3] > 12)
        if cuenta >= minimo:
            filas.append(y)
    columnas = []
    for x in range(an):
        cuenta = sum(1 for y in range(al) if px[x, y][3] > 12)
        if cuenta >= minimo:
            columnas.append(x)
    if not filas or not columnas:
        return im

    # Lo que quedo fuera del recorte se borra, para que no reaparezca.
    x0, x1 = columnas[0], columnas[-1] + 1
    y0, y1 = filas[0], filas[-1] + 1
    return im.crop((x0, y0, x1, y1))


def escalar(im, alto_final):
    factor = alto_final / im.height
    ancho = max(1, round(im.width * factor))
    return im.resize((ancho, alto_final), Image.LANCZOS)


def limpiar_semitransparentes(im, umbral=90):
    """Despues de reducir quedan bordes a medio pintar. Los muy tenues se
    borran: si no, el personaje se ve con un halo sucio alrededor."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if 0 < a < umbral:
                px[x, y] = (r, g, b, 0)
    return im


def main():
    for nombre, alto in ALTURAS.items():
        ruta = os.path.join(PERS, nombre + ".png")
        if not os.path.exists(ruta):
            print("  falta", nombre)
            continue
        im = Image.open(ruta).convert("RGBA")
        im = recortar_firme(im)
        im = escalar(im, alto)
        im = limpiar_semitransparentes(im)
        im.save(ruta)
        print("  %-18s %s" % (nombre, im.size))


if __name__ == "__main__":
    main()
