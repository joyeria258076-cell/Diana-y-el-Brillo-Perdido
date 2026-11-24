# Proyectil. De Diana: destello (lupa), abanico (espejo, corto alcance) o aros
# (rebotan entre enemigos y regresan a su mano). Enemigo: niebla o polvo.
extends Node2D

var main
var direccion := Vector2.RIGHT
var velocidad := 330.0
var enemigo := false
var tipo := "destello"
var dano := 1
var rebotes := 0
var vida := 1.6
var t := 0.0
var regresando := false
var golpeados: Array = []
static var _astilla: Texture2D
var estela: Array = []   # posiciones anteriores (estela corta de 3 copias)

const BRASA := Color(1.0, 0.78, 0.25)   # amarillo de los ojos del Vendedor
var luz_niebla: PointLight2D

func _ready() -> void:
	if tipo == "roca":
		# Roca del gólem: brilla por sus grietas (luz naranja) y no se pierde en la penumbra.
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = mat
		var lr := _luz_nueva()
		lr.texture = Fx.textura_luz()
		lr.texture_scale = 0.7
		lr.energy = 0.9
		lr.color = Color(1.0, 0.55, 0.2)
		add_child(lr)
	if tipo == "niebla":
		# La niebla del Vendedor trae su brasa encendida: luz ámbar que titila.
		luz_niebla = _luz_nueva()
		luz_niebla.texture = Fx.textura_luz()
		luz_niebla.texture_scale = 0.3
		luz_niebla.energy = 0.6
		luz_niebla.color = BRASA
		add_child(luz_niebla)
	if tipo in ["destello", "abanico", "aros", "perla", "sonica"] and not enemigo:
		# Cada proyectil lleva su propia luz.
		var l := _luz_nueva()
		l.texture = Fx.textura_luz()
		l.texture_scale = 0.18
		l.energy = 0.35
		l.color = _color()
		if tipo == "sonica":
			l.texture_scale = 0.3
			l.energy = 0.6
		add_child(l)
	match tipo:
		"destello":
			rebotes = 1  # como en Soul Knight: rebota una vez en la pared
		"abanico":
			velocidad = 380.0
			vida = 0.6
			rebotes = 1  # el cristal rebota una vez en la pared
		"aros":
			velocidad = 300.0
			rebotes = 3
			vida = 3.0
		"perla":
			velocidad = 290.0
			rebotes = 1
			vida = 0.75
		"sonica":
			velocidad = 280.0
			rebotes = 1
			vida = 0.8
		"polvo":
			velocidad = 140.0
		"astilla":
			velocidad = 200.0
		"niebla":
			velocidad = 170.0
		"roca":
			velocidad = 150.0
			vida = 2.6

