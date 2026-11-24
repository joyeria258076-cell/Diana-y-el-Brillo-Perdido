# Interfaz al estilo Soul Knight: panel de madera con barras, minimapa,
# contador de destellos y botón de pausa.
extends Control

const MADERA := Color(0.45, 0.29, 0.16)
const MADERA_OSC := Color(0.25, 0.15, 0.08)
const BORDE := Color(0.12, 0.07, 0.03)
const UI_LLENO := preload("res://assets/ui/corazon_lleno.png")
const UI_MEDIO := preload("res://assets/ui/corazon_medio.png")
const UI_VACIO := preload("res://assets/ui/corazon_vacio.png")
const UI_RELLENO := preload("res://assets/ui/barra_relleno.png")
const UI_ENERGIA := preload("res://assets/ui/icono_energia.png")
const UI_DESTELLO := preload("res://assets/ui/icono_destello.png")
const UI_GEMA := preload("res://assets/ui/icono_gema.png")
const UI_ESQUIVE := preload("res://assets/ui/boton_esquive.png")

# Posición de cada cuarto en el minimapa (columna, fila), igual que Bodega mapa.jpg.
const POS_MAPA := {
	"inicio": Vector2(1, 4), "pelea1": Vector2(1, 3), "pelea2": Vector2(1, 2),
	"cofre": Vector2(0, 2), "pelea3": Vector2(2, 2), "apartado": Vector2(3, 2),
	"descanso": Vector2(2, 3), "pelea4": Vector2(1, 1), "jefe": Vector2(2, 1),
}

var main
var cuarto: Label
var msg: Label
var fuente: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuente = ThemeDB.fallback_font
	cuarto = Label.new()
	cuarto.position = Vector2(730, 150)
	cuarto.size = Vector2(225, 20)
	cuarto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cuarto.add_theme_font_size_override("font_size", 13)
	_contorno(cuarto)
	add_child(cuarto)
	msg = Label.new()
	msg.position = Vector2(80, 430)
	msg.size = Vector2(800, 80)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	_contorno(msg)
	add_child(msg)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Botón de pausa (invisible, encima del dibujo de madera).
	var b := Button.new()
	b.flat = true
	b.position = Vector2(897, 9)
	b.size = Vector2(52, 46)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(alternar_pausa)
	add_child(b)
	_crear_menu()

var menu: Control

func _crear_menu() -> void:
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.visible = false
	add_child(menu)
	menu.add_child(Ui.velo(0.65))
	# Panel de la izquierda: botones.
	var p := Ui.panel()
	p.position = Vector2(150, 80)
	p.custom_minimum_size = Vector2(300, 0)
	menu.add_child(p)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	p.add_child(caja)
	caja.add_child(Ui.titulo("Pausa"))
	botones_pausa.clear()
	for par in [["Continuar", alternar_pausa], ["Opciones", _opciones_pausa], ["Reiniciar", _reiniciar],
			["Menú principal", func(): Juego.ir_al_menu()], ["Salir", func(): get_tree().quit()]]:
		var b := Ui.boton(par[0], 240)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(par[1])
		caja.add_child(b)
		botones_pausa.append(b)
	Ui.enlazar(botones_pausa)
	# Panel de la derecha: controles.
	var pc := Ui.panel()
	pc.position = Vector2(500, 80)
	pc.custom_minimum_size = Vector2(320, 0)
	menu.add_child(pc)
	var cc := VBoxContainer.new()
	cc.add_theme_constant_override("separation", 6)
	pc.add_child(cc)
	cc.add_child(Ui.titulo("Controles", 24))
	for par in [["WASD / Flechas", "moverse"], ["Mouse", "apuntar"], ["Clic / Espacio", "usar arma"],
			["Shift / Clic der.", "esquivar"], ["Q", "cambiar de arma"], ["F", "recoger, abrir, apartar"],
			["E", "Destello de joyera"], ["Esc / P", "pausa"], ["M", "sonido"]]:
		var fila := HBoxContainer.new()
		var k := Ui.texto(par[0], 14, Ui.CHAMPAN)
		k.custom_minimum_size = Vector2(130, 0)
		fila.add_child(k)
		fila.add_child(Ui.texto(par[1], 14, Ui.ROSA_PALIDO))
		cc.add_child(fila)

