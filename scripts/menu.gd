# Menú principal: título, Diana y Quilate de fondo, y los botones
# Jugar, Opciones, Créditos y Salir (mouse o flechas + Enter).
extends Control

# Colores de la marca (libreto: negro, oro rosa, champán y rosa pálido).
const NEGRO := Ui.NEGRO
const ORO_ROSA := Ui.ORO_ROSA
const CHAMPAN := Ui.CHAMPAN
const ROSA_PALIDO := Ui.ROSA_PALIDO
const CIRUELA := Ui.CIRUELA

var botones: Array = []
var quilate: AnimatedSprite2D
var titulo: Label
var brillos: Control
var t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Para pruebas viejas (--captura / --prueba) se entra directo al nivel.
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1 and (args[0] == "--captura" or args[0] == "--prueba"):
		get_tree().change_scene_to_file.call_deferred(Juego.NIVEL)
		return
	Juego.musica("menu")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_fondo()
	titulo = Ui.texto("Diana y el Brillo Perdido", 46, CHAMPAN)
	titulo.position = Vector2(0, 40)
	titulo.size = Vector2(960, 64)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_outline_color", CIRUELA.darkened(0.4))
	titulo.add_theme_constant_override("outline_size", 12)
	titulo.add_theme_color_override("font_shadow_color", ORO_ROSA.darkened(0.2))
	titulo.add_theme_constant_override("shadow_offset_x", 0)
	titulo.add_theme_constant_override("shadow_offset_y", 4)
	add_child(titulo)
	titulo.visible = false
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.size = Vector2(300, 172)
	logo.position = Vector2(480 - 150, 4)
	logo.pivot_offset = logo.size / 2.0
	add_child(logo)
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.85, 0.85)
	var tl := create_tween()
	tl.tween_property(logo, "modulate:a", 1.0, 0.6)
	tl.parallel().tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tl.tween_callback(func():
		var flota := logo.create_tween().set_loops()
		flota.tween_property(logo, "position:y", 9.0, 2.2).set_trans(Tween.TRANS_SINE)
		flota.tween_property(logo, "position:y", 4.0, 2.2).set_trans(Tween.TRANS_SINE))
	var brillo := BrilloLogo.new()
	brillo.logo = logo
	add_child(brillo)
	var sub := Ui.texto("J O Y E R Í A   D I A N A   L A U R A", 14, ROSA_PALIDO)
	sub.position = Vector2(0, 176)
	sub.visible = false
	sub.size = Vector2(960, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var caja := VBoxContainer.new()
	caja.position = Vector2(110, 200)
	caja.add_theme_constant_override("separation", 14)
	add_child(caja)
	for par in [["Jugar", _elegir_dificultad], ["Opciones", _opciones], ["Créditos", _creditos], ["Salir", func(): get_tree().quit()]]:
		var b := _boton(par[0])
		b.pressed.connect(par[1])
		caja.add_child(b)
		botones.append(b)
	Ui.enlazar(botones)
	botones[0].grab_focus()
	# Los botones entran uno tras otro desde la izquierda.
	for i in botones.size():
		var b: Button = botones[i]
		b.modulate.a = 0.0
		var tb := create_tween()
		tb.tween_interval(0.25 + i * 0.09)
		tb.tween_property(b, "modulate:a", 1.0, 0.3)
	var ayuda := Ui.texto("Flechas: elegir     Enter: aceptar", 13, ROSA_PALIDO)
	ayuda.modulate.a = 0.7
	ayuda.position = Vector2(110, 500)
	add_child(ayuda)
	var version := Ui.texto("v0.1", 13, ROSA_PALIDO)
	version.modulate.a = 0.6
	version.position = Vector2(905, 510)
	add_child(version)
	_pruebas()

# Botón del menú: el de Ui (colores de la joyería), un poco más grande.
func _boton(texto: String) -> Button:
	var b := Ui.boton(texto, 240)
	b.add_theme_font_size_override("font_size", 20)
	return b

# La tienda de fondo en penumbra, una luz de aparador detrás de Diana y destellos.
func _fondo() -> void:
	var tienda := TextureRect.new()
	tienda.texture = load("res://assets/ui/menu_fondo.png")
	tienda.set_anchors_preset(Control.PRESET_FULL_RECT)
	tienda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tienda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tienda.modulate = Color(0.85, 0.8, 0.88)
	tienda.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(tienda)
	# Penumbra ciruela: más oscura abajo para que resalten los botones y Diana.
	add_child(_degradado(Color(NEGRO, 0.55), Color(NEGRO, 0.93), Vector2(0.5, 0), Vector2(0.5, 1)))
	# Lado izquierdo más oscuro, detrás de los botones.
	add_child(_degradado(Color(NEGRO, 0.7), Color(NEGRO, 0.0), Vector2(0, 0.5), Vector2(0.55, 0.5)))
	add_child(Ambiente.new())   # encima de la penumbra para que se noten las luces
	# Luz rosada de aparador detrás de Diana.
	var luz := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(ORO_ROSA, 0.55))
	g.set_color(1, Color(ORO_ROSA, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	luz.texture = gt
	luz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luz.position = Vector2(470, 170)
	luz.size = Vector2(380, 340)
	add_child(luz)
	brillos = Brillos.new()
	brillos.menu = self
	add_child(brillos)
	var diana := Anim.sprite({"reposo": ["diana_idle", 3, true]}, "reposo")
	diana.scale = Vector2(0.75, 0.75)  # tira a 4x: 0.75 = 3 pixeles de pantalla por pixel del dibujo
	diana.position = Vector2(660, 432)
	# Contraluz: la misma Diana un poco más grande en rosa detrás, como luz del aparador en la orilla.
	var aura := Anim.sprite({"reposo": ["diana_idle", 3, true]}, "reposo")
	aura.scale = Vector2(0.8, 0.78)
	aura.position = diana.position + Vector2(3, 1)
	aura.modulate = Color(4.0, 2.0, 2.4, 0.55)
	aura.material = CanvasItemMaterial.new()
	aura.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(aura)
	var ta := aura.create_tween().set_loops()
	ta.tween_property(aura, "modulate:a", 0.35, 1.4).set_trans(Tween.TRANS_SINE)
	ta.tween_property(aura, "modulate:a", 0.6, 1.4).set_trans(Tween.TRANS_SINE)
	diana.modulate = Color(0.95, 0.88, 0.9)   # toma el tono cálido y oscuro de la tienda
	add_child(diana)
	# Luz de la lámpara del pedestal que la ilumina desde abajo.
	var luz_abajo := TextureRect.new()
	var gl := Gradient.new()
	gl.set_color(0, Color(1.0, 0.85, 0.7, 0.22))
	gl.set_color(1, Color(1.0, 0.85, 0.7, 0.0))
	var gtl := GradientTexture2D.new()
	gtl.gradient = gl
	gtl.fill = GradientTexture2D.FILL_RADIAL
	gtl.fill_from = Vector2(0.5, 1.0)
	gtl.fill_to = Vector2(0.5, 0.0)
	luz_abajo.texture = gtl
	luz_abajo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luz_abajo.position = Vector2(600, 330)
	luz_abajo.size = Vector2(120, 100)
	luz_abajo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(luz_abajo)
	quilate = Anim.sprite({"volar": ["quilate_fly", 10, true]}, "volar")
	quilate.scale = Vector2(1.5, 1.5)  # tira a 2x: 1.5 = 3 pixeles por pixel del dibujo
	quilate.position = Vector2(790, 290)
	quilate.flip_h = true
	add_child(quilate)

func _degradado(a: Color, b: Color, desde: Vector2, hasta: Vector2) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = desde
	gt.fill_to = hasta
	gt.width = 64
	gt.height = 64
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _process(delta: float) -> void:
	t += delta
	if quilate:
		quilate.position = Vector2(790 + sin(t * 0.9) * 14.0, 290 + sin(t * 3.0) * 6.0)
	if titulo:
		titulo.position.y = 40 + sin(t * 1.6) * 3.0


# Destellos que suben por la pantalla, el exhibidor bajo Diana, el adorno del
# título y una estrellita junto al botón elegido.
class Brillos extends Control:
	var menu
	var puntos: Array = []
	var t := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 26:
			puntos.append({"p": Vector2(randf() * 960, randf() * 540), "v": randf_range(8, 22),
				"f": randf() * TAU, "s": [1, 2, 2, 3].pick_random()})

	func _process(delta: float) -> void:
		t += delta
		for d in puntos:
			d.p.y -= d.v * delta
			d.p.x += sin(t + d.f) * 6.0 * delta
			if d.p.y < -10:
				d.p = Vector2(randf() * 960, 550)
		queue_redraw()

	const PEDESTAL := preload("res://assets/ui/pedestal.png")

	func _draw() -> void:
		# Exhibidor de joyería bajo los pies de Diana.
		var c := Vector2(660, 432)
		var ped: Texture2D = PEDESTAL
		# Haz de luz que sale del pedestal hacia arriba, detrás de Diana.
		var late := 0.5 + 0.5 * sin(t * 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(c.x - 44, c.y - 20), Vector2(c.x + 44, c.y - 20), Vector2(c.x + 70, c.y - 190), Vector2(c.x - 70, c.y - 190)]),
			Color(1.0, 0.85, 0.75, 0.05 + 0.03 * late))
		draw_texture(ped, Vector2(c.x - ped.get_width() / 2.0, c.y - 44).round())
		# Sombra de Diana sobre la tapa del pedestal.
		draw_set_transform(Vector2(c.x + 4, c.y - 4), 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, 50, Color(0.1, 0.04, 0.1, 0.45))
		draw_circle(Vector2.ZERO, 38, Color(0.08, 0.03, 0.08, 0.6))
		draw_circle(Vector2.ZERO, 26, Color(0.05, 0.02, 0.05, 0.75))
		draw_set_transform(Vector2.ZERO)
		# Brillo de la tapa alrededor de la sombra.
		draw_set_transform(Vector2(c.x, c.y - 16), 0, Vector2(1, 0.3))
		draw_arc(Vector2.ZERO, 58, 0, TAU, 40, Color(1.0, 0.9, 0.8, 0.25 + 0.15 * late), 3.0)
		draw_set_transform(Vector2.ZERO)
		# Chispitas que suben desde el pedestal.
		for k in 6:
			var f := fmod(t * 0.5 + k * 0.33, 2.0)
			var px := c.x - 50 + fmod(k * 37.0, 100.0) + sin(t + k) * 4.0
			var py := c.y - 22 - f * 80.0
			Ui.estrella(self, Vector2(px, py), 1.0, Color(1.0, 0.85, 0.7, (1.0 - f / 2.0) * 0.8))
		# Adorno bajo el título: dos líneas y un rombo.
		var y := 142.0
		draw_rect(Rect2(330, y, 130, 2), menu.ORO_ROSA)
		draw_rect(Rect2(500, y, 130, 2), menu.ORO_ROSA)
		_estrella(Vector2(480, y + 1), 3, menu.CHAMPAN)
		# Destellos flotando.
		for d in puntos:
			var a := 0.35 + 0.65 * absf(sin(t * 2.0 + d.f))
			_estrella(d.p, d.s, Color(menu.CHAMPAN, a))
		# Estrellita junto al botón elegido.
		var foco := get_viewport().gui_get_focus_owner()
		if foco in menu.botones:
			var r: Rect2 = foco.get_global_rect()
			var s := 3 if int(t * 3.0) % 2 == 0 else 4
			_estrella(Vector2(r.position.x - 18, r.get_center().y), s, menu.CHAMPAN)
			_estrella(Vector2(r.end.x + 18, r.get_center().y), s, menu.CHAMPAN)

	# Destello de cuatro puntas hecho con cuadritos (pixel art).
	func _estrella(p: Vector2, s: int, col: Color) -> void:
		var q := float(s)
		draw_rect(Rect2(p.x - q * 0.5, p.y - q * 2.5, q, q * 5), col)
		draw_rect(Rect2(p.x - q * 2.5, p.y - q * 0.5, q * 5, q), col)
		draw_rect(Rect2(p.x - q, p.y - q, q * 2, q * 2), Color(1, 1, 1, col.a))

