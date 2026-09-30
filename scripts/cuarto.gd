extends Node2D
## Pinta el cuarto de la bodega, lo ilumina con las antorchas y controla a sus enemigos.
## La puerta del cuarto solo se abre cuando todos los enemigos quedaron pulidos.

const ESCARABAJO := preload("res://escenas/escarabajo.tscn")
const LUZ := preload("res://sprites/interfaz/luz.png")

## Medidas del cuarto en tiles. Cada tile mide 32 pixeles, igual que los
## personajes: asi Diana ocupa justo un cuadro de piso.
const ANCHO: int = 20
const ALTO: int = 12
const TILE: int = 32

## Columnas dentro del atlas. Va todo en una sola fila, por eso la Y siempre
## es 0 y solo cambia la X.
const PISO: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const MURO: Vector2i = Vector2i(4, 0)
const CAJA: Vector2i = Vector2i(5, 0)
const ROCA: Vector2i = Vector2i(6, 0)
const COFRE: Vector2i = Vector2i(7, 0)

## Cajas y rocas. No estan puestas al azar: forman pasillos y coberturas,
## que es lo que hace que el cuarto se juegue en vez de ser una cancha vacia.
const OBSTACULOS: Array[Vector2i] = [
	Vector2i(3, 2), Vector2i(4, 2), Vector2i(3, 3),
	Vector2i(15, 2), Vector2i(16, 2), Vector2i(16, 3),
	Vector2i(6, 7), Vector2i(7, 7), Vector2i(13, 7), Vector2i(14, 7),
]
const ROCAS: Array[Vector2i] = [Vector2i(9, 4), Vector2i(10, 8), Vector2i(2, 9), Vector2i(17, 8)]

## Donde aparecen los enemigos, donde esta el cofre y donde la puerta.
const ENEMIGOS: Array[Vector2i] = [Vector2i(5, 4), Vector2i(14, 4), Vector2i(16, 9), Vector2i(4, 9)]
const SITIO_COFRE: Vector2i = Vector2i(18, 2)
const PUERTA: Vector2i = Vector2i(10, -1)

var _enemigos_restantes: int = 0

@onready var piso: TileMapLayer = $Piso
@onready var objetos: TileMapLayer = $Objetos
@onready var aviso: Label = $Hud/Aviso


func _ready() -> void:
	_pintar_piso()
	_pintar_muros()
	_colocar_objetos()
	_colocar_enemigos()


## El piso usa cuatro variantes del mismo material para que no se vea repetido.
func _pintar_piso() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = 20221056  # semilla fija: el cuarto se ve igual cada vez que se juega
	for y in ALTO:
		for x in ANCHO:
			piso.set_cell(Vector2i(x, y), 0, PISO[azar.randi_range(0, PISO.size() - 1)])


## Marco de muros alrededor del cuarto. Cada antorcha ademas enciende una luz.
func _pintar_muros() -> void:
	for x in range(-1, ANCHO + 1):
		objetos.set_cell(Vector2i(x, -1), 0, MURO)
		objetos.set_cell(Vector2i(x, ALTO), 0, MURO)
		if x > 0 and x < ANCHO and x % 5 == 2:
			_encender_antorcha(Vector2(x * TILE + TILE / 2.0, -TILE / 4.0))
	for y in range(0, ALTO):
		objetos.set_cell(Vector2i(-1, y), 0, MURO)
		objetos.set_cell(Vector2i(ANCHO, y), 0, MURO)
	objetos.set_cell(PUERTA, 0, COFRE)
	_encender_antorcha(Vector2(-TILE / 4.0, 4 * TILE))
	_encender_antorcha(Vector2(ANCHO * TILE + TILE / 4.0, 8 * TILE))


## Luz calida de cada antorcha, con un titileo suave.
func _encender_antorcha(donde: Vector2) -> void:
	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.position = donde
	luz.color = Color(1.0, 0.72, 0.34)
	luz.energy = 1.15
	luz.texture_scale = 2.0
	add_child(luz)

	var titileo := create_tween().set_loops()
	titileo.tween_property(luz, "energy", 0.95, 0.7).set_trans(Tween.TRANS_SINE)
	titileo.tween_property(luz, "energy", 1.2, 0.5).set_trans(Tween.TRANS_SINE)


## Cajas, rocas y el cofre con el objeto nuevo.
func _colocar_objetos() -> void:
	for celda in OBSTACULOS:
		objetos.set_cell(celda, 0, CAJA)
	for celda in ROCAS:
		objetos.set_cell(celda, 0, ROCA)
	objetos.set_cell(SITIO_COFRE, 0, COFRE)


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
	objetos.erase_cell(PUERTA)
	aviso.text = "¡Cuarto limpio! La puerta se abrió"
	_encender_antorcha(Vector2(PUERTA.x * TILE + TILE / 2.0, -TILE / 4.0))