var botones_pausa: Array = []

func _opciones_pausa() -> void:
	var o = preload("res://scripts/opciones.gd").new()
	o.cerrado.connect(func(): botones_pausa[1].grab_focus())
	menu.add_child(o)

func alternar_pausa() -> void:
	if (Juego.ocupado or main.fin) and not get_tree().paused:
		return
	get_tree().paused = not get_tree().paused
	menu.visible = get_tree().paused
	if menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		botones_pausa[0].grab_focus()

func _reiniciar() -> void:
	Juego.reintentar()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e.physical_keycode == KEY_ESCAPE or e.physical_keycode == KEY_P):
		alternar_pausa()

func _contorno(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)

# Barra de energía suave: la visible sigue al valor real y deja una "sombra" clara que baja después.
var energia_vista := -1.0
var energia_sombra := -1.0
var sombra_espera := 0.0

func _process(d: float) -> void:
	var p = main.player
	if p != null:
		if energia_vista < 0.0:
			energia_vista = p.energia
			energia_sombra = p.energia
		energia_vista = lerpf(energia_vista, p.energia, 1.0 - exp(-18.0 * d))
		if p.energia < energia_sombra - 0.5:
			sombra_espera -= d
			if sombra_espera <= 0.0:
				energia_sombra = lerpf(energia_sombra, p.energia, 1.0 - exp(-6.0 * d))
		else:
			energia_sombra = maxf(energia_vista, p.energia)
			sombra_espera = 0.35
	queue_redraw()

