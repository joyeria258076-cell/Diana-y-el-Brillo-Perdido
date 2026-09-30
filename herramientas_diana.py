# -*- coding: utf-8 -*-
"""Diana: sprite detallado en 32x32.

Especificacion que sigue:
  - Proporciones chibi, unas 2.5 cabezas de alto.
  - Sombreado cel de cuatro tonos por material: base, sombra, sombra
    profunda y luz. Nada de degradados ni suavizado.
  - Contorno oscuro limpio de un pixel.
  - Luz constante desde arriba a la izquierda, mas una luz de contorno
    tenue por el borde iluminado.
  - Dithering solo en detalles chicos (el terciopelo de la bolsita).
  - Paleta limitada: 24 colores como maximo, contados al final.
  - Bordes duros, sin anti-aliasing.

Accesorios, que son los que cuentan su oficio de un vistazo:
  broche de flor de oro rosa en el pelo recogido, delantal de trabajo
  color champan sobre blusa negra, y la lupa de joyero colgada al cuello
  con una cadena delgada. Todo sale de la ficha del personaje en el
  libreto, que la describe asi: 24 anios, cabello negro largo recogido,
  pantalon comodo y botines cafes.

Sigue siendo una sola vista de frente que se voltea en espejo, y la lupa
va en un sprite aparte porque esa gira siguiendo al puntero.
"""
import os
from PIL import Image

W, H = 32, 32
SALIDA = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------- la paleta
NEGRO = (30, 24, 34, 255)          # contorno
BLANCO = (255, 255, 255, 255)      # brillos y tela clara

PIEL_PRO = (168, 112, 88, 255)     # sombra profunda
PIEL_SOM = (206, 156, 122, 255)
PIEL = (242, 202, 168, 255)
PIEL_LUZ = (255, 232, 206, 255)

PELO_PRO = (26, 24, 34, 255)       # cabello negro, que en pixel art se
PELO_SOM = (44, 42, 58, 255)       # pinta azulado para que no se confunda
PELO = (62, 60, 82, 255)           # con el contorno
PELO_LUZ = (96, 94, 122, 255)

# Blusa negra.
ROPA_PRO = (40, 38, 46, 255)
ROPA_SOM = (58, 56, 66, 255)
ROPA = (82, 78, 92, 255)
ROPA_LUZ = (112, 108, 124, 255)

# Delantal de trabajo color champan.
TELA_PRO = (148, 124, 88, 255)
TELA_SOM = (194, 172, 132, 255)
TELA = (230, 210, 170, 255)
# La tela clara comparte el blanco puro con los brillos de los ojos:
# a este tamano nadie nota la diferencia y ahorra un color de la paleta.

ORO_PRO = (146, 96, 24, 255)
ORO = (226, 172, 56, 255)
ORO_LUZ = (255, 226, 130, 255)

ROSA_ORO = (232, 172, 158, 255)    # el broche de flor
ROSA_ORO_SOM = (188, 122, 112, 255)
VIDRIO = (176, 222, 236, 255)      # el cristal de la lupa

PANT_SOM = (62, 58, 72, 255)       # pantalon comodo, gris calido
PANT = (96, 90, 108, 255)

# Las botas usan el mismo cafe del pelo. Es practica comun en paletas
# limitadas y evita gastar dos colores casi identicos.
BOTA_SOM = (72, 48, 36, 255)       # botines cafes
BOTA = (112, 78, 56, 255)

OJO = (36, 26, 40, 255)
RUBOR = ROSA_ORO          # el rosa del broche sirve de rubor


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


# Silueta de la cabeza, fila por fila. Grande y redonda: es la mitad
# del personaje, que es lo que define la proporcion chibi.
CRANEO = {
    1: (11, 20), 2: (9, 22), 3: (8, 23), 4: (7, 24), 5: (7, 24),
    6: (6, 25), 7: (6, 25), 8: (6, 25), 9: (6, 25), 10: (6, 25),
    11: (6, 25), 12: (7, 24), 13: (8, 23), 14: (10, 21), 15: (12, 19),
}


