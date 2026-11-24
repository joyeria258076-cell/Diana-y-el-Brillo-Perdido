# Piezas de interfaz con los colores de la joyería (los mismos del menú principal):
# botones, paneles, textos y adornos. El HUD del juego sigue siendo de madera.
class_name Ui

const HUD := preload("res://scripts/hud.gd")
const DORADO := Color(1.0, 0.85, 0.4)
const CREMA := Color(0.95, 0.85, 0.7)
# Colores de la marca (libreto: negro, oro rosa, champán y rosa pálido).
const NEGRO := Color(0.09, 0.05, 0.1)
const ORO_ROSA := Color(0.86, 0.56, 0.52)
const CHAMPAN := Color(1.0, 0.89, 0.68)
const ROSA_PALIDO := Color(1.0, 0.8, 0.84)
const CIRUELA := Color(0.24, 0.1, 0.22)

# Estilo de madera: borde oscuro, madera y fondo más oscuro adentro.
static func estilo_madera(color := HUD.MADERA, borde := 3) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = color
	st.border_color = HUD.BORDE
	st.set_border_width_all(borde)
	st.set_content_margin_all(10)
	return st

# Estilo de joyería: fondo ciruela oscuro con borde de oro rosa.
static func estilo_joya(fondo := Color(NEGRO, 0.82), borde := ORO_ROSA.darkened(0.15), ancho := 2) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(ancho)
	st.set_content_margin_all(10)
	return st

# Panel grande (opciones, créditos, diálogo, pausa, pantallas finales).
static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	var st := marco("panel", 22, 22)
	st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	st.set_content_margin_all(26)
	p.add_theme_stylebox_override("panel", st)
	return p

# Botón de joyería; el elegido (mouse o flechas) se ilumina en oro rosa con letra oscura.
static func boton(texto: String, ancho := 220.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(ancho, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", ROSA_PALIDO)
	b.add_theme_color_override("font_focus_color", CHAMPAN)
	b.add_theme_color_override("font_hover_color", CHAMPAN)
	b.add_theme_color_override("font_pressed_color", CHAMPAN)
	b.add_theme_color_override("font_outline_color", NEGRO)
	b.add_theme_constant_override("outline_size", 3)
	var elegido := estilo_joya(ORO_ROSA, CHAMPAN, 3)
	elegido.shadow_color = Color(ORO_ROSA, 0.45)
	elegido.shadow_size = 8
	var presionado := elegido.duplicate()
	presionado.bg_color = CHAMPAN
	# Marco de joyería en pixel art (oro rosa con gemas); el elegido brilla.
	var m_normal := marco("boton_normal", 30, 14)
	var m_elegido := marco("boton_elegido", 30, 14)
	var m_presionado := m_elegido.duplicate()
	m_presionado.modulate_color = Color(1.15, 1.1, 1.05)
	b.custom_minimum_size.y = 48
	b.add_theme_stylebox_override("normal", m_normal)
	b.add_theme_stylebox_override("hover", m_elegido)
	b.add_theme_stylebox_override("focus", m_elegido)
	b.add_theme_stylebox_override("pressed", m_presionado)
	# Con el foco la letra queda oscura sobre el oro rosa.
	b.focus_entered.connect(func():
		b.add_theme_color_override("font_color", CHAMPAN)
		Juego.sonido("mover", false, -4.0))
	b.focus_exited.connect(func(): b.add_theme_color_override("font_color", ROSA_PALIDO))
	b.pressed.connect(func(): Juego.sonido("click", false))
	# Al pasar el mouse toma el foco, así mouse y teclado no se pelean.
	b.mouse_entered.connect(b.grab_focus)
	return b

# Marco de pixel art que se estira por el centro (las esquinas con gemas no se deforman).
static func marco(nombre: String, lado: int, arriba: int) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = load("res://assets/ui/%s.png" % nombre)
	st.texture_margin_left = lado
	st.texture_margin_right = lado
	st.texture_margin_top = arriba
	st.texture_margin_bottom = arriba
	st.content_margin_left = lado
	st.content_margin_right = lado
	st.content_margin_top = 6
	st.content_margin_bottom = 8
	st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return st

# Texto con contorno oscuro.
static func texto(t: String, tam := 16, color := CREMA) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", NEGRO)
	l.add_theme_constant_override("outline_size", 6 if tam >= 20 else 4)
	return l

# Título centrado en champán con un adorno debajo (dos líneas y un destello).
static func titulo(t: String, tam := 30) -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 2)
	var l := texto(t, tam, CHAMPAN)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", CIRUELA.darkened(0.4))
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_shadow_color", ORO_ROSA.darkened(0.2))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	caja.add_child(l)
	var a := Adorno.new()
	a.custom_minimum_size = Vector2(0, 12)
	caja.add_child(a)
	return caja

# Velo oscuro de pantalla completa.
static func velo(alfa := 0.6) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(NEGRO, alfa)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

# Cuadro 0 de una tira de assets/chars, para retratos y decoración.
static func retrato(clave: String) -> AtlasTexture:
	Anim.load_data()
	var info: Dictionary = Anim.data.chars[clave]
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/chars/%s.png" % clave)
	at.region = Rect2(0, 0, info.w, info.h)
	return at

# Pone los botones en cadena (el último lleva al primero) para moverse con flechas.
# Llamar cuando ya estén en el árbol.
static func enlazar(botones: Array) -> void:
	for i in botones.size():
		var b: Control = botones[i]
		b.focus_neighbor_top = b.get_path_to(botones[(i - 1 + botones.size()) % botones.size()])
		b.focus_neighbor_bottom = b.get_path_to(botones[(i + 1) % botones.size()])

# Destello de cuatro puntas hecho con cuadritos (pixel art).
static func estrella(lienzo: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	lienzo.draw_rect(Rect2(p.x - s * 0.5, p.y - s * 2.5, s, s * 5), col)
	lienzo.draw_rect(Rect2(p.x - s * 2.5, p.y - s * 0.5, s * 5, s), col)
	lienzo.draw_rect(Rect2(p.x - s, p.y - s, s * 2, s * 2), Color(1, 1, 1, col.a))


# Dos líneas de oro rosa con un destello al centro, bajo los títulos.
class Adorno extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var largo := minf(90.0, c.x - 24.0)
		draw_rect(Rect2(c.x - 20 - largo, c.y - 1, largo, 2), ORO_ROSA)
		draw_rect(Rect2(c.x + 20, c.y - 1, largo, 2), ORO_ROSA)
		Ui.estrella(self, c, 2.0, CHAMPAN)


# Destellos que suben flotando por toda la pantalla.
class Lluvia extends Control:
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

	func _draw() -> void:
		for d in puntos:
			Ui.estrella(self, d.p, d.s, Color(CHAMPAN, 0.35 + 0.65 * absf(sin(t * 2.0 + d.f))))
