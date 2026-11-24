# Caja de diálogo abajo: retrato, nombre y texto que aparece letra por letra.
# Clic, Espacio o Enter: completa el texto o pasa a la siguiente línea.
# Pausa el juego mientras dura. Los textos están en assets/dialogos.json.
extends CanvasLayer

signal terminado

const LETRAS_POR_SEGUNDO := 40.0

static var datos: Dictionary = {}

var lineas: Array = []
var i := 0
var visibles := 0.0
var retrato: TextureRect
var nombre: Label
var texto: Label
var flecha: Polygon2D
var t := 0.0

static func cargar() -> Dictionary:
	if datos.is_empty():
		datos = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dialogos.json"))
	return datos

static func lineas_de(clave: String) -> Array:
	return cargar().get(clave, [])

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	var p := Ui.panel()
	p.position = Vector2(40, 388)
	p.size = Vector2(880, 136)
	raiz.add_child(p)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	p.add_child(fila)
	# Marco de oro rosa para el retrato.
	var marco := PanelContainer.new()
	# Marco de joyería con gemas en las esquinas y un brillo suave detrás del personaje.
	var st := Ui.marco("panel", 16, 16)
	st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	st.set_content_margin_all(8)
	marco.add_theme_stylebox_override("panel", st)
	var luz := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(Ui.ORO_ROSA, 0.45))
	g.set_color(1, Color(Ui.ORO_ROSA, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.6)
	gt.fill_to = Vector2(1.0, 0.6)
	luz.texture = gt
	luz.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(luz)
	marco.custom_minimum_size = Vector2(96, 96)
	fila.add_child(marco)
	retrato = TextureRect.new()
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	retrato.custom_minimum_size = Vector2(88, 88)
	marco.add_child(retrato)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	fila.add_child(col)
	nombre = Ui.texto("", 18, Ui.ORO_ROSA)
	col.add_child(nombre)
	texto = Ui.texto("", 17, Ui.CHAMPAN)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	texto.custom_minimum_size = Vector2(700, 60)
	col.add_child(texto)
	# Flechita que parpadea cuando la línea ya terminó de aparecer.
	flecha = Polygon2D.new()
	flecha.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(7, 0), Vector2(0, 8)])
	flecha.color = Ui.CHAMPAN
	flecha.position = Vector2(894, 500)
	raiz.add_child(flecha)

# Empieza a mostrar las líneas; al terminar emite "terminado" y se borra solo.
func mostrar(nuevas: Array) -> void:
	lineas = nuevas
	i = 0
	Juego.ocupado = true
	get_tree().paused = true
	_poner_linea()

func _poner_linea() -> void:
	var l: Dictionary = lineas[i]
	var quien: String = l.get("quien", "")
	nombre.text = quien
	texto.text = l.get("texto", "")
	visibles = 0.0
	texto.visible_characters = 0
	var clave: String = cargar().get("personajes", {}).get(quien, "")
	retrato.texture = Ui.retrato(clave) if clave != "" else null
	# Retrato con expresión: "cara" en la línea (0 normal, 1 feliz/radio/emocionado, 2 preocupado, 3 decidido/alerta).
	var corto: String = {"Diana": "diana", "Don Aurelio": "aurelio", "Quilate": "quilate"}.get(quien, "")
	if corto != "":
		_cargar_retratos()
		var cara := int(l.get("cara", 1 if (quien == "Don Aurelio" and texto.text.begins_with("(por radio)")) else 0))
		retrato.texture = RETRATOS[corto][clampi(cara, 0, 3)]
	# Saltito al cambiar de quien habla.
	if quien != _ultimo:
		_ultimo = quien
		retrato.pivot_offset = retrato.size / 2.0
		retrato.scale = Vector2(0.85, 0.85)
		var tw := create_tween()
		tw.tween_property(retrato, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

var _ultimo := ""
static var RETRATOS := {}
static func _cargar_retratos() -> void:
	if not RETRATOS.is_empty():
		return
	for n in ["diana", "aurelio", "quilate"]:
		RETRATOS[n] = []
		for k in 4:
			RETRATOS[n].append(load("res://assets/ui/retrato_%s_%d.png" % [n, k]))

func _process(delta: float) -> void:
	t += delta
	var total := texto.get_total_character_count()
	if texto.visible_characters >= 0 and texto.visible_characters < total:
		visibles += LETRAS_POR_SEGUNDO * delta
		# Un "bip" cada tres letras mientras se escribe.
		if int(visibles) / 3 > texto.visible_characters / 3:
			Juego.sonido("texto", true, -6.0)
		texto.visible_characters = int(visibles)
		flecha.visible = false
	else:
		texto.visible_characters = -1
		flecha.visible = int(t * 2.5) % 2 == 0

func _input(e: InputEvent) -> void:
	var avanzar := false
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		avanzar = true
	elif e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		avanzar = true
	if not avanzar:
		return
	get_viewport().set_input_as_handled()
	if texto.visible_characters != -1:
		# Aún escribiendo: mostrar todo de una vez.
		texto.visible_characters = -1
	elif i + 1 < lineas.size():
		i += 1
		_poner_linea()
	else:
		_terminar()

func _terminar() -> void:
	set_process_input(false)
	visible = false
	# Pequeña espera para que el mismo clic no se vuelva un disparo al despausar.
	await get_tree().create_timer(0.15).timeout
	get_tree().paused = false
	Juego.ocupado = false
	terminado.emit()
	queue_free()