func _process(delta: float) -> void:
	if tipo in ["destello", "abanico", "aros", "astilla", "perla", "sonica"]:
		estela.push_front(global_position)
		if estela.size() > 7:
			estela.pop_back()
	t += delta
	vida -= delta
	if tipo == "roca" and fmod(t, 0.05) < delta:   # piedritas y brasas que va soltando
		Fx.chispas(main.mundo, position - direccion * 8.0, Color(1.0, 0.55, 0.2), 1)
	if tipo == "niebla":
		luz_niebla.energy = 0.5 + 0.15 * sin(t * 23.0) + randf() * 0.1
		if fmod(t, 0.06) < delta:   # pavesas que se le desprenden de la cola
			Fx.chispas(main.mundo, position - direccion * 13.0 + Vector2(randf_range(-3, 3), randf_range(-3, 3)), BRASA, 1)
		if fmod(t, 0.1) < delta:   # humo que deja atrás
			Fx.polvo(main.mundo, position - direccion * 16.0 + Vector2(0, 6))
	# La perla va soltando chispitas rosas.
	if tipo == "sonica" and fmod(t, 0.06) < delta:
		Fx.chispas(main.mundo, position - direccion * 6.0, Color(0.5, 0.95, 1.0), 1)
	if tipo == "sonica" and fmod(t, 0.16) < delta:
		Fx.estallido(main.mundo, position, Color(0.4, 0.9, 1.0, 0.45))   # anillo que queda vibrando
	if tipo == "perla" and fmod(t, 0.07) < delta:
		Fx.chispas(main.mundo, position, Color(1.0, 0.65, 0.85), 1)
	if tipo == "aros":
		_aros(delta)
		queue_redraw()
		return
	var siguiente := position + direccion * velocidad * delta
	if vida <= 0.0:
		if not enemigo:
			_explotar()
		elif tipo == "roca":   # cae donde estaba Diana y revienta
			_impacto()
		queue_free()
		return
	# Los muebles ocupan celdas como la pared: primero se revisa si la bala les pega.
	if not enemigo:
		for r in main.rompibles():
			if r.has_method("toca") and (r.toca(siguiente) or r.toca(position)):
				r.golpear()
				if tipo == "sonica":
					_explotar()
				else:
					_impacto()
				queue_free()
				return
	if _choca(siguiente):
		if not enemigo:
			main.golpear_decor(siguiente)
		if rebotes > 0 and not enemigo:
			rebotes -= 1
			if _choca(Vector2(siguiente.x, position.y)):
				direccion.x = -direccion.x
			if _choca(Vector2(position.x, siguiente.y)):
				direccion.y = -direccion.y
			Fx.chispas(main.mundo, position, _color(), 3)
			if tipo == "sonica" and Fx.meta_o_nada("fx_limpiador_rebote"):
				# Chapuzón de agua que sale de la pared hacia donde rebota.
				var ch := Fx.animar(main.mundo, position, "fx_limpiador_rebote", 16.0, Color(1, 1, 1, 0.85), 0.5)
				ch.rotation = direccion.angle() + PI / 2.0
				return
			_impacto()   # al rebotar suelta su destello en vez de solo perderse
			return
		Fx.chispas(main.mundo, position, _color(), 4)
		set_meta("pared", true)
		_impacto()   # al chocar con la pared también deja su destello
		queue_free()
		return
	position = siguiente
	if enemigo:
		if position.distance_to(main.player.position + Vector2(0, -20)) < (26.0 if tipo == "roca" else 14.0):
			# El Impulso de luz atraviesa (y deshace) la niebla.
			if main.player.impulso_t > 0.0 and main.player.impulso_luz and tipo == "niebla":
				Fx.chispas(main.mundo, position, Color(1.0, 0.95, 0.6), 6)
				queue_free()
				return
			if not main.PRUEBAS:   # en pruebas los disparos enemigos no hacen daño
				main.player.herir(1, main.player.position - position)
			_impacto()
			queue_free()
	else:
		# El destello de la Lupa revela las gemas ocultas.
		if tipo == "destello":
			for g in main.gemas_ocultas():
				if position.distance_to(g.position + Vector2(0, -6)) < 18.0:
					g.revelar()
		var e = _enemigo_tocado()
		if e:
			var critico := randf() < 0.15
			e.danar(dano * (2 if critico else 1), direccion, critico)
			golpeados.append(e)
			if tipo == "sonica":
				_explotar()   # el estallido de agua también moja a los de alrededor
			else:
				_impacto()
			queue_free()
			return
		for r in main.rompibles():
			if (r.toca(position) if r.has_method("toca") else position.distance_to(r.position + Vector2(0, -8)) < 13.0):
				r.golpear()
				queue_free()
				return
	queue_redraw()

func _enemigo_tocado():
	for e in main.enemigos():
		if not e in golpeados and e.impacta(position, 6.0):
			return e
	return null

# Aros: al pegar saltan al enemigo más cercano; sin rebotes o al chocar, regresan.
func _aros(delta: float) -> void:
	var mano: Vector2 = main.player.position + Vector2(0, -20)
	# Seguro: si algo los atora, desaparecen solos y se pueden volver a lanzar.
	if vida < -2.5:
		queue_free()
		return
	if regresando or vida <= 0.0:
		regresando = true
		direccion = (mano - position).normalized()
		position += direccion * 380.0 * delta
		if position.distance_to(mano) < 14.0:
			queue_free()
		return
	var siguiente := position + direccion * velocidad * delta
	if _choca(siguiente):
		if rebotes > 0:
			rebotes -= 1
			if _choca(Vector2(siguiente.x, position.y)):
				direccion.x = -direccion.x
			if _choca(Vector2(position.x, siguiente.y)):
				direccion.y = -direccion.y
			_impacto()
		else:
			regresando = true
		return
	position = siguiente
	if fmod(t, 0.06) < delta:
		Fx.chispas(main.mundo, position, Color(1.0, 0.7, 0.3), 1)
	var e = _enemigo_tocado()
	if e:
		var critico := randf() < 0.15
		e.danar(dano * (2 if critico else 1), direccion, critico)
		golpeados.append(e)
		_impacto()
		if golpeados.size() >= 2:
			# Ya dañó a dos: se rompe y desaparece (Diana recupera sus aros).
			queue_free()

