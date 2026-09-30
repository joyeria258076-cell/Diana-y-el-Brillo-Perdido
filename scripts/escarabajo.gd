extends CharacterBody2D
## Escarabajo Oxidado. Persigue a Diana y, al recibir el haz, se le va quitando el oxido.
## Cuando el oxido llega a cero NO muere: recupera su color original y se retira del cuarto.

signal pulido

const DESTELLO := preload("res://escenas/destello.tscn")

@export var oxido_maximo: int = 3
@export var velocidad: float = 26.0
@export var distancia_de_alerta: float = 130.0

var _oxido: int = 0
var _limpio: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var sombra: Sprite2D = $Sombra

## La hoja del escarabajo ya pulido: el mismo dibujo con la paleta cambiada
## a plata. Los cuadros se arman en codigo para no duplicar la escena.
const HOJA_LIMPIA := preload("res://sprites/personajes/escarabajo_limpio_caminar.png")


func _ready() -> void:
	_oxido = oxido_maximo
	add_to_group("enemigos")


func _physics_process(_delta: float) -> void:
	if _limpio:
		return
	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	var hacia: Vector2 = jugador.global_position - global_position
	# Solo persigue cuando Diana esta cerca; si no, se queda en su lugar.
	if hacia.length() <= distancia_de_alerta:
		velocity = hacia.normalized() * velocidad
		sprite.flip_h = hacia.x < 0.0
	else:
		velocity = Vector2.ZERO
	move_and_slide()


## Lo llama el haz de la lupa. Devuelve true cuando el enemigo queda limpio.
func recibir_pulido(fuerza: int) -> void:
	if _limpio:
		return
	_oxido -= fuerza
	_parpadear()
	if _oxido <= 0:
		_quedar_limpio()


## Destello blanco corto para que se note que le pego el haz.
func _parpadear() -> void:
	var animacion := create_tween()
	animacion.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.05)
	animacion.tween_property(sprite, "modulate", Color.WHITE, 0.12)


## Cambia los cuadros por los de la hoja ya pulida, recortandola en cuatro.
func _ponerse_limpio() -> void:
	var cuadros := SpriteFrames.new()
	cuadros.add_animation(&"limpio")
	cuadros.set_animation_loop(&"limpio", true)
	cuadros.set_animation_speed(&"limpio", 6.0)
	for i in 4:
		var recorte := AtlasTexture.new()
		recorte.atlas = HOJA_LIMPIA
		recorte.region = Rect2(i * 32, 0, 32, 32)
		cuadros.add_frame(&"limpio", recorte)
	sprite.sprite_frames = cuadros
	sprite.play(&"limpio")


## Recupera su forma original, suelta un destello y se retira.
func _quedar_limpio() -> void:
	_limpio = true
	velocity = Vector2.ZERO
	_ponerse_limpio()
	set_collision_layer_value(2, false)

	var destello := DESTELLO.instantiate()
	destello.global_position = global_position
	get_parent().add_child(destello)

	pulido.emit()

	var salida := create_tween()
	salida.set_parallel(true)
	salida.tween_property(self, "position", position + Vector2(0, -14), 0.8)
	salida.tween_property(sprite, "modulate:a", 0.0, 0.8)
	salida.tween_property(sombra, "modulate:a", 0.0, 0.5)
	await salida.finished
	queue_free()
