# Objetos que se rompen: caja, jarrón y barril de solvente (este explota).
extends Node2D

var main
var tipo := "caja"
var vida := 2
var celda := Vector2i.ZERO

func _ready() -> void:
	vida = 3 if tipo == "caja" else (1 if tipo == "jarron" else 2)
	celda = Vector2i(int(position.x / 16.0), int(position.y / 16.0))
	main.bloques_dyn[celda] = true
	# Sprite de "sprites objetos que se rompen" (con la base en el piso).
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/objetos/%s.png" % tipo)
	sprite.scale = Vector2(0.5, 0.5)
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	add_child(sprite)

var sprite: Sprite2D

# El objeto roto se queda un rato en el piso y luego se desvanece.
func _dejar_restos() -> void:
	var r := Sprite2D.new()
	r.texture = load("res://assets/objetos/%s.png" % (tipo + ("_rota" if tipo == "caja" else "_roto")))
	r.scale = Vector2(0.5, 0.5)
	r.offset = Vector2(0, -r.texture.get_height() / 2.0)
	r.position = position + Vector2(0, 2)
	r.z_index = -1
	main.mundo.add_child(r)
	var tw := r.create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(r, "modulate:a", 0.0, 1.0)
	tw.tween_callback(r.queue_free)

func golpear(n := 1) -> void:
	vida -= n
	Juego.sonido("golpe", true, -4.0)
	scale = Vector2(1.2, 0.85)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.12)
	if vida <= 0:
		romper()

func romper() -> void:
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	main.bloques_dyn.erase(celda)
	var color := Color(0.7, 0.5, 0.3) if tipo == "caja" else (Color(0.4, 0.6, 0.9) if tipo == "jarron" else Color(0.4, 0.75, 0.3))
	Fx.chispas(main.mundo, position + Vector2(0, -8), color, 10)
	_dejar_restos()
	if tipo == "barril":
		_explotar()
	elif randf() < 0.4:
		main.soltar("destello", position)
	queue_free()

func _explotar() -> void:
	Juego.sonido("pulir", false)
	main.sacudir(9.0)
	Fx.animar(main.mundo, position + Vector2(0, -14), "fx_explosion", 12.0, Color.WHITE, 1.0)
	Fx.chispas(main.mundo, position + Vector2(0, -8), Color(1.0, 0.7, 0.3), 24)
	for e in main.enemigos():
		if e.position.distance_to(position) < 60.0:
			e.danar(4, (e.position - position).normalized(), false)
	if main.player.position.distance_to(position) < 50.0:
		main.player.herir(1)
	for r in main.rompibles():
		if r != self and r.position.distance_to(position) < 50.0:
			r.call_deferred("romper")

func _draw() -> void:
	# Sombra bajo el objeto; el dibujo es el sprite.
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.3))
