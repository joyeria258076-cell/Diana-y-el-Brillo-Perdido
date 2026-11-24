# Efectos que le dan vida al combate: sombras, chispas y estallidos de brillo.
class_name Fx

# Sombra ovalada bajo los pies; se agrega como hijo para que siga al personaje.
static func sombra(padre: Node2D, ancho: float) -> Node2D:
	var s := Sombra.new()
	s.ancho = ancho
	s.z_index = -1
	padre.add_child(s)
	return s

# Chispas que salen disparadas desde un punto y se apagan.
static func chispas(mundo: Node, pos: Vector2, color: Color, cuantas: int) -> void:
	for i in cuantas:
		var c := Chispa.new()
		c.position = pos
		c.color = color
		c.vel = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60.0, 170.0)
		mundo.add_child(c)

# Anillo de luz que crece y se desvanece (al pulir a un enemigo).
static func estallido(mundo: Node, pos: Vector2, color: Color) -> void:
	var a := Anillo.new()
	a.position = pos
	a.color = color
	mundo.add_child(a)


class Sombra extends Node2D:
	var ancho := 20.0
	func _draw() -> void:
		# Sombra en dos capas (orilla suave y centro oscuro) para que se note sobre el piso oscuro.
		draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.38))
		draw_circle(Vector2.ZERO, ancho * 0.62, Color(0, 0, 0, 0.32), true, -1.0, false)
		draw_circle(Vector2.ZERO, ancho * 0.44, Color(0, 0, 0, 0.45), true, -1.0, false)
		draw_circle(Vector2.ZERO, ancho * 0.26, Color(0, 0, 0, 0.55), true, -1.0, false)


class Chispa extends Node2D:
	var vel := Vector2.ZERO
	var color := Color.WHITE
	var vida := 0.35
	var _total := -1.0
	func _process(delta: float) -> void:
		if _total < 0.0:
			_total = vida
		position += vel * delta
		vel *= 0.88
		vida -= delta
		if vida <= 0.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var c := color
		c.a = clampf(vida / maxf(_total, 0.01), 0.0, 1.0)
		draw_rect(Rect2(-1.5, -1.5, 3, 3), c)


class Anillo extends Node2D:
	var color := Color.WHITE
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.4:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var c := color
		c.a = 1.0 - t / 0.4
		draw_arc(Vector2.ZERO, 6.0 + t * 70.0, 0, TAU, 24, c, 3.0)


