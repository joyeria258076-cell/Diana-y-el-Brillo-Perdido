# Muebles de la mazmorra (estilo piedra). Bloquean el paso y reaccionan a los disparos.
# Los de madera y vidrio se rompen con su animación; la piedra solo se sacude y suelta polvo.
extends Node2D

const VIDA := {"caja": 3, "barril": 3, "barril_joyas": 3, "estante": 3, "vitrina": 2, "cofre": 4}

var main
var tipo := "caja"
var vida := 0
var roto := false
var sprite: Sprite2D
var w := 40.0
var h := 40.0
var celdas: Array = []
var pisable := false  # se dibuja en el piso y se camina encima (vías del tren, manchas)
var img := ""        # objeto de los niveles 2 y 3 (assets/objetos/deco/...)
var esc := 0.5

# Objetos de los niveles 2 y 3 que se rompen (assets/objetos/deco/rompe/rompe.json).
static var ROMPE := {}
func _rompe() -> Dictionary:
	if ROMPE.is_empty() and FileAccess.file_exists("res://assets/objetos/deco/rompe/rompe.json"):
		ROMPE = JSON.parse_string(FileAccess.get_file_as_string("res://assets/objetos/deco/rompe/rompe.json"))
	return ROMPE.get(img.get_file().get_basename(), {})

func _ready() -> void:
	vida = VIDA.get(tipo, 0)
	if tipo == "deco" and not _rompe().is_empty():
		vida = 1 if "inicio_4" in img or "inicio_5" in img else int(_rompe().get("vida", 3))   # faroles: un golpe; rocas y cristales: 5
	if tipo == "tina":
		_piscina()
		return
	sprite = Sprite2D.new()
	sprite.texture = load(img if img != "" else "res://assets/objetos/mueble_%s.png" % tipo)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(esc, esc)
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	add_child(sprite)
	w = sprite.texture.get_width() * esc
	h = sprite.texture.get_height() * esc
	if pisable:
		z_index = -4
		roto = true   # no bloquea ni recibe disparos
		return
	# Huella en el piso: la parte de abajo del mueble (vista 3/4).
	var pie := h * 0.45
	for cx in range(int((position.x - w * 0.42) / 16.0), int((position.x + w * 0.42) / 16.0) + 1):
		for cy in range(int((position.y - pie) / 16.0), int((position.y - 2) / 16.0) + 1):
			var c := Vector2i(cx, cy)
			main.bloques_dyn[c] = true
			celdas.append(c)
	if tipo == "tina":
		main.TINAS[main.room_id] = Rect2(position.x - w * 0.38, position.y - h * 0.82, w * 0.76, h * 0.5)

# Piscina hundida en el piso: no bloquea ni recibe disparos; lo que camina dentro se hunde.
func _piscina() -> void:
	roto = true
	z_index = -4
	sprite = Sprite2D.new()
	var v: String = ["piscina", "piscina", "piscina_cadenas", "piscina_calavera"].pick_random()
	sprite.texture = load("res://assets/objetos/%s.png" % v)
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	var tam := sprite.texture.get_size() * 2.0
	if v == "piscina":
		sprite.hframes = 4
		tam.x /= 4.0
		var tw := create_tween().set_loops()
		for i in 4:
			tw.tween_callback(func(): sprite.frame = i).set_delay(0.22)
	w = tam.x
	h = tam.y
	main.TINAS[main.room_id] = Rect2(position - tam * Vector2(0.36, 0.3), tam * Vector2(0.72, 0.6))

func toca(p: Vector2) -> bool:
	return not roto and Rect2(position.x - w * 0.45, position.y - h * 0.92, w * 0.9, h * 0.92).has_point(p)

func _color() -> Color:
	if main.player and not main.player.armas.is_empty():
		return Armas.DATOS[main.player.arma()].color
	return Color(1.0, 0.85, 0.5)

func golpear(n := 1) -> void:
	if roto:
		return
	var c := _color()
	Fx.chispas(main.mundo, position + Vector2(randf_range(-w, w) * 0.3, -h * 0.5), c, 5)
	sprite.modulate = Color(1.8, 1.8, 1.8)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	var t2 := create_tween()
	for i in 4:
		t2.tween_property(sprite, "position:x", (2.0 if i % 2 == 0 else -2.0) * (1.0 - i * 0.22), 0.03)
	t2.tween_property(sprite, "position:x", 0.0, 0.03)
	if vida <= 0:
		# Piedra: no se rompe, suelta polvo y lascas.
		Juego.sonido("golpe", true, -8.0)
		Fx.polvo(main.mundo, position + Vector2(randf_range(-w, w) * 0.3, -2))
		Fx.chispas(main.mundo, position + Vector2(0, -h * 0.6), Color(0.55, 0.58, 0.55), 4)
		return
	Juego.sonido("golpe", true, -4.0)
	vida -= n
	if vida <= 0:
		romper()

