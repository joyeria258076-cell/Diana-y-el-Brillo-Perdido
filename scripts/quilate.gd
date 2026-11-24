# Quilate: el colibrí que acompaña a Diana. La sigue con un poco de retraso,
# aletea y se adelanta al lado hacia donde ella mira.
extends Node2D

var target: Node2D
var sprite: AnimatedSprite2D
var t := 0.0
var vel := Vector2.ZERO

func _ready() -> void:
	sprite = Anim.sprite({"volar": ["quilate_fly", 10, true]}, "volar")
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	t += delta
	var lado := -1.0 if target.sprite.flip_h else 1.0
	var meta := target.position + Vector2(18 * lado, -4 + sin(t * 1.7) * 4.0)
	# Resorte suave: acelera hacia la meta y se pasa un poquito, como un colibrí.
	vel += (meta - position) * 18.0 * delta
	vel *= exp(-5.0 * delta)
	position += vel * delta
	# Vuela por encima del piso: el sprite sube, el origen (para ordenar) queda en el suelo.
	sprite.position.y = -34 + sin(t * 3.0) * 3.0
	sprite.scale = Vector2(0.5, 0.5)  # sin estirar: el pixel se embarra
	sprite.flip_h = (vel.x < 0.0) if absf(vel.x) > 5.0 else (lado < 0.0)