# Número de daño que sube y se desvanece. Los críticos salen amarillos y grandes.
static func numero(mundo: Node, pos: Vector2, n: int, critico := false) -> void:
	var l := Label.new()
	l.text = str(n) + ("!" if critico else "")
	l.add_theme_font_size_override("font_size", 14 if critico else 10)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2) if critico else Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.position = pos + Vector2(randf_range(-8, 4), -10)
	l.z_index = 50
	l.add_theme_constant_override("outline_size", 3)
	mundo.add_child(l)
	# Salta hacia arriba, cae rebotando un poco y se desvanece.
	var lado := randf_range(-14.0, 14.0)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:x", l.position.x + lado, 0.7)
	tw.tween_property(l, "position:y", l.position.y - 22, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_property(l, "position:y", l.position.y - 8, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tw.chain().tween_callback(l.queue_free)

# Nubecita de polvo al caminar.
static func polvo(mundo: Node, pos: Vector2) -> void:
	var p := Polvo.new()
	p.position = pos + Vector2(randf_range(-4, 4), 0)
	p.z_index = -1
	mundo.add_child(p)

# Arco del corte del paño.
static func corte(mundo: Node, pos: Vector2, angulo: float, color: Color) -> void:
	var c := Corte.new()
	c.position = pos
	c.rotation = angulo
	c.color = color
	mundo.add_child(c)

# Textura de luz redonda para PointLight2D.
static var _luz: GradientTexture2D

static func textura_luz() -> GradientTexture2D:
	if _luz == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_luz = GradientTexture2D.new()
		_luz.gradient = g
		_luz.fill = GradientTexture2D.FILL_RADIAL
		_luz.fill_from = Vector2(0.5, 0.5)
		_luz.fill_to = Vector2(0.5, 0.0)
		_luz.width = 256
		_luz.height = 256
	return _luz


class Polvo extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		position.y -= 8.0 * delta
		if t > 0.4:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 2.0 + t * 8.0, Color(0.7, 0.62, 0.5, 0.45 * (1.0 - t / 0.4)))


class Corte extends Node2D:
	var color := Color.WHITE
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.18:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 - t / 0.18
		draw_arc(Vector2.ZERO, 30.0, -1.1, 1.1, 16, Color(color, a), 7.0)
		draw_arc(Vector2.ZERO, 30.0, -0.9, 0.9, 16, Color(1, 1, 1, a), 2.5)


# Animación de un solo uso con una tira de assets/objetos (fx_explosion, fx_estallido...).
static var _meta: Dictionary = {}

static func meta_o_nada(clave: String) -> bool:
	if _meta.is_empty():
		_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/objetos/objetos.json"))
	return _meta.has(clave)

static func meta(clave: String) -> Dictionary:
	if _meta.is_empty():
		_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/objetos/objetos.json"))
	return _meta[clave]

# Cuadros guardados para no crear (y soltar) texturas en cada dibujo.
static var _cuadros := {}

static func cuadro(clave: String, i: int) -> AtlasTexture:
	var k := "%s_%d" % [clave, i]
	if not _cuadros.has(k):
		var m := meta(clave)
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/objetos/%s.png" % clave)
		at.region = Rect2(i * m.w, 0, m.w, m.h)
		_cuadros[k] = at
	return _cuadros[k]

# Cuadro reducido a "tam" pixeles del mundo (1 pixel del dibujo = 1 del mundo), como Diana retro:
# promedia por mitades (sin perder color) y deja la orilla dura, sin semitransparencias.
static var _retro := {}
static func cuadro_retro(clave: String, i: int, tam: Vector2) -> Texture2D:
	var w := maxi(1, roundi(tam.x))
	var h := maxi(1, roundi(tam.y))
	var k := "%s_%d_%d_%d" % [clave, i, w, h]
	if not _retro.has(k):
		var at := cuadro(clave, i)
		var src := at.atlas.get_image().get_region(Rect2i(at.region))
		src.convert(Image.FORMAT_RGBA8)
		# Cada pixel nuevo toma un color REAL del bloque (el más cercano al promedio), sin mezclar:
		# así no se embarra. Luego se le pone contorno oscuro como a Diana.
		var sw := src.get_width()
		var sh := src.get_height()
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var x0 := int(float(x) * sw / w)
				var x1 := maxi(x0 + 1, int(float(x + 1) * sw / w))
				var y0 := int(float(y) * sh / h)
				var y1 := maxi(y0 + 1, int(float(y + 1) * sh / h))
				var suma := Vector3.ZERO
				var llenos: Array[Color] = []
				for yy in range(y0, mini(y1, sh)):
					for xx in range(x0, mini(x1, sw)):
						var c := src.get_pixel(xx, yy)
						if c.a >= 0.5:
							llenos.append(c)
							suma += Vector3(c.r, c.g, c.b)
				var total := (x1 - x0) * (y1 - y0)
				if llenos.size() < total * 0.4:
					continue
				var prom := suma / llenos.size()
				var mejor := llenos[0]
				var dmin := 99.0
				for c in llenos:
					var d := Vector3(c.r, c.g, c.b).distance_squared_to(prom)
					if d < dmin:
						dmin = d
						mejor = c
				mejor.a = 1.0
				img.set_pixel(x, y, mejor)
		var con := img.duplicate()
		for y in h:
			for x in w:
				if img.get_pixel(x, y).a > 0.0:
					continue
				for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = Vector2i(x, y) + o
					if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and img.get_pixelv(q).a > 0.0:
						con.set_pixel(x, y, Color8(24, 18, 24))
						break
		_retro[k] = ImageTexture.create_from_image(con)
	return _retro[k]

static func animar(mundo: Node, pos: Vector2, clave: String, fps: float, color := Color.WHITE, escala := 1.0, voltear := false) -> AnimatedSprite2D:
	var m := meta(clave)
	var sf := SpriteFrames.new()
	sf.set_animation_loop("default", false)
	sf.set_animation_speed("default", fps)
	for i in int(m.n):
		sf.add_frame("default", cuadro(clave, i))
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.position = pos
	s.scale = Vector2.ONE * 0.5 * escala
	s.modulate = color
	s.flip_h = voltear
	s.z_index = 20
	mundo.add_child(s)
	s.play()
	s.animation_finished.connect(s.queue_free)
	return s

# Igual que animar, pero entra creciendo y se desvanece al final (no aparece ni se corta de golpe).
# El último cuadro se queda un momento mientras se apaga.
static func animar_suave(padre: Node, pos: Vector2, clave: String, fps: float, color := Color.WHITE, escala := 1.0, apagar := 0.3) -> AnimatedSprite2D:
	var s := animar(padre, pos, clave, fps, color, escala)
	s.animation_finished.disconnect(s.queue_free)
	var base := s.scale
	s.scale = base * 0.65
	s.modulate.a = 0.0
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "modulate:a", color.a, 0.15)
	tw.tween_property(s, "scale", base, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Fundido entre cuadros: el cuadro que se va deja una copia que se desvanece.
	var previo := [0]
	s.frame_changed.connect(func():
		var f0: int = previo[0]
		previo[0] = s.frame
		var g := Sprite2D.new()
		g.texture = s.sprite_frames.get_frame_texture("default", f0)
		g.position = s.position
		g.scale = s.scale
		g.flip_h = s.flip_h
		g.z_index = s.z_index
		g.modulate = Color(s.modulate, s.modulate.a * 0.55)
		s.get_parent().add_child(g)
		var tg := g.create_tween()
		tg.tween_property(g, "modulate:a", 0.0, 1.6 / fps)
		tg.tween_callback(g.queue_free))
	s.animation_finished.connect(func():
		var t2 := s.create_tween().set_parallel()
		t2.tween_property(s, "modulate:a", 0.0, apagar)
		t2.tween_property(s, "scale", base * 1.08, apagar)
		t2.chain().tween_callback(s.queue_free))
	return s

# Collar de perlas lanzado como látigo.
static func latigo(mundo: Node, desde: Vector2, dir: Vector2, largo: float) -> void:
	var l := Latigo.new()
	l.position = desde
	l.dir = dir
	l.largo = largo
	l.z_index = 20
	mundo.add_child(l)


class Latigo extends Node2D:
	var dir := Vector2.RIGHT
	var largo := 140.0
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.22:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		# Se estira rápido y se recoge, con una ondita.
		var k := sin(clampf(t / 0.22, 0.0, 1.0) * PI)
		var n := 12
		for i in n:
			var f := float(i) / (n - 1)
			var p := dir * largo * k * f + dir.orthogonal() * sin(f * 9.0 + t * 30.0) * 4.0 * f
			draw_circle(p, 3.2, Color(0.1, 0.07, 0.07))
			draw_circle(p, 2.4, Color(0.97, 0.95, 0.9))
			draw_circle(p + Vector2(-0.8, -0.8), 0.9, Color.WHITE)


# Destello de joyera: varias capas a la vez para que se sienta fuerte.
# Destello blanco, luz rosa que se apaga, onda expansiva doble, el sprite del
# estallido, estrellitas que salen volando y un golpe de zoom en la cámara.
static func destello_joyera(main, pos: Vector2) -> void:
	var mundo: Node = main.mundo
	var onda := Onda.new()
	onda.position = pos
	onda.z_index = 25
	mundo.add_child(onda)
	animar(mundo, pos, "fx_estallido", 16.0, Color(1, 1, 1, 0.95), 1.7)
	var luz := PointLight2D.new()
	luz.texture = textura_luz()
	luz.color = Color(1.0, 0.45, 0.75)
	luz.energy = 3.0
	luz.texture_scale = 1.0
	luz.position = pos
	mundo.add_child(luz)
	var tw := luz.create_tween().set_parallel(true)
	tw.tween_property(luz, "energy", 0.0, 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(luz, "texture_scale", 3.5, 0.6).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(luz.queue_free)
	for i in 22:
		var e := Estrella.new()
		e.position = pos
		var a := TAU * i / 22.0 + randf_range(-0.1, 0.1)
		e.vel = Vector2.RIGHT.rotated(a) * randf_range(120.0, 260.0)
		e.tam = randf_range(2.5, 5.5)
		e.color = [Color(1.0, 0.55, 0.8), Color(1.0, 0.85, 0.95), Color(1.0, 0.9, 0.5)].pick_random()
		e.z_index = 26
		mundo.add_child(e)
	var cam: Camera2D = main.camara
	var z := cam.zoom
	var tz := cam.create_tween()
	tz.tween_property(cam, "zoom", z * 1.07, 0.06)
	tz.tween_property(cam, "zoom", z, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


class Onda extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > 0.55:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / 0.55
		var e := 1.0 - pow(1.0 - k, 3.0)  # sale rápido y frena
		# Destello blanco del centro al inicio.
		if t < 0.12:
			draw_circle(Vector2.ZERO, 40.0 * (1.0 - t / 0.12) + 10.0, Color(1, 1, 1, 0.85 * (1.0 - t / 0.12)))
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.62))
		draw_arc(Vector2.ZERO, 12.0 + e * 110.0, 0, TAU, 48, Color(1.0, 0.5, 0.78, 1.0 - k), 12.0 * (1.0 - k) + 1.0)
		draw_arc(Vector2.ZERO, 6.0 + e * 80.0, 0, TAU, 40, Color(1, 1, 1, 0.9 * (1.0 - k)), 5.0 * (1.0 - k) + 1.0)
		draw_circle(Vector2.ZERO, e * 100.0, Color(1.0, 0.6, 0.85, 0.18 * (1.0 - k)))


class Estrella extends Node2D:
	var vel := Vector2.ZERO
	var tam := 4.0
	var color := Color.WHITE
	var t := 0.0
	var vida := 0.7
	func _process(delta: float) -> void:
		t += delta
		position += vel * delta
		vel *= exp(-4.0 * delta)
		vel.y += 60.0 * delta
		rotation += delta * 8.0
		if t > vida:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 - t / vida
		var s := tam * (0.6 + a * 0.6)
		var c := Color(color, a)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(s * 0.3, -s * 0.3), Vector2(s, 0), Vector2(s * 0.3, s * 0.3),
			Vector2(0, s), Vector2(-s * 0.3, s * 0.3), Vector2(-s, 0), Vector2(-s * 0.3, -s * 0.3)]), c)
		draw_circle(Vector2.ZERO, s * 0.25, Color(1, 1, 1, a))