func _draw() -> void:
	var p = main.player
	var t := Time.get_ticks_msec() / 1000.0
	# Panel de madera: 3 corazones (libreto) y la barra de brillo.
	draw_style_box(_marco_vida, Rect2(6, 4, 268, 88))
	_corazones(p, t)
	var color_brillo := Color(0.25, 0.55, 0.95)
	if main.sin_brillo_t > 0.0 and int(t * 12) % 2 == 0:
		color_brillo = Color(0.95, 0.3, 0.3)
	_barra(Vector2(52, 56), roundi(energia_vista), int(p.energia_max), color_brillo,
		"%d/%d" % [int(p.energia), int(p.energia_max)], energia_sombra)
	_icono("icono_energia", Vector2(33, 65), 1.0)
	# Gemas ocultas encontradas.
	draw_texture(UI_GEMA, Vector2(799, 43))
	draw_string_outline(fuente, Vector2(820, 58), "%d/5" % main.gemas_tomadas.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	draw_string(fuente, Vector2(820, 58), "%d/5" % main.gemas_tomadas.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	# Destellos (monedas) y pausa.
	draw_texture(UI_DESTELLO, Vector2(790, 20))
	draw_string_outline(fuente, Vector2(812, 36), str(main.destellos), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color.BLACK)
	draw_string(fuente, Vector2(812, 36), str(main.destellos), HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	_panel(Rect2(900, 12, 46, 40))
	draw_rect(Rect2(914, 22, 6, 20), Color(0.95, 0.85, 0.7))
	draw_rect(Rect2(926, 22, 6, 20), Color(0.95, 0.85, 0.7))
	_minimapa(Vector2(790, 70))
	_armas(p)
	_esquive(p)
	_boton_destello(p)
	_cambio(p)
	# Tinte dorado al limpiar un cuarto.
	if main.tinte_t > 0.0:
		draw_rect(Rect2(0, 0, 960, 540), Color(1.0, 0.85, 0.35, main.tinte_t * 0.35))
	_barra_jefe()
	# Borde rojo al recibir daño.
	if main.dano_t > 0.0:
		var a: float = main.dano_t / 0.5 * 0.55
		for i in 6:
			var w := 4.0 + i * 5.0
			var c := Color(0.9, 0.05, 0.1, a * (1.0 - i / 6.0) * 0.5)
			draw_rect(Rect2(0, 0, 960, w), c)
			draw_rect(Rect2(0, 540 - w, 960, w), c)
			draw_rect(Rect2(0, 0, w, 540), c)
			draw_rect(Rect2(960 - w, 0, w, 540), c)

# Dos casillas de arma abajo a la derecha; la que está en la mano, resaltada.
func _armas(p) -> void:
	for i in 2:
		var r := Rect2(780 + i * 84, 466, 74, 58)
		var activa: bool = i == p.actual
		if activa:   # brillo champán que late detrás del marco
			var k := 0.35 + 0.2 * sin(Time.get_ticks_msec() / 180.0)
			draw_rect(r.grow(9), Color(1.0, 0.89, 0.68, k * 0.35))
			draw_rect(r.grow(6), Color(1.0, 0.89, 0.68, k * 0.5))
		_panel(r)
		if i < p.armas.size():
			var id: String = p.armas[i]
			# Objeto centrado en la ranura; gris si no alcanza el brillo.
			var esc := 1.5 if activa else 1.25
			var costo: int = Armas.DATOS[id].costo
			var alcanza: bool = p.energia >= costo
			draw_set_transform((r.get_center() + Vector2(-12 * esc, -3)).round(), 0.0, Vector2.ONE * esc)
			Armas.dibujar(self, id, 1.0)
			draw_set_transform(Vector2.ZERO)
			if not alcanza:
				draw_rect(r.grow(-6), Color(0.05, 0.02, 0.06, 0.55))
			# Costo en una placa pequeña abajo al centro (sin tapar las gemas de las esquinas).
			if costo > 0:
				var txt := str(costo)
				var tw := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
				var pl := Rect2(roundf(r.get_center().x - (tw + 18) / 2.0), r.end.y - 15, tw + 18, 12)
				draw_rect(pl.grow(1), Color(0.85, 0.6, 0.5))
				draw_rect(pl, Color(0.1, 0.04, 0.1))
				var g := pl.position + Vector2(7, 6)
				draw_colored_polygon(PackedVector2Array([g + Vector2(0, -4), g + Vector2(3, 0), g + Vector2(0, 4), g + Vector2(-3, 0)]), Color(0.3, 0.6, 1.0) if alcanza else Color(0.8, 0.3, 0.35))
				draw_string(fuente, pl.position + Vector2(12, 10), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.88) if alcanza else Color(1, 0.5, 0.5))
	var nombre := Armas.nombre(p.arma()) if p.arma() != "" else "Sin objeto"
	var w := fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string_outline(fuente, Vector2(938 - w, 458), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
	draw_string(fuente, Vector2(938 - w, 458), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.92, 0.75))
	if p.armas.size() > 1:
		draw_string_outline(fuente, Vector2(780, 458), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
		draw_string(fuente, Vector2(780, 458), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

# 3 corazones con el sprite de corazón: lleno, medio o vacío. Laten con poca vida.
func _corazones(p, t: float) -> void:
	var lleno_t: Texture2D = UI_LLENO
	var medio_t: Texture2D = UI_MEDIO
	var vacio_t: Texture2D = UI_VACIO
	var tam := lleno_t.get_size()
	var late := 1.0 + (sin(t * 10.0) * 0.12 if p.vida <= 2 else 0.0)
	# Al curarse los corazones dan un saltito.
	var desde_cura: float = (Time.get_ticks_msec() - p.cura_ms) / 1000.0
	if p.cura_ms > 0 and desde_cura < 0.3:
		late += sin(desde_cura / 0.3 * PI) * 0.35
	for i in 3:
		var c := Vector2(40 + i * 38, 34)
		# El corazón que se acaba de perder tiembla y salta un poco (pixeles enteros).
		if i == p.corazon_roto and main.dano_t > 0.0:
			var k: float = main.dano_t / 0.5
			c += Vector2(roundf(sin(t * 60.0) * 3.0 * k), roundf(-4.0 * k))
		var s := tam * late
		var r := Rect2((c - s / 2.0).round(), s.round())
		var lleno: int = clampi(p.vida - i * 2, 0, 2)
		draw_texture_rect([vacio_t, medio_t, lleno_t][lleno], r, false)

# Al cambiar de objeto con Q, se muestra en grande con su nombre junto a Diana.
func _cambio(p) -> void:
	if main.cambio_t <= 0.0 or p.arma() == "":
		return
	var a: float = clampf(main.cambio_t / 0.3, 0.0, 1.0)
	var c := Vector2(480, 330)
	var r := Rect2(c - Vector2(80, 24), Vector2(160, 48))
	draw_rect(r.grow(3), Color(BORDE, a))
	draw_rect(r, Color(MADERA_OSC, a * 0.95))
	draw_set_transform(c + Vector2(-70, 0), 0, Vector2.ONE * 1.4)
	Armas.dibujar(self, p.arma(), 1.0)
	draw_set_transform(Vector2.ZERO)
	var nombre := Armas.nombre(p.arma())
	draw_string(fuente, c + Vector2(-26, 5), nombre, HORIZONTAL_ALIGNMENT_LEFT, 104, 12, Color(1, 0.92, 0.75, a))

static var _texturas := {}

func _tex(clave: String) -> Texture2D:
	if not _texturas.has(clave):
		_texturas[clave] = load("res://assets/objetos/%s.png" % clave)
	return _texturas[clave]

func _textura(clave: String, c: Vector2, escala: float) -> void:
	var tex := _tex(clave)
	var s := tex.get_size() * 0.5 * escala
	draw_texture_rect(tex, Rect2(c - s / 2.0, s), false)

# Botón pequeño del esquive (Impulso de luz dorado después del jefe).
func _esquive(p) -> void:
	var c := Vector2(735, 500)
	var listo: bool = p.impulso_cd <= 0.0
	var col := Color(1.0, 0.85, 0.4) if p.impulso_luz else Color(0.55, 0.85, 1.0)
	# Botón de joyería; mientras recarga se ve apagado y se llena un arco alrededor.
	draw_texture(UI_ESQUIVE, c - Vector2(20, 20), Color.WHITE if listo else Color(0.45, 0.45, 0.5))
	if listo:
		draw_arc(c, 21, 0, TAU, 32, Color(col, 0.35 + 0.25 * sin(Time.get_ticks_msec() / 200.0)), 2.0)
	else:
		draw_arc(c, 21, -PI / 2, -PI / 2 + TAU * (1.0 - p.impulso_cd / p.RECARGA_IMPULSO), 32, col, 3.0)
	draw_string_outline(fuente, c + Vector2(-16, 28), "Shift", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color.BLACK)
	draw_string(fuente, c + Vector2(-16, 28), "Shift", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)

# Barra del jefe arriba al centro con su nombre.
var jefe_vista := 1.0   # la vida que se acaba de perder baja despacio (franja clara)
var jefe_t := 0.0       # entrada de la barra

func _barra_jefe() -> void:
	var j = main.jefe
	if j == null or not is_instance_valid(j) or not j.vivo:
		jefe_t = 0.0
		jefe_vista = 1.0
		return
	var t := Time.get_ticks_msec() / 1000.0
	jefe_t = minf(jefe_t + get_process_delta_time() * 2.5, 1.0)
	var k: float = clampf(float(j.vida) / j.vida_max, 0.0, 1.0)
	jefe_vista = maxf(k, move_toward(jefe_vista, k, get_process_delta_time() * 0.35))
	# Entra deslizándose desde arriba.
	var dy := roundf((1.0 - ease(jefe_t, 0.4)) * -70.0)
	var marco := Rect2(250, 8 + dy, 460, 54)
	draw_style_box(_marco_vida, marco)
	# Nombre en champán con destellos a los lados.
	var titulo: String = main.NIVEL_DATOS[main.nivel].jefe_nombre
	var w := fuente.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var tp := Vector2(480 - w / 2, 28 + dy)
	draw_string_outline(fuente, tp, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Ui.NEGRO)
	draw_string(fuente, tp, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Ui.CHAMPAN)
	var late := 0.5 + 0.5 * sin(t * 3.0)
	Ui.estrella(self, Vector2(480 - w / 2 - 14, 23 + dy), 1.5, Color(Ui.ORO_ROSA, 0.6 + 0.4 * late))
	Ui.estrella(self, Vector2(480 + w / 2 + 14, 23 + dy), 1.5, Color(Ui.ORO_ROSA, 0.6 + 0.4 * late))
	# Barra de cristal morado (gris mientras está inmune) con la franja de lo recién perdido.
	var r := Rect2(282, 36 + dy, 396, 14)
	draw_rect(r, Color(0.1, 0.04, 0.1))
	if jefe_vista > k:
		draw_rect(Rect2(r.position, Vector2(roundf(r.size.x * jefe_vista), r.size.y)), Color(1.0, 0.9, 0.8, 0.7))
	var tinte := Color(0.7, 0.7, 0.75) if j.humo else Color(1.7, 0.55, 1.5)
	draw_texture_rect(UI_RELLENO, Rect2(r.position, Vector2(roundf(r.size.x * k), r.size.y)), false, tinte)
	# Brillo que recorre la barra.
	var bx := r.position.x + fmod(t * 160.0, r.size.x * maxf(k, 0.01))
	draw_rect(Rect2(bx, r.position.y + 2, 6, 3), Color(1, 1, 1, 0.35 if not j.humo else 0.15))
	draw_style_box(_marco_barra, Rect2(r.position - Vector2(12, 4), r.size + Vector2(24, 8)))
	# Porcentaje; con el escudo de humo avisa que es inmune.
	var txt := "%d%%" % ceili(k * 100.0)
	if j.humo:
		txt = "INMUNE: pule a los escarabajos"
	var tw := fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var pp := Vector2(480 - tw / 2, r.position.y + 11)
	draw_string_outline(fuente, pp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Ui.NEGRO)
	draw_string(fuente, pp, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.95, 0.88) if not j.humo else Color(0.85, 0.85, 0.9))

var _marco_vida: StyleBoxTexture = Ui.marco("marco_vida", 30, 14)
var _marco_panel: StyleBoxTexture = Ui.marco("panel", 16, 16)
var _marco_barra: StyleBoxTexture = Ui.marco("barra_marco", 12, 6)

func _init() -> void:
	_marco_barra.draw_center = false   # el centro del marco no tapa el cristal de energía

func _panel(r: Rect2) -> void:
	draw_style_box(_marco_panel, r.grow(4))

func _icono(clave: String, c: Vector2, escala: float) -> void:
	var tex: Texture2D = UI_ENERGIA
	var s := tex.get_size() * escala
	draw_texture_rect(tex, Rect2((c - s / 2.0).round(), s), false)

func _barra(pos: Vector2, val: int, maxv: int, color: Color, texto: String, sombra := -1.0) -> void:
	var r := Rect2(pos, Vector2(200, 18))
	draw_rect(r, Color(0.13, 0.06, 0.12))
	# Sombra clara de lo que se acaba de gastar (baja un momento después).
	if sombra > val:
		draw_rect(Rect2(pos, Vector2(roundf(200.0 * sombra / max(maxv, 1)), 18)), Color(0.85, 0.9, 1.0, 0.55))
	var relleno: Texture2D = UI_RELLENO
	var tinte := Color.WHITE if color.b > color.r else Color(1.6, 0.45, 0.45)   # rojo cuando falta brillo
	draw_texture_rect(relleno, Rect2(pos, Vector2(roundf(200.0 * val / max(maxv, 1)), 18)), false, tinte)
	draw_style_box(_marco_barra, Rect2(pos - Vector2(12, 4), Vector2(224, 26)))
	var w := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string_outline(fuente, pos + Vector2(100 - w / 2, 15), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	draw_string(fuente, pos + Vector2(100 - w / 2, 15), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)

func _corazon(c: Vector2) -> void:
	draw_circle(c + Vector2(-4, -3), 5, Color(0.9, 0.2, 0.25))
	draw_circle(c + Vector2(4, -3), 5, Color(0.9, 0.2, 0.25))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -1), c + Vector2(9, -1), c + Vector2(0, 9)]), Color(0.9, 0.2, 0.25))

