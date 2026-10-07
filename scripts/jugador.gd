extends CharacterBody2D
## Diana. Se mueve en cualquier direccion y apunta por separado, hacia donde
## este el raton. No usa armas: con la lupa "pule" a los enemigos, que es el
## sistema de dano del juego visto al reves.

signal vida_cambiada(actual: int, maxima: int)
signal brillo_cambiado(actual: int, maximo: int)
signal destellos_cambiados(cantidad: int)
signal murio

const HAZ := preload("res://escenas/haz.tscn")
const Efectos := preload("res://scripts/efectos.gd")

@export var velocidad: float = 118.0
@export var vida_maxima: int = 6
@export var brillo_maximo: int = 180
@export var recarga_por_segundo: float = 26.0
@export var costo_por_disparo: int = 6
@export var espera_entre_disparos: float = 0.2

## Impulso de esquive: se desbloquea al vencer al primer jefe.
@export var impulso: float = 420.0
@export var espera_de_impulso: float = 1.1

var vida: int = 6
var destellos: int = 0
var tiene_impulso: bool = false
var limites: Rect2 = Rect2()

var _brillo: float = 0.0
var _espera: float = 0.0
var _espera_impulso: float = 0.0
var _invulnerable: float = 0.0
var _impulsando: float = 0.0
var _direccion_impulso: Vector2 = Vector2.ZERO
var _paso: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var sombra: Sprite2D = $Sombra
@onready var camara: Camera2D = $Camara
@onready var lupa: Node2D = $Lupa


func _ready() -> void:
	add_to_group("jugador")
	vida = vida_maxima
	_brillo = brillo_maximo
	# Diferido: asi el HUD ya existe cuando le mandamos los primeros valores.
	_avisar.call_deferred()


func _physics_process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	_espera_impulso = maxf(0.0, _espera_impulso - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_impulsando = maxf(0.0, _impulsando - delta)

	var direccion := _leer_direccion()
	if _impulsando > 0.0:
		velocity = _direccion_impulso * impulso * (_impulsando / 0.16)
	else:
		velocity = direccion * velocidad
	move_and_slide()
	_quedarse_dentro()

	_animar(direccion, delta)
	_apuntar()
	_recargar(delta)
	_parpadeo_de_invulnerable()

	if _quiere_impulso() and tiene_impulso and _espera_impulso == 0.0 \
			and direccion != Vector2.ZERO:
		_dar_impulso(direccion)

	if _quiere_disparar() and _espera == 0.0 and _brillo >= costo_por_disparo:
		_disparar()


## Teclado: W A S D o las flechas. Normalizado para que en diagonal no
## corra mas rapido.
func _leer_direccion() -> Vector2:
	var d := Vector2.ZERO
	d.x = _eje(KEY_D, KEY_RIGHT) - _eje(KEY_A, KEY_LEFT)
	d.y = _eje(KEY_S, KEY_DOWN) - _eje(KEY_W, KEY_UP)
	return d.normalized()


func _eje(tecla: Key, alterna: Key) -> float:
	return 1.0 if Input.is_key_pressed(tecla) or Input.is_key_pressed(alterna) else 0.0


func _quiere_disparar() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_J)


func _quiere_impulso() -> bool:
	return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_K)


## El cuerpo rebota y se encoge al caminar, y suelta polvo cada tantos pasos.
## Es la caminata: el sprite es uno solo, el movimiento lo pone el codigo.
func _animar(direccion: Vector2, delta: float) -> void:
	if direccion == Vector2.ZERO:
		_paso = 0.0
		sprite.position.y = lerpf(sprite.position.y, 0.0, 0.3)
		sprite.scale = sprite.scale.lerp(Vector2.ONE, 0.3)
		return

	var antes := _paso
	_paso += delta * 11.0
	sprite.position.y = -absf(sin(_paso)) * 2.4
	sprite.scale = Vector2(1.0 + sin(_paso) * 0.045, 1.0 - sin(_paso) * 0.045)
	sombra.scale.x = 1.0 - absf(sin(_paso)) * 0.18

	# Cada vez que el pie toca el suelo (cuando el seno cruza cero).
	if int(antes / PI) != int(_paso / PI):
		Efectos.polvo(get_parent(), global_position + Vector2(0, 14))


