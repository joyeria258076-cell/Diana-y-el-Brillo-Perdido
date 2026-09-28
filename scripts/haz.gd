extends Area2D
## Haz de luz que sale de la lupa. Al tocar a un enemigo le quita oxido.
## No hace dano "de verdad": lo que hace es limpiar.

## Fuerza con la que pule; se resta del oxido del enemigo.
@export var fuerza: int = 1
@export var velocidad: float = 260.0
@export var alcance: float = 150.0

var direccion: Vector2 = Vector2.RIGHT
var _recorrido: float = 0.0


func _ready() -> void:
	body_entered.connect(_al_tocar)


func _physics_process(delta: float) -> void:
	var avance := direccion * velocidad * delta
	position += avance
	_recorrido += avance.length()
	if _recorrido >= alcance:
		queue_free()


func _al_tocar(cuerpo: Node) -> void:
	if cuerpo.has_method("recibir_pulido"):
		cuerpo.recibir_pulido(fuerza)
		queue_free()
	elif cuerpo is StaticBody2D:
		queue_free()  # choca contra los muros
