extends CharacterBody2D
## Los jefes. Comparten la mecanica de pulir con los enemigos normales, pero
## cada uno pelea distinto, como dice el libreto:
##
##   parpadeo  el Vendedor de Humo se desvanece y reaparece en otra esquina
##   escondite Carbonel se esconde en la oscuridad y sale por sorpresa
##   copias    el Baron crea copias falsas y hay que dar con el verdadero
##
## Y todos entran en furia cuando les queda poco oxido: se mueven mas rapido
## y atacan mas seguido.

signal pulido(quien)
signal oxido_cambiado(actual: int, total: int)

const DESTELLO := preload("res://escenas/destello.tscn")
const Efectos := preload("res://scripts/efectos.gd")

var ficha: Dictionary = {}
var limites: Rect2 = Rect2()
var es_copia: bool = false

var _oxido: int = 20
var _oxido_total: int = 20
var _limpio: bool = false
var _reloj: float = 0.0
var _siguiente_truco: float = 3.0
var _golpe: float = 0.0
var _oculto: bool = false
var _copias: Array[Node] = []

@onready var sprite: Sprite2D = $Sprite
@onready var sombra: Sprite2D = $Sombra
@onready var colision: CollisionShape2D = $Colision


func preparar(datos: Dictionary) -> void:
	ficha = datos
	_oxido = datos.get("oxido", 20)
	_oxido_total = _oxido

	var textura: Texture2D = load(datos["sprite"])
	sprite.texture = textura
	sprite.offset.y = -textura.get_height() * 0.5

	var forma := RectangleShape2D.new()
	forma.size = Vector2(textura.get_width() * 0.55, textura.get_height() * 0.4)
	colision.shape = forma
	colision.position.y = -textura.get_height() * 0.2

	sombra.position.y = 2.0
	sombra.scale = Vector2(textura.get_width() / 55.0, 0.55)


func _ready() -> void:
	add_to_group("enemigos")
	add_to_group("jefes")
	if not es_copia:
		oxido_cambiado.emit(_oxido, _oxido_total)


func _physics_process(delta: float) -> void:
	if _limpio:
		return
	_reloj += delta
	_golpe = maxf(0.0, _golpe - delta)
	_siguiente_truco -= delta

	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var furioso := _oxido <= _oxido_total / 3
	var rapidez: float = ficha.get("velocidad", 46.0) * (1.5 if furioso else 1.0)

	if not _oculto:
		var hacia: Vector2 = jugador.global_position - global_position
		velocity = hacia.normalized() * rapidez
		sprite.flip_h = hacia.x < 0.0
		move_and_slide()
		_quedarse_dentro()

		if hacia.length() < 34.0 and _golpe == 0.0 \
				and jugador.has_method("recibir_dano"):
			jugador.recibir_dano(ficha.get("dano", 1), global_position)
			_golpe = 1.0

	sprite.position.y = -absf(sin(_reloj * 6.0)) * 3.0

	if _siguiente_truco <= 0.0 and not es_copia:
		_hacer_truco(jugador, furioso)


func _hacer_truco(jugador: Node2D, furioso: bool) -> void:
	_siguiente_truco = (2.2 if furioso else 3.6)
	match ficha.get("patron", ""):
		"parpadeo":
			_teletransportarse(jugador)
		"escondite":
			_esconderse()
		"copias":
			_crear_copias(jugador)


## Vendedor de Humo: desaparece en una nube y sale en otro lado.
func _teletransportarse(jugador: Node2D) -> void:
	Efectos.humo(get_parent(), global_position, Color(0.75, 0.75, 0.8, 0.85), 60.0)
	var destino := Vector2(
		randf_range(limites.position.x, limites.position.x + limites.size.x),
		randf_range(limites.position.y, limites.position.y + limites.size.y))
	# Nunca aparece encima de Diana.
	if destino.distance_to(jugador.global_position) < 120.0:
		destino += (destino - jugador.global_position).normalized() * 160.0
	global_position = destino
	Efectos.humo(get_parent(), global_position, Color(0.75, 0.75, 0.8, 0.85), 60.0)
	Efectos.chispas(get_parent(), global_position, Color(0.8, 0.8, 0.9), 12)