def cabeza(l):
    # --- Cara, con sus cuatro tonos.
    for y, (a, b) in CRANEO.items():
        l.r(a, y, b - a + 1, 1, PIEL)
    l.r(9, 7, 5, 4, PIEL_LUZ)              # luz de arriba a la izquierda
    l.r(20, 8, 3, 6, PIEL_SOM)             # sombra del lado contrario
    l.r(21, 10, 2, 3, PIEL_PRO)
    l.r(13, 15, 6, 1, PIEL_SOM)            # filo del menton, apenas

    # --- Pelo castano corto: casco arriba y mechones a los lados.
    l.r(11, 0, 10, 1, PELO_SOM)
    l.r(9, 1, 14, 2, PELO)
    l.r(7, 3, 18, 3, PELO)
    # Cabello recogido: los mechones caen largos por los lados.
    l.r(6, 6, 3, 13, PELO)
    l.r(23, 6, 3, 13, PELO)
    l.r(6, 16, 3, 3, PELO_PRO)
    l.r(23, 15, 3, 4, PELO_PRO)
    l.r(10, 1, 7, 2, PELO_LUZ)             # brillo del pelo
    l.r(18, 2, 3, 1, PELO_LUZ)
    l.r(20, 4, 5, 2, PELO_SOM)             # lado en sombra
    l.r(23, 9, 3, 4, PELO_SOM)
    l.r(7, 6, 1, 4, PELO_LUZ)              # luz de contorno

    # --- Broche de flor de oro rosa, del lado iluminado.
    l.r(7, 3, 3, 3, ROSA_ORO_SOM)
    l.r(8, 3, 2, 2, ROSA_ORO)
    l.p(8, 4, ORO_LUZ)                     # centro de la flor
    l.p(7, 2, ROSA_ORO)
    l.p(10, 5, ROSA_ORO_SOM)

    # --- Ojos grandes con dos brillos, que es lo que da expresion.
    for x in (12, 18):
        l.r(x, 9, 3, 4, OJO)
        l.r(x, 9, 1, 1, BLANCO)            # brillo principal
        l.p(x + 2, 12, BLANCO)             # segundo brillo, abajo

    l.r(8, 12, 2, 2, RUBOR)
    l.r(22, 12, 2, 2, RUBOR)
    l.r(15, 14, 2, 1, ROSA_ORO_SOM)        # boca


def torso(l, balanceo=0):
    # --- Blusa rosa, cuatro tonos.
    l.r(9, 16, 14, 8, ROPA)
    l.r(9, 22, 14, 2, ROPA_SOM)
    l.r(9, 23, 14, 1, ROPA_PRO)
    l.r(10, 17, 2, 5, ROPA_LUZ)
    l.r(20, 17, 3, 7, ROPA_SOM)
    l.r(22, 19, 1, 4, ROPA_PRO)
    l.r(13, 16, 6, 1, PIEL_PRO)            # escote

    # --- Delantal de trabajo color champan, con su peto y tirantes.
    l.r(11, 18, 10, 6, TELA)
    l.r(11, 18, 3, 3, BLANCO)
    l.r(11, 22, 10, 2, TELA_SOM)
    l.r(11, 23, 10, 1, TELA_PRO)
    l.r(12, 17, 2, 1, TELA_SOM)            # tirantes
    l.r(18, 17, 2, 1, TELA_PRO)

    # --- La lupa de joyero colgada al cuello. Es su herramienta y lo que
    # la identifica, asi que va grande y con sus tres partes a la vista:
    # cadena, aro con cristal y mango.
    for x, y in ((13, 16), (14, 17), (19, 16), (18, 17)):
        l.p(x, y, ORO_PRO)                 # cadena, bajando del cuello
    l.r(15, 17, 3, 1, ORO)                 # argolla de union

    l.r(14, 18, 5, 5, ORO_PRO)             # aro exterior
    l.r(15, 18, 3, 1, ORO_LUZ)             # brillo de arriba del aro
    l.r(14, 19, 1, 3, ORO)
    l.r(15, 19, 3, 3, VIDRIO)              # cristal
    l.r(15, 19, 2, 1, BLANCO)              # destello del cristal
    l.p(17, 21, ROSA_ORO_SOM)              # reflejo del otro lado

    l.r(15, 23, 3, 2, ORO_PRO)             # mango
    l.r(16, 23, 1, 2, ORO)

    # --- Mangas y manos.
    # El hombro queda fijo y solo se mueve del codo para abajo: si se
    # desplaza el brazo entero parece que flota, que era el problema.
    for x, luz, sentido in ((6, True, 1), (23, False, -1)):
        dy = balanceo * sentido
        l.r(x, 17, 3, 3, ROPA_LUZ if luz else ROPA)        # hombro, fijo
        l.r(x, 20 + dy, 3, 1, ROPA_SOM if luz else ROPA_PRO)  # codo
        l.r(x, 21 + dy, 3, 3, PIEL if luz else PIEL_SOM)      # antebrazo
        if dy > 0:                                  # brazo atrasado:
            l.r(x, 20, 3, 1, ROPA if luz else ROPA_SOM)   # la manga estira


