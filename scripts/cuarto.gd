extends Node2D
## Pinta el cuarto de la bodega con los tiles del pack y lo ilumina con las antorchas.
## El cuarto se dibuja por codigo para poder cambiar su tamano sin acomodar tile por tile.

## Medidas del cuarto en tiles (cada tile mide 16 pixeles).
const ANCHO: int = 30
const ALTO: int = 20
const TILE: int = 16

## Coordenadas dentro del atlas de tiles: Vector2i(columna, fila).
const PISO: Array[Vector2i] = [Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 4), Vector2i(5, 4)]
const MURO: Vector2i = Vector2i(4, 3)
const MURO_ANTORCHA: Vector2i = Vector2i(5, 2)
const CAJA: Vector2i = Vector2i(3, 5)
const CAJA_ALTA: Vector2i = Vector2i(0, 6)
const BARRIL: Vector2i = Vector2i(10, 6)
const COFRE: Vector2i = Vector2i(5, 7)

## Sprite provisional de los enemigos; se asigna desde la escena.
@export var sprite_enemigo: Texture2D

## Posiciones (en tiles) donde aparecen los enemigos del cuarto.
const ENEMIGOS: Array[Vector2i] = [Vector2i(9, 5), Vector2i(19, 4), Vector2i(23, 12), Vector2i(12, 15)]

@onready var piso: TileMapLayer = $Piso
@onready var objetos: TileMapLayer = $Objetos


func _ready() -> void:
	_pintar_piso()
	_pintar_muros()
	_colocar_objetos()
	_colocar_enemigos()


## El piso usa cuatro variantes del mismo tile para que no se vea repetido.
func _pintar_piso() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 20221056  # semilla fija: el cuarto se ve igual cada vez que se juega
	for y in ALTO:
		for x in ANCHO:
			var variante: Vector2i = PISO[0]
			if azar.randi_range(0, 5) == 0:
				variante = PISO[azar.randi_range(1, PISO.size() - 1)]
			piso.set_cell(Vector2i(x, y), 0, variante)


## Marco de muros alrededor del cuarto. Cada antorcha ademas enciende una luz.
func _pintar_muros() -> void:
	for x in range(-1, ANCHO + 1):
		var hay_antorcha := x > 0 and x < ANCHO and x % 6 == 3
		objetos.set_cell(Vector2i(x, -1), 0, MURO_ANTORCHA if hay_antorcha else MURO)
		objetos.set_cell(Vector2i(x, ALTO), 0, MURO)
		if hay_antorcha:
			_encender_antorcha(Vector2(x * TILE + TILE / 2.0, -TILE / 2.0))
	for y in range(0, ALTO):
		objetos.set_cell(Vector2i(-1, y), 0, MURO)
		objetos.set_cell(Vector2i(ANCHO, y), 0, MURO)
	# Un par de antorchas en los muros laterales
	_encender_antorcha(Vector2(-TILE / 2.0, 7 * TILE))
	_encender_antorcha(Vector2(ANCHO * TILE + TILE / 2.0, 13 * TILE))


## Luz calida y fija de cada antorcha.
func _encender_antorcha(donde: Vector2) -> void:
	var luz := PointLight2D.new()
	luz.texture = preload("res://sprites/luz.png")
	luz.position = donde
	luz.color = Color(1.0, 0.72, 0.34)
	luz.energy = 1.15
	luz.texture_scale = 1.1
	add_child(luz)


## Cajas, barriles y el cofre con el objeto nuevo. Sirven de cobertura, como dice el documento.
func _colocar_objetos() -> void:
	for celda in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(21, 5), Vector2i(22, 5)]:
		objetos.set_cell(celda, 0, CAJA)
	for celda in [Vector2i(8, 12), Vector2i(9, 12), Vector2i(24, 14)]:
		objetos.set_cell(celda, 0, CAJA_ALTA)
	for celda in [Vector2i(2, 15), Vector2i(26, 3)]:
		objetos.set_cell(celda, 0, BARRIL)
	objetos.set_cell(Vector2i(26, 10), 0, COFRE)


## Enemigos del cuarto. Por ahora solo se dibujan; su comportamiento va en el siguiente paso.
func _colocar_enemigos() -> void:
	if sprite_enemigo == null:
		return
	for celda in ENEMIGOS:
		var enemigo := Sprite2D.new()
		enemigo.texture = sprite_enemigo
		enemigo.position = Vector2(celda.x * TILE + TILE / 2.0, celda.y * TILE + TILE / 2.0)
		add_child(enemigo)