## Carbonel: se mete en la oscuridad y reaparece a los dos segundos.
func _esconderse() -> void:
	_oculto = true
	velocity = Vector2.ZERO
	Efectos.humo(get_parent(), global_position, Color(0.4, 0.45, 0.7, 0.8), 50.0)

	var ir := create_tween()
	ir.tween_property(sprite, "modulate:a", 0.12, 0.3)
	ir.tween_property(sombra, "modulate:a", 0.0, 0.1)
	await get_tree().create_timer(1.6).timeout
	if _limpio or not is_instance_valid(self):
		return

	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador:
		global_position = jugador.global_position + Vector2(
			randf_range(-150, 150), randf_range(-120, 120))
		_quedarse_dentro()
	var volver := create_tween()
	volver.tween_property(sprite, "modulate:a", 1.0, 0.2)
	volver.parallel().tween_property(sombra, "modulate:a", 0.5, 0.2)
	Efectos.chispas(get_parent(), global_position, Color(0.6, 0.7, 1.0), 14)
	_oculto = false


## Baron Oxido: crea dos copias. Solo el verdadero recibe el pulido; las
## copias se deshacen en humo al primer toque.
func _crear_copias(jugador: Node2D) -> void:
	for c in _copias:
		if is_instance_valid(c):
			c.queue_free()
	_copias.clear()

	for i in 2:
		var copia := duplicate() as CharacterBody2D
		copia.es_copia = true
		copia.global_position = global_position + Vector2(
			randf_range(-170, 170), randf_range(-110, 110))
		get_parent().add_child(copia)
		copia.preparar(ficha)
		copia.limites = limites
		copia.modulate = Color(1, 1, 1, 0.78)
		_copias.append(copia)
	Efectos.humo(get_parent(), global_position, Color(0.7, 0.85, 0.7, 0.7), 70.0)


func recibir_pulido(fuerza: int) -> void:
	if _limpio:
		return

	# Las copias se deshacen de un toque y no quitan oxido al verdadero.
	if es_copia:
		Efectos.humo(get_parent(), global_position, Color(0.7, 0.85, 0.7, 0.7), 40.0)
		Efectos.numero(get_parent(), global_position, "¡falsa!",
			Color(0.7, 1.0, 0.7))
		queue_free()
		return

	if _oculto:
		return

	_oxido -= fuerza
	oxido_cambiado.emit(maxi(_oxido, 0), _oxido_total)
	Efectos.parpadear(sprite)
	Efectos.chispas(get_parent(), global_position + Vector2(0, -20),
		Color(0.95, 0.7, 0.4), 10)
	Efectos.numero(get_parent(), global_position + Vector2(0, -20),
		"-%d" % fuerza, Color(1, 0.86, 0.5))

	if _oxido <= 0:
		_quedar_limpio()


func _quedar_limpio() -> void:
	_limpio = true
	velocity = Vector2.ZERO
	set_collision_layer_value(2, false)
	colision.set_deferred("disabled", true)
	for c in _copias:
		if is_instance_valid(c):
			c.queue_free()

	sprite.modulate = Color(1.4, 1.4, 1.45)
	Efectos.humo(get_parent(), global_position, Color(1, 1, 0.9, 0.9), 110.0)
	Efectos.chispas(get_parent(), global_position, Color(1, 0.95, 0.7), 30)

	for i in 8:
		var d := DESTELLO.instantiate()
		d.global_position = global_position + Vector2(
			randf_range(-40, 40), randf_range(-25, 25))
		get_parent().call_deferred("add_child", d)

	pulido.emit(self)

	var salida := create_tween()
	salida.set_parallel(true)
	salida.tween_property(self, "position", position + Vector2(0, -40), 1.2)
	salida.tween_property(sprite, "modulate:a", 0.0, 1.2)
	salida.tween_property(sombra, "modulate:a", 0.0, 0.6)
	await salida.finished
	queue_free()


func _quedarse_dentro() -> void:
	if limites.size == Vector2.ZERO:
		return
	global_position.x = clampf(global_position.x, limites.position.x,
		limites.position.x + limites.size.x)
	global_position.y = clampf(global_position.y, limites.position.y,
		limites.position.y + limites.size.y)
