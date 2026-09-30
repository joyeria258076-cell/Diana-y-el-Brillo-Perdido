extends CharacterBody2D
## Diana. Se mueve en cualquier direccion (con teclado salen las ocho combinaciones)
## y apunta por separado: en computadora, hacia donde este el puntero del raton.

const HAZ := preload("res://escenas/haz.tscn")

## Velocidad de caminata en pixeles por segundo.
@export var velocidad: float = 90.0
## Cuanto brillo gasta cada disparo y que tan seguido se puede disparar.
@export var costo_por_disparo: int = 6
@export var espera_entre_disparos: float = 0.22
## Brillo: es la "municion" de los objetos. Se recarga solo.
@export var brillo_maximo: int = 180
@export var recarga_por_segundo: float = 22.0

var vida: int = 3
var destellos: int = 0

var _brillo: float = 0.0
var _espera: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("jugador")
	_brillo = brillo_maximo
	# Diferido: asi el HUD ya termino de cargar cuando le mandamos los primeros valores.
	_avisar_al_hud.call_deferred()


func _physics_process(delta: float) -> void:
	var direccion := _leer_direccion()
	velocity = direccion * velocidad
	move_and_slide()

	_animar_caminata(direccion)
	_voltear_segun_apuntado()
	_recargar_brillo(delta)

	_espera = maxf(0.0, _espera - delta)
	if _quiere_disparar() and _espera == 0.0 and _brillo >= costo_por_disparo:
		_disparar()


## Lee el teclado y devuelve la direccion ya normalizada,
## para que en diagonal no se mueva mas rapido.
func _leer_direccion() -> Vector2:
	var direccion := Vector2.ZERO
	direccion.x = _eje(KEY_D, KEY_RIGHT) - _eje(KEY_A, KEY_LEFT)
	direccion.y = _eje(KEY_S, KEY_DOWN) - _eje(KEY_W, KEY_UP)
	return direccion.normalized()


func _eje(tecla: Key, alterna: Key) -> float:
	return 1.0 if Input.is_key_pressed(tecla) or Input.is_key_pressed(alterna) else 0.0


## Se dispara con clic izquierdo o con la tecla J; las dos hacen lo mismo.
func _quiere_disparar() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_J)


## La caminata ya viene dibujada en los cuatro cuadros del sprite, con su
## rebote incluido. Aqui solo se elige que animacion toca.
func _animar_caminata(direccion: Vector2) -> void:
	var quieta := direccion == Vector2.ZERO
	var toca := &"quieta" if quieta else &"caminar"
	if sprite.animation != toca:
		sprite.play(toca)


## El personaje se dibuja en una sola vista de frente y solo se voltea en espejo
## segun hacia donde apunte, en lugar de animarlo en cuatro direcciones.
func _voltear_segun_apuntado() -> void:
	var objetivo := get_global_mouse_position()
	if not is_equal_approx(objetivo.x, global_position.x):
		sprite.flip_h = objetivo.x < global_position.x


func _recargar_brillo(delta: float) -> void:
	if _brillo < brillo_maximo:
		_brillo = minf(brillo_maximo, _brillo + recarga_por_segundo * delta)
		_avisar_al_hud()


func _disparar() -> void:
	_brillo -= costo_por_disparo
	_espera = espera_entre_disparos

	var haz := HAZ.instantiate()
	haz.direccion = (get_global_mouse_position() - global_position).normalized()
	haz.global_position = global_position + haz.direccion * 8.0
	get_parent().add_child(haz)
	_avisar_al_hud()


func recoger_destello(cantidad: int) -> void:
	destellos += cantidad
	_avisar_al_hud()


func _avisar_al_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	hud.mostrar_vida(vida)
	hud.mostrar_brillo(int(_brillo))
	hud.mostrar_destellos(destellos)