func romper() -> void:
	if tipo == "deco" and not roto and not _rompe().is_empty():
		_romper_deco()
		return
	if roto or not VIDA.has(tipo):
		return
	roto = true
	for c in celdas:
		main.bloques_dyn.erase(c)
	celdas.clear()
	var m: Dictionary = Fx.meta("mueble_%s_rompe" % tipo)
	sprite.texture = load("res://assets/objetos/mueble_%s_rompe.png" % tipo)
	sprite.hframes = 6
	sprite.frame = 0
	var fw: float = m.w
	var fh: float = m.h
	sprite.offset = Vector2(fw / 2.0 - m.ax, m.base - fh / 2.0)
	var c := _color()
	Fx.estallido(main.mundo, position + Vector2(0, -h * 0.5), c)
	Fx.chispas(main.mundo, position + Vector2(0, -h * 0.5), c, 12)
	main.sacudir(3.0 if tipo != "cofre" else 4.5)
	Juego.sonido("pulir", true, -6.0)
	var lento := 0.13 if tipo == "cofre" else 0.08
	var tw := create_tween()
	for i in range(1, 6):
		tw.tween_callback(func(): sprite.frame = i).set_delay(lento)
	tw.tween_callback(func(): z_index = -1)   # los restos quedan en el piso
	# Botín
	match tipo:
		"cofre":
			Fx.chispas(main.mundo, position + Vector2(0, -h * 0.7), Color(1.0, 0.85, 0.3), 20)
			for i in 5:
				main.soltar("destello", position + Vector2(randf_range(-22, 22), randf_range(6, 18)))
			if randf() < 0.35:
				main.soltar("corazon", position + Vector2(0, 16))
		"barril_joyas":
			for i in 3:
				main.soltar("destello", position + Vector2(randf_range(-18, 18), randf_range(6, 14)))
		_:
			if randf() < 0.3:
				main.soltar("destello", position + Vector2(0, 10))

func _draw() -> void:
	if tipo == "tina":
		return
	draw_set_transform(Vector2(0, 0), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, w * 0.48, Color(0, 0, 0, 0.3))


# Se rompe con su tira de Gemini: deja de estorbar, suelta astillas y polvo,
# y los restos se quedan en el piso.
func _romper_deco() -> void:
	roto = true
	for c in celdas:
		main.bloques_dyn.erase(c)
	celdas.clear()
	var d: Dictionary = _rompe()
	var tex: Texture2D = load("res://assets/objetos/deco/rompe/%s.png" % d.get("tira", img.get_file().get_basename()))
	var alto_orig: float = sprite.texture.get_height() * esc
	var b0: Array = d.b0
	var k: float = alto_orig / maxf(1.0, float(b0[3]) - float(b0[1]))
	sprite.texture = tex
	sprite.hframes = int(d.n)
	sprite.frame = 0
	sprite.scale = Vector2(k, k)
	sprite.offset = Vector2(float(d.w) / 2.0 - (float(b0[0]) + float(b0[2])) / 2.0, float(d.h) / 2.0 - float(b0[3]))
	var c := Color(0.55, 0.4, 0.28)
	Fx.polvo(main.mundo, position + Vector2(0, -2))
	Fx.chispas(main.mundo, position + Vector2(0, -h * 0.5), c, 12)
	Fx.chispas(main.mundo, position + Vector2(0, -h * 0.5), _color(), 6)
	main.sacudir(2.5)
	Juego.sonido("golpe", true, -2.0)
	Juego.sonido("pulir", true, -8.0)
	var tw := create_tween()
	for i in range(1, int(d.n)):
		tw.tween_callback(func(): sprite.frame = i).set_delay(0.07)
	tw.tween_callback(func():
		z_index = -1   # los restos quedan en el piso
		Fx.polvo(main.mundo, position + Vector2(0, -2)))
	if randf() < 0.35:
		main.soltar("destello", position + Vector2(0, 12))
