# -*- coding: utf-8 -*-
"""Prepara el arte descargado para meterlo al juego.

Las imagenes vienen en JPEG, asi que no traen transparencia: los personajes
estan sobre una cuadricula gris y los cuartos sobre un fondo casi negro.
Aqui se les quita ese fondo y se recortan.

Como el JPEG ensucia los bordes, el fondo no se puede quitar por color
exacto. Se hace por relleno desde las orillas: se entra por los bordes de
la imagen y se va borrando todo lo que se parezca al fondo, parando en
cuanto aparece algo distinto. Asi los grises que estan DENTRO del personaje
(la ropa, el metal) no se borran.
"""
import os
from collections import deque
from PIL import Image

ORIGEN = "C:/Users/uriel/Documents/10A/Juvencio/Mes 1/Sprites/Downloads"
JUEGO = ("C:/Users/uriel/Documents/Empresa UTHH/"
         "Mes 2 - Proyecto Joyeria Diana Laura/Diana-y-el-Brillo-Perdido")
SAL_PERS = JUEGO + "/sprites/personajes"
SAL_ESCE = JUEGO + "/sprites/escenarios"

# Que archivo es quien. El orden salio de revisar las imagenes una por una.
PERSONAJES = {
    "Gemini_Generated_Image_1jhvw01jhvw01jhv.jpeg": "don_aurelio",
    "Gemini_Generated_Image_28vh6v28vh6v28vh.jpeg": "vendedor_de_humo",
    "Gemini_Generated_Image_2z063w2z063w2z06.jpeg": "escarabajo",
    "Gemini_Generated_Image_9w1qrw9w1qrw9w1q.jpeg": "baron_oxido",
    "Gemini_Generated_Image_ipirxpipirxpipir.jpeg": "diana",
    "Gemini_Generated_Image_ofx94sofx94sofx9.jpeg": "polilla",
    "Gemini_Generated_Image_p0177hp0177hp017.jpeg": "golem_de_carbon",
    "Gemini_Generated_Image_qc4105qc4105qc41.jpeg": "quilate",
    "Gemini_Generated_Image_sq2u7asq2u7asq2u.jpeg": "dona_chela",
    "Gemini_Generated_Image_tt52rmtt52rmtt52.jpeg": "carbonel",
}

ESCENARIOS = {
    "Gemini_Generated_Image_2cd1s32cd1s32cd1.jpeg": "bodega",
    "Gemini_Generated_Image_51q2ii51q2ii51q2.jpeg": "pasillo_vertical",
    "Gemini_Generated_Image_5k9rgu5k9rgu5k9r.jpeg": "taller",
    "Gemini_Generated_Image_dk4u7sdk4u7sdk4u.jpeg": "mina_hielo",
    "Gemini_Generated_Image_fk6e3hfk6e3hfk6e.jpeg": "calle",
    "Gemini_Generated_Image_kzau5skzau5skzau.jpeg": "joyeria",
    "Gemini_Generated_Image_po416npo416npo41.jpeg": "pasillo_horizontal",
    "Gemini_Generated_Image_qofq28qofq28qofq.jpeg": "sala_jefe",
    "Gemini_Generated_Image_rskudfrskudfrsku.jpeg": "mina_abismo",
}


def parecido(a, b, margen):
    return (abs(a[0] - b[0]) <= margen and abs(a[1] - b[1]) <= margen
            and abs(a[2] - b[2]) <= margen)


def es_cuadricula(p):
    """La cuadricula del fondo es clara y gris: sin color y bien iluminada.

    Se detecta asi y no por color exacto porque son dos grises que se
    alternan, mas las lineas de la reja, mas la basura que deja el JPEG.
    """
    r, g, b = p[:3]
    return max(r, g, b) - min(r, g, b) <= 34 and min(r, g, b) >= 118


def es_oscuro(p):
    """El fondo de los cuartos es casi negro."""
    return max(p[:3]) <= 46


def quitar_fondo(im, condicion=None, margen=30):
    """Borra el fondo entrando por las orillas.

    Avanza desde los bordes hacia adentro borrando todo lo que cumpla la
    condicion de fondo, y se detiene en cuanto topa con algo distinto. Por
    eso lo que esta DENTRO de la figura no se borra aunque sea del mismo
    gris: el contorno oscuro del dibujo le corta el paso.
    """
    im = im.convert("RGBA")
    an, al = im.size
    px = im.load()

    if condicion is None:
        esquinas = [px[0, 0][:3], px[an - 1, 0][:3],
                    px[0, al - 1][:3], px[an - 1, al - 1][:3]]

        def condicion(p):
            return any(parecido(p[:3], e, margen) for e in esquinas)

    visitados = bytearray(an * al)
    cola = deque()
    for x in range(an):
        cola.append((x, 0))
        cola.append((x, al - 1))
    for y in range(al):
        cola.append((0, y))
        cola.append((an - 1, y))

    while cola:
        x, y = cola.popleft()
        if x < 0 or y < 0 or x >= an or y >= al:
            continue
        i = y * an + x
        if visitados[i]:
            continue
        if not condicion(px[x, y]):
            continue
        visitados[i] = 1
        px[x, y] = (0, 0, 0, 0)
        cola.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return im


def recortar(im, borde=2):
    """Deja solo la figura, con un par de pixeles de aire alrededor."""
    caja = im.getbbox()
    if caja is None:
        return im
    x0, y0, x1, y1 = caja
    x0 = max(0, x0 - borde)
    y0 = max(0, y0 - borde)
    x1 = min(im.width, x1 + borde)
    y1 = min(im.height, y1 + borde)
    return im.crop((x0, y0, x1, y1))


def limpiar_orillas(im, umbral=40):
    """Los pixeles medio transparentes que deja el JPEG se vuelven opacos o
    se borran del todo. Si no, el sprite queda con un halo gris."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if a < umbral:
                px[x, y] = (r, g, b, 0)
            elif a < 255:
                px[x, y] = (r, g, b, 255)
    return im


def preparar_personajes():
    os.makedirs(SAL_PERS, exist_ok=True)
    for archivo, nombre in PERSONAJES.items():
        ruta = os.path.join(ORIGEN, "personajes", archivo)
        if not os.path.exists(ruta):
            print("  falta", archivo)
            continue
        im = Image.open(ruta)
        im = quitar_fondo(im, es_cuadricula)
        im = limpiar_orillas(im)
        im = recortar(im)
        salida = os.path.join(SAL_PERS, nombre + ".png")
        im.save(salida)
        print("  %-18s %s" % (nombre, im.size))


def preparar_escenarios():
    os.makedirs(SAL_ESCE, exist_ok=True)
    for archivo, nombre in ESCENARIOS.items():
        ruta = os.path.join(ORIGEN, "escenarios", archivo)
        if not os.path.exists(ruta):
            print("  falta", archivo)
            continue
        # Los cuartos van sobre fondo casi negro: se recortan a lo que hay.
        im = quitar_fondo(Image.open(ruta), es_oscuro)
        im = recortar(im, borde=0)
        salida = os.path.join(SAL_ESCE, nombre + ".png")
        im.convert("RGBA").save(salida)
        print("  %-20s %s" % (nombre, im.size))


if __name__ == "__main__":
    print("personajes:")
    preparar_personajes()
    print("escenarios:")
    preparar_escenarios()
