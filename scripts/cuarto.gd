extends Node2D
## Pinta el cuarto de la bodega, lo ilumina con las antorchas y controla a sus enemigos.
## La puerta del cuarto solo se abre cuando todos los enemigos quedaron pulidos.

const ESCARABAJO := preload("res://escenas/escarabajo.tscn")
const LUZ := preload("res://sprites/interfaz/luz.png")

## Medidas del cuarto en tiles (cada tile mide 16 pixeles).
const ANCHO: int = 30
const ALTO: int = 20
const TILE: int = 16

## Coordenadas dentro del atlas de tiles: Vector2i(columna, fila).
const PISO: Array[Vector2i] = [Vector2i(0, 4), Vector2i(1, 4), Vector2i(3, 4), Vector2i(5, 4)]
const MURO: Vector2i = Vector2i(4, 3)
const MURO_ANTORCHA: Vector2i = Vector2i(5, 2)
const PUERTA_CERRADA: Vector2i = Vector2i(9, 3)
const PUERTA_ABIERTA: Vector2i = Vector2i(9, 1)
const CAJA: Vector2i = Vector2i(3, 5)
const CAJA_ALTA: Vector2i = Vector2i(0, 6)
const BARRIL: Vector2i = Vector2i(10, 6)
const COFRE: Vector2i = Vector2i(5, 7)

## Donde aparecen los enemigos y donde esta la puerta al siguiente cuarto.
const ENEMIGOS: Array[Vector2i] = [Vector2i(9, 5), Vector2i(19, 4), Vector2i(23, 12), Vector2i(12, 15)]
const PUERTA: Vector2i = Vector2i(15, -1)

var _enemigos_restantes: int = 0

@onready var piso: TileMapLayer = $Piso
@onready var objetos: TileMapLayer = $Objetos
@onready var aviso: Label = $Hud/Aviso


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
	objetos.set_cell(PUERTA, 0, PUERTA_CERRADA)
	# Un par de antorchas en los muros laterales
	_encender_antorcha(Vector2(-TILE / 2.0, 7 * TILE))
	_encender_antorcha(Vector2(ANCHO * TILE + TILE / 2.0, 13 * TILE))


## Luz calida de cada antorcha, con un titileo suave.
func _encender_antorcha(donde: Vector2) -> void:
	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.position = donde
	luz.color = Color(1.0, 0.72, 0.34)
	luz.energy = 1.15
	luz.texture_scale = 1.1
	add_child(luz)

	var titileo := create_tween().set_loops()
	titileo.tween_property(luz, "energy", 0.95, 0.7).set_trans(Tween.TRANS_SINE)
	titileo.tween_property(luz, "energy", 1.2, 0.5).set_trans(Tween.TRANS_SINE)


## Cajas, barriles y el cofre con el objeto nuevo. Sirven de cobertura, como dice el documento.
func _colocar_objetos() -> void:
	for celda in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(21, 5), Vector2i(22, 5)]:
		objetos.set_cell(celda, 0, CAJA)
	for celda in [Vector2i(8, 12), Vector2i(9, 12), Vector2i(24, 14)]:
		objetos.set_cell(celda, 0, CAJA_ALTA)
	for celda in [Vector2i(2, 15), Vector2i(26, 3)]:
		objetos.set_cell(celda, 0, BARRIL)
	objetos.set_cell(Vector2i(26, 10), 0, COFRE)


func _colocar_enemigos() -> void:
	for celda in ENEMIGOS:
		var enemigo := ESCARABAJO.instantiate()
		enemigo.position = Vector2(celda.x * TILE + TILE / 2.0, celda.y * TILE + TILE / 2.0)
		enemigo.pulido.connect(_al_pulir_enemigo)
		add_child(enemigo)
		_enemigos_restantes += 1
	_mostrar_pendientes()


func _al_pulir_enemigo() -> void:
	_enemigos_restantes -= 1
	if _enemigos_restantes > 0:
		_mostrar_pendientes()
	else:
		_abrir_puerta()


func _mostrar_pendientes() -> void:
	aviso.text = "Faltan %d por pulir" % _enemigos_restantes


## La puerta del cuarto se abre solo cuando ya no queda nada oxidado.
func _abrir_puerta() -> void:
	objetos.set_cell(PUERTA, 0, PUERTA_ABIERTA)
	aviso.text = "¡Cuarto limpio! La puerta se abrió"
	_encender_antorcha(Vector2(PUERTA.x * TILE + TILE / 2.0, -TILE / 2.0))