def piernas(l, izq_sube, der_sube):
    for x, sube in ((11, izq_sube), (17, der_sube)):
        y = 24 - sube
        l.r(x, y, 4, 3, PANT)
        l.r(x, y + 2, 4, 1, PANT_SOM)
        l.r(x, y + 3, 4, 3, BOTA)
        l.r(x, y + 5, 4, 1, BOTA_SOM)
        l.r(x, y + 6, 4, 1, TELA)          # suela clara


def contornear(l):
    """Contorno limpio de un pixel alrededor de toda la silueta."""
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


def cuadro(fase):
    """fase 0 y 2: apoyada. fase 1 y 3: en el aire, un pie adelante.
    El cuerpo entero rebota un pixel en cada paso."""
    balanceo = {0: 0, 1: -1, 2: 0, 3: 1}[fase]
    cuerpo = Lienzo()
    torso(cuerpo, balanceo)
    cabeza(cuerpo)
    l = Lienzo()
    piernas(l, 1 if fase == 1 else 0, 1 if fase == 3 else 0)
    l.im.alpha_composite(cuerpo.im, (0, 0),
                         (0, 1 if fase in (1, 3) else 0, W, H))
    contornear(l)
    return l.im


def main():
    cuadros = [cuadro(f) for f in range(4)]

    colores = set()
    for im in cuadros:
        colores |= {p for p in im.get_flattened_data() if p[3] > 0}
    print("colores usados:", len(colores), "(el limite era 24)")

    hoja = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    for i, im in enumerate(cuadros):
        hoja.paste(im, (i * W, 0), im)
    hoja.save(os.path.join(SALIDA, "diana_det_caminar.png"))
    cuadros[0].save(os.path.join(SALIDA, "diana_det_quieta.png"))

    carpeta = os.path.join(SALIDA, "diana_det_frames")
    os.makedirs(carpeta, exist_ok=True)
    for i, im in enumerate(cuadros, start=1):
        im.save(os.path.join(carpeta, "%02d.png" % i))

    # Lamina sobre fondo blanco plano, como pide la especificacion.
    zoom = 10
    prev = Image.new("RGB", (W * 4 * zoom + 50, H * zoom + 20), (255, 255, 255))
    gif = []
    for i, im in enumerate(cuadros):
        g = im.resize((W * zoom, H * zoom), Image.NEAREST)
        prev.paste(g, (10 + i * (W * zoom + 10), 10), g)
        f = Image.new("RGB", g.size, (255, 255, 255))
        f.paste(g, (0, 0), g)
        gif.append(f)
    prev.save(os.path.join(SALIDA, "diana_det.png"))
    gif[0].save(os.path.join(SALIDA, "diana_det.gif"), save_all=True,
                append_images=gif[1:], duration=160, loop=0)


if __name__ == "__main__":
    main()
