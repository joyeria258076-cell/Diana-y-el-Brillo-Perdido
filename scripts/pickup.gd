# Cosas en el piso: destello (moneda), corazón, poción, arma, cofre o gema oculta.
# Destellos, corazones y pociones salen en arco y luego vuelan hacia Diana;
# armas y cofre se toman con F; las gemas ocultas aparecen con el destello de la Lupa.
extends Node2D

var main
var tipo := "destello"
var arma := ""
var t := 0.0
var salto := Vector2.ZERO
var abierto := false
var atraer := false  # el collar jala los destellos desde lejos
static var _texturas := {}
var z := 0.0        # altura del salto en arco
var vz := 0.0
var gema := ""      # nombre de la gema oculta
var oculta := true
const GEMAS := {"cuarzo": Color(1.0, 0.75, 0.85), "amatista": Color(0.75, 0.5, 1.0),
	"topacio": Color(1.0, 0.75, 0.3), "zirconia": Color(0.85, 0.95, 1.0), "ópalo": Color(0.55, 1.0, 0.9)}

func _ready() -> void:
	t = randf() * 3.0
	if tipo in ["destello", "corazon", "pocion"]:
		salto = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30, 80)
		vz = randf_range(90.0, 150.0)

func _process(delta: float) -> void:
	t += delta
	var p = main.player
	var d: Vector2 = p.position - position
	# Arco: sube y cae rebotando antes de poder recogerse.
	if vz != 0.0 or z > 0.0:
		z += vz * delta
		vz -= 420.0 * delta
		if z <= 0.0:
			z = 0.0
			vz = -vz * 0.35 if absf(vz) > 40.0 else 0.0
	if tipo == "gema":
		if not oculta and d.length() < 14.0:
			main.tomar_gema(self)
			return
	elif salto.length() > 1.0 or z > 0.0:
		position = main.mover(position, salto * delta)
		salto = salto.move_toward(Vector2.ZERO, 160.0 * delta)
	elif tipo in ["destello", "corazon", "pocion"]:
		if d.length() < 70.0 or atraer:
			position += d.normalized() * 220.0 * delta
		if d.length() < 12.0:
			_recoger()
			return
	queue_redraw()

var abierto_ms := 0

# Lo llama Diana al presionar F cerca.
func usar() -> void:
	if tipo == "arma":
		main.player.tomar_arma(self)
	elif tipo == "cofre" and not abierto:
		abierto = true
		abierto_ms = Time.get_ticks_msec()
		Juego.sonido("recoger", false)
		Fx.estallido(main.mundo, position + Vector2(0, -10), Color(1.0, 0.85, 0.4))
		Fx.chispas(main.mundo, position + Vector2(0, -10), Color(1.0, 0.85, 0.4), 16)
		var libres: Array = Armas.BODEGA.filter(func(a): return not a in main.player.armas)
		if libres.size() > 0 and randf() < 0.7:
			main.soltar("arma", position + Vector2(0, 18), libres.pick_random())
		else:
			for i in 2:
				main.soltar("pocion", position + Vector2(0, 12))
		for i in 4:
			main.soltar("destello", position + Vector2(0, 10))

# La Lupa toca la gema: deja de estar oculta con un destello.
func revelar() -> void:
	if not oculta:
		return
	oculta = false
	vz = 120.0
	Juego.sonido("recoger", false)
	Fx.estallido(main.mundo, position + Vector2(0, -6), GEMAS[gema])
	Fx.chispas(main.mundo, position + Vector2(0, -6), GEMAS[gema], 14)
	main.mensaje("¡Una gema oculta! (%s)" % gema, 1.6)

func _recoger() -> void:
	match tipo:
		"destello":
			main.destellos += 1
			Juego.sonido("recoger", true, -6.0)
		"corazon":
			main.player.curar(2)
			Juego.sonido("curar")
			Fx.numero(main.mundo, position, 1)
		"pocion":
			main.player.energia = minf(main.player.energia + 60.0, main.player.energia_max)
			Juego.sonido("pocion")
	if tipo == "pocion":
		main.player.alegria(Color(0.35, 0.65, 1.0))
	elif tipo != "destello":
		main.player.alegria()
	queue_free()