func _escudo(c: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -8), c + Vector2(8, -8), c + Vector2(8, 1), c + Vector2(0, 9), c + Vector2(-8, 1)]), Color(0.65, 0.67, 0.72))

func _rombo(c: Vector2, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(7, 0), c + Vector2(0, 8), c + Vector2(-7, 0)]), col)

func _minimapa(o: Vector2) -> void:
	var celda := 22.0
	var t := Time.get_ticks_msec() / 1000.0
	var dirs := {"arriba": Vector2.UP, "abajo": Vector2.DOWN, "izquierda": Vector2.LEFT, "derecha": Vector2.RIGHT}
	# Marco de joyería detrás del mapa.
	draw_style_box(_marco_panel, Rect2(o - Vector2(14, 12), Vector2(4 * celda + 22, 5 * celda + 20)))
	# Pasillos primero (oro rosa), para que queden debajo de los cuartos.
	for id in POS_MAPA:
		if not main.visitados.has(id):
			continue
		var c: Vector2 = o + POS_MAPA[id] * celda + Vector2(8, 8)
		for dir in main.GRAFO[id]:
			var otro: String = main.GRAFO[id][dir]
			var col := Ui.ORO_ROSA if main.visitados.has(otro) else Color(Ui.ORO_ROSA, 0.35)
			draw_line(c, c + dirs[dir] * celda * 0.5, col, 3)
	for id in POS_MAPA:
		var visto: bool = main.visitados.has(id)
		if not visto and not _vecino_visitado(id):
			continue
		var r := Rect2(o + POS_MAPA[id] * celda, Vector2(16, 16))
		var ic := r.get_center()
		if id == main.room_id:
			# Cuarto actual: champán que late con un halo.
			var late := 0.5 + 0.5 * sin(t * 4.0)
			draw_rect(r.grow(3), Color(Ui.CHAMPAN, 0.25 + 0.25 * late))
			draw_rect(r.grow(1), Ui.NEGRO)
			draw_rect(r, Ui.CHAMPAN)
			draw_rect(Rect2(r.position, Vector2(16, 4)), Color(1, 1, 1, 0.5))
		elif visto:
			var limpio: bool = main.limpios.has(id) or not main.OLEADAS.has(id)
			draw_rect(r.grow(1), Ui.NEGRO)
			draw_rect(r, Ui.CIRUELA.lightened(0.25) if limpio else Color(0.5, 0.18, 0.22))
			draw_rect(Rect2(r.position, Vector2(16, 3)), Color(1, 1, 1, 0.12))
		else:
			# Conocido pero sin visitar: solo el contorno punteado.
			for k in 4:
				draw_rect(Rect2(r.position + Vector2(k * 4, 0), Vector2(2, 1)), Color(Ui.ORO_ROSA, 0.6))
				draw_rect(Rect2(r.position + Vector2(k * 4, 15), Vector2(2, 1)), Color(Ui.ORO_ROSA, 0.6))
				draw_rect(Rect2(r.position + Vector2(0, k * 4), Vector2(1, 2)), Color(Ui.ORO_ROSA, 0.6))
				draw_rect(Rect2(r.position + Vector2(15, k * 4), Vector2(1, 2)), Color(Ui.ORO_ROSA, 0.6))
		# Iconos pixel art de cada tipo de cuarto.
		var oscuro: bool = id == main.room_id
		match id:
			"cofre":
				draw_rect(Rect2(ic - Vector2(5, 3), Vector2(10, 7)), Color(0.55, 0.32, 0.15))
				draw_rect(Rect2(ic - Vector2(5, 3), Vector2(10, 2)), Color(0.8, 0.55, 0.25))
				draw_rect(Rect2(ic - Vector2(1, 0), Vector2(2, 2)), Color(1.0, 0.85, 0.3))
			"apartado":
				var ca := Color(1.0, 0.85, 0.3) if main.apartado_activo else Color(0.75, 0.5, 0.2)
				draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -5), ic + Vector2(5, 0), ic + Vector2(0, 5), ic + Vector2(-5, 0)]), ca)
				draw_rect(Rect2(ic - Vector2(1, 3), Vector2(2, 2)), Color(1, 1, 1, 0.8))
			"jefe":
				# Calavera roja.
				var cj := Color(0.85, 0.2, 0.3) if not oscuro else Color(0.6, 0.1, 0.2)
				draw_rect(Rect2(ic - Vector2(4, 4), Vector2(8, 6)), cj)
				draw_rect(Rect2(ic + Vector2(-3, 2), Vector2(6, 3)), cj)
				draw_rect(Rect2(ic + Vector2(-3, -2), Vector2(2, 2)), Ui.NEGRO)
				draw_rect(Rect2(ic + Vector2(1, -2), Vector2(2, 2)), Ui.NEGRO)
			"descanso":
				# Corazón verde menta.
				var cd := Color(0.45, 0.85, 0.6)
				draw_rect(Rect2(ic + Vector2(-4, -3), Vector2(3, 3)), cd)
				draw_rect(Rect2(ic + Vector2(1, -3), Vector2(3, 3)), cd)
				draw_rect(Rect2(ic + Vector2(-4, -1), Vector2(8, 2)), cd)
				draw_rect(Rect2(ic + Vector2(-2, 1), Vector2(4, 2)), cd)
				draw_rect(Rect2(ic + Vector2(-1, 3), Vector2(2, 1)), cd)
		# Gema oculta que falta en un cuarto ya visitado: rombito rosa que brilla.
		if visto and main.GEMAS_CUARTO.has(id) and not main.gemas_tomadas.has(main.GEMAS_CUARTO[id]) and id != "cofre":
			var g := ic + Vector2(4, 4)
			var cg := Color(1.0, 0.45, 0.7, 0.6 + 0.4 * sin(t * 5.0 + POS_MAPA[id].x))
			draw_colored_polygon(PackedVector2Array([g + Vector2(0, -3), g + Vector2(3, 0), g + Vector2(0, 3), g + Vector2(-3, 0)]), cg)
		# Diana en el cuarto actual.
		if id == main.room_id:
			draw_rect(Rect2(ic - Vector2(2, 2), Vector2(4, 4)), Color(0.85, 0.3, 0.45))
			draw_rect(Rect2(ic - Vector2(1, 2), Vector2(2, 1)), Color(1, 1, 1, 0.8))