# "!" que salta sobre la cabeza cuando un enemigo descubre a Diana.
static func alerta(padre: Node2D, alto: float) -> void:
	var l := Label.new()
	l.text = "!"
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.position = Vector2(-4, -alto - 30)
	l.pivot_offset = Vector2(4, 22)
	l.z_index = 40
	l.scale = Vector2(0.2, 1.6)
	padre.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.45)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)

# Burbujas que suben y revientan (tina del limpiador).
static func burbujas(mundo: Node, pos: Vector2, cuantas: int, ancho := 20.0) -> void:
	for i in cuantas:
		var b := Burbuja.new()
		b.position = pos + Vector2(randf_range(-ancho, ancho), randf_range(-4, 4))
		b.vida = randf_range(0.5, 1.1)
		b.r = randf_range(1.5, 3.5)
		b.z_index = 20
		mundo.add_child(b)

# Partículas de colores que salen disparadas (al pulir a un enemigo).
static func confeti(mundo: Node, pos: Vector2, color: Color, cuantas: int) -> void:
	for i in cuantas:
		var c := Chispa.new()
		c.position = pos
		c.color = color.lightened(randf_range(-0.15, 0.3))
		c.vel = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(80.0, 220.0)
		c.vida = randf_range(0.35, 0.6)
		mundo.add_child(c)


