# Letrero de logro en pantalla (¡PULIDO!, ¡DOBLE BRILLO!...): entra con rebote,
# brilla, suelta chispas del color del arma y se desvanece subiendo.
extends Node2D

var clave := "pulido"
var color := Color(1.0, 0.85, 0.4)
var t := 0.0
var dura := 1.5
var tex: Texture2D
var chispas: Array = []   # [pos, vel, vida, tam, color]
var rayos := 0.0
var reaviva_t := 0.0
var letrero: Sprite2D   # el letrero con su disolución en pixeles
const SH := """
shader_type canvas_item;
uniform float corte = 1.0;      // 0 = completo, 1 = deshecho
uniform vec4 orilla : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform vec2 tam = vec2(120.0, 80.0);
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = floor(UV * tam);
	// Se deshace de afuera hacia adentro con ruido por pixel (nunca en línea recta).
	float lejos = length((UV - 0.5) * vec2(1.0, 0.7)) * 1.4;
	float v = h(px) * 0.6 + lejos * 0.4;
	float lim = 1.0 - corte;
	if (v > lim) { discard; }
	if (v > lim - 0.07 && corte > 0.0) { c.rgb = mix(c.rgb, orilla.rgb, 0.85); }
	COLOR = c * COLOR;
}
"""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tex = load("res://assets/objetos/logro_%s.png" % clave)
	var fuerte := clave in ["triple", "racha", "jefe", "impecable", "critico"]
	if clave == "jefe":
		dura = 2.6
	elif fuerte:
		dura = 2.0
	else:
		dura = 1.6
	# Estallido inicial: chispas que salen de la orilla del letrero.
	var n := 26 if fuerte else 16
	for i in n:
		var a := TAU * i / n + randf() * 0.3
		var v := Vector2.RIGHT.rotated(a)
		var c := color.lightened(randf() * 0.4) if randf() < 0.6 else Color(1.0, 0.9, 0.55)
		chispas.append([v * Vector2(tex.get_width() * 0.35, tex.get_height() * 0.3), v * randf_range(60.0, 160.0), randf_range(0.4, 0.8), 2.0 if randf() < 0.5 else 3.0, c])
	rayos = 1.0 if fuerte else 0.0
	letrero = Sprite2D.new()
	letrero.texture = tex
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SH
	m.shader = sh
	m.set_shader_parameter("tam", tex.get_size())
	m.set_shader_parameter("orilla", color.lightened(0.35))
	letrero.material = m
	letrero.visible = false
	add_child(letrero)