func _vecino_visitado(id: String) -> bool:
	for dir in main.GRAFO[id]:
		if main.visitados.has(main.GRAFO[id][dir]):
			return true
	return false


# Botón del Destello de joyera (E): gema rosa que late cuando está lista; mientras recarga
# se ve apagada con un arco que se llena. Si no alcanza el brillo, la gema queda gris.
func _boton_destello(p) -> void:
	var c := Vector2(684, 500)
	var t := Time.get_ticks_msec() / 1000.0
	var listo: bool = p.destello_cd <= 0.0
	var alcanza: bool = p.energia >= 40.0
	draw_circle(c, 20.0, Color(0.1, 0.04, 0.1, 0.9))
	draw_arc(c, 20.0, 0, TAU, 32, Color(0.85, 0.6, 0.5), 2.0)
	var col := Color(1.0, 0.5, 0.78) if listo and alcanza else Color(0.45, 0.4, 0.48)
	var late := 1.0 + (0.12 * sin(t * 5.0) if listo and alcanza else 0.0)
	var g := PackedVector2Array([c + Vector2(0, -11) * late, c + Vector2(10, -2) * late, c + Vector2(0, 11) * late, c + Vector2(-10, -2) * late])
	draw_colored_polygon(g, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11) * late, c + Vector2(10, -2) * late, c + Vector2(0, -2)]), Color(1, 1, 1, 0.35))
	if listo and alcanza:
		draw_arc(c, 23.0, 0, TAU, 32, Color(1.0, 0.6, 0.85, 0.35 + 0.3 * sin(t * 4.0)), 2.0)
		Ui.estrella(self, c + Vector2(13, -13), 1.5 + 0.5 * sin(t * 6.0), Color(1, 0.95, 0.85))
	elif not listo:
		draw_arc(c, 23.0, -PI / 2, -PI / 2 + TAU * (1.0 - p.destello_cd / p.RECARGA_DESTELLO), 32, Color(1.0, 0.55, 0.8), 3.0)
	draw_string_outline(fuente, c + Vector2(-4, 28), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color.BLACK)
	draw_string(fuente, c + Vector2(-4, 28), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