class Burbuja extends Node2D:
	var vida := 0.8
	var r := 2.5
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		position += Vector2(sin(t * 9.0) * 12.0, -28.0) * delta
		if t > vida:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 - t / vida
		draw_arc(Vector2.ZERO, r, 0, TAU, 10, Color(0.8, 0.95, 1.0, a), 1.0)
		draw_circle(Vector2(-r * 0.35, -r * 0.35), r * 0.3, Color(1, 1, 1, a))


# Limpiador ultrasónico: tres ondas de agua a ras del piso, gotas y burbujas.
static func onda_agua(mundo: Node, pos: Vector2) -> void:
	for i in 3:
		var o := OndaAgua.new()
		o.position = pos
		o.retraso = i * 0.09
		o.z_index = -1
		mundo.add_child(o)
	burbujas(mundo, pos + Vector2(0, -6), 14, 30.0)
	for i in 12:
		var g := Chispa.new()
		g.position = pos + Vector2(0, -6)
		g.color = Color(0.6, 0.9, 1.0)
		g.vel = Vector2.RIGHT.rotated(TAU * i / 12.0) * randf_range(110.0, 170.0)
		g.vida = 0.4
		mundo.add_child(g)


class OndaAgua extends Node2D:
	var t := 0.0
	var retraso := 0.0
	func _process(delta: float) -> void:
		t += delta
		if t > retraso + 0.45:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := clampf((t - retraso) / 0.45, 0.0, 1.0)
		if k <= 0.0:
			return
		var e := 1.0 - pow(1.0 - k, 2.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
		draw_arc(Vector2.ZERO, 10.0 + e * 76.0, 0, TAU, 40, Color(0.55, 0.88, 1.0, 0.85 * (1.0 - k)), 4.0 * (1.0 - k) + 1.0)
		draw_arc(Vector2.ZERO, 8.0 + e * 76.0, 0, TAU, 40, Color(1, 1, 1, 0.6 * (1.0 - k)), 1.0)


# El enemigo se desarma en pedacitos de su propio dibujo: se deshace de arriba hacia abajo,
# los pedazos saltan, caen al piso, se quedan como restos un rato y se desvanecen.
static func desintegrar(mundo: Node, spr: AnimatedSprite2D, piso_y: float, tinte := Color.WHITE) -> void:
	var tex := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	if tex == null:
		return
	var img := tex.get_image()
	var esc := spr.global_scale.x
	var bloque := maxi(1, int(round(1.0 / esc)))   # 1 pixel del mundo por pedazo
	var w := img.get_width()
	var h := img.get_height()
	var r := Restos.new()
	r.piso = piso_y
	r.tam = bloque * esc
	var origen := spr.global_position + spr.offset * esc - Vector2(w, h) * 0.5 * esc
	for y in range(0, h, bloque):
		for x in range(0, w, bloque):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var xx := (w - 1 - x) if spr.flip_h else x
			var p := origen + Vector2(xx, y) * esc
			var k := float(y) / h   # los de arriba se sueltan primero
			r.pz.append({"p": p, "v": Vector2(randf_range(-55, 55), randf_range(-90, -20)),
				"c": c * tinte, "suelta": k * 0.35 + randf() * 0.08, "suelo": piso_y + randf_range(-3.0, 4.0), "quieto": false})
	r.z_index = -1   # los restos quedan en el piso: Diana camina por encima (antes se dibujaban sobre ella)
	mundo.add_child(r)

class Restos extends Node2D:
	var pz: Array = []
	var piso := 0.0
	var tam := 1.0
	var t := 0.0
	const DURA := 4.0   # segundos que los restos se quedan en el piso
	func _process(delta: float) -> void:
		t += delta
		for q in pz:
			if q.quieto or t < q.suelta:
				continue
			q.v.y += 420.0 * delta
			q.p += q.v * delta
			if q.p.y >= q.suelo:
				q.p.y = q.suelo
				if absf(q.v.y) > 60.0:
					q.v = Vector2(q.v.x * 0.5, -q.v.y * 0.3)   # rebotito
				else:
					q.quieto = true
		if t > DURA + 1.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := clampf((DURA + 1.0 - t), 0.0, 1.0)
		for q in pz:
			var c: Color = q.c
			c.a *= a
			draw_rect(Rect2(q.p.round(), Vector2(tam, tam)), c)
