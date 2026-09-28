extends Node2D
## Pinta el cuarto de la bodega con los tiles del pack.
## El cuarto se dibuja por codigo para poder cambiar su tamano sin volver a acomodar tile por tile.

## Medidas del cuarto en tiles (cada tile mide 16 pixeles).
const ANCHO: int = 30
const ALTO: int = 20

## Coordenadas dentro del atlas de tiles: Vector2i(columna, fila).
const PISO: Array[Vector2i] = [Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 4), Vector2i(5, 4)]
const MURO: Vector2i = Vector2i(4, 3)
const MURO_ANTORCHA: Vector2i = Vector2i(5, 2)
const CAJA: Vector2i = Vector2i(3, 5)
const CAJA_ALTA: Vector2i = Vector2i(0, 6)
const BARRIL: Vector2i = Vector2i(10, 6)
const COFRE: Vector2i = Vector2i(5, 7)

@onready var piso: TileMapLayer = $Piso
@onready var objetos: TileMapLayer = $Objetos


func _ready() -> void:
	_pintar_piso()
	_pintar_muros()
	_colocar_objetos()


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


## Marco de muros alrededor del cuarto, con antorchas cada seis tiles en el muro de arriba.
func _pintar_muros() -> void:
	for x in range(-1, ANCHO + 1):
		var arriba := MURO_ANTORCHA if x > 0 and x < ANCHO and x % 6 == 3 else MURO
		objetos.set_cell(Vector2i(x, -1), 0, arriba)
		objetos.set_cell(Vector2i(x, ALTO), 0, MURO)
	for y in range(0, ALTO):
		objetos.set_cell(Vector2i(-1, y), 0, MURO)
		objetos.set_cell(Vector2i(ANCHO, y), 0, MURO)


## Cajas, barriles y el cofre con el objeto nuevo. Sirven de cobertura, como dice el documento.
func _colocar_objetos() -> void:
	for celda in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(21, 5), Vector2i(22, 5)]:
		objetos.set_cell(celda, 0, CAJA)
	for celda in [Vector2i(8, 12), Vector2i(9, 12), Vector2i(24, 14)]:
		objetos.set_cell(celda, 0, CAJA_ALTA)
	for celda in [Vector2i(2, 15), Vector2i(26, 3)]:
		objetos.set_cell(celda, 0, BARRIL)
	objetos.set_cell(Vector2i(26, 10), 0, COFRE)
