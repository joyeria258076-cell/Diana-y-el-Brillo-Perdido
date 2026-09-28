extends CharacterBody2D
## Diana. Se mueve en cualquier direccion (con teclado salen las ocho combinaciones)
## y apunta por separado: en computadora, hacia donde este el puntero del raton.

## Velocidad de caminata en pixeles por segundo. Se puede ajustar desde el inspector.
@export var velocidad: float = 90.0

@onready var sprite: Sprite2D = $Sprite


func _physics_process(_delta: float) -> void:
	velocity = _leer_direccion() * velocidad
	move_and_slide()
	_voltear_segun_apuntado()


## Lee el teclado y devuelve la direccion de movimiento ya normalizada,
## para que en diagonal no se mueva mas rapido.
func _leer_direccion() -> Vector2:
	var direccion := Vector2.ZERO
	direccion.x = _eje(KEY_D, KEY_RIGHT) - _eje(KEY_A, KEY_LEFT)
	direccion.y = _eje(KEY_S, KEY_DOWN) - _eje(KEY_W, KEY_UP)
	return direccion.normalized()


func _eje(tecla: Key, alterna: Key) -> float:
	return 1.0 if Input.is_key_pressed(tecla) or Input.is_key_pressed(alterna) else 0.0


## El personaje se dibuja en una sola vista de frente y solo se voltea en espejo
## segun hacia donde apunte, en lugar de animarlo en cuatro direcciones.
func _voltear_segun_apuntado() -> void:
	var objetivo := get_global_mouse_position()
	if not is_equal_approx(objetivo.x, global_position.x):
		sprite.flip_h = objetivo.x < global_position.x