# El proyectil vuela a la altura del pecho; se revisa el piso bajo él.
func _choca(p: Vector2) -> bool:
	var suelo := p + Vector2(0, 22)
	return not main.interior().grow(8).has_point(suelo) or main.bloqueado(suelo)

func _color() -> Color:
	match tipo:
		"roca": return Color(1.0, 0.55, 0.2)
		"niebla": return Color(0.55, 0.55, 0.6)
		"polvo": return Color(0.75, 0.7, 0.6)
		"astilla": return Color(0.75, 0.7, 0.95)
		"abanico": return Color(0.8, 0.95, 1.0)
		"aros": return Color(1.0, 0.85, 0.35)
		"perla": return Color(1.0, 0.75, 0.88)
		"sonica": return Color(0.45, 0.9, 1.0)
	return Color(1.0, 0.92, 0.6)

func _draw() -> void:
	var cuadro := int(t * 12.0) % 4
	# Estela: copias más chicas y transparentes en las posiciones de hace 2, 4 y 6 cuadros.
	if false:
		for i in [2, 4, 6]:
			if i < estela.size():
				var atras: Vector2 = (estela[i] - global_position).round()
				draw_set_transform(atras)
				_tex(Fx.cuadro("fx_destello", cuadro), 0.7 - i * 0.07, Color(_color(), 0.55 - i * 0.07))
		draw_set_transform(Vector2.ZERO)
	match tipo:
		"roca":
			# Roca del gólem girando en el aire.
			draw_set_transform(Vector2.ZERO, t * 5.0 * (1.0 if direccion.x >= 0.0 else -1.0), Vector2.ONE)
			_tex(Fx.cuadro("fx_gol_roca", int(t * 10.0) % 6), 1.0)
			draw_set_transform(Vector2.ZERO)
		"niebla":
			# Jirón de humo con ojos: apunta hacia donde vuela, sin quedar de cabeza.
			draw_set_transform(Vector2.ZERO, direccion.angle(), Vector2(1.0, -1.0 if direccion.x < 0.0 else 1.0))
			_tex(Fx.cuadro("fx_niebla", int(t * 10.0) % 5), 0.34)
			draw_set_transform(Vector2.ZERO)
		"astilla":
			draw_set_transform(Vector2.ZERO, direccion.angle(), Vector2.ONE)
			if _astilla == null:
				_astilla = load("res://assets/objetos/astilla.png")
			draw_texture_rect(_astilla, Rect2(Vector2(-7, -3.5), Vector2(14, 7)), false)
			draw_set_transform(Vector2.ZERO)
		"polvo":
			draw_circle(Vector2.ZERO, 5.0, Color(0.4, 0.35, 0.3))
			draw_circle(Vector2(-1, -1), 3.0, _color())
		"perla":
			# Estela: copias de la perla que se desvanecen detrás.
			var cp := "fx_collar_perla" if Fx.meta_o_nada("fx_collar_perla") else "fx_perla"
			for i in [2, 4, 6]:
				if i < estela.size():
					var atras: Vector2 = (estela[i] - global_position).round()
					var cq := Fx.cuadro(cp, cuadro)
					var tq: Vector2 = cq.get_size() * ((12.0 - i) / cq.get_size().x)
					draw_texture_rect(cq, Rect2(atras - tq / 2.0, tq), false, Color(1.0, 0.75, 0.9, 0.45 - i * 0.06))
			# Perla del collar (tira propia si existe; si no, la perla del juego).
			var clave_p := "fx_collar_perla" if Fx.meta_o_nada("fx_collar_perla") else "fx_perla"
			var pq := Fx.cuadro(clave_p, cuadro)
			var tp := pq.get_size() * (12.0 / pq.get_size().x)
			# la estela del dibujo sale de abajo a la izquierda: se gira para que quede atrás
			draw_set_transform(Vector2.ZERO, direccion.angle() + PI / 4.0 if clave_p == "fx_collar_perla" else 0.0, Vector2.ONE)
			draw_texture_rect(pq, Rect2(-tp / 2.0, tp), false)
			draw_set_transform(Vector2.ZERO)
		"sonica":
			# Onda sónica: los arcos van al frente y las burbujas quedan atrás.
			var ms := Fx.meta("fx_limpiador_vuelo")
			var sq := Fx.cuadro("fx_limpiador_vuelo", int(t * 12.0) % int(ms.n))
			var ts := sq.get_size() * 0.25   # ~40 px de largo
			var ang := direccion.angle()
			# Resplandor turquesa que late alrededor de la onda.
			var late := 0.5 + 0.5 * sin(t * 30.0)
			draw_circle(Vector2.ZERO, 6.0 + late * 2.0, Color(0.3, 0.85, 1.0, 0.10 + late * 0.06))
			draw_circle(Vector2.ZERO, 3.5, Color(0.6, 0.95, 1.0, 0.18))
			# Ecos: copias de la onda que se quedan atrás, más tenues y abiertas.
			for k in [3, 6]:
				if k < estela.size():
					var atras: Vector2 = (estela[k] - global_position).round()
					var ab: float = 1.0 + k * 0.06
					draw_set_transform(atras, ang, Vector2(1.0, ab))
					draw_texture_rect(sq, Rect2(Vector2(-ts.x * 0.8, -ts.y / 2.0), ts), false, Color(0.5, 0.9, 1.0, 0.42 - k * 0.05))
			# Onda principal: vibra (se estira y encoge a lo alto) al viajar.
			var vib := 1.0 + 0.08 * sin(t * 40.0)
			draw_set_transform(Vector2.ZERO, ang, Vector2(1.0, vib))
			draw_texture_rect(sq, Rect2(Vector2(-ts.x * 0.8, -ts.y / 2.0), ts), false)
			draw_set_transform(Vector2.ZERO)
		"abanico":
			draw_set_transform(Vector2.ZERO, direccion.angle(), Vector2.ONE)
			var e := Fx.cuadro("fx_espejo_tiro", cuadro)
			var te := e.get_size() * 0.5 * 0.55
			draw_texture_rect(e, Rect2(Vector2(-te.x * 0.8, -te.y / 2.0), te), false, Color(1, 1, 1, 0.82))
			draw_set_transform(Vector2.ZERO)
		"aros":
			if Fx.meta_o_nada("fx_aros_tiro"):
				# Aro girando (la tira ya lo muestra en distintos ángulos) con su estela.
				var gira := "fx_aros_giro" if Fx.meta_o_nada("fx_aros_giro") else "fx_aros_tiro"
				var ar := Fx.cuadro(gira, int(t * 20.0) % int(Fx.meta(gira).n))
				# Misma escala exacta que los aros que flotan junto a Diana (nítidos, mismo tamaño).
				var ta := ar.get_size() * 0.375
				# Estela: copias del aro que se desvanecen detrás.
				for k in [2, 4, 6]:
					if k < estela.size():
						var atras: Vector2 = (estela[k] - global_position).round()
						draw_texture_rect(ar, Rect2(atras - ta * 0.45, ta * 0.9), false, Color(1.0, 0.75, 0.4, 0.4 - k * 0.05))
				var org := (-ta / 2.0 + (global_position.round() - global_position)).round()
				draw_texture_rect(ar, Rect2(org, ta), false)
			else:
				draw_set_transform(Vector2.ZERO, t * 14.0, Vector2.ONE * 0.7)
				var a := Armas.textura("aros")
				draw_texture_rect(a, Rect2(-a.get_size() / 4.0, a.get_size() / 2.0), false)
				draw_set_transform(Vector2.ZERO)
		_:
			# Rayo de la lupa: la tira ya trae su estela; apunta hacia donde viaja.
			draw_set_transform(Vector2.ZERO, direccion.angle(), Vector2.ONE)
			var r := Fx.cuadro("fx_lupa_tiro", cuadro)
			var tam := r.get_size() * 0.5 * 0.62
			draw_texture_rect(r, Rect2(Vector2(-tam.x * 0.8, -tam.y / 2.0), tam), false, Color(1, 1, 1, 0.82))
			draw_set_transform(Vector2.ZERO)

