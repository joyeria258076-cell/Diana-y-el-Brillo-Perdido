# Diana y el Brillo Perdido

Videojuego de acción y aventura 2D con vista cenital, hecho en Godot 4.

Proyecto de la asignatura **Optativa 1: Creación de Videojuegos**, de la Ingeniería en Desarrollo y Gestión de
Software (UTHH). El juego parte del giro comercial del Proyecto Transversal: la *Plataforma Digital Integral para la
Gestión de Ventas y Pedidos en Joyería Diana Laura*.

## De qué trata

Diana, una joyera, se queda sin el aparador que iba a presentar en una exposición: el Barón Óxido cubrió la tienda
con una niebla que deja opacas las joyas y se llevó las piezas. Para recuperarlas hay que recorrer los lugares por
donde pasa la mercancía.

En lugar de armas, Diana usa lo que hay en su mostrador (la lupa de joyero, el espejo del aparador, el paño de pulir
y algunas joyas del catálogo). Los enemigos no mueren: se **pulen**, o sea que pierden el óxido y recuperan su forma
original.

## Escenarios

| Nivel | Escenario | Pieza |
|---|---|---|
| 1 | Bodega del Proveedor | Anillo Alborada |
| 2 | Mina de Cuarzo | Collar Luna de Plata |
| 3 | Taller de Imitaciones | Esclava del Sol |

## Cómo abrirlo

1. Descargar [Godot 4.7.2](https://godotengine.org/download/windows/) (versión estándar, sin .NET).
2. Abrir Godot, elegir **Importar** y seleccionar el archivo `project.godot` de esta carpeta.

## Estructura

```
escenas/    escenas de Godot (.tscn): cuartos, personajes, interfaz
scripts/    código en GDScript
sprites/    imágenes: personajes, enemigos, objetos y tiles
sonidos/    efectos y música
```

## Recursos de terceros

Los recursos que no son propios se anotan en `creditos.txt` con su autor y licencia. Solo se usan recursos de
licencia libre (CC0 o equivalente).

## Licencia

Código bajo licencia MIT. Ver el archivo `LICENSE`.