func _process(delta: float) -> void:
	if get_tree().paused:
		queue_redraw()
		return
	t += delta
	reaviva_t = maxf(0.0, reaviva_t - delta)
	for c in chispas:
		c[0] += c[1] * delta
		c[1] *= 0.9
		c[1].y += 60.0 * delta
		c[2] -= delta
	chispas = chispas.filter(func(c): return c[2] > 0.0)
	# Destellitos que brotan mientras está en pantalla.
	if t < dura - 0.4 and randf() < delta * 10.0:
		var p := Vector2(randf_range(-0.5, 0.5) * tex.get_width(), randf_range(-0.5, 0.5) * tex.get_height())
		chispas.append([p, Vector2(0, -20), 0.4, 3.0, Color(1.0, 0.95, 0.7)])
	if t >= dura:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if get_tree().paused:
		letrero.visible = false
		return   # no se encima con el menú de pausa
	# Entrada con rebote en pasos de pixel (crece de más y se asienta); sale subiendo.
	var e := 1.0
	if t < 0.26 and t > 0.14:
		e = 1.1
	elif t < 0.34 and t > 0.14:
		e = 0.97
	const ENTRA := 0.14     # el letrero se arma cuando el efecto llega a la estrella
	const FPS := 14.0
	var t_sale := dura - 0.45
	var sale := clampf((t - t_sale) / 0.45, 0.0, 1.0)
	# Salida: destello blanco, sube y se desvanece.
	var alfa := 1.0 - clampf((sale - 0.25) / 0.75, 0.0, 1.0)
	var dy := roundf((1.0 if fmod(t, 0.8) < 0.4 else 0.0) * (1.0 - sale) - sale * sale * 16.0)
	# Letreros con animación propia (Triple brillo, Racha radiante).
	var c_entra := "logro_%s_entra" % clave
	var c_sale := "logro_%s_sale" % clave
	if Fx.meta_o_nada(c_entra):
		# Solo los cuadros sin texto (gema, medallón, marco); el texto sale del letrero nítido.
		var ne := 3
		var fa := int(t * 14.0)
		if fa < ne:
			letrero.visible = false
			_anim(c_entra, fa, dy)
			for c in chispas:
				var s2: float = c[3]
				draw_rect(Rect2((c[0] as Vector2).round() - Vector2(s2, s2) / 2.0, Vector2(s2, s2)), Color(c[4], clampf(c[2] * 2.5, 0.0, 1.0)))
			return
	var desde_s := 2 if clave == "triple" else 2
	if Fx.meta_o_nada(c_sale) and t >= t_sale + 0.12:
		letrero.visible = false
		var fsa := desde_s + int((t - t_sale - 0.12) * 14.0)
		if fsa < int(Fx.meta(c_sale).n):
			_anim(c_sale, fsa, dy)
		return
	# Efecto de aparecer (detrás del letrero).
	var fe := int(t * FPS)
	if fe < 5 and not Fx.meta_o_nada(c_entra):
		_fx("logro_fx_entra", fe, dy)
	if t < ENTRA:
		letrero.visible = false
		return
	var tam := (tex.get_size() * e).round()
	var org := (Vector2(0, dy) - tam / 2.0).round()
	# Se arma desde el centro hacia los lados, y al salir se cierra hacia el centro.
	var abre := clampf((t - ENTRA) / 0.22, 0.0, 1.0)
	if Fx.meta_o_nada(c_entra):
		abre = clampf((t - 3.0 / 14.0) / 0.15, 0.0, 1.0)   # el texto se arma en pixeles sobre el medallón
	var ancho_vis := abre   # la disolución en pixeles solo es para entrar
	if alfa <= 0.0:
		letrero.visible = false
		var fs0 := int((t - t_sale) * FPS)
		if fs0 < 6:
			_fx("logro_fx_sale", fs0, dy)
		return
	var corte := 0.0   # ya no se recorta: se disuelve en pixeles
	letrero.visible = true
	letrero.position = Vector2(0, dy)
	letrero.scale = Vector2.ONE * e
	(letrero.material as ShaderMaterial).set_shader_parameter("corte", 1.0 - ancho_vis)
	var solido := ancho_vis * ancho_vis
	# Contorno de luz pixelado del color del arma: la silueta del letrero 1 y 2 pixeles alrededor.
	var pulso := 0.55 + 0.25 * (1.0 if fmod(t, 0.3) < 0.15 else 0.0)
	for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		_tex_corte(org + d, tam, corte, Color(color.r, color.g, color.b, 0.35 * alfa * pulso * solido))
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_tex_corte(org + d, tam, corte, Color(color.lightened(0.3), 0.7 * alfa * pulso * solido))
	# Letrero (destello blanco al aparecer).
	var brillo := 1.7 if abre < 1.0 or reaviva_t > 0.0 else 1.0
	if sale > 0.0:
		brillo = 1.0 + 1.6 * (1.0 - clampf(sale / 0.3, 0.0, 1.0)) if sale < 0.3 else 1.0
	if reaviva_t > 0.0:
		var k2 := 1.08
		org = (Vector2(0, dy) - tam * k2 / 2.0).round()
		tam = (tam * k2).round()
	letrero.modulate = Color(brillo, brillo, brillo, alfa)
	if reaviva_t > 0.0:
		letrero.scale = Vector2.ONE * 1.08
	# Destello de salida: estrella de 4 puntas que crece y gira en el centro del letrero.
	if sale > 0.0 and sale < 0.6:
		var k := sale / 0.6
		var largo := roundf(lerpf(4.0, tam.x * 0.6, sin(k * PI)))
		var ancho := maxf(1.0, roundf(3.0 * (1.0 - k)))
		var cc := Color(1.0, 0.97, 0.85, 1.0 - k)
		var ctr := Vector2(0, dy).round()
		draw_rect(Rect2(ctr - Vector2(largo, ancho / 2.0), Vector2(largo * 2.0, ancho)), cc)
		draw_rect(Rect2(ctr - Vector2(ancho / 2.0, largo * 0.45), Vector2(ancho, largo * 0.9)), cc)
		draw_rect(Rect2(ctr - Vector2(3, 3), Vector2(6, 6)), Color(1, 1, 1, 1.0 - k))
	# Efecto de desaparecer encima.
	if t >= t_sale:
		var fs := int((t - t_sale) * FPS)
		if fs < 6:
			_fx("logro_fx_sale", fs, dy)
	# Estrellitas de 4 puntas en pixeles que se prenden y apagan en las orillas.
	for k in (6 if rayos > 0.0 else 3):
		var fase := fmod(t * 2.5 + k * 0.37, 1.0)
		if fase > 0.6:
			continue
		var semilla := float(k * 97 % 13) / 13.0
		var ang := TAU * (k / (6.0 if rayos > 0.0 else 3.0)) + semilla
		var p := (Vector2(cos(ang) * tam.x * 0.5, sin(ang) * tam.y * 0.5) + Vector2(0, dy)).round()
		var g := 1 if fase < 0.15 or fase > 0.45 else 3
		var c := Color(1.0, 0.95, 0.7, alfa)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), c)
		draw_rect(Rect2(p + Vector2(-1, -1 - g), Vector2(2, g)), Color(color.lightened(0.4), alfa))
		draw_rect(Rect2(p + Vector2(-1, 1), Vector2(2, g)), Color(color.lightened(0.4), alfa))
		draw_rect(Rect2(p + Vector2(-1 - g, -1), Vector2(g, 2)), Color(color.lightened(0.4), alfa))
		draw_rect(Rect2(p + Vector2(1, -1), Vector2(g, 2)), Color(color.lightened(0.4), alfa))
	# Chispas cuadradas.
	for c in chispas:
		var s: float = c[3]
		draw_rect(Rect2((c[0] as Vector2).round() - Vector2(s, s) / 2.0, Vector2(s, s)), Color(c[4], clampf(c[2] * 2.5, 0.0, 1.0) * alfa))