func _tex(tex: Texture2D, escala: float, color := Color.WHITE) -> void:
	var tam := tex.get_size() * 0.5 * escala
	draw_texture_rect(tex, Rect2(-tam / 2.0, tam), false, color)

# Destello del color del arma sobre el enemigo golpeado.
func _impacto() -> void:
	if tipo == "roca":   # la roca se parte en pedazos con polvo y brasas
		var lanzador = get_meta("lanzador") if has_meta("lanzador") else null
		var en_piso: bool = not has_meta("pared")
		for off in [Vector2(0, 24), Vector2(0, 0), Vector2(-30, 24), Vector2(30, 24), Vector2(0, 44), Vector2(0, -20)]:
			if main.bloqueado(position + off):
				en_piso = false
		if not en_piso:   # contra la pared: se desmorona en pedazos y polvo, sin cráter
			for k in 3:
				Fx.polvo(main.mundo, position + Vector2(randf_range(-14, 14), randf_range(-6, 10)))
			Fx.chispas(main.mundo, position, Color(1.0, 0.55, 0.2), 14)
			main.sacudir(3.0)
		if lanzador != null and is_instance_valid(lanzador):
			if en_piso:
				lanzador.marca_piso("fx_gol_crater", position + Vector2(0, 24), 0.8)
			lanzador.estallido_roca(position, en_piso)
		var rg: AnimatedSprite2D = Fx.animar(main.mundo, position, "fx_gol_roca_golpe", 12.0, Color.WHITE, 1.0, direccion.x < 0.0)
		var mg := CanvasItemMaterial.new()
		mg.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		rg.material = mg
		rg.z_index = 4
		Fx.chispas(main.mundo, position, Color(1.0, 0.55, 0.2), 8)
		Fx.polvo(main.mundo, position + Vector2(0, 10))
		main.sacudir(4.0)
		return
	if tipo == "niebla":   # la niebla del Vendedor revienta en humo
		var g := Fx.animar(main.mundo, position, "fx_niebla_golpe", 12.0, Color.WHITE, 0.36, direccion.x < 0.0)
		g.rotation = direccion.angle() + (PI if direccion.x < 0.0 else 0.0)
		Fx.chispas(main.mundo, position, BRASA, 9)
		Fx.estallido(main.mundo, position, Color(BRASA, 0.7))
		var fl := _luz_nueva()   # fogonazo ámbar que se apaga
		fl.texture = Fx.textura_luz()
		fl.texture_scale = 0.5
		fl.color = BRASA
		fl.energy = 1.1
		fl.position = position
		main.mundo.add_child(fl)
		var tw := fl.create_tween()
		tw.tween_property(fl, "energy", 0.0, 0.3)
		tw.tween_callback(fl.queue_free)
		return
	var id := ""
	match tipo:
		"destello": id = "lupa"
		"perla": id = "collar"
		"abanico": id = "espejo"
		"aros": id = "aros"
		"sonica": id = "limpiador"
	if id != "":
		main.player.impacto_arma(position, id)

# Al acabarse su recorrido en el aire: estalla con el destello del arma y
# daña a los enemigos que estén cerca (radio corto).
func _explotar() -> void:
	_impacto()
	if tipo == "perla":
		Fx.chispas(main.mundo, position, Color(1.0, 0.85, 0.45), 3)
	Fx.chispas(main.mundo, position, _color(), 6)
	for e in main.enemigos():
		if position.distance_to(e.position + Vector2(0, -e.alto * 0.5)) < e.radio + 20.0 and not e in golpeados:
			e.danar(dano, (e.position - position).normalized(), false)


# Tope de luces de disparos: cada luz 2D vuelve a dibujar todo lo que alumbra y con muchas
# balas el juego se trababa. Pasando el tope se usa una luz apagada (no cuesta casi nada).
static var luces_activas := 0
const TOPE_LUCES := 10
func _luz_nueva() -> PointLight2D:
	var l := PointLight2D.new()
	if luces_activas >= TOPE_LUCES:
		l.enabled = false
		return l
	luces_activas += 1
	l.tree_exiting.connect(func(): luces_activas -= 1)
	return l
