extends Area2D
## Haz de luz que sale de la lupa. Al tocar a un enemigo le quita oxido.
## No hace dano "de verdad": lo que hace es limpiar, que es la mecanica
## del juego vista al reves.

const Efectos := preload("res://scripts/efectos.gd")

## Fuerza con la que pule; se resta del oxido del enemigo.
@export var fuerza: int = 1
@export var velocidad: float = 420.0
@export var alcance: float = 300.0

var direccion: Vector2 = Vector2.RIGHT

var _recorrido: float = 0.0
var _dejo_estela: float = 0.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_al_tocar)
	rotation = direccion.angle()
	# El haz nace chico y se estira: se siente que sale disparado.
	sprite.scale = Vector2(0.015, 0.03)
	var crecer := create_tween()
	crecer.tween_property(sprite, "scale", Vector2(0.075, 0.035), 0.07)


func _physics_process(delta: float) -> void:
	var avance := direccion * velocidad * delta
	position += avance
	_recorrido += avance.length()

	# Va soltando puntos de luz detras, que se apagan solos.
	_dejo_estela -= delta
	if _dejo_estela <= 0.0:
		_dejo_estela = 0.02
		Efectos.estela(get_parent(), global_position, Color(1, 0.9, 0.6, 0.8))

	if _recorrido >= alcance:
		_apagarse()


func _al_tocar(algo: Node) -> void:
	if algo.has_method("recibir_pulido"):
		algo.recibir_pulido(fuerza)
		_apagarse()


## Se apaga con un destello corto en vez de desaparecer de golpe.
func _apagarse() -> void:
	if not is_inside_tree():
		return
	set_physics_process(false)
	set_deferred("monitoring", false)
	Efectos.chispas(get_parent(), global_position, Color(1, 0.93, 0.7), 5,
		-direccion)
	queue_free()