# Dibuja el letrero sin las orillas (para armarlo o cerrarlo desde el centro).
func _tex_corte(org: Vector2, tam: Vector2, corte: float, col: Color) -> void:
	var k := tam.x / float(tex.get_width())
	var src := Rect2(corte, 0, tex.get_width() - corte * 2.0, tex.get_height())
	if src.size.x <= 0.0:
		return
	draw_texture_rect_region(tex, Rect2(org + Vector2(corte * k, 0).round(), Vector2(src.size.x * k, tam.y).round()), src, col)

# Cuadro de un efecto de la hoja, estirado a lo ancho del letrero.
func _fx(clave: String, i: int, dy: float) -> void:
	var c := Fx.cuadro(clave, i)
	var tam := Vector2(c.get_size().x * 2.0, c.get_size().y)
	draw_texture_rect(c, Rect2((Vector2(0, dy) - tam / 2.0).round(), tam), false)

# Otro letrero lo reemplaza: hace su salida (rápida) en su lugar.
func salir() -> void:
	if t < 0.14:
		queue_free()   # todavía no se veía
		return
	if t < dura - 0.45:
		dura = t + 0.45

# Salió el mismo otra vez: destello y se queda un rato más.
func reavivar() -> void:
	if t >= dura - 0.45:
		return
	dura = maxf(dura, t + 1.2)
	reaviva_t = 0.15
	for i in 10:
		var a := TAU * i / 10.0
		var v := Vector2.RIGHT.rotated(a)
		chispas.append([v * Vector2(tex.get_width() * 0.35, tex.get_height() * 0.3), v * randf_range(50.0, 110.0), 0.5, 2.0, color.lightened(0.3)])

# Cuadro de la animación propia del letrero, centrado.
func _anim(clave_a: String, i: int, dy: float) -> void:
	var c := Fx.cuadro(clave_a, i)
	var tam := c.get_size()
	draw_texture_rect(c, Rect2((Vector2(0, dy) - tam / 2.0).round(), tam), false)