## La lupa gira siguiendo al raton y Diana se voltea hacia ese lado. Si
## apunta hacia arriba, la lupa pasa por detras de ella.
func _apuntar() -> void:
	var hacia := get_global_mouse_position() - global_position
	if hacia.length() < 1.0:
		return
	lupa.rotation = hacia.angle()
	lupa.scale.y = -1.0 if absf(hacia.angle()) > PI / 2.0 else 1.0
	lupa.z_index = -2 if hacia.y < -10.0 else 2
	sprite.flip_h = hacia.x < 0.0


func _recargar(delta: float) -> void:
	if _brillo < brillo_maximo:
		_brillo = minf(brillo_maximo, _brillo + recarga_por_segundo * delta)
		brillo_cambiado.emit(int(_brillo), brillo_maximo)


func _disparar() -> void:
	_brillo -= costo_por_disparo
	_espera = espera_entre_disparos

	var hacia := (get_global_mouse_position() - global_position).normalized()
	var haz := HAZ.instantiate()
	haz.direccion = hacia
	haz.global_position = global_position + hacia * 18.0
	get_parent().add_child(haz)

	Efectos.fogonazo(get_parent(), global_position + hacia * 20.0,
		Color(1.0, 0.95, 0.7), 0.9)
	Efectos.sacudir(camara, 1.4, 0.08)
	brillo_cambiado.emit(int(_brillo), brillo_maximo)


func _dar_impulso(direccion: Vector2) -> void:
	_impulsando = 0.16
	_espera_impulso = espera_de_impulso
	_direccion_impulso = direccion
	_invulnerable = maxf(_invulnerable, 0.3)
	Efectos.humo(get_parent(), global_position + Vector2(0, 10),
		Color(1, 0.95, 0.8, 0.5), 30.0)


## Lo llaman los enemigos al tocarla.
func recibir_dano(cuanto: int, desde: Vector2) -> void:
	if _invulnerable > 0.0:
		return
	vida = maxi(0, vida - cuanto)
	_invulnerable = 1.0
	vida_cambiada.emit(vida, vida_maxima)

	# Empujon hacia el lado contrario del golpe.
	var hacia := (global_position - desde).normalized()
	velocity = hacia * 180.0
	move_and_slide()

	Efectos.parpadear(sprite, 2)
	Efectos.sacudir(camara, 6.0, 0.3)
	Efectos.chispas(get_parent(), global_position, Color(1, 0.5, 0.5), 10, hacia)

	if vida == 0:
		murio.emit()


func curar(cuanto: int) -> void:
	vida = mini(vida_maxima, vida + cuanto)
	vida_cambiada.emit(vida, vida_maxima)
	Efectos.humo(get_parent(), global_position, Color(0.6, 1.0, 0.7, 0.6), 34.0)


func recoger_destello(cantidad: int) -> void:
	destellos += cantidad
	destellos_cambiados.emit(destellos)


## Mientras es invulnerable se ve intermitente, como en todos los juegos:
## es la forma mas clara de avisar que ahorita no le entran golpes.
func _parpadeo_de_invulnerable() -> void:
	sprite.modulate.a = 1.0 if _invulnerable == 0.0 \
		else (0.35 if int(_invulnerable * 14.0) % 2 == 0 else 1.0)


## No deja salir a Diana de la zona caminable del cuarto.
func _quedarse_dentro() -> void:
	if limites.size == Vector2.ZERO:
		return
	global_position.x = clampf(global_position.x, limites.position.x,
		limites.position.x + limites.size.x)
	global_position.y = clampf(global_position.y, limites.position.y,
		limites.position.y + limites.size.y)


func _avisar() -> void:
	vida_cambiada.emit(vida, vida_maxima)
	brillo_cambiado.emit(int(_brillo), brillo_maximo)
	destellos_cambiados.emit(destellos)
