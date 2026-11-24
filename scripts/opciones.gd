# Panel de opciones: volumen (general, música y efectos) y pantalla completa. Se abre
# desde el menú principal y desde la pausa; avisa con "cerrado" al regresar.
extends Control

signal cerrado

var completa: CheckButton
var regresar: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # en los menús siempre se ve la flecha del mouse
	add_child(Ui.velo(0.6))
	var p := Ui.panel()
	p.position = Vector2(255, 12)
	p.custom_minimum_size = Vector2(450, 0)
	add_child(p)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 5)
	p.add_child(caja)
	caja.add_child(Ui.titulo("Opciones"))

	var deslizadores := []
	for par in [["Volumen general", "volumen", Juego.volumen], ["Música", "musica", Juego.volumen_musica],
			["Efectos", "efectos", Juego.volumen_efectos]]:
		deslizadores.append(_deslizador(caja, par[0], par[1], par[2]))

	# Pantalla completa
	completa = CheckButton.new()
	completa.text = "Pantalla completa (F11):  " + ("SÍ" if Juego.pantalla_completa else "NO")
	completa.button_pressed = Juego.pantalla_completa
	completa.add_theme_font_size_override("font_size", 16)
	completa.add_theme_color_override("font_color", Ui.ROSA_PALIDO)
	completa.add_theme_color_override("font_focus_color", Ui.CHAMPAN)
	completa.add_theme_color_override("font_hover_color", Ui.CHAMPAN)
	completa.add_theme_color_override("font_pressed_color", Ui.ROSA_PALIDO)
	completa.add_theme_color_override("font_hover_pressed_color", Ui.CHAMPAN)
	completa.add_theme_color_override("font_outline_color", Ui.NEGRO)
	completa.add_theme_constant_override("outline_size", 4)
	completa.add_theme_stylebox_override("focus", _marco_foco())
	completa.toggled.connect(func(si: bool):
		Juego.sonido("click", false)
		completa.text = "Pantalla completa (F11):  " + ("SÍ" if si else "NO")
		Juego.set_pantalla_completa(si))
	completa.mouse_entered.connect(completa.grab_focus)
	caja.add_child(completa)

	# Mirilla: flechas a los lados y la mira elegida en grande al centro.
	var Mir = preload("res://scripts/mirilla.gd")
	caja.add_child(Ui.texto("Mirilla", 15, Ui.ORO_ROSA))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	var izq := Ui.boton("<", 64)
	var vista := VistaMira.new()
	vista.custom_minimum_size = Vector2(150, 64)
	var der := Ui.boton(">", 64)
	fila.add_child(izq)
	fila.add_child(vista)
	fila.add_child(der)
	var mover := func(paso: int):
		Juego.mirilla = (Juego.mirilla + paso + Mir.TOTAL) % Mir.TOTAL
		Juego.guardar_opciones()
		vista.queue_redraw()
	izq.pressed.connect(mover.bind(-1))
	der.pressed.connect(mover.bind(1))
	# Botón que abre el catálogo con las 20 miras.
	var mir := Ui.boton("Ver catálogo de miras", 260)
	mir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mir.pressed.connect(func():
		var cat := Catalogo.new()
		cat.cerrado.connect(func():
			vista.queue_redraw()
			mir.grab_focus())
		add_child(cat))
	caja.add_child(mir)
	# Con el foco en cualquiera de las dos flechas, izquierda/derecha también cambian la mira.
	for b in [izq, der]:
		b.gui_input.connect(func(e: InputEvent):
			if e.is_action_pressed("ui_left"):
				mover.call(-1)
				Juego.sonido("mover", false, -4.0)
				b.accept_event()
			elif e.is_action_pressed("ui_right"):
				mover.call(1)
				Juego.sonido("mover", false, -4.0)
				b.accept_event())

	regresar = Ui.boton("Regresar")
	regresar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	regresar.pressed.connect(cerrar)
	caja.add_child(regresar)
	Ui.enlazar(deslizadores + [completa, mir, regresar])
	deslizadores[0].grab_focus()

# Renglón con nombre, barra de volumen y porcentaje. cual: "volumen", "musica" o "efectos".
func _deslizador(caja: VBoxContainer, nombre: String, cual: String, valor: float) -> HSlider:
	caja.add_child(Ui.texto(nombre, 15, Ui.ORO_ROSA))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	caja.add_child(fila)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.value = roundf(valor * 100.0)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 26)
	_estilo_deslizador(s)
	fila.add_child(s)
	var porcentaje := Ui.texto("%d%%" % int(s.value), 16, Ui.CHAMPAN)
	porcentaje.custom_minimum_size = Vector2(50, 0)
	fila.add_child(porcentaje)
	s.value_changed.connect(func(v: float):
		porcentaje.text = "%d%%" % int(v)
		Juego.set_volumen(v / 100.0, cual)
		# Al mover el volumen de efectos se escucha cómo queda.
		if cual != "musica":
			Juego.sonido("mover", false))
	s.mouse_entered.connect(s.grab_focus)
	return s

