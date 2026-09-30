# -*- coding: utf-8 -*-
"""Exporta al proyecto de Godot lo que de verdad usa el juego.

Hasta ahora todo vivia en carpetas de diseno, que sirven para revisar pero
no para jugar. Aqui se arma lo minimo que necesita la escena:

  - Las hojas de caminata de Diana y del escarabajo, con su sombra aparte.
  - Un atlas de tiles de 32x32 para la bodega, hecho con los tiles de
    Dungeon Crawl ya aplanados (CC0).

El atlas queda en una sola fila y con un orden fijo, porque asi se
referencia desde el TileSet de Godot por numero de columna:

  0..3  piso (cuatro variantes)
  4     muro
  5     caja
  6     roca
  7     cofre
"""
import os
import sys
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import escenarios32 as E                                    # noqa: E402

JUEGO = ("C:/Users/uriel/Documents/Empresa UTHH/"
         "Mes 2 - Proyecto Joyeria Diana Laura/Diana-y-el-Brillo-Perdido")
T = 32


def exportar_personajes():
    destino = os.path.join(JUEGO, "sprites", "personajes")

    # Diana: hoja de caminata y sombra.
    for origen, nombre in (("diana_det_caminar.png", "diana_caminar.png"),
                           ("diana_det_sombra.png", "sombra.png")):
        ruta = os.path.join(AQUI, origen)
        if os.path.exists(ruta):
            Image.open(ruta).save(os.path.join(destino, nombre))

    # Escarabajo: hoja de caminata, y su version limpia (la misma con la
    # paleta cambiada a plata, que es como queda cuando Diana lo pule).
    hoja = os.path.join(AQUI, "reparto", "05_escarabajo_oxidado.png")
    if os.path.exists(hoja):
        im = Image.open(hoja).convert("RGBA")
        im.save(os.path.join(destino, "escarabajo_caminar.png"))

        limpio = im.copy()
        px = limpio.load()
        for y in range(limpio.height):
            for x in range(limpio.width):
                r, g, b, a = px[x, y]
                if a and r > g and r > b:
                    gris = (r + g + b) // 3
                    px[x, y] = (min(255, gris + 70), min(255, gris + 78),
                                min(255, gris + 92), a)
        limpio.save(os.path.join(destino, "escarabajo_limpio_caminar.png"))
    print("personajes exportados")


def exportar_tiles():
    """Arma el atlas de la bodega con los tiles ya aplanados."""
    pisos = E.aplanados(E.PISOS["bodega"], 8)[:4]
    muros = E.aplanados(E.MUROS["bodega"], 5)[:1]
    props = [E.CAJA, E.ROCA, E.COFRE]

    piezas = pisos + muros + props
    atlas = Image.new("RGBA", (T * len(piezas), T), (0, 0, 0, 0))
    for i, p in enumerate(piezas):
        if p is not None:
            atlas.paste(p, (i * T, 0))
    salida = os.path.join(JUEGO, "sprites", "escenarios", "atlas_bodega.png")
    atlas.save(salida)
    print("atlas de", len(piezas), "tiles en", os.path.basename(salida))


if __name__ == "__main__":
    exportar_personajes()
    exportar_tiles()
