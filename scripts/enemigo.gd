extends CharacterBody2D
## Enemigo opacado. Persigue a Diana y, al recibir el haz, se le va quitando
## el oxido. Cuando llega a cero NO muere: recupera su color y se retira.
##
## Un solo guion sirve para los tres tipos. Lo que cambia (velocidad, oxido,
## si vuela, si va en zigzag) viene de la ficha que se le pasa al crearlo.

signal pulido(quien)

const DESTELLO := preload("res://escenas/destello.tscn")
const Efectos := preload("res://scripts/efectos.gd")

var ficha: Dictionary = {}
var limites: Rect2 = Rect2()

var _oxido: int = 3
var _oxido_total: int = 3
var _limpio: bool = false
var _reloj: float = 0.0
var _golpe: float = 0.0
var _flota: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var sombra: Sprite2D = $Sombra
@onready var colision: CollisionShape2D = $Colision


## Lo llama el cuarto justo despues de crearlo.
func preparar(datos: Dictionary) -> void:
	ficha = datos
	_oxido = datos.get("oxido", 3)
	_oxido_total = _oxido

	var textura: Texture2D = load(datos["sprite"])
	sprite.texture = textura

	# La caja de colision se ajusta al tamano real del dibujo.
	var forma := RectangleShape2D.new()
	forma.size = Vector2(textura.get_width() * 0.6, textura.get_height() * 0.45)
	colision.shape = forma
	colision.position.y = textura.get_height() * 0.22

	sombra.position.y = textura.get_height() * 0.44
	sombra.scale = Vector2(textura.get_width() / 60.0, 0.5)

	# Los que vuelan no tocan el piso: se les baja la sombra y se les sube
	# el cuerpo, que es lo que hace leer que estan en el aire.
	if datos.get("vuela", false):
		sprite.position.y = -14.0
		sombra.modulate.a = 0.35


func _ready() -> void:
	add_to_group("enemigos")
	sprite.offset.y = -sprite.texture.get_height() * 0.5 if sprite.texture else 0.0


func _physics_process(delta: float) -> void:
	if _limpio:
		return
	_reloj += delta
	_golpe = maxf(0.0, _golpe - delta)

	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var hacia: Vector2 = jugador.global_position - global_position
	var distancia := hacia.length()

	if distancia <= ficha.get("alerta", 260.0):
		var rumbo := hacia.normalized()
		# La polilla no va derecho: se mueve en zigzag, como dice su ficha.
		if ficha.get("zigzag", false):
			rumbo = rumbo.rotated(sin(_reloj * 4.0) * 0.6)
		velocity = rumbo * ficha.get("velocidad", 50.0)
		sprite.flip_h = hacia.x < 0.0
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)

	move_and_slide()
	_quedarse_dentro()

	# Los que vuelan flotan todo el tiempo; los que caminan rebotan al andar.
	if ficha.get("vuela", false):
		_flota += delta * 3.4
		sprite.position.y = -14.0 + sin(_flota) * 3.0
	elif velocity.length() > 4.0:
		_flota += delta * 9.0
		sprite.position.y = -absf(sin(_flota)) * 2.0

	if distancia < 26.0 and _golpe == 0.0 and jugador.has_method("recibir_dano"):
		jugador.recibir_dano(ficha.get("dano", 1), global_position)
		_golpe = 0.8


## Lo llama el haz de la lupa.
func recibir_pulido(fuerza: int) -> void:
	if _limpio:
		return
	_oxido -= fuerza
	Efectos.parpadear(sprite)
	Efectos.chispas(get_parent(), global_position, Color(0.95, 0.65, 0.35), 8)
	Efectos.numero(get_parent(), global_position, "-%d" % fuerza,
		Color(1, 0.86, 0.5))

	# Retroceso corto: se siente que el haz pega.
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador:
		var empuje: float = ficha.get("empuje", 70.0)
		velocity = (global_position - jugador.global_position).normalized() * empuje
		move_and_slide()

	if _oxido <= 0:
		_quedar_limpio()


## Recupera su forma original, suelta destellos y se retira volando.
func _quedar_limpio() -> void:
	_limpio = true
	velocity = Vector2.ZERO
	set_collision_layer_value(2, false)
	colision.set_deferred("disabled", true)

	# Al quedar limpio recupera el color: se le quita el tinte oxidado.
	sprite.modulate = Color(1.35, 1.35, 1.4)
	Efectos.humo(get_parent(), global_position, Color(1, 1, 0.9, 0.8), 46.0)
	Efectos.chispas(get_parent(), global_position, Color(1, 0.95, 0.7), 16)

	var cuantos := 2 if _oxido_total <= 3 else 4
	for i in cuantos:
		var d := DESTELLO.instantiate()
		d.global_position = global_position + Vector2(
			randf_range(-18, 18), randf_range(-10, 10))
		get_parent().call_deferred("add_child", d)

	pulido.emit(self)

	var salida := create_tween()
	salida.set_parallel(true)
	salida.tween_property(self, "position", position + Vector2(0, -26), 0.9)
	salida.tween_property(sprite, "modulate:a", 0.0, 0.9)
	salida.tween_property(sombra, "modulate:a", 0.0, 0.5)
	await salida.finished
	queue_free()


func _quedarse_dentro() -> void:
	if limites.size == Vector2.ZERO:
		return
	global_position.x = clampf(global_position.x, limites.position.x,
		limites.position.x + limites.size.x)
	global_position.y = clampf(global_position.y, limites.position.y,
		limites.position.y + limites.size.y)
