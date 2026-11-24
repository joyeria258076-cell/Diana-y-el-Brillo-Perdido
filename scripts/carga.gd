# Pantalla de carga: fondo oscuro, nombre del lugar, barra de madera y un consejo.
# Carga la escena en otro hilo y dura al menos MINIMO segundos para alcanzar a leerse.
extends CanvasLayer

const MINIMO := 1.5
const CONSEJOS := [
	"Los enemigos no mueren: se pulen.",
	"Usa las cajas para cubrirte de los proyectiles.",
	"Usa la Lupa en los rincones: hay 5 gemas ocultas en cada nivel.",
	"Abre los cofres: ahí encuentras armas nuevas.",
	"En el Apartado recuperas todo tu brillo.",
	"Quilate vio el robo: síguelo, él conoce el camino.",
	"Mantén el disparo para lanzar una fila de destellos.",
	"Con Shift haces un impulso: mientras dura, nada te hace daño.",
	"Guarda las pociones de brillo y tómalas con Q cuando las necesites.",
	"Si no sabes a dónde ir, sigue las flechitas doradas.",
]

var ruta := ""
var lugar := ""
var t := 0.0
var listo := false
var raiz: Control
var barra: Barra
var diana: AnimatedSprite2D

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	raiz.add_child(Ui.velo(1.0))
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, 0.2)
	if lugar == "":
		return  # al menú: solo el fundido
	# Ilustración del nivel (una al azar de assets/ui/carga_<nivel>_*.png) en marco de joyería, a la izquierda.
	var n := clampi(Juego.nivel_actual + 1, 1, 3)
	var opciones: Array = []
	for f in DirAccess.get_files_at("res://assets/ui"):
		f = f.trim_suffix(".import")
		if f.begins_with("carga_%d_" % n) and f.ends_with(".png") and not f in opciones:
			opciones.append(f)
	var marco := PanelContainer.new()
	var st := Ui.marco("panel", 22, 22)
	st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	st.set_content_margin_all(12)
	marco.add_theme_stylebox_override("panel", st)
	marco.position = Vector2(60, 40)
	marco.size = Vector2(300, 460)
	raiz.add_child(marco)
	if not opciones.is_empty():
		var img := TextureRect.new()
		img.texture = load("res://assets/ui/" + opciones.pick_random())
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.custom_minimum_size = Vector2(276, 436)
		marco.add_child(img)
		img.modulate.a = 0.0
		create_tween().tween_property(img, "modulate:a", 1.0, 0.5)
	raiz.add_child(Ui.Lluvia.new())
	# A la derecha: nombre del nivel, barra con Diana caminando encima y el consejo.
	var titulo := Ui.titulo(lugar, 26)
	titulo.position = Vector2(400, 130)
	titulo.size = Vector2(520, 50)
	raiz.add_child(titulo)
	barra = Barra.new()
	barra.position = Vector2(430, 290)
	barra.size = Vector2(460, 22)
	raiz.add_child(barra)
	diana = Anim.sprite({"caminar": ["diana_walk", 10, true]}, "caminar")
	diana.scale = Vector2(0.4, 0.4)
	# Pies de Diana justo sobre el marco de la barra.
	var cuadro: Texture2D = diana.sprite_frames.get_frame_texture("caminar", 0)
	diana.centered = true
	diana.position = Vector2(430, 290 - cuadro.get_height() * 0.4 / 2.0 + 44.0)
	raiz.add_child(diana)
	var pc := Ui.panel()
	pc.position = Vector2(430, 350)
	pc.custom_minimum_size = Vector2(460, 0)
	raiz.add_child(pc)
	var consejo := Ui.texto("Consejo: " + CONSEJOS.pick_random(), 15, Ui.ROSA_PALIDO)
	consejo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	consejo.autowrap_mode = TextServer.AUTOWRAP_WORD
	consejo.custom_minimum_size = Vector2(400, 0)
	pc.add_child(consejo)

func _process(delta: float) -> void:
	if listo:
		return
	t += delta
	var minimo := MINIMO if lugar != "" else 0.25
	# La barra avanza con el tiempo mínimo; la escena se carga en el hilo principal al final
	# (cargar en otro hilo dejaba sin cargar las imágenes que los scripts precargan).
	var avance := minf(t / minimo, 1.0)
	if barra:
		barra.value = avance
		diana.position.x = 444.0 + 432.0 * avance
	if t >= minimo:
		listo = true
		_entrar()

func _entrar() -> void:
	await get_tree().process_frame
	var escena: PackedScene = load(ruta)
	if escena == null:
		push_error("No se pudo cargar " + ruta)
		queue_free()
		return
	get_tree().change_scene_to_packed(escena)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw := create_tween()
	tw.tween_property(raiz, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


# Barra de carga: canal oscuro, relleno de cristal recortado dentro del marco, brillo que corre
# y el marco encima (sin centro) para que el relleno nunca se salga.
class Barra extends Control:
	const RELLENO := preload("res://assets/ui/barra_relleno.png")
	var value := 0.0
	var marco: StyleBoxTexture
	var t := 0.0

	func _ready() -> void:
		marco = Ui.marco("barra_marco", 12, 6)
		marco.draw_center = false
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var dentro := Rect2(Vector2(12, 6), size - Vector2(24, 12))
		draw_rect(Rect2(Vector2(4, 3), size - Vector2(8, 6)), Color(0.08, 0.03, 0.08))
		var w := roundf(dentro.size.x * clampf(value, 0.0, 1.0))
		if w > 0.0:
			var r := Rect2(dentro.position, Vector2(w, dentro.size.y))
			# Cristal rosa en franjas pixel: brillo arriba, tono medio y sombra abajo.
			var h := r.size.y
			draw_rect(r, Color(0.86, 0.36, 0.55))
			draw_rect(Rect2(r.position, Vector2(w, roundf(h * 0.35))), Color(1.0, 0.72, 0.78))
			draw_rect(Rect2(r.position, Vector2(w, 1)), Color(1, 0.95, 0.9))
			draw_rect(Rect2(r.position + Vector2(0, h - 2), Vector2(w, 2)), Color(0.55, 0.16, 0.35))
			var bx := dentro.position.x + fmod(t * 180.0, maxf(w, 1.0))
			draw_rect(Rect2(bx, dentro.position.y + 2, 6, 3), Color(1, 1, 1, 0.5))
			draw_rect(Rect2(r.end.x - 2, r.position.y, 2, r.size.y), Color(1, 0.95, 0.85, 0.9))
		draw_style_box(marco, Rect2(Vector2.ZERO, size))
