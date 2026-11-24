# Elegir dificultad antes de jugar: 4 tarjetas con estrellas (1 fácil ... 4 demoníaco).
# Flechas o mouse para elegir, Enter para empezar y Esc para regresar.
extends Control

signal cerrado

const COLORES := {1: Color(0.55, 0.9, 0.7), 2: Color(1.0, 0.89, 0.68), 3: Color(0.95, 0.55, 0.45), 4: Color(0.95, 0.2, 0.3)}

var tarjetas: Array = []
var t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Ui.velo(0.72))   # el fondo de la tienda se ve oscurecido
	var titulo := Ui.titulo("Elige la dificultad", 30)
	titulo.position = Vector2(0, 26)
	titulo.size = Vector2(960, 50)
	add_child(titulo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	fila.position = Vector2(40, 104)
	add_child(fila)
	for n in [1, 2, 3, 4]:
		var b := _tarjeta(n)
		fila.add_child(b)
		tarjetas.append(b)
	for i in tarjetas.size():
		var b: Button = tarjetas[i]
		b.focus_neighbor_left = b.get_path_to(tarjetas[(i + 3) % 4])
		b.focus_neighbor_right = b.get_path_to(tarjetas[(i + 1) % 4])
		b.focus_neighbor_top = b.get_path()
		b.focus_neighbor_bottom = b.get_path()
	var ayuda := Ui.texto("Flechas: elegir     Enter: jugar     Esc: regresar", 13, Ui.ROSA_PALIDO)
	ayuda.modulate.a = 0.75
	ayuda.position = Vector2(0, 470)
	ayuda.size = Vector2(960, 20)
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(ayuda)
	tarjetas[clampi(Juego.dificultad, 1, 4) - 1].grab_focus()

func _tarjeta(n: int) -> Button:
	var d: Dictionary = Juego.DIFICULTADES[n]
	var col: Color = COLORES[n]
	var b := Button.new()
	b.custom_minimum_size = Vector2(206, 330)
	b.focus_mode = Control.FOCUS_ALL
	# Marco de joyería; la elegida se ilumina con el color de su dificultad.
	var normal := Ui.marco("panel", 22, 22)
	normal.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	normal.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	normal.modulate_color = Color(0.7, 0.62, 0.68)
	var elegido := normal.duplicate()
	elegido.modulate_color = Color(1.15, 1.08, 1.05)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", elegido)
	b.add_theme_stylebox_override("focus", elegido)
	b.add_theme_stylebox_override("pressed", elegido)
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(func(): Juego.sonido("mover", false, -4.0))
	b.pressed.connect(func(): _jugar(n))
	var dibujo := Dibujo.new()
	dibujo.n = n
	dibujo.col = col
	dibujo.boton = b
	dibujo.set_anchors_preset(Control.PRESET_FULL_RECT)
	dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(dibujo)
	# Nombre y texto dentro de un margen para que el texto se acomode en renglones.
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	margen.add_theme_constant_override("margin_top", 126)
	margen.add_theme_constant_override("margin_bottom", 22)
	b.add_child(margen)
	var col_v := VBoxContainer.new()
	col_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_v.add_theme_constant_override("separation", 12)
	margen.add_child(col_v)
	var nombre := Ui.texto(d.nombre, 22, col)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_v.add_child(nombre)
	var txt := Ui.texto(d.texto, 13, Ui.CREMA)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.custom_minimum_size = Vector2(160, 0)
	col_v.add_child(txt)
	return b

func _jugar(n: int) -> void:
	Juego.sonido("click", false)
	Juego.dificultad = n
	Juego.guardar_opciones()
	Juego.jugar()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrado.emit()
		queue_free()


# Estrellas de la tarjeta (pixel art): las de la dificultad brillan y laten cuando está elegida.
class Dibujo extends Control:
	const EMBLEMAS := [preload("res://assets/ui/emblema_1.png"), preload("res://assets/ui/emblema_2.png"),
		preload("res://assets/ui/emblema_3.png"), preload("res://assets/ui/emblema_4.png")]
	var n := 1
	var col := Color.WHITE
	var boton: Button
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var activo := boton.has_focus()
		if activo:
			var k := 0.5 + 0.5 * sin(t * 4.0)
			draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color(col, 0.08 + 0.06 * k))
			draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(col, 0.55 + 0.35 * k), false, 2.0)
		# Emblema de la dificultad: late y brilla cuando la tarjeta está elegida.
		var em: Texture2D = EMBLEMAS[n - 1]
		var esc := 1.0 + (0.06 * sin(t * 5.0) if activo else 0.0)
		var tam := em.get_size() * esc
		var ce := Vector2(size.x / 2.0, 52.0)
		if activo:
			draw_circle(ce, 40.0, Color(col, 0.12 + 0.06 * sin(t * 4.0)))
		draw_texture_rect(em, Rect2((ce - tam / 2.0).round(), tam.round()), false, Color.WHITE if activo else Color(0.7, 0.65, 0.7))
		# Estrellas de la dificultad debajo del emblema.
		var x0 := size.x / 2.0 - 1.5 * 26.0
		for i in 4:
			var c := Vector2(x0 + i * 26.0, 104.0)
			if i < n:
				Ui.estrella(self, c, 3.0 * (1.0 + (0.15 * sin(t * 6.0 + i) if activo else 0.0)), col if activo else col.darkened(0.3))
			else:
				Ui.estrella(self, c, 2.0, Color(1, 1, 1, 0.12))