func _draw() -> void:
	var y := sin(t * 4.0) * 2.0 - z
	if tipo == "gema":
		if oculta:
			# Apenas un brillito de vez en cuando delata dónde está.
			if fmod(t, 3.0) < 0.15:
				draw_circle(Vector2(0, -6), 1.5, Color(1, 1, 1, 0.5))
			return
		_textura("joya", Vector2(0, -8 + y), Vector2.ONE, GEMAS[gema])
		return
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	match tipo:
		"destello":
			# Gira: se angosta y vuelve a ensancharse.
			_textura("destello", Vector2(0, -6 + y), Vector2(absf(cos(t * 5.0)) * 0.8 + 0.2, 1.0))
		"corazon":
			_textura("corazon", Vector2(0, -7 + y))
		"pocion":
			_textura("pocion", Vector2(0, -8 + y))
		"arma":
			# Luz del color del arma: aro en el piso, columna tenue y chispitas que suben.
			var c: Color = Armas.DATOS[arma].color
			var cerca := _mas_cercana()
			var pulso := 0.5 + 0.5 * sin(t * 3.0)
			draw_set_transform(Vector2(0, 0), 0, Vector2(1, 0.4))
			draw_circle(Vector2.ZERO, 13.0 + pulso * 2.0, Color(c, 0.16 + (0.14 if cerca else 0.0)))
			draw_arc(Vector2.ZERO, 15.0 + pulso * 2.0, 0, TAU, 24, Color(c, 0.55 if cerca else 0.35), 2.0)
			draw_set_transform(Vector2.ZERO)
			draw_rect(Rect2(-5, -30, 10, 30), Color(c, 0.05 + pulso * 0.05))
			for i in 4:
				var k := fmod(t * 0.6 + i * 0.25, 1.0)
				var px := sin(t * 2.0 + i * 1.7) * 9.0
				var tam := 2.0 if fmod(t * 4.0 + i, 2.0) < 1.0 else 1.0
				draw_rect(Rect2(Vector2(px, -4 - k * 30.0).round(), Vector2(tam, tam)), Color(c.lightened(0.4), 1.0 - k))
			# El arma flota, se mece y destella de vez en cuando.
			draw_set_transform_matrix(Transform2D(sin(t * 2.0) * 0.35, Vector2(0, -12 + y)) * Transform2D(0, Vector2(-12, 0)))
			Armas.dibujar(self, arma, 1.0)
			draw_set_transform(Vector2.ZERO)
			var g := fmod(t, 2.4)
			if g < 0.3:
				var s := sin(g / 0.3 * PI) * 5.0
				var o := Vector2(5, -18 + y)
				draw_line(o - Vector2(s, 0), o + Vector2(s, 0), Color(1, 1, 1, 0.9), 1.0)
				draw_line(o - Vector2(0, s), o + Vector2(0, s), Color(1, 1, 1, 0.9), 1.0)
			if cerca:
				_letrero("F: " + Armas.nombre(arma))
		"cofre":
			# Se abre en 3 cuadros (cerrado, entreabierto, abierto) apoyado en el piso.
			var clave := "cofre"
			if abierto:
				clave = "cofre_medio" if Time.get_ticks_msec() - abierto_ms < 140 else "cofre_abierto"
			if not _texturas.has(clave):
				_texturas[clave] = load("res://assets/objetos/%s.png" % clave)
			var tc: Texture2D = _texturas[clave]
			var tam := tc.get_size() * 0.5
			draw_texture_rect(tc, Rect2(Vector2(-tam.x / 2.0, -tam.y + 4.0).round(), tam), false)
			if not abierto and position.distance_to(main.player.position) < 32.0:
				_letrero("F: abrir")

# Dibuja un sprite de assets/objetos centrado en "centro" (a la mitad de tamaño).
func _textura(clave: String, centro: Vector2, escala := Vector2.ONE, color := Color.WHITE) -> void:
	if not _texturas.has(clave):
		_texturas[clave] = load("res://assets/objetos/%s.png" % clave)
	var tex: Texture2D = _texturas[clave]
	var tam := tex.get_size() * 0.5 * escala
	draw_texture_rect(tex, Rect2(centro - tam / 2.0, tam), false, color)

# Solo el arma más cercana a Diana muestra su letrero (si no, se enciman).
func _mas_cercana() -> bool:
	var d := position.distance_to(main.player.position)
	if d >= 28.0:
		return false
	for n in get_parent().get_children():
		if n != self and n.get("tipo") == "arma" and n.position.distance_to(main.player.position) < d:
			return false
	return true

func _letrero(texto: String) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string_outline(f, Vector2(-w / 2, -30), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
	draw_string(f, Vector2(-w / 2, -30), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.8))
