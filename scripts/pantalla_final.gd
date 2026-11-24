# Pantalla de derrota o de victoria: título, un texto y dos botones de madera.
# Pausa el juego mientras está abierta.
extends CanvasLayer

var titulo := ""
var detalle := ""
var color_titulo := Ui.DORADO
# [["Texto", Callable], ...]
var opciones: Array = []
var joyas: Array = []      # índices 1..3 de las joyas que se muestran girando arriba
var fondo_fin := false     # pantalla final: escena del amanecer de fondo y créditos que suben
var raiz: Control

func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	Juego.ocupado = true
	get_tree().paused = true
	raiz = Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	if fondo_fin:
		var f := TextureRect.new()
		f.texture = preload("res://assets/ui/epilogo.png")
		f.set_anchors_preset(Control.PRESET_FULL_RECT)
		f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		f.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		raiz.add_child(f)
		raiz.add_child(Ui.velo(0.45))
		raiz.add_child(Ui.Lluvia.new())
		var cr := Creditos.new()
		raiz.add_child(cr)
	else:
		raiz.add_child(Ui.velo(0.7))
	var p := Ui.panel()
	p.custom_minimum_size = Vector2(460, 0)
	p.position = Vector2(60 if fondo_fin else 250, 90 if not joyas.is_empty() else 140)
	raiz.add_child(p)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	p.add_child(caja)
	if not joyas.is_empty():
		var vj := Joyas.new()
		vj.cuales = joyas
		vj.custom_minimum_size = Vector2(0, 84)
		caja.add_child(vj)
	var t := Ui.texto(titulo, 28, color_titulo)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD
	caja.add_child(t)
	if detalle != "":
		var d := Ui.texto(detalle, 17, Ui.CREMA)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		caja.add_child(d)
	var botones := []
	for par in opciones:
		var b := Ui.boton(par[0], 240)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(par[1])
		caja.add_child(b)
		botones.append(b)
	Ui.enlazar(botones)
	botones[0].grab_focus()
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, 0.35)

# Cierra la pantalla y deja seguir jugando (lo usa "Continuar" mientras no exista el nivel 2).
func cerrar() -> void:
	get_tree().paused = false
	Juego.ocupado = false
	queue_free()


# Joyas recuperadas: giran (se estrechan y ensanchan), flotan y sueltan destellos.
class Joyas extends Control:
	const TEX := [preload("res://assets/ui/joya_1.png"), preload("res://assets/ui/joya_2.png"), preload("res://assets/ui/joya_3.png")]
	var cuales: Array = []
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var n := cuales.size()
		for i in n:
			var tex: Texture2D = TEX[cuales[i] - 1]
			var c := Vector2(size.x / 2.0 + (i - (n - 1) / 2.0) * 90.0, 42.0 + sin(t * 2.0 + i) * 4.0)
			var giro := absf(cos(t * 1.6 + i * 0.8))
			var tam := tex.get_size() * Vector2(maxf(giro, 0.15), 1.0)
			draw_circle(c, 34.0, Color(1.0, 0.85, 0.5, 0.12 + 0.06 * sin(t * 3.0)))
			draw_texture_rect(tex, Rect2((c - tam / 2.0).round(), tam.round()), false)
			var f := fmod(t * 1.3 + i * 0.6, 1.8)
			if f < 0.4:
				Ui.estrella(self, c + Vector2(22, -22), 1.5 + sin(f / 0.4 * PI) * 1.5, Color(1, 0.95, 0.8, sin(f / 0.4 * PI)))


# Créditos que suben a la derecha en la pantalla final.
class Creditos extends Control:
	var y := 560.0
	const LINEAS := [["Diana y el Brillo Perdido", 22], ["", 10], ["Desarrollo y arte", 14], ["Hernández Bautista Marcos Uriel", 16],
		["Hernández Martínez Diana Laura", 16], ["", 10], ["Optativa 1: Creación de Videojuegos", 14], ["MTI. Juvencio Mendoza Castelán", 16],
		["", 10], ["Universidad Tecnológica de la Huasteca Hidalguense", 13], ["Joyería Diana Laura", 14], ["", 10], ["Gracias por jugar", 20]]
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		y -= delta * 28.0
		if y < -420.0:
			y = 560.0
		queue_redraw()
	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var yy := y
		for l in LINEAS:
			var txt: String = l[0]
			var tam: int = l[1]
			if txt != "":
				var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
				var x := 735.0 - w / 2.0
				var col := Ui.CHAMPAN if tam >= 16 else Ui.ORO_ROSA
				draw_string_outline(f, Vector2(x, yy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 5, Ui.NEGRO)
				draw_string(f, Vector2(x, yy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
			yy += tam + 12.0
