# -*- coding: utf-8 -*-
"""Diana a la densidad de pixel del tileset del juego.

El problema que teniamos: los personajes eran de 32x32 con pixel fino y los
escenarios de 16x16 con pixel gordo. Mezclados nunca iban a encajar, por eso
Diana se veia pegada encima del cuarto en vez de estar dentro.

Aqui se dibuja a 16x28, que es la medida exacta de los personajes del
DungeonTileset II (CC0) con el que se arman los escenarios. Mismo tamano de
pixel, mismo grosor de contorno y la misma cantidad de tonos por color: dos
o tres, no cuatro. A este tamano el detalle sobra y lo que manda es la
silueta.

Se dibuja con un mapa de letras porque a 16 pixeles de ancho cada uno cuenta.
"""
import os
from PIL import Image

W, H = 16, 28
SALIDA = os.path.dirname(os.path.abspath(__file__))

PAL = {
    " ": None,
    "o": (26, 20, 30, 255),        # contorno
    "p": (48, 44, 68, 255),        # cabello negro, azulado
    "P": (82, 76, 112, 255),       # cabello con luz
    "s": (242, 200, 164, 255),     # piel
    "S": (202, 152, 118, 255),     # piel en sombra
    "e": (34, 28, 38, 255),        # ojo
    "b": (58, 54, 68, 255),        # blusa negra
    "B": (86, 80, 100, 255),       # blusa con luz
    "m": (226, 204, 160, 255),     # delantal champan
    "M": (180, 156, 114, 255),     # delantal en sombra
    "g": (236, 184, 74, 255),      # oro: la lupa y el broche
    "n": (72, 68, 88, 255),        # pantalon
    "t": (108, 76, 52, 255),       # botines
}

# Cada fila mide 16 caracteres. La cabeza ocupa casi la mitad del alto,
# que es la proporcion de los personajes del tileset.
QUIETA = [
    "                ",
    "     oooooo     ",
    "    oppppppo    ",
    "   oppppppppo   ",
    "   opgppppppo   ",
    "   opssssssPo   ",
    "   opsessesPo   ",
    "   opsessesPo   ",
    "   opssssssPo   ",
    "   opsssSsspo   ",
    "    osssssso    ",
    "   oppppppppo   ",
    "   obbbbbbbbo   ",
    "   obBmmmmbbo   ",
    "   obBmggmbbo   ",
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


# Cuadros de caminata: solo cambian los pies. El resto del movimiento es el
# rebote del cuerpo, que a esta escala es lo que de verdad se nota.
PIES = {
    0: ("otttoottto", "oooooooooo"),
    1: ("onnnoottto", "otttoooooo"),
    2: ("otttoottto", "oooooooooo"),
    3: ("otttoonnno", "ooooootttо".replace("о", "o")),
}


def pintar(mapa, subir=0):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    for y, fila in enumerate(mapa):
        for x, letra in enumerate(fila[:W]):
            color = PAL.get(letra)
            if color is not None:
                destino = y - subir
                if 0 <= destino < H:
                    px[x, destino] = color
    return im


def cuadro(fase):
    """Cuatro cuadros de caminata.

    fase 0 y 2: apoyada.
    fase 1 y 3: el cuerpo entero sube un pixel y una pierna se acorta.
    A esta escala el rebote es practicamente toda la animacion; los pies
    solo alternan un pixel.
    """
    mapa = list(QUIETA)
    pie_a, pie_b = PIES[fase]
    mapa[22] = "   " + pie_a + "   "
    mapa[23] = "   " + pie_b + "   "
    return pintar(mapa, subir=1 if fase in (1, 3) else 0)


def sombra(fase):
    """Sombra en su propio sprite, de 16x5, para ponerla debajo en el juego."""
    im = Image.new("RGBA", (W, 5), (0, 0, 0, 0))
    px = im.load()
    encogida = 1 if fase in (1, 3) else 0
    anchos = (6 - encogida, 10 - encogida * 2, 8 - encogida * 2)
    alfas = (70, 135, 95)
    for i, ancho in enumerate(anchos):
        y = 1 + i
        x = 8 - ancho // 2
        for j in range(ancho):
            px[x + j, y] = (14, 10, 20, alfas[i])
    return im


def main():
    cuadros = [cuadro(f) for f in range(4)]

    hoja = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    sombras = Image.new("RGBA", (W * 4, 5), (0, 0, 0, 0))
    for i, im in enumerate(cuadros):
        hoja.paste(im, (i * W, 0), im)
        sombras.paste(sombra(i), (i * W, 0))
    hoja.save(os.path.join(SALIDA, "diana16_caminar.png"))
    sombras.save(os.path.join(SALIDA, "diana16_sombra.png"))

    carpeta = os.path.join(SALIDA, "diana16_frames")
    os.makedirs(carpeta, exist_ok=True)
    for i, im in enumerate(cuadros, start=1):
        im.save(os.path.join(carpeta, "%02d.png" % i))

    zoom = 12
    prev = Image.new("RGB", (W * 4 * zoom + 50, (H + 4) * zoom + 20),
                     (44, 40, 52))
    gif = []
    for i, im in enumerate(cuadros):
        junto = Image.new("RGBA", (W, H + 4), (0, 0, 0, 0))
        junto.alpha_composite(sombra(i), (0, H - 5))
        junto.alpha_composite(im, (0, 0))
        g = junto.resize((W * zoom, (H + 4) * zoom), Image.NEAREST)
        prev.paste(g, (10 + i * (W * zoom + 10), 10), g)
        f = Image.new("RGB", g.size, (44, 40, 52))
        f.paste(g, (0, 0), g)
        gif.append(f)
    prev.save(os.path.join(SALIDA, "diana16.png"))
    gif[0].save(os.path.join(SALIDA, "diana16.gif"), save_all=True,
                append_images=gif[1:], duration=150, loop=0)
    print("listo")


if __name__ == "__main__":
    main()