func _elegir_dificultad() -> void:
	# Se esconde el menú (logo, botones y adornos) y queda solo el fondo de la tienda.
	var ocultos: Array = []
	for c in get_children():
		if c is CanvasItem and c.visible and c.get_index() > 0:
			c.visible = false
			ocultos.append(c)
	var e = preload("res://scripts/dificultad.gd").new()
	e.cerrado.connect(func():
		for c in ocultos:
			if is_instance_valid(c):
				c.visible = true
		botones[0].grab_focus())
	add_child(e)

func _opciones() -> void:
	var o = preload("res://scripts/opciones.gd").new()
	o.cerrado.connect(func(): botones[1].grab_focus())
	add_child(o)

func _creditos() -> void:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(Ui.velo(0.6))
	add_child(capa)
	var p := Ui.panel()
	p.position = Vector2(220, 70)
	p.custom_minimum_size = Vector2(520, 0)
	capa.add_child(p)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	p.add_child(caja)
	caja.add_child(Ui.titulo("Créditos"))
	# Secciones en oro rosa y nombres en champán, con un respiro entre secciones.
	for linea in [
		["Desarrollo y arte", ORO_ROSA, 15],
		["Hernández Bautista Marcos Uriel", CHAMPAN, 17],
		["Hernández Martínez Diana Laura", CHAMPAN, 17],
		["", null, 4],
		["Optativa 1: Creación de Videojuegos", ORO_ROSA, 15],
		["MTI. Juvencio Mendoza Castelán", CHAMPAN, 17],
		["", null, 4],
		["Universidad Tecnológica de la Huasteca Hidalguense", ROSA_PALIDO, 15],
		["Hecho con Godot Engine 4.7", ROSA_PALIDO, 13]]:
		if linea[0] == "":
			var hueco := Control.new()
			hueco.custom_minimum_size = Vector2(0, linea[2])
			caja.add_child(hueco)
			continue
		var l := Ui.texto(linea[0], linea[2], linea[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(l)
	var b := Ui.boton("Regresar")
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(b)
	var cerrar := func():
		capa.queue_free()
		botones[2].grab_focus()
	b.pressed.connect(cerrar)
	b.grab_focus()

# Solo para pruebas: godot -- --foto menu|opciones|creditos|carga|juego
func _pruebas() -> void:
	match Juego.foto:
		"opciones": _opciones()
		"creditos": _creditos()
		"dificultad": _elegir_dificultad()
		"carga", "dialogo", "derrota", "victoria", "pausa", "menu_pausa", "fin", "juego":
			Juego.jugar()
	if Juego.foto in ["menu", "opciones", "creditos", "carga", "dificultad"]:
		await get_tree().create_timer(1.0 if Juego.foto != "carga" else 1.3).timeout
		get_viewport().get_texture().get_image().save_png("user://foto_%s.png" % Juego.foto)
		get_tree().quit()


# Vida del fondo: lámparas que titilan, luz de luna que respira, niebla que se arrastra
# por el piso y destellos en las joyas del aparador y las repisas.
class Ambiente extends Control:
	var t := 0.0
	var niebla: Array = []
	var luz: Texture2D

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		luz = gt
		for i in 9:
			niebla.append({"x": randf() * 1100.0 - 70.0, "y": randf_range(330, 470), "v": randf_range(6, 16), "s": randf_range(140, 260), "f": randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		for n in niebla:
			n.x += n.v * delta
			if n.x > 1060.0:
				n.x = -200.0
		queue_redraw()

	func _draw() -> void:
		# Lámparas de pared: halo cálido que titila.
		for p in [Vector2(285, 48), Vector2(680, 48)]:
			var k := 0.75 + 0.15 * sin(t * 9.0 + p.x) + 0.1 * sin(t * 23.0 + p.x * 0.3)
			var r := 46.0 * k
			draw_texture_rect(luz, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1.0, 0.72, 0.4, 0.35 * k))
			draw_texture_rect(luz, Rect2(p - Vector2(10, 10), Vector2(20, 20)), false, Color(1.0, 0.9, 0.6, 0.6 * k))
		# Luz de luna que entra por la ventana y respira.
		var lu := 0.12 + 0.05 * sin(t * 0.9)
		draw_colored_polygon(PackedVector2Array([Vector2(905, 60), Vector2(960, 60), Vector2(820, 470), Vector2(640, 470)]), Color(0.6, 0.75, 1.0, lu))
		# Destellos en las joyas del aparador y las repisas.
		var joyas := [Vector2(545, 215), Vector2(585, 205), Vector2(612, 230), Vector2(655, 212), Vector2(690, 225),
			Vector2(560, 285), Vector2(600, 290), Vector2(640, 288), Vector2(680, 292), Vector2(430, 238), Vector2(465, 170), Vector2(760, 245), Vector2(780, 165)]
		for i in joyas.size():
			var f := fmod(t * 0.7 + i * 0.37, 2.2)
			if f < 0.35:
				var a := sin(f / 0.35 * PI)
				Ui.estrella(self, joyas[i], 1.0 + a, Color(1.0, 0.92, 0.8, a))
		# Niebla gris que se arrastra por el piso (la que robó el brillo).
		for n in niebla:
			var a2 := 0.10 + 0.05 * sin(t * 0.8 + n.f)
			var w: float = n.s
			draw_texture_rect(luz, Rect2(Vector2(n.x, n.y + sin(t * 0.6 + n.f) * 6.0), Vector2(w, w * 0.32)), false, Color(0.75, 0.75, 0.85, a2))


# Reflejo que cruza el logo cada pocos segundos.
class BrilloLogo extends Control:
	var logo: Control
	var t := 0.0
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var f := fmod(t, 4.5)
		if f > 1.0 or not is_instance_valid(logo):
			return
		var r := Rect2(logo.position + Vector2(24, 20), logo.size - Vector2(48, 50))
		var x := r.position.x + (r.size.x + 60.0) * f - 30.0
		for i in 3:
			var xx := x + i * 7.0
			if xx < r.position.x or xx > r.end.x:
				continue
			draw_line(Vector2(xx, r.position.y), Vector2(xx - 26, r.end.y), Color(1, 0.95, 0.85, 0.22 - i * 0.06), 5.0 - i)