func _estilo_deslizador(s: HSlider) -> void:
	var riel := Ui.estilo_joya(Ui.NEGRO, Ui.ORO_ROSA.darkened(0.3), 2)
	riel.set_content_margin_all(4)
	var lleno := Ui.estilo_joya(Ui.ORO_ROSA, Ui.CHAMPAN, 2)
	lleno.set_content_margin_all(4)
	s.add_theme_stylebox_override("slider", riel)
	s.add_theme_stylebox_override("grabber_area", lleno)
	s.add_theme_stylebox_override("grabber_area_highlight", lleno)
	s.add_theme_stylebox_override("focus", _marco_foco())

func _marco_foco() -> StyleBoxFlat:
	var foco := StyleBoxFlat.new()
	foco.draw_center = false
	foco.border_color = Ui.CHAMPAN
	foco.set_border_width_all(2)
	return foco

func cerrar() -> void:
	cerrado.emit()
	queue_free()

# Esc también regresa.
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		cerrar()


# Muestra la mira elegida en grande, con su número.
class VistaMira extends Control:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var tex: Texture2D = Fx.cuadro("miras", Juego.mirilla % 20)
		var c := Vector2(size.x / 2.0, 26.0)
		var late := 1.0 + 0.06 * sin(t * 4.0)
		var tam := tex.get_size() * 1.3 * late
		draw_circle(c, 24.0, Color(Ui.ORO_ROSA, 0.12))
		draw_texture_rect(tex, Rect2((c - tam / 2.0).round(), tam), false)
		var f := ThemeDB.fallback_font
		var txt := "Estilo %d / 20" % (Juego.mirilla % 20 + 1)
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string_outline(f, Vector2(c.x - w / 2.0, 62), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Ui.NEGRO)
		draw_string(f, Vector2(c.x - w / 2.0, 62), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Ui.CHAMPAN)


# Catálogo: las 20 miras en cuadrícula (4 filas de 5). Clic o Enter elige; Esc regresa.
class Catalogo extends Control:
	signal cerrado
	var casillas: Array = []
	var t := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(Ui.velo(0.7))
		var p := Ui.panel()
		p.position = Vector2(170, 30)
		p.custom_minimum_size = Vector2(620, 0)
		add_child(p)
		var caja := VBoxContainer.new()
		caja.add_theme_constant_override("separation", 10)
		p.add_child(caja)
		caja.add_child(Ui.titulo("Elige tu mira", 26))
		var rejilla := GridContainer.new()
		rejilla.columns = 5
		rejilla.add_theme_constant_override("h_separation", 12)
		rejilla.add_theme_constant_override("v_separation", 12)
		rejilla.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		caja.add_child(rejilla)
		for i in 20:
			var b := Button.new()
			b.custom_minimum_size = Vector2(84, 74)
			var normal := Ui.estilo_joya(Color(Ui.NEGRO, 0.7), Ui.ORO_ROSA.darkened(0.45), 2)
			var elegido := Ui.estilo_joya(Color(Ui.CIRUELA, 0.95), Ui.CHAMPAN, 3)
			elegido.shadow_color = Color(Ui.CHAMPAN, 0.45)
			elegido.shadow_size = 8
			b.add_theme_stylebox_override("normal", normal)
			b.add_theme_stylebox_override("hover", elegido)
			b.add_theme_stylebox_override("focus", elegido)
			b.add_theme_stylebox_override("pressed", elegido)
			b.mouse_entered.connect(b.grab_focus)
			b.focus_entered.connect(func(): Juego.sonido("mover", false, -6.0))
			b.pressed.connect(_elegir.bind(i))
			var d := Casilla.new()
			d.i = i
			d.boton = b
			d.set_anchors_preset(Control.PRESET_FULL_RECT)
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(d)
			rejilla.add_child(b)
			casillas.append(b)
		var ayuda := Ui.texto("Flechas o mouse: ver     Enter / clic: elegir     Esc: regresar", 13, Ui.ROSA_PALIDO)
		ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ayuda.modulate.a = 0.8
		caja.add_child(ayuda)
		casillas[Juego.mirilla % 20].grab_focus()

	func _elegir(i: int) -> void:
		Juego.sonido("click", false)
		Juego.mirilla = i
		Juego.guardar_opciones()
		for b in casillas:
			b.queue_redraw()
		_cerrar()

	func _cerrar() -> void:
		cerrado.emit()
		queue_free()

	func _unhandled_input(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cerrar()


# Una casilla del catálogo: la mira (más grande y brillando si tiene el foco) y una gema si es la actual.
class Casilla extends Control:
	var i := 0
	var boton: Button
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var tex: Texture2D = Fx.cuadro("miras", i)
		var foco := boton.has_focus()
		var esc := 1.25 + (0.12 * sin(t * 5.0) if foco else 0.0)
		var tam := tex.get_size() * esc
		var c := size / 2.0
		draw_texture_rect(tex, Rect2((c - tam / 2.0).round(), tam), false, Color.WHITE if foco else Color(0.8, 0.75, 0.75))
		if i == Juego.mirilla % 20:
			Ui.estrella(self, Vector2(size.x - 10, 10), 2.0, Ui.CHAMPAN)
