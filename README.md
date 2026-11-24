# Diana y el Brillo Perdido

Videojuego de acción y aventura 2D con vista cenital, hecho en Godot 4.

Proyecto de la asignatura **Optativa 1: Creación de Videojuegos**, de la Ingeniería en Desarrollo y Gestión de
Software (UTHH). El juego parte del giro comercial del Proyecto Transversal: la *Plataforma Digital Integral para la
Gestión de Ventas y Pedidos en Joyería Diana Laura*.

## De qué trata

Diana, una joyera, despierta con el aparador vacío: una niebla salió de la bodega de su proveedor, Don Aurelio,
y se llevó las tres piezas que iban a presentarse en una exposición. Don Aurelio la guía por radio y le pide
además recuperar las gemas que escondió en cada lugar.

En lugar de armas, Diana usa lo que hay en su mostrador (la lupa de joyero, el espejo del aparador, el paño de pulir
y algunas joyas del catálogo). Al inicio solo tiene la lupa; las demás aparecen en los cofres. Los enemigos no
mueren: se **pulen**.

## Escenarios

| Nivel | Escenario | Jefe | Pieza |
|---|---|---|---|
| 1 | Bodega del Proveedor | Vendedor de Humo | Anillo Alborada |
| 2 | Mina de Cuarzo | Gólem de la Mina | Collar Luna de Plata |
| 3 | Taller de Imitaciones | Guardia del Taller | Esclava del Sol |

Cada nivel tiene nueve cuartos, sus propios enemigos y cinco gemas ocultas. Hay cuatro dificultades
(Fácil, Intermedio, Difícil y Demoníaco).

## Controles

| Tecla | Acción |
|---|---|
| WASD / flechas | moverse |
| Clic izquierdo / Espacio | usar el objeto |
| Shift / clic derecho | impulso (esquivar) |
| Q | cambiar de objeto |
| F | recoger, abrir |
| E | Destello de joyera (gasta el brillo y daña a los enemigos cercanos) |
| Esc / P | pausa |
| F11 | pantalla completa |
| M | silenciar |

## Descargar

El APK para Android está en la sección **Releases** del repositorio.

## Cómo abrirlo

1. Descargar [Godot 4.7.2](https://godotengine.org/download/windows/) (versión estándar, sin .NET).
2. Abrir Godot, elegir **Importar** y seleccionar el archivo `project.godot` de esta carpeta.

## Estructura

```
menu.tscn, main.tscn   escenas: menú principal y juego
scripts/               código en GDScript
assets/                personajes, enemigos, objetos, interfaz, música y sonidos
```

## Recursos de terceros

Los recursos que no son propios se anotan en `creditos.txt` con su autor y licencia. Solo se usan recursos de
licencia libre (CC0 o equivalente).

## Licencia

Código bajo licencia MIT. Ver el archivo `LICENSE`.
