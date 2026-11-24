# Nivel 1: Bodega del Proveedor. Arma cada cuarto, las salidas, las puertas y el HUD.
extends Node2D

const T := 32.0  # tamaño de baldosa en el mundo

# Conexiones del mapa (Bodega mapa.jpg).
const GRAFO := {
	"inicio":   {"arriba": "pelea1"},
	"pelea1":   {"abajo": "inicio", "arriba": "pelea2"},
	"pelea2":   {"abajo": "pelea1", "izquierda": "cofre", "derecha": "pelea3", "arriba": "pelea4"},
	"cofre":    {"derecha": "pelea2"},
	"pelea3":   {"izquierda": "pelea2", "derecha": "apartado", "abajo": "descanso"},
	"apartado": {"izquierda": "pelea3"},
	"descanso": {"arriba": "pelea3"},
	"pelea4":   {"abajo": "pelea2", "derecha": "jefe"},
	"jefe":     {"izquierda": "pelea4"},
}
# Hordas por cuarto: cada diccionario es una oleada (tipo: cantidad).
# La siguiente oleada sale cuando se pule la anterior, como en Soul Knight.
# Bodega: escarabajo, polilla, candado, cadena y nubecita. Mientras no existan la Mina y el
# Taller, sus enemigos (gólem, murciélago, gota, cuarzo, vagoneta, guardia, engrane, lingote
# y brillito) aparecen como refuerzos en los últimos cuartos.
var OLEADAS := {
	"pelea1": [{"escarabajo": 6, "polilla": 2}, {"escarabajo": 5, "cadena": 3, "nubecita": 2}],
	"pelea2": [{"escarabajo": 5, "polilla": 3, "cadena": 2}, {"polilla": 4, "nubecita": 3, "candado": 2}, {"escarabajo": 6, "candado": 2, "cadena": 2}],
	"pelea3": [{"polilla": 5, "candado": 2, "cadena": 2}, {"escarabajo": 5, "nubecita": 3, "candado": 2}, {"escarabajo": 6, "polilla": 3, "cadena": 3}],
	"pelea4": [{"candado": 3, "cadena": 3, "escarabajo": 4}, {"polilla": 5, "nubecita": 3, "candado": 2}, {"escarabajo": 6, "cadena": 3, "polilla": 4}],
	"jefe":   [{"vendedor": 1}, {"escarabajo": 5, "polilla": 3, "nubecita": 3}],
}
var NOMBRES := {
	"inicio": "Bodega - Andén de recepción", "pelea1": "Bodega - Pasillo de estantes",
	"pelea2": "Bodega - Zona de empaque", "cofre": "Bodega - Cofre",
	"pelea3": "Bodega - Limpiador ultrasónico", "apartado": "Bodega - Apartado",
	"descanso": "Bodega - Descanso", "pelea4": "Bodega - Almacén", "jefe": "Bodega - Patio de carga",
}
const OPUESTA := {"arriba": "abajo", "abajo": "arriba", "izquierda": "derecha", "derecha": "izquierda"}

var room_id := ""
var room: Dictionary
var limpios := {}
var usados := {}
var cerrado := false
var cambiando := false
var oleada := 0
var apareciendo := 0

var fondo: Sprite2D
var mundo: Node2D
var player
var efecto_pantalla: ColorRect
var vineta_mat: ShaderMaterial
var prisa := 0.0
var cansancio := 0.0
var cansa_sube := 0.0     # segundos que le quedan subiendo/sosteniéndose
var cansa_desde := 0.0    # momento en que empezó (para que las gotas resbalen)

# Sin esquives: la pantalla se empaña poco a poco, se sostiene y luego se seca despacio.
func cansar() -> void:
	if cansa_sube <= 0.0 and cansancio <= 0.05:
		cansa_desde = Time.get_ticks_msec() / 1000.0
	cansa_sube = 3.2
var quilate
var camara: Camera2D
var puertas: Array = []
var hud: CanvasLayer
var hud_ui
var visitados := {}
var destellos := 0
var hud_cuarto: Label
var hud_msg: Label
var msg_t := 0.0
var fin := false
var dano_t := 0.0      # borde rojo al recibir daño
var pulidos := 0
var tiempo := 0.0
var jefe = null
var piso_piedra: Sprite2D
var racha := 0            # enemigos pulidos seguidos (se corta si pasan 2.5 s)
var racha_t := 0.0
var herido_sala := false  # para ¡IMPECABLE!
var _logro_actual: Node = null
var _logro_desde := 0
var _logro_pendiente := ""
var muros: Array = []   # piedra nueva encima de las paredes dibujadas en el cuarto
var bloques_dyn := {}  # celdas ocupadas por cajas, jarrones y barriles que se rompen
var flecha: Node2D
var luces: Array = []
var cambio_t := 0.0       # muestra el objeto nuevo en grande al cambiar con Q
var sin_brillo_t := 0.0   # la barra de brillo parpadea cuando no alcanza
var tinte_t := 0.0        # tinte dorado al limpiar un cuarto
var gemas_tomadas := {}
var gema_pos := {}
var apartado_activo := false
var burbuja_t := 0.0
var ambiente: Array = []   # partículas del cuarto (polvo en el aire, llamas)
var sombras: Node2D
var cortina: ColorRect
# Cuartos con antorchas en la pared de arriba (posición x relativa al cuarto).
# Tina del limpiador ultrasónico (zona de agua) y mostrador del Apartado, en coordenadas del mundo.
var TINAS := {}   # tina de piedra del cuarto (la pone mueble.gd)
const MOSTRADOR := Rect2(259, 208, 233, 146)
# Gemas ocultas de la Bodega (libreto: 5 por escenario), una por cuarto.
var GEMAS_CUARTO := {"pelea1": "cuarzo", "pelea2": "amatista", "cofre": "topacio", "descanso": "zirconia", "pelea4": "ópalo"}
const ANTORCHAS := {"inicio": [0.27, 0.73], "cofre": [0.24, 0.66], "apartado": [0.2, 0.86], "descanso": [0.28, 0.73]}

func _ready() -> void:
	if Juego.foto == "juego":
		# Solo pruebas: captura del primer cuarto y sale.
		get_tree().create_timer(2.5).timeout.connect(func():
			player.position = Vector2(interior().position.x + 140.0, interior().position.y + 20.0))
		get_tree().create_timer(6.75).timeout.connect(func(): get_tree().paused = false; logro("triple", true))
		get_tree().create_timer(7.0).timeout.connect(func():
			get_viewport().get_texture().get_image().save_png("user://foto_juego.png")
			get_tree().quit())
	Anim.load_data()
	fondo = Sprite2D.new()
	fondo.centered = false
	fondo.scale = Vector2(0.5, 0.5)
	fondo.z_index = -10  # el piso hasta abajo: sombras y polvo (capa -1) quedan encima de él
	add_child(fondo)
	# Piso de piedra que se repite encima del piso dibujado en el cuarto.
	piso_piedra = Sprite2D.new()
	_configurar_nivel()
	piso_piedra.texture = load("res://assets/objetos/%s.png" % NIVEL_DATOS[nivel].piso)
	piso_piedra.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	piso_piedra.region_enabled = true
	piso_piedra.centered = false
	piso_piedra.z_index = -10
	piso_piedra.modulate = Color(1.15, 1.08, 1.0) if nivel == 1 else Color.WHITE   # un poco más cálido y claro, como la piedra de la puerta con antorchas
	add_child(piso_piedra)
	sombras = Sombras.new()
	sombras.main = self
	sombras.z_index = -9
	add_child(sombras)
	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	player = preload("res://scripts/player.gd").new()
	player.main = self
	mundo.add_child(player)
	quilate = preload("res://scripts/quilate.gd").new()
	quilate.target = player
	mundo.add_child(quilate)
	camara = Camera2D.new()
	camara.zoom = Vector2(2.0, 2.0)  # entero: cada pixel del sprite cae en pixeles exactos de pantalla
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 7.0
	player.add_child(camara)
	# Cuartos en penumbra: Diana y las antorchas llevan luz.
	var penumbra := CanvasModulate.new()
	penumbra.color = Color(0.48, 0.45, 0.54)   # mazmorra: casi todo en sombra, solo las luces alumbran
	add_child(penumbra)
	# La penumbra respira: a ratos baja la luz como si algo pasara cerca.
	var tw := penumbra.create_tween().set_loops()
	tw.tween_property(penumbra, "color", Color(0.43, 0.40, 0.49), 3.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(penumbra, "color", Color(0.50, 0.47, 0.56), 4.0).set_trans(Tween.TRANS_SINE)
	flecha = Flecha.new()
	flecha.main = self
	flecha.z_index = 50   # encima del piso, los muebles y Diana
	add_child(flecha)
	_crear_hud()
	cargar_cuarto("inicio", "")
	if not OS.get_cmdline_user_args().has("--captura") and not OS.get_cmdline_user_args().has("--vitrina"):
		dialogo.call_deferred("inicio")
	# Solo para pruebas: godot -- --captura <cuarto> guarda una imagen y cierra.
	var args := OS.get_cmdline_user_args()
	# Solo para pruebas: empuja a Diana contra cada pared y reporta si se sale del cuarto.
	if args.has("--muros"):
		for id in GRAFO:
			cargar_cuarto(id, "")
			cerrado = true
			var r: Array = room.rect
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(1, 1).normalized(), Vector2(-1, -1).normalized()]:
				var p: Vector2 = interior().get_center()
				for i in 600:
					p = mover(p, d * 7.0)
				var fuera: bool = p.x < r[0] or p.x > r[2] or p.y < r[1] or p.y > r[3]
				print("MURO ", id, " ", d, " ", p.round(), " FUERA" if fuera else "")
		get_tree().quit()
		return
	# Solo para pruebas: godot -- --vitrina <tipo> muestra al enemigo en cada animación junto a Diana.
	if args.size() >= 2 and args[0] == "--vitrina":
		cargar_cuarto("inicio", "")
		await get_tree().create_timer(0.5).timeout
		var tipo: String = args[1]
		var nombres: Array = preload("res://scripts/enemy.gd").TIPOS[tipo].anims.keys()
		for i in nombres.size():
			var e = aparecer_ya(tipo, player.position + Vector2((i - (nombres.size() - 1) / 2.0) * 80.0, 90.0))
			await get_tree().process_frame
			e.set_physics_process(false)
			e.set_process(false)
			e.sprite.play(nombres[i])
			e.sprite.scale = Vector2.ONE * e.escala_actual   # sin _process: la escala de esa animación se pone aquí
			if args.has("--ver"):
				# Galería: cada animación se repite sola con su nombre encima.
				e.sprite.sprite_frames.set_animation_loop(nombres[i], true)
				var etiqueta := Label.new()
				etiqueta.text = {"mover": "caminar", "pulir": "pulido", "dano": "daño", "embiste": "embestir", "prepara": "prepararse", "frena": "frenar", "ataque": "ataque", "reposo": "reposo"}.get(nombres[i], nombres[i])
				etiqueta.add_theme_font_size_override("font_size", 8)
				etiqueta.position = Vector2(-20, -50)
				e.add_child(etiqueta)
				continue
			e.sprite.frame = mini(1, e.sprite.sprite_frames.get_frame_count(nombres[i]) - 1)
			e.sprite.pause()
			var tx: Texture2D = e.sprite.sprite_frames.get_frame_texture(nombres[i], 0)
			print("VITRINA ", nombres[i], " ", tx.atlas.resource_path, " ", tx.atlas.get_size(), " escala ", e.sprite.scale)
		if args.has("--ver"):
			return  # se queda abierta para verla
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png("user://vitrina_%s.png" % tipo)
		get_tree().quit()
		return
	if args.size() >= 2 and args[0] == "--captura":
		cargar_cuarto(args[1], "abajo" if Anim.data.rooms[args[1]].exits.has("abajo") else "")
		if args.has("--jugar"):   # prueba: abre el cuarto y deja jugar
			return
		if args.has("--todo"):   # prueba: ve el cuarto completo
			hud.visible = false
			camara.limit_left = -100000; camara.limit_top = -100000; camara.limit_right = 100000; camara.limit_bottom = 100000
			camara.zoom = camara.zoom * (0.3 if args.has("--lejos") else 0.45)
			player.position = interior().get_center()
			camara.reset_smoothing()
		if args.has("--fin"):   # prueba: pantalla final o de victoria
			if args.has("--n2"):
				_pantalla("¡Recuperaste el Anillo Alborada!", "Nueva habilidad: Impulso de luz
(el esquive dura más y atraviesa la niebla)

Destellos: 266
Gemas ocultas: 1 / 5
Enemigos pulidos: 135
Tiempo: 6:54", Ui.DORADO,
					[["Continuar", func(): Juego.siguiente_nivel()], ["Menú principal", Juego.ir_al_menu]], [1])
				if args.has("--continuar"):   # prueba: presiona Enter y revisa que cargue el nivel 2
					await get_tree().create_timer(2.0, true, false, true).timeout
					get_viewport().get_texture().get_image().save_png("user://captura_fin.png")
					var foco := get_viewport().gui_get_focus_owner()
					print("FOCO ", foco, " ", foco.text if foco is Button else "")
					foco.pressed.emit()
					await get_tree().create_timer(5.0, true, false, true).timeout
					print("NIVEL TRAS CONTINUAR ", Juego.nivel_actual + 1, " escena ", get_tree().current_scene.name)
					get_tree().quit()
					return
			else:
				_pantalla("Fin", "Diana recuperó las tres joyas y el brillo de la tienda.

Gracias por jugar.", Ui.CHAMPAN, [["Menú principal", Juego.ir_al_menu]], [1, 2, 3], true)
			await get_tree().create_timer(2.5, true, false, true).timeout
			get_viewport().get_texture().get_image().save_png("user://captura_fin.png")
			get_tree().quit()
			return
		if args.has("--arriba"):   # prueba: Diana junto a la pared de arriba (ver los objetos)
			player.position = Vector2(interior().get_center().x + (120.0 if args.has("--der") else -120.0 if args.has("--izq") else 0.0), interior().position.y + 90.0)
			camara.reset_smoothing()
		var ia := args.find("--arma")
		if ia >= 0:   # prueba: Diana con un arma en la mano
			player.armas = [args[ia + 1]]
			player.actual = 0
		if args.has("--correr_disparar"):   # prueba: camina disparando, suelta todo y registra la animación
			await _prueba_correr()
		if args.has("--destello"):   # prueba: Destello de joyera justo antes de la foto
			get_tree().create_timer(2.15).timeout.connect(func(): player.energia = 100.0; player.destello_joyera())
		for prueba in ["--tomar", "--curar", "--herir", "--energia"]:   # prueba: anima a Diana justo antes de la foto
			if args.has(prueba):
				get_tree().create_timer(2.15).timeout.connect(_prueba_diana.bind(prueba))
		if args.has("--tina") and TINAS.has(room_id):   # prueba: junto a la piscina
			player.position = TINAS[room_id].get_center() + Vector2(0, 70)
			camara.reset_smoothing()
		if args.has("--muebles"):   # prueba: lista los objetos del cuarto, les pega 3 veces y dice si se rompieron
			await get_tree().create_timer(0.5).timeout
			for m in mundo.get_children():
				if m.get("img") != null and m.img != "":
					for i in 3:
						m.golpear(1)
					print("MUEBLE ", m.img.get_file(), " vida=", m.vida, " roto=", m.roto, " pisable=", m.pisable)
		if args.has("--romper"):   # prueba: rompe los muebles y retrata los restos
			var ms := rompibles().filter(func(r): return r.has_method("toca"))
			print("muebles ", ms.map(func(r): return r.tipo))
			if not ms.is_empty():
				player.position = ms[0].position + Vector2(0, 40)
				camara.reset_smoothing()
			await get_tree().create_timer(1.0).timeout
			for r in ms:
				r.golpear(9)
		await get_tree().create_timer(2.5).timeout
		print("FPS ", Engine.get_frames_per_second(), " enemigos ", enemigos().size())
		print("proceso ms ", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, " draw ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objetos ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " nodos ", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		get_viewport().get_texture().get_image().save_png("user://captura_%s.png" % args[1])
		get_tree().quit()

func _prueba_diana(prueba: String) -> void:
	if prueba == "--tomar":
		player.alegria()
	elif prueba == "--energia":
		player.alegria(Color(0.35, 0.65, 1.0))
	elif prueba == "--curar":
		player.vida -= 1
		player.curar(1)
	else:
		player.herir(1, Vector2(-1, 0))

# ---------- cuartos ----------

func cargar_cuarto(id: String, entrada: String) -> void:
	room_id = id
	room = Anim.data.rooms[id]
	fondo.texture = load("res://assets/rooms/%s.png" % id)
	var zp := interior()
	piso_piedra.position = zp.position.round()
	piso_piedra.region_rect = Rect2(zp.position.round(), (zp.size + Vector2(0, 6)).round())
	_cargar_bloques()
	bloques_dyn.clear()
	TINAS.clear()
	jefe = null
	for l in luces:
		l.queue_free()
	luces.clear()
	_poner_muros()
	_poner_antorchas(id)
	_poner_ambiente(id)
	_poner_decoracion()
	sombras.queue_redraw()
	_musica_cuarto()
	visitados[id] = true
	for n in mundo.get_children():
		if n != player and n != quilate:
			n.queue_free()
	for p in puertas:
		p.queue_free()
	puertas.clear()
	puertas_candado.clear()
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = int(room.size[0])
	camara.limit_bottom = int(room.size[1])
	player.position = _punto_entrada(entrada)
	quilate.position = player.position + Vector2(-20, -30)
	player.vel = Vector2.ZERO
	player.reset_physics_interpolation()
	quilate.reset_physics_interpolation()
	camara.reset_smoothing()
	hud_cuarto.text = NOMBRES[id]
	cerrado = false
	oleada = 0
	if nivel == 1:
		_poner_muebles(id)
	else:
		_poner_objetos_nivel(id)
	if OLEADAS.has(id) and not limpios.has(id):
		_cerrar_puertas()
		_poner_rompibles()
		_lanzar_oleada()
	_poner_gema(id)
	_eventos_cuarto()
	# Primer cuarto: todas las armas en el piso para elegir (solo la primera vez).
	if id == "inicio" and not has_meta("armas_puestas"):
		set_meta("armas_puestas", true)
		# Al empezar solo está la Lupa de Aurelio; las demás armas salen de los cofres.
		var todas := ["lupa"].filter(func(a): return not a in player.armas)
		var c := interior().get_center() + Vector2(0, 40)
		for i in todas.size():
			soltar("arma", c + Vector2((i - (todas.size() - 1) / 2.0) * 52.0, 0), todas[i])
	if PRUEBAS and id == "inicio":
		_poner_pruebas()

# ---------- modo de pruebas (quitar al terminar: PRUEBAS = false) ----------
# En el primer cuarto: corazones y pociones para ver curación y energía, muebles para romper,
# la piscina, y la tecla H para recibir daño.
const PRUEBAS := false

func _poner_pruebas() -> void:
	var z := interior()
	var c := z.get_center()
	for i in 3:
		soltar("corazon", c + Vector2(-150 + i * 22, -50))
		soltar("pocion", c + Vector2(110 + i * 22, -50))
	var puestos: Array = []
	var arriba := z.position.y + 22.0
	var x := z.position.x + 60.0
	for t in ["caja", "barril", "barril_joyas", "estante", "vitrina", "cofre", "columna"]:
		_mueble(t, Vector2(x, arriba), puestos)
		x += 56.0
	_mueble("tina", Vector2(z.end.x - 90.0, c.y + 30.0), puestos)
	mensaje("PRUEBAS: corazones y pociones arriba, muebles para romper, H = recibir daño", 6.0)

func _unhandled_key_input(e: InputEvent) -> void:
	if PRUEBAS and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_H:
		player.invulnerable = 0.0
		# prueba: el golpe llega de frente (hacia donde mira Diana), la empuja hacia atrás
		player.herir(1, Vector2(1.0 if player.sprite.flip_h else -1.0, 0.0))
		if player.vida <= 1:
			player.vida = player.vida_max

func _punto_entrada(entrada: String) -> Vector2:
	var r: Array = room.rect
	if entrada == "":
		return Vector2((r[0] + r[2]) / 2.0, (r[1] + r[3]) / 2.0 + T * 2)
	var c: float = room.exits[entrada]
	match entrada:
		"arriba": return Vector2(c, r[1] + T * 4.4)
		"abajo": return Vector2(c, r[3] - T * 1.4)
		"izquierda": return Vector2(r[0] + T * 1.8, c + T * 0.5)
		_: return Vector2(r[2] - T * 1.8, c + T * 0.5)

func interior() -> Rect2:
	var r: Array = room.rect
	# Abajo se deja libre la cara del muro inferior (en la vista 3/4 se dibuja sobre el piso).
	# Arriba el piso empieza bajo la moldura del panel de madera (los pies no suben a la pared).
	return Rect2(Vector2(r[0] + T, r[1] + T * 3.55), Vector2(r[2] - r[0] - T * 2, r[3] - r[1] - T * 5.25))

func _salida_abierta(dir: String) -> bool:
	return not cerrado and GRAFO[room_id].has(dir) and room.exits.has(dir) and _candado(dir) == ""

# Orden de los cuartos: sin objeto no se sale del primero, y al jefe solo se entra con
# todos los cuartos de pelea limpios. Devuelve el aviso ("" si se puede pasar).
func _candado(dir: String) -> String:
	if not GRAFO[room_id].has(dir):
		return ""
	var destino: String = GRAFO[room_id][dir]
	if room_id == "inicio" and player != null and player.armas.is_empty():
		return "Primero escoge un objeto del mostrador (acércate y presiona F)."
	if destino == "jefe":
		var faltan := 0
		for id in OLEADAS:
			if id != "jefe" and not limpios.has(id):
				faltan += 1
		if faltan > 0:
			return "La puerta del jefe no abre: faltan %d cuarto%s por limpiar." % [faltan, "" if faltan == 1 else "s"]
	return ""

# Aviso cuando Diana se acerca a una salida con candado (una vez cada pocos segundos).
var _aviso_t := 0.0
# La puerta cerrada es sólida: sus celdas se bloquean (nadie se para encima ni pasa debajo).
func _solida(s: AnimatedSprite2D, si: bool) -> void:
	var tex: Texture2D = s.sprite_frames.get_frame_texture(s.animation, 0)
	var tam: Vector2 = tex.get_size() * s.scale.abs()
	if absf(s.rotation) > 0.1:
		tam = Vector2(tam.y, tam.x)
	var r := Rect2(s.position - tam / 2.0, tam)
	for cx in range(int(floor(r.position.x / 16.0)), int(ceil(r.end.x / 16.0))):
		for cy in range(int(floor(r.position.y / 16.0)), int(ceil(r.end.y / 16.0))):
			if si:
				bloques_dyn[Vector2i(cx, cy)] = true
			else:
				bloques_dyn.erase(Vector2i(cx, cy))

var puertas_candado := {}   # dir -> puerta cerrada mientras falta algo
func _puertas_con_candado() -> void:
	if cambiando or room.is_empty():
		return
	var r: Array = room.rect
	for d in GRAFO[room_id]:
		if not room.exits.has(d):
			continue
		var con := _candado(d) != ""
		if con and not puertas_candado.has(d):
			var c: float = room.exits[d]
			var s := Anim.sprite({"abrir": ["door", 12, false]}, "abrir")
			s.offset = Vector2.ZERO
			s.stop()
			s.frame = 0   # cerrada
			match d:
				"arriba": s.position = Vector2(c, r[1] + T * 2.2)
				"abajo": s.position = Vector2(c, r[3] - T * 0.4)
				"izquierda":
					s.position = Vector2(r[0] + T * 0.4, c)
					s.rotation = -PI / 2
				"derecha":
					s.position = Vector2(r[2] - T * 0.4, c)
					s.rotation = PI / 2
			add_child(s)
			puertas.append(s)
			puertas_candado[d] = s
			_solida(s, true)
		elif not con and puertas_candado.has(d):
			var s: AnimatedSprite2D = puertas_candado[d]
			puertas_candado.erase(d)
			if is_instance_valid(s):
				_solida(s, false)
				Juego.sonido("puerta_abrir", false)
				s.play("abrir")
				s.animation_finished.connect(func(): s.visible = false)

func _avisar_candado(delta: float) -> void:
	_puertas_con_candado()
	_aviso_t -= delta
	if cerrado or cambiando or player == null or _aviso_t > 0.0:
		return
	var r: Array = room.rect
	var p: Vector2 = player.position
	for d in GRAFO[room_id]:
		if not room.exits.has(d):
			continue
		var aviso := _candado(d)
		if aviso == "":
			continue
		var c: float = room.exits[d]
		var puerta: Vector2 = {"arriba": Vector2(c, interior().position.y), "abajo": Vector2(c, interior().end.y),
			"izquierda": Vector2(interior().position.x, c), "derecha": Vector2(interior().end.x, c)}[d]
		if p.distance_to(puerta) < 70.0:
			mensaje(aviso, 2.5)
			_aviso_t = 3.0
			return

# Rectángulo del pasillo de una salida (por donde sí se puede pasar).
func _canal(dir: String) -> Rect2:
	var r: Array = room.rect
	var c: float = room.exits[dir]
	match dir:
		"arriba": return Rect2(c - T * 1.1, r[1] - T * 3, T * 2.2, T * 7)   # llega hasta el piso del cuarto
		"abajo": return Rect2(c - T * 1.1, r[3] - T * 2, T * 2.2, T * 5)
		"izquierda": return Rect2(r[0] - T * 3, c - T * 0.6, T * 5, T * 2.0)
		_: return Rect2(r[2] - T * 2, c - T * 0.6, T * 5, T * 2.0)

var bloques := {}  # celdas de 16 px ocupadas por cajas, estantes, tina...

func _cargar_bloques() -> void:
	bloques.clear()
	# Solo los muros: los muebles dibujados en el cuarto viejo ya no están (piso de piedra limpio).
	var zona := interior().grow(-2.0)
	for c in room.get("bloques", []):
		var cel := Vector2i(int(c[0]), int(c[1]))
		if not zona.has_point(Vector2(cel) * 16.0 + Vector2(8, 8)):
			bloques[cel] = true

func bloqueado(p: Vector2) -> bool:
	var c := Vector2i(int(p.x / 16.0), int(p.y / 16.0))
	return bloques.has(c) or bloques_dyn.has(c)

func permitido(p: Vector2) -> bool:
	if bloqueado(p):
		return false
	if interior().has_point(p):
		return true
	for d in OPUESTA:
		if _salida_abierta(d) and _canal(d).has_point(p):
			return true
	return false

# Revisa toda la huella de los pies (no solo un punto), para que el cuerpo no se meta en cajas ni muros.
func cabe(p: Vector2, ancho := 0.0) -> bool:
	if ancho <= 0.0:
		return permitido(p)
	for o in [Vector2(-ancho, 0), Vector2(ancho, 0), Vector2(-ancho, -6), Vector2(ancho, -6), Vector2(0, 2), Vector2(0, -6)]:
		if not permitido(p + o):
			return false
	return true

# Mueve respetando muros, eje por eje para poder deslizarse.
func mover(desde: Vector2, delta_pos: Vector2, ancho := 0.0) -> Vector2:
	var p := desde
	# Si quedó fuera del área (p. ej. en la puerta cuando se cierra), puede caminar hacia adentro.
	if not permitido(p):
		var centro := interior().get_center()
		var nueva := p + delta_pos
		return nueva if nueva.distance_to(centro) < p.distance_to(centro) else p
	if ancho > 0.0 and not cabe(p, ancho):
		ancho = 0.0  # si ya quedó encimado (al aparecer), que pueda salir
	if cabe(Vector2(p.x + delta_pos.x, p.y), ancho):
		p.x += delta_pos.x
	if cabe(Vector2(p.x, p.y + delta_pos.y), ancho):
		p.y += delta_pos.y
	return p

var temblor := 0.0

# Sacude la cámara; los golpes fuertes sacuden más.
var temblor_dir := Vector2.ZERO
var temblor_t := 0.0

# Sacude la cámara; con dirección, el primer empujón va hacia ese lado.
func sacudir(fuerza: float, dir := Vector2.ZERO) -> void:
	if fuerza >= temblor:
		temblor_dir = dir.normalized()
	temblor = maxf(temblor, fuerza)

func _process(delta: float) -> void:
	if vineta_mat:
		vineta_mat.set_shader_parameter("tiempo", Time.get_ticks_msec() / 1000.0)
	if efecto_pantalla and player:
		var quiere := 1.0 if player.impulso_t > 0.0 else (0.45 if player.andaba else 0.0)
		prisa = lerpf(prisa, quiere, 1.0 - exp(-(10.0 if quiere > prisa else 4.0) * delta))
		if cansa_sube > 0.0:
			cansa_sube -= delta
			cansancio = minf(cansancio + delta / 1.4, 1.0)   # se empaña en ~1.4 s
		else:
			cansancio = maxf(cansancio - delta / 6.0, 0.0)   # se seca en ~6 s
		var mt: ShaderMaterial = efecto_pantalla.material
		mt.set_shader_parameter("prisa", prisa)
		mt.set_shader_parameter("cansancio", smoothstep(0.0, 1.0, cansancio))
		mt.set_shader_parameter("desliza", (Time.get_ticks_msec() / 1000.0 - cansa_desde) * 0.012)
		# Secuencia: 0-3 mientras sube el cansancio, luego 3-5 en bucle mientras sigue cansada.
		var seg := Time.get_ticks_msec() / 1000.0 - cansa_desde
		var cu := minf(seg * 2.2, 3.0) if seg < 1.4 else 3.0 + fmod((seg - 1.4) * 1.6, 3.0)
		mt.set_shader_parameter("cuadro", cu * clampf(cansancio * 1.5, 0.0, 1.0))
		mt.set_shader_parameter("tiempo", Time.get_ticks_msec() / 1000.0)
		efecto_pantalla.visible = prisa > 0.01 or cansancio > 0.0
	if Engine.time_scale > 0.0 and Engine.time_scale < 1.0 and Time.get_ticks_msec() >= _pausa_hasta:
		Engine.time_scale = 1.0
	# La cámara se adelanta un poco hacia donde apunta el mouse.
	var mira: Vector2 = (get_global_mouse_position() - player.global_position).limit_length(260.0) * 0.18
	camara.position = camara.position.lerp(mira, 1.0 - exp(-6.0 * delta))
	# Sacudida suave en pixeles enteros: oscila (no salta al azar) y se apaga.
	temblor_t += delta
	var osc := Vector2(sin(temblor_t * 47.0), sin(temblor_t * 39.0 + 1.3))
	camara.offset = (osc * 0.7 + temblor_dir * 0.6) * temblor
	camara.offset = camara.offset.round()
	temblor = move_toward(temblor, 0.0, (10.0 + temblor * 6.0) * delta)
	if temblor <= 0.0:
		temblor_dir = Vector2.ZERO
	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0:
			hud_msg.text = ""
	dano_t = maxf(dano_t - delta, 0.0)
	cambio_t = maxf(cambio_t - delta, 0.0)
	sin_brillo_t = maxf(sin_brillo_t - delta, 0.0)
	tinte_t = maxf(tinte_t - delta, 0.0)
	# Burbujas que suben de la tina.
	if TINAS.has(room_id):
		burbuja_t -= delta
		if burbuja_t <= 0.0:
			burbuja_t = 0.35
			var t: Rect2 = TINAS[room_id]
			Fx.burbujas(mundo, Vector2(randf_range(t.position.x + 4, t.end.x - 4), randf_range(t.position.y + 2, t.end.y - 2)), 1, 1.0)
	if fin:
		return
	tiempo += delta
	_revisar_salidas()
	if cerrado and apareciendo == 0 and _enemigos_vivos() == 0:
		if oleada < OLEADAS[room_id].size():
			_lanzar_oleada()
		else:
			limpios[room_id] = true
			_abrir_puertas()
			if room_id != "jefe":
				_musica_cuarto()
			if room_id == "jefe":
				logro("jefe", true)
				_victoria()
			else:
				logro("sala" if herido_sala else "impecable", true)
				Juego.sonido("oleada", false)
				tinte_t = 0.6
				# Cofre de recompensa al centro del cuarto.
				var c := interior().get_center()
				while bloqueado(c):
					c.y += 16
				soltar("cofre", c)
	_actualizar_hud()

func _revisar_salidas() -> void:
	if cambiando:
		return
	_avisar_candado(get_process_delta_time())
	var r: Array = room.rect
	var p: Vector2 = player.position
	var dir := ""
	if p.y < r[1] + T * 0.3:
		dir = "arriba"
	elif p.y > r[3] + T * 0.6:
		dir = "abajo"
	elif p.x < r[0] - T * 0.3:
		dir = "izquierda"
	elif p.x > r[2] + T * 0.3:
		dir = "derecha"
	if dir != "" and GRAFO[room_id].has(dir) and _candado(dir) == "":
		_transicion(GRAFO[room_id][dir], OPUESTA[dir])

# Cortinilla circular que se cierra sobre Diana y se vuelve a abrir en el cuarto nuevo.
const CORTINA := """shader_type canvas_item;
uniform vec2 centro = vec2(480.0, 270.0);
uniform float radio = 600.0;
uniform vec2 tam = vec2(960.0, 540.0);
void fragment() {
	float d = distance(UV * tam, centro);
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(radio - 2.0, radio + 2.0, d));
}"""

func _centro_diana() -> Vector2:
	return player.get_global_transform_with_canvas().origin + Vector2(0, -20)

func _transicion(destino: String, entrada: String) -> void:
	cambiando = true
	if cortina == null:
		cortina = ColorRect.new()
		cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
		cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = Shader.new()
		m.shader.code = CORTINA
		cortina.material = m
		hud.add_child(cortina)
	var mat: ShaderMaterial = cortina.material
	cortina.visible = true
	mat.set_shader_parameter("centro", _centro_diana())
	var tw := create_tween()
	tw.tween_method(func(r): mat.set_shader_parameter("radio", r), 620.0, 0.0, 0.28).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		cargar_cuarto(destino, entrada)
		mat.set_shader_parameter("centro", _centro_diana()))
	tw.tween_interval(0.05)
	tw.tween_method(func(r): mat.set_shader_parameter("radio", r), 0.0, 620.0, 0.32).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		cortina.visible = false
		cambiando = false)

func _eventos_cuarto() -> void:
	if room_id == "inicio" and player.armas.is_empty():
		# Las armas para escoger ya las pone _entrar (todas en una fila).
		mensaje("Escoge un objeto del mostrador: acércate y presiona F.", 4.0)
	elif room_id == "cofre" and not usados.has("cofre"):
		usados["cofre"] = true
		# El cofre del cuarto especial siempre trae un arma.
		var libres: Array = Armas.BODEGA.filter(func(a): return not a in player.armas)
		soltar("arma", interior().get_center() + Vector2(0, 30), libres.pick_random() if libres.size() > 0 else "espejo")
		mensaje("¡Un arma nueva! Acércate y presiona F.", 3.0)
	elif room_id == "apartado":
		if apartado_activo:
			mensaje("Tu Apartado está activo: si pierdes, vuelves aquí.", 2.5)
		else:
			mensaje("Apartado: presiona F en el mostrador y deja 10 destellos de anticipo.", 3.5)
	elif room_id == "descanso" and not usados.has("descanso"):
		usados["descanso"] = true
		dialogo("descanso")
	elif room_id == "jefe" and not limpios.has("jefe"):
		dialogo("jefe_entrada")

# ---------- enemigos y puertas ----------

func _lanzar_oleada() -> void:
	var total: int = OLEADAS[room_id].size()
	var grupo: Dictionary = OLEADAS[room_id][oleada]
	if oleada == 0:
		_musica_cuarto(true)
		herido_sala = false   # empieza la pelea de la sala: cuenta para ¡IMPECABLE!
	oleada += 1
	if total > 1:
		mensaje("Oleada %d de %d" % [oleada, total], 1.5)
	if oleada > 1:
		Juego.sonido("oleada", false)
	var zona := interior().grow(-T)
	for tipo in grupo:
		var cuantos := int(grupo[tipo])
		if tipo != "vendedor":
			cuantos = maxi(1, roundi(cuantos * Juego.dif().cantidad))   # dificultad
		for i in cuantos:
			var pos: Vector2 = player.position
			var intentos := 0
			while (pos.distance_to(player.position) < T * 5 or bloqueado(pos)) and intentos < 30:
				pos = Vector2(randf_range(zona.position.x, zona.end.x), randf_range(zona.position.y, zona.end.y))
				intentos += 1
			if tipo == NIVEL_DATOS[nivel].jefe and room_id == "jefe":
				pos = Vector2(zona.get_center().x, zona.position.y + T * 3)
			_aparecer(tipo, pos, randf() * 0.5)

# Antes de salir, cada enemigo marca su lugar con un círculo que avisa al jugador.
var _solo_puesto := 0
func _aparecer(tipo: String, pos: Vector2, espera: float) -> void:
	var a_solo := OS.get_cmdline_user_args().find("--solo")
	if a_solo >= 0:   # prueba: solo los tipos pedidos, uno de cada uno (separados por coma)
		var tipos: PackedStringArray = OS.get_cmdline_user_args()[a_solo + 1].split(",")
		if _solo_puesto >= tipos.size():
			return
		tipo = tipos[_solo_puesto]
		_solo_puesto += 1
	apareciendo += 1
	var marca := preload("res://scripts/marca.gd").new()
	marca.position = pos
	marca.color = COLOR_PORTAL.get(nivel, Color(0.75, 0.45, 1.0))
	mundo.add_child(marca)
	await get_tree().create_timer(0.8 + espera).timeout
	if not is_instance_valid(marca):
		apareciendo -= 1
		return
	marca.queue_free()
	var e = preload("res://scripts/enemy.gd").new()
	e.tipo = tipo
	e.main = self
	e.objetivo = player
	e.position = pos
	if tipo == NIVEL_DATOS[nivel].jefe and room_id == "jefe":
		e.set_meta("jefe", true)
	mundo.add_child(e)
	if e.has_meta("jefe"):
		jefe = e
	else:
		_efecto_aparicion(e)
	apareciendo -= 1

# El jefe llama refuerzos al instante (sin marca previa).
func aparecer_ya(tipo: String, pos: Vector2):
	var e = preload("res://scripts/enemy.gd").new()
	e.tipo = tipo
	e.main = self
	e.objetivo = player
	e.position = pos
	mundo.add_child(e)
	_efecto_aparicion(e)
	return e

# Color del portal de aparición en cada nivel (bodega morado, mina rosa cuarzo, taller ámbar).
const COLOR_PORTAL := {1: Color(0.75, 0.45, 1.0), 2: Color(1.0, 0.5, 0.8), 3: Color(1.0, 0.65, 0.3)}

# El enemigo sale del portal: destello, columna de luz, chispas y entra creciendo desde transparente.
func _efecto_aparicion(e) -> void:
	var col: Color = COLOR_PORTAL.get(nivel, Color(0.75, 0.45, 1.0))
	var pos: Vector2 = e.position
	Fx.estallido(mundo, pos + Vector2(0, -12), col)
	Fx.chispas(mundo, pos + Vector2(0, -16), col.lightened(0.3), 12)
	var columna := Columna.new()
	columna.position = pos
	columna.color = col
	columna.z_index = 20
	mundo.add_child(columna)
	var s: Node2D = e.get("sprite")
	if s:
		var esc := s.scale
		s.modulate.a = 0.0
		s.scale = esc * Vector2(0.4, 1.4)
		var tw := s.create_tween().set_parallel(true)
		tw.tween_property(s, "modulate:a", 1.0, 0.25)
		tw.tween_property(s, "scale", esc, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

class Columna extends Node2D:
	var t := 0.0
	var color := Color.WHITE
	func _process(delta: float) -> void:
		t += delta
		if t > 0.4:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		var k := t / 0.4
		var ancho := 22.0 * (1.0 - k)
		draw_rect(Rect2(-ancho / 2.0, -90.0, ancho, 90.0), Color(color, 0.45 * (1.0 - k)))
		draw_rect(Rect2(-ancho / 5.0, -90.0, ancho / 2.5, 90.0), Color(1, 1, 1, 0.6 * (1.0 - k)))

var _cuadro_romp := -1
var _lista_romp: Array = []
# Se calcula una vez por cuadro (los disparos la piden muchas veces y recorrer todo el mundo trababa el juego).
func rompibles() -> Array:
	var cuadro := Engine.get_physics_frames() * 2 + Engine.get_process_frames()
	if cuadro != _cuadro_romp:
		_cuadro_romp = cuadro
		_lista_romp = mundo.get_children().filter(func(c): return c.has_method("golpear") and not c.is_queued_for_deletion())
	return _lista_romp.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion())

# Deja algo en el piso: destello, corazon, pocion, arma o cofre.
func soltar(tipo: String, pos: Vector2, arma := "") -> void:
	var p = preload("res://scripts/pickup.gd").new()
	p.main = self
	p.tipo = tipo
	p.arma = arma
	p.position = pos
	mundo.call_deferred("add_child", p)

# Cajas, jarrones y barriles repartidos en las orillas del cuarto.
func _poner_rompibles() -> void:
	var zona := interior()
	var puestos := 0
	var intentos := 0
	while puestos < 4 and intentos < 80:
		intentos += 1
		var lado := randi() % 4
		var p := Vector2(randf_range(zona.position.x + 24, zona.end.x - 24), randf_range(zona.position.y + 24, zona.end.y - 8))
		match lado:
			0: p.y = zona.position.y + 22
			1: p.y = zona.end.y - 24
			2: p.x = zona.position.x + 22
			3: p.x = zona.end.x - 22
		if bloqueado(p) or p.distance_to(player.position) < 80.0:
			continue
		var cerca_salida := false
		for d in room.exits:
			var c: float = room.exits[d]
			if (d in ["arriba", "abajo"] and absf(p.x - c) < 48) or (d in ["izquierda", "derecha"] and absf(p.y - c) < 48):
				cerca_salida = true
		if cerca_salida:
			continue
		var r = preload("res://scripts/rompible.gd").new()
		r.main = self
		r.tipo = (["jarron", "jarron", "barril"] if nivel == 1 else ["caja", "caja", "barril"]).pick_random()   # en la mina y el taller no hay jarrones
		r.position = p
		mundo.add_child(r)
		puestos += 1

# Muebles acomodados con lógica de bodega: estantes, vitrinas y mesas contra la pared
# de arriba; barriles y cajas amontonados en las esquinas; columnas en pares.
# Lo que se rompe (y el cofre) solo sale en cuartos con pelea pendiente.
func _poner_muebles(id: String) -> void:
	if id in ["inicio", "apartado"]:
		return
	var pelea: bool = OLEADAS.has(id) and not limpios.has(id)
	var z := interior()
	var arriba := z.position.y + 22.0
	var abajo := z.end.y - 4.0
	var izq := z.position.x + 26.0
	var der := z.end.x - 26.0
	var puestos: Array = []
	# Esquinas: monton de barriles/cajas (o escombros si no hay pelea).
	var esquinas := [[izq, arriba, 1, 1], [der, arriba, -1, 1], [izq, abajo, 1, -1], [der, abajo, -1, -1]]
	esquinas.shuffle()
	for i in (randi_range(1, 2) if pelea else 1):
		var e: Array = esquinas[i]
		var monton: Array
		if pelea:
			monton = [["barril", "caja", "cajas"].pick_random(), ["barril", "caja", "barril_joyas"].pick_random(), ["barril", "caja"].pick_random()]
		else:
			monton = [["escombros", "cajas"].pick_random()]
		var offs := [Vector2.ZERO, Vector2(e[2] * 40, 0), Vector2(e[2] * 14, e[3] * 30)]
		for k in monton.size():
			_mueble(monton[k], Vector2(e[0], e[1]) + offs[k], puestos)
	# Contra la pared de arriba.
	var pared: Array = []
	if id == "jefe" or (pelea and randf() < 0.6):
		# Piscina hundida en el piso, en un costado abierto del cuarto.
		for intento in 30:
			var pp := Vector2(randf_range(z.position.x + 80, z.end.x - 80), randf_range(z.position.y + 70, z.end.y - 50))
			if absf(pp.x - z.get_center().x) < 70.0 or pp.distance_to(player.position) < 110.0:
				continue
			if _mueble("tina", pp, puestos):
				break
	if pelea:
		pared.append(["estante", "vitrina"].pick_random())
		if randf() < 0.4:
			pared.append("cofre")
	pared.append("mesa" if randf() < 0.5 else "estante")
	var xs: Array = []
	var x := izq + 60.0
	while x < der - 60.0:
		xs.append(x)
		x += 56.0
	xs.shuffle()
	for tipo in pared:
		for px in xs:
			if _mueble(tipo, Vector2(px, arriba), puestos):
				xs.erase(px)
				break
	# Par de columnas a los lados del centro (cobertura).
	if randf() < 0.6:
		var c := z.get_center() + Vector2(0, 10)
		var t: String = ["columna", "pedestal"].pick_random()
		var dx := z.size.x * 0.25
		if _libre(c + Vector2(-dx, 0), puestos) and _libre(c + Vector2(dx, 0), puestos):
			_mueble(t, c + Vector2(-dx, 0), puestos)
			_mueble(t, c + Vector2(dx, 0), puestos)

func _libre(p: Vector2, puestos: Array) -> bool:
	if p.distance_to(player.position) < 70.0:
		return false
	if TINAS.has(room_id) and TINAS[room_id].grow(40).has_point(p):
		return false
	for q in puestos:
		if p.distance_to(q) < 34.0:
			return false
	for d in room.exits:
		var c: float = room.exits[d]
		if (d in ["arriba", "abajo"] and absf(p.x - c) < 52) or (d in ["izquierda", "derecha"] and absf(p.y - c) < 52):
			return false
	for dx in [-16, 0, 16]:
		if bloqueado(p + Vector2(dx, -6)):
			return false
	return true

func _mueble(tipo: String, p: Vector2, puestos: Array) -> bool:
	p = p.round()
	if not _libre(p, puestos):
		return false
	var m = preload("res://scripts/mueble.gd").new()
	m.main = self
	m.tipo = tipo
	m.position = p
	mundo.add_child(m)
	puestos.append(p)
	return true

# Detalles del piso (telarañas, musgo, grietas, rasguños, runas, polvo) al azar:
# cada partida los cuartos se ven distintos. Nunca sobre obstáculos.
var decoracion: Array = []
func _poner_decoracion() -> void:
	for d in decoracion:
		d.queue_free()
	decoracion.clear()
	if nivel == 2:
		return   # el piso nuevo de la mina ya trae piedras, grava y vetas
	var lista: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/objetos/piso_detalles.json"))
	var zona := interior()
	# Mina y taller: sus propios detalles (musgo y charcos / aceite, pintura y tuercas).
	var propios: Dictionary = {}
	if nivel > 1:
		propios = JSON.parse_string(FileAccess.get_file_as_string("res://assets/objetos/piso_detalles_n%d.json" % nivel))
	# Telarañas SOLO en esquinas, y no en todas: 1 o 2 por cuarto (a veces ninguna).
	var esquinas := [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
	esquinas.shuffle()
	var webs := 0 if randf() < 0.2 else randi_range(1, 2)
	for k in webs:
		var e: Vector2 = esquinas[k]
		var s := Sprite2D.new()
		# La de la araña solo arriba (la araña cuelga hacia abajo).
		var nt := randi_range(1, 6)
		while nt == 4 and e.y > 0.0:
			nt = randi_range(1, 6)
		if nivel > 1 and not propios.telarana.is_empty():
			nt = 0
			s.texture = load("res://assets/objetos/piso_%s.png" % propios.telarana.pick_random())
		else:
			s.texture = load("res://assets/objetos/piso_telarana%d.png" % nt)
		s.centered = false
		s.flip_h = e.x > 0.0
		s.flip_v = e.y > 0.0
		var tw := float(s.texture.get_width())
		var th := float(s.texture.get_height())
		s.position = Vector2(zona.position.x - 2.0 if e.x == 0.0 else zona.end.x - tw + 2.0,
			zona.position.y - T * 0.6 if e.y == 0.0 else zona.end.y - th + 4.0).round()
		s.z_index = -9
		s.modulate = Color(1, 1, 1, 0.8)
		add_child(s)
		decoracion.append(s)
		# Vaivén muy leve, como si corriera aire.
		s.skew = 0.0
		var tv := s.create_tween().set_loops()
		tv.tween_property(s, "skew", 0.025 * (1.0 if e.x == 0.0 else -1.0), 2.4 + randf()).set_trans(Tween.TRANS_SINE)
		tv.tween_property(s, "skew", 0.0, 2.4 + randf()).set_trans(Tween.TRANS_SINE)
		if nt == 4:
			_poner_arana(s, tw)
	# Baldosas dañadas o con naturaleza (2x2 baldosas): pocas por cuarto y sin encimarse.
	var grandes := lista.filter(func(n): return "_" in n)
	if nivel > 1:
		grandes = propios.grandes if not propios.grandes.is_empty() else propios.sueltos
	var puestas: Array = []
	var cuantas := randi_range(2, 4)
	var intentos_g := 0
	while cuantas > 0 and intentos_g < 40:
		intentos_g += 1
		var ng: String = grandes.pick_random()
		var pg := Vector2(randf_range(zona.position.x + 40, zona.end.x - 40), randf_range(zona.position.y + 40, zona.end.y - 30))
		if bloqueado(pg) or pg.distance_to(_punto_entrada("")) < 50.0:
			continue
		if puestas.any(func(q): return q.distance_to(pg) < 90.0):
			continue
		var sg := Sprite2D.new()
		sg.texture = load("res://assets/objetos/piso_%s.png" % ng)
		sg.position = pg.round()
		sg.flip_h = randf() < 0.5
		sg.flip_v = randf() < 0.5 and not ng.begins_with("oro") and nivel == 1
		sg.z_index = -9
		sg.modulate = Color(1, 1, 1, 0.9)
		add_child(sg)
		decoracion.append(sg)
		puestas.append(pg)
		cuantas -= 1
	_poner_pared()
	var sueltos := lista.filter(func(n): return not n.begins_with("telarana") and not "_" in n)
	if nivel > 1:
		sueltos = propios.sueltos
	var cuantos := randi_range(5, 8)
	var intentos := 0
	while cuantos > 0 and intentos < 60:
		intentos += 1
		var n: String = sueltos.pick_random()
		var tex: Texture2D = load("res://assets/objetos/piso_%s.png" % n)
		var p := Vector2(randf_range(zona.position.x + 20, zona.end.x - 20), randf_range(zona.position.y + 20, zona.end.y - 10))
		if bloqueado(p) or p.distance_to(_punto_entrada("")) < 30.0:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.position = p.round()
		s.flip_h = randf() < 0.5
		s.z_index = -9
		s.modulate = Color(1, 1, 1, 0.55 if n.begins_with("rasguno") or n.begins_with("runas") else 0.85)
		add_child(s)
		decoracion.append(s)
		cuantos -= 1

# ---------- letreros de logro ----------

func logro(clave: String, importante := false) -> void:
	# Nunca dos a la vez: si es el mismo, el que está se reaviva; si es otro,
	# el que está sale con su animación y el nuevo espera su turno.
	if is_instance_valid(_logro_actual):
		if _logro_actual.clave == clave:
			_logro_actual.reavivar()
			return
		if not importante and Time.get_ticks_msec() - _logro_desde < 500:
			return
		_logro_actual.salir()
		_logro_pendiente = clave
		return
	_crear_logro(clave)

func _crear_logro(clave: String) -> void:
	var l = preload("res://scripts/logro.gd").new()
	l.clave = clave
	var id: String = player.arma()
	l.color = Armas.DATOS[id].color if Armas.DATOS.has(id) else Color(1.0, 0.85, 0.4)
	var vp := get_viewport().get_visible_rect().size
	l.position = Vector2(vp.x * 0.5, vp.y * 0.22).round()
	hud.add_child(l)
	_logro_actual = l
	_logro_desde = Time.get_ticks_msec()
	l.tree_exited.connect(func():
		if _logro_pendiente != "":
			var siguiente := _logro_pendiente
			_logro_pendiente = ""
			_crear_logro.call_deferred(siguiente))

# Lo llama cada enemigo al ser pulido.
func enemigo_pulido() -> void:
	racha = racha + 1 if tiempo - racha_t < 2.5 else 1
	racha_t = tiempo
	match racha:
		1: logro("pulido")
		2: logro("doble", true)
		3: logro("triple", true)
		_: logro("racha", true)

# Paredes de piedra (mismo estilo que la puerta) encima de las del cuarto, sin tapar las salidas.
func _poner_muros() -> void:
	for m in muros:
		m.queue_free()
	muros.clear()
	var r: Array = room.rect
	var ex: Dictionary = room.exits
	var x0 := float(r[0])
	var x1 := float(r[2])
	var piso_y := float(r[1]) + T * 3.55
	var fondo_y := float(r[3]) - T * 1.7
	# Pared de arriba (frente): tramos de 3 dibujos al azar.
	var huecos_h: Array = []
	if ex.has("arriba"):
		huecos_h.append([float(ex.arriba) - T * 1.1, float(ex.arriba) + T * 1.1])
	for tramo in _tramos(x0, x1, huecos_h):
		var x: float = tramo[0]
		while x < tramo[1] - 0.5:
			var tex: Texture2D = load("res://assets/objetos/pared_frente%d.png" % (1 if randf() < 0.5 else randi_range(2, 3))) if nivel == 1 else load("res://assets/objetos/pared_frente_%s.png" % NIVEL_DATOS[nivel].tema)
			var w := minf(float(tex.get_width()), tramo[1] - x)
			_muro(tex, Rect2(0, 0, w, tex.get_height()), Vector2(x, piso_y - tex.get_height()))
			x += w
	# Pared de abajo: 3 hileras de bloques.
	var huecos_b: Array = []
	if ex.has("abajo"):
		huecos_b.append([float(ex.abajo) - T * 1.1, float(ex.abajo) + T * 1.1])
	var tb: Texture2D = load("res://assets/objetos/pared_abajo.png" if nivel == 1 else "res://assets/objetos/pared_abajo_%s.png" % NIVEL_DATOS[nivel].tema)
	for fila in 3:
		for tramo in _tramos(x0, x1, huecos_b):
			var x: float = tramo[0] - fila * 17.0
			while x < tramo[1] - 0.5:
				var desde := maxf(x, tramo[0])
				var w := minf(x + tb.get_width(), tramo[1]) - desde
				_muro(tb, Rect2(desde - x, 0, w, tb.get_height()), Vector2(desde, fondo_y + fila * float(tb.get_height())))
				x += tb.get_width()
	# Paredes de los lados (solo la parte de arriba se ve).
	var tl: Texture2D = load("res://assets/objetos/pared_lado.png" if nivel == 1 else "res://assets/objetos/pared_lado_%s.png" % NIVEL_DATOS[nivel].tema)
	for lado in ["izquierda", "derecha"]:
		var huecos_v: Array = []
		if ex.has(lado):
			huecos_v.append([float(ex[lado]) - T * 0.6, float(ex[lado]) + T * 1.4])
		var lx := x0 if lado == "izquierda" else x1 - T
		for tramo in _tramos(piso_y, fondo_y, huecos_v):
			var y: float = tramo[0]
			while y < tramo[1] - 0.5:
				var h := minf(float(tl.get_height()), tramo[1] - y)
				_muro(tl, Rect2(0, 0, tl.get_width(), h), Vector2(lx, y))
				y += h

	# Pasillos de las salidas: mismo piso de piedra y muros a los lados.
	for d in ex:
		var c := float(ex[d])
		var canal := _canal(d)
		var ps := Sprite2D.new()
		ps.texture = piso_piedra.texture
		ps.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		ps.region_enabled = true
		ps.centered = false
		ps.region_rect = Rect2(canal.position.round(), canal.size.round())
		ps.position = canal.position.round()
		ps.z_index = -10
		ps.modulate = piso_piedra.modulate
		add_child(ps)
		muros.append(ps)
		if d in ["arriba", "abajo"]:
			var ya := canal.position.y if d == "arriba" else fondo_y
			var yb := piso_y if d == "arriba" else canal.end.y
			for lx in [c - T * 1.1 - T, c + T * 1.1]:
				var y := ya
				while y < yb - 0.5:
					var h := minf(float(tl.get_height()), yb - y)
					_muro(tl, Rect2(0, 0, tl.get_width(), h), Vector2(lx, y))
					y += h
		else:
			var xa := canal.position.x if d == "izquierda" else x1 - T
			var xb := x0 + T if d == "izquierda" else canal.end.x
			for ly in [c - T * 0.6 - tb.get_height(), c + T * 1.4]:
				var x := xa
				while x < xb - 0.5:
					var w := minf(float(tb.get_width()), xb - x)
					_muro(tb, Rect2(0, 0, w, tb.get_height()), Vector2(x, ly))
					x += w


# Partes de [a, b] que no caen en los huecos de las puertas.
func _tramos(a: float, b: float, huecos: Array) -> Array:
	var out := [[a, b]]
	for hq in huecos:
		var nuevo := []
		for t in out:
			if hq[1] <= t[0] or hq[0] >= t[1]:
				nuevo.append(t)
				continue
			if hq[0] > t[0]:
				nuevo.append([t[0], hq[0]])
			if hq[1] < t[1]:
				nuevo.append([hq[1], t[1]])
		out = nuevo
	return out

func _muro(tex: Texture2D, region: Rect2, pos: Vector2) -> void:
	var m := Sprite2D.new()
	m.texture = tex
	m.centered = false
	m.region_enabled = true
	m.region_rect = region
	m.position = pos.round()
	m.z_index = -9
	m.modulate = Color(1.05, 1.0, 0.95)
	add_child(m)
	muros.append(m)

# Cosas en la pared de arriba (huecos, huesos, fierros, brillos): 2 o 3 por cuarto,
# lejos de la puerta del centro y de las antorchas.
const PARED_COLGADAS := ["hueco_tablas", "grieta", "ojo", "ojos_rojos", "brazo", "barrotes", "cadenas", "retrato", "repisa", "gema", "vitrina", "runas"]
const PARED_PISO := ["calavera_tablas", "esqueleto", "huesos"]
const PARED_LUZ := {"gema": Color(1.0, 0.35, 0.7), "vitrina": Color(1.0, 0.8, 0.4), "runas": Color(0.35, 0.75, 1.0), "ojo": Color(1.0, 0.8, 0.2), "ojos_rojos": Color(1.0, 0.15, 0.15)}

var decor_golpe: Array = []   # [{nodo, rect, nombre}] cosas de la pared que reaccionan a los disparos

func _poner_pared() -> void:
	decor_golpe.clear()
	var r: Array = room.rect
	var centro := (float(r[0]) + float(r[2])) / 2.0
	var usados: Array = []
	var nombres: Array = PARED_COLGADAS + PARED_PISO
	if nivel == 2:
		nombres = ["grieta", "gema", "cadenas", "runas", "huesos"]   # mina: nada de cuadros ni vitrinas
	elif nivel == 3:
		nombres = ["grieta", "cadenas", "barrotes", "repisa", "hueco_tablas"]   # taller
	nombres.shuffle()
	var cuantas := randi_range(2, 3)
	var intentos := 0
	for n in nombres:
		if cuantas <= 0 or intentos > 40:
			break
		intentos += 1
		var tex: Texture2D = load("res://assets/objetos/pared_%s.png" % n)
		var w := float(tex.get_width())
		var h := float(tex.get_height())
		var x := randf_range(float(r[0]) + T * 1.4 + w / 2.0, float(r[2]) - T * 1.4 - w / 2.0)
		if absf(x - centro) < T * 2.2 + w / 2.0:
			continue
		var cerca := false
		for l in luces:
			if absf(l.position.x - x) < T * 0.9 + w / 2.0:
				cerca = true
		for u in usados:
			if absf(u - x) < 70.0:
				cerca = true
		if cerca:
			continue
		usados.append(x)
		cuantas -= 1
		var s := Sprite2D.new()
		s.texture = tex
		s.z_index = -9
		s.flip_h = randf() < 0.5 and n != "runas"
		if n in PARED_PISO:
			# Salen un poco al piso: estorban el paso (Diana los rodea).
			var pie := float(r[1]) + T * 3.75
			s.position = Vector2(x, pie - h / 2.0).round()
			s.z_index = 0
			var cx0 := int((x - w * 0.4) / 16.0)
			var cx1 := int((x + w * 0.4) / 16.0)
			for cx in range(cx0, cx1 + 1):
				for cy in range(int((pie - 14.0) / 16.0), int(pie / 16.0) + 1):
					bloques_dyn[Vector2i(cx, cy)] = true
		else:
			s.position = Vector2(x, float(r[1]) + T * 1.75).round()
		add_child(s)
		decoracion.append(s)
		decor_golpe.append({"nodo": s, "rect": Rect2(s.position - Vector2(w, h) / 2.0, Vector2(w, h)), "nombre": n})
		if n == "cadenas":
			# Se mecen desde el gancho.
			s.offset = Vector2(0, h / 2.0)
			s.position.y -= h / 2.0
			var tc := s.create_tween().set_loops()
			tc.tween_property(s, "rotation", 0.05, 1.8).set_trans(Tween.TRANS_SINE)
			tc.tween_property(s, "rotation", -0.05, 1.8).set_trans(Tween.TRANS_SINE)
		if n in ["ojo", "ojos_rojos"]:
			# Parpadean de vez en cuando.
			var tb := s.create_tween().set_loops()
			tb.tween_interval(randf_range(2.0, 5.0))
			if n == "ojo":
				tb.tween_property(s, "scale:y", 0.15, 0.08)
				tb.tween_property(s, "scale:y", 1.0, 0.12)
			else:
				tb.tween_property(s, "modulate:a", 0.0, 0.1)
				tb.tween_interval(0.12)
				tb.tween_property(s, "modulate:a", 1.0, 0.15)
		if PARED_LUZ.has(n):
			var l := PointLight2D.new()
			l.texture = Fx.textura_luz()
			l.texture_scale = 0.35 if n.begins_with("ojo") else 0.6
			l.energy = 0.5
			l.color = PARED_LUZ[n]
			l.position = s.position
			add_child(l)
			decoracion.append(l)
			var tl := l.create_tween().set_loops()
			tl.tween_property(l, "energy", 0.8, 1.2).set_trans(Tween.TRANS_SINE)
			tl.tween_property(l, "energy", 0.35, 1.2).set_trans(Tween.TRANS_SINE)

# Un disparo pegó cerca de algo de la pared: se sacude y suelta pedacitos.
func golpear_decor(p: Vector2) -> void:
	for d in decor_golpe:
		var nodo: Sprite2D = d.nodo
		if not is_instance_valid(nodo) or not (d.rect as Rect2).grow(26.0).has_point(p):
			continue
		if nodo.has_meta("golpeado") and Time.get_ticks_msec() - int(nodo.get_meta("golpeado")) < 250:
			return
		nodo.set_meta("golpeado", Time.get_ticks_msec())
		var n: String = d.nombre
		var col := Color(0.55, 0.38, 0.25)   # madera
		if n in ["calavera_tablas", "esqueleto", "huesos", "brazo"]:
			col = Color(0.9, 0.85, 0.7)   # hueso
		elif n in ["barrotes", "cadenas"]:
			col = Color(0.75, 0.45, 0.25)   # óxido
		elif PARED_LUZ.has(n):
			col = PARED_LUZ[n]
		Fx.chispas(mundo, nodo.position, col, 6)
		Fx.chispas(mundo, nodo.position + Vector2(0, 6), Color(0.5, 0.45, 0.4), 3)   # polvo
		Juego.sonido("golpe", true, -8.0)
		var base := nodo.position
		var tw := nodo.create_tween()
		nodo.modulate = Color(1.8, 1.8, 1.8)
		tw.tween_property(nodo, "modulate", Color.WHITE, 0.2)
		var ts := nodo.create_tween()
		for k in 4:
			ts.tween_property(nodo, "position", base + Vector2(randf_range(-2, 2), randf_range(-1, 1)).round(), 0.03)
		ts.tween_property(nodo, "position", base, 0.03)
		if n == "cadenas":
			var tc := nodo.create_tween()
			tc.tween_property(nodo, "rotation", 0.3, 0.15)
			tc.tween_property(nodo, "rotation", -0.15, 0.3).set_trans(Tween.TRANS_SINE)
		if n in ["ojo", "ojos_rojos"]:
			# Se esconde un momento del susto.
			var to := nodo.create_tween()
			to.tween_property(nodo, "modulate:a", 0.0, 0.08)
			to.tween_interval(1.2)
			to.tween_property(nodo, "modulate:a", 1.0, 0.4)
		return

# Araña que sube y baja despacio colgada de su hilo.
func _poner_arana(web: Sprite2D, tw: float) -> void:
	var ar := Sprite2D.new()
	ar.texture = load("res://assets/objetos/piso_arana.png")
	ar.centered = false
	var aw := float(ar.texture.get_width())
	var x := 32.0 if not web.flip_h else tw - 32.0 - aw
	var ancla := web.position + Vector2(x + aw / 2.0, 38.0)
	var hilo := Line2D.new()
	hilo.width = 1.0
	hilo.default_color = Color(0.62, 0.66, 0.7, 0.6)
	hilo.z_index = -9
	add_child(hilo)
	ar.z_index = -9
	add_child(ar)
	decoracion.append(hilo)
	decoracion.append(ar)
	var mover := func(baja: float):
		ar.position = (web.position + Vector2(x, 53.0 + baja)).round()
		hilo.points = PackedVector2Array([ancla, ar.position + Vector2(aw / 2.0, 1.0)])
	mover.call(0.0)
	var ta := ar.create_tween().set_loops()
	ta.tween_interval(randf_range(1.0, 3.0))
	ta.tween_method(mover, 0.0, 14.0, 2.6).set_trans(Tween.TRANS_SINE)
	ta.tween_interval(randf_range(1.5, 3.5))
	ta.tween_method(mover, 14.0, -6.0, 3.0).set_trans(Tween.TRANS_SINE)
	ta.tween_method(mover, -6.0, 0.0, 1.5).set_trans(Tween.TRANS_SINE)

func _poner_antorchas(id: String) -> void:
	var r: Array = room.rect
	for fx in ANTORCHAS.get(id, []):
		var l := PointLight2D.new()
		l.texture = Fx.textura_luz()
		l.texture_scale = 2.2
		l.energy = 1.0
		l.color = Color(1.0, 0.7, 0.35)
		l.position = Vector2(lerpf(r[0], r[2], fx), r[1] + T * 1.6)
		add_child(l)
		luces.append(l)
		# Antorcha nueva clavada en la pared (tapa la que viene dibujada), con fuego animado.
		var an := Sprite2D.new()
		an.texture = load("res://assets/objetos/antorcha_pared.png")
		an.hframes = 6
		an.frame = randi() % 6
		an.position = Vector2(lerpf(r[0], r[2], fx) + 1.0, r[1] + T * 3.0 - 33.0).round()
		an.z_index = -8
		add_child(an)
		luces.append(an)
		var ta := an.create_tween().set_loops()
		ta.tween_interval(0.11)
		ta.tween_callback(func(): an.frame = (an.frame + 1) % 6)
		var tw := l.create_tween().set_loops()
		tw.tween_property(l, "energy", 0.8, 0.15 + randf() * 0.1)
		tw.tween_property(l, "energy", 1.05, 0.15 + randf() * 0.1)

# Congela el juego una fracción de segundo para que el golpe se sienta.
var _pausa_hasta := 0  # ms (reloj real) en que termina la pausa de impacto
# Pausa de impacto: casi congela el juego un instante. La velocidad normal la regresa
# _process en cuanto pasa el tiempo (así nunca se queda en cámara lenta).
func pausa_impacto(segundos: float) -> void:
	if Engine.time_scale == 0.0:
		return  # modo captura congelado (F8)
	_pausa_hasta = maxi(_pausa_hasta, Time.get_ticks_msec() + int(segundos * 1000.0))
	Engine.time_scale = 0.05

# Muestra un diálogo de assets/dialogos.json y espera a que termine.
func dialogo(clave: String) -> void:
	if nivel > 1:
		clave = "%s_%d" % [clave, nivel]
	var lineas: Array = preload("res://scripts/dialogo.gd").lineas_de(clave)
	if lineas.is_empty():
		return
	while cambiando:
		await get_tree().process_frame
	var d = preload("res://scripts/dialogo.gd").new()
	add_child(d)
	d.mostrar(lineas)
	await d.terminado

func _pantalla(titulo: String, detalle: String, color: Color, opciones: Array, joyas: Array = [], fondo_fin := false) -> void:
	var p = preload("res://scripts/pantalla_final.gd").new()
	p.titulo = titulo
	p.detalle = detalle
	p.color_titulo = color
	p.opciones = opciones
	p.joyas = joyas
	p.fondo_fin = fondo_fin
	add_child(p)

func _victoria() -> void:
	fin = true
	Juego.sonido("victoria", false)
	Juego.musica("victoria")
	tinte_t = 1.0
	player.festejar()
	# El Anillo Alborada mejora el esquive (libreto): Impulso de luz.
	Juego.set_meta("impulso_luz", true)
	player.impulso_luz = true
	await get_tree().create_timer(1.0).timeout
	await dialogo("jefe_vencido")
	var extra := "Nueva habilidad: Impulso de luz\n(el esquive dura más y atraviesa la niebla)\n\n" if nivel == 1 else ""
	var detalle := extra + "Destellos: %d\nGemas ocultas: %d / 5\nEnemigos pulidos: %d\nTiempo: %d:%02d" % [destellos, gemas_tomadas.size(), pulidos, int(tiempo) / 60, int(tiempo) % 60]
	if nivel == 3:
		# Epílogo: regreso a la tienda al amanecer y pantalla de fin.
		await _epilogo()
		_pantalla("Fin", "Diana recuperó las tres joyas y el brillo de la tienda.

Gracias por jugar.

" + detalle, Ui.CHAMPAN,
			[["Menú principal", Juego.ir_al_menu]], [1, 2, 3], true)
		return
	var continuar := func():
		if not Juego.siguiente_nivel():
			Juego.ir_al_menu()
	_pantalla("¡Recuperaste %s!" % NIVEL_DATOS[nivel].joya, detalle, Ui.DORADO,
		[["Continuar", continuar], ["Menú principal", Juego.ir_al_menu]], [nivel])

func _enemigos_vivos() -> int:
	return enemigos().size()

# La lista se arma una sola vez por cuadro: enemigos y disparos la piden muchas veces.
var _lista_enemigos: Array = []
var _cuadro_lista := -1

func enemigos() -> Array:
	var cuadro := Engine.get_physics_frames() * 2 + Engine.get_process_frames()
	if cuadro != _cuadro_lista:
		_cuadro_lista = cuadro
		_lista_enemigos = mundo.get_children().filter(func(c): return c.has_method("es_enemigo") and c.vivo and not c.is_queued_for_deletion())
	return _lista_enemigos

func agregar(n: Node2D) -> void:
	mundo.add_child(n)

func _cerrar_puertas() -> void:
	cerrado = true
	# Que la puerta no se cierre encima de Diana: si está junto a una, pasa al cuarto.
	var adentro := interior().grow_individual(-T * 0.6, -T * 1.3, -T * 0.6, -T * 0.4)
	var antes: Vector2 = player.position
	player.position = player.position.clamp(adentro.position, adentro.end)
	if player.position != antes:
		player.reset_physics_interpolation()
	Juego.sonido("puerta_cerrar", false)
	var r: Array = room.rect
	for d in GRAFO[room_id]:
		if not room.exits.has(d):
			continue
		var c: float = room.exits[d]
		var s := Anim.sprite({"abrir": ["door", 12, false]}, "abrir")
		s.offset = Vector2.ZERO
		# Baja desde abierta hasta cerrada; al tocar el piso, sacude y levanta polvo.
		s.play_backwards("abrir")
		s.animation_finished.connect(func():
			sacudir(4.0)
			for i in 4:
				Fx.polvo(mundo, s.position + Vector2(randf_range(-20, 20), 4)), CONNECT_ONE_SHOT)
		match d:
			"arriba":
				s.position = Vector2(c, r[1] + T * 2.2)
			"abajo":
				s.position = Vector2(c, r[3] - T * 0.4)
			"izquierda":
				s.position = Vector2(r[0] + T * 0.4, c)
				s.rotation = -PI / 2
			"derecha":
				s.position = Vector2(r[2] - T * 0.4, c)
				s.rotation = PI / 2
		add_child(s)
		puertas.append(s)
		_solida(s, true)

func _abrir_puertas() -> void:
	cerrado = false
	Juego.sonido("puerta_abrir", false)
	for s in puertas:
		if s in puertas_candado.values():
			continue   # la del jefe sigue cerrada hasta limpiar todos los cuartos
		_solida(s, false)
		s.play("abrir")
		s.animation_finished.connect(func(): s.visible = false)
	for s in puertas_candado.values():
		if is_instance_valid(s):
			_solida(s, true)   # la puerta de pelea compartía celdas con la del candado

# ---------- HUD ----------

func _crear_hud() -> void:
	# Viñeta: oscurece suave las orillas de la pantalla (debajo del HUD, encima del mundo).
	var capa := CanvasLayer.new()
	capa.layer = 1  # misma capa que el HUD pero creada antes: queda debajo de él
	capa.follow_viewport_enabled = false
	add_child(capa)
	# Corrección de color: menos saturado, sombras más hondas y un tinte frío verdoso de mazmorra.
	var grado := ColorRect.new()
	grado.set_anchors_preset(Control.PRESET_FULL_RECT)
	grado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shg := Shader.new()
	shg.code = """shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
void fragment() {
	vec3 c = texture(pantalla, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, 0.75);                 // colores apagados
	c = pow(c, vec3(1.08));                     // sombras más hondas
	c = (c - 0.5) * 1.05 + 0.5;                 // un poco más de contraste
	c *= vec3(0.94, 0.98, 1.02);                // frío
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}"""
	var mg := ShaderMaterial.new()
	mg.shader = shg
	grado.material = mg
	capa.add_child(grado)
	var vineta := ColorRect.new()
	vineta.set_anchors_preset(Control.PRESET_FULL_RECT)
	vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float tiempo = 0.0;
float azar(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 0.75);
	// Orillas negras más cerradas y un grano leve, como película vieja.
	float v = smoothstep(0.34, 0.75, length(d));
	float grano = (azar(floor(FRAGCOORD.xy / 2.0) + floor(tiempo * 12.0)) - 0.5) * 0.05;
	COLOR = vec4(0.01, 0.0, 0.03, clamp(v * 0.62 + grano, 0.0, 1.0));
}"""
	var m := ShaderMaterial.new()
	m.shader = sh
	vineta.material = m
	vineta_mat = m
	capa.add_child(vineta)
	# Prisa y cansancio: orillas desenfocadas al moverse (Diana queda nítida al centro)
	# y la pantalla se empaña con sudor después de dos esquives seguidos.
	var capa2 := CanvasLayer.new()
	capa2.layer = 1
	add_child(capa2)
	efecto_pantalla = ColorRect.new()
	efecto_pantalla.set_anchors_preset(Control.PRESET_FULL_RECT)
	efecto_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh2 := Shader.new()
	sh2.code = """shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap;
uniform float prisa = 0.0;
uniform float cansancio = 0.0;
uniform float tiempo = 0.0;
uniform sampler2D sudor : filter_nearest, repeat_enable;
uniform float desliza = 0.0;
uniform float cuadro = 0.0;   // 0..5: secuencia de sudor (aparece, crece, escurre)
float azar(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1, 0)), f.x), mix(azar(i + vec2(0, 1)), azar(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = (UV - 0.5) * vec2(1.0, 0.75);
	float orilla = smoothstep(0.1, 0.5, length(d));
	// Gotas dibujadas (sudor.png): resbalan despacio mientras dura el cansancio.
	// Las gotas aparecen poco a poco (unas antes que otras) y resbalan sin parar.
	// Mezcla suave entre dos cuadros seguidos de la secuencia (6 cuadros apilados).
	float c0 = floor(cuadro);
	float c1 = c0 + 1.0 >= 6.0 ? 3.0 : c0 + 1.0;
	vec2 uvs = vec2(UV.x, fract(UV.y - desliza * 0.15));
	vec4 g = mix(texture(sudor, vec2(uvs.x, (uvs.y + c0) / 6.0)), texture(sudor, vec2(uvs.x, (uvs.y + c1) / 6.0)), smoothstep(0.6, 1.0, fract(cuadro)));
	float aparece = smoothstep(0.0, 0.25, cansancio * 1.25 - ruido(floor(UV * vec2(24.0, 14.0)) * 0.37));
	float gota = g.a * aparece * smoothstep(0.0, 0.3, cansancio);
	// Vaho que respira (como jadeo) y crece desde las esquinas.
	float vaho = ruido(UV * 6.0 + tiempo * 0.05) * 0.6 + ruido(UV * 14.0 - tiempo * 0.03) * 0.4;
	float jadeo = 0.85 + 0.15 * sin(tiempo * 3.2);
	float empa = cansancio * jadeo * clamp(orilla * 1.4 + vaho * 0.4 - (1.0 - cansancio) * 0.5 - 0.1, 0.0, 1.0);
	// La gota funciona como lupa: dobla lo que hay detrás según su borde (como agua en un vidrio).
	vec2 px = vec2(1.0 / 512.0, 1.0 / 1728.0);
	float gx = texture(sudor, vec2(uvs.x + px.x * 2.0, (uvs.y + c0) / 6.0)).a - texture(sudor, vec2(uvs.x - px.x * 2.0, (uvs.y + c0) / 6.0)).a;
	float gy = texture(sudor, vec2(uvs.x, (uvs.y + px.y * 12.0 + c0) / 6.0)).a - texture(sudor, vec2(uvs.x, (uvs.y - px.y * 12.0 + c0) / 6.0)).a;
	uv -= vec2(gx, gy) * 0.012 * gota;
	uv += (vec2(0.5) - UV) * 0.01 * gota;   // un poco de aumento dentro de la gota
	// Desenfoque radial solo en las orillas.
	vec2 hacia = (vec2(0.5) - SCREEN_UV);
	float fuerza = prisa * orilla * 0.09 + empa * 0.012;
	vec3 c = vec3(0.0);
	for (int i = 0; i < 12; i++) {
		c += textureLod(pantalla, uv + hacia * fuerza * float(i) / 11.0, empa * 2.0).rgb;
	}
	c /= 12.0;
	c *= 1.0 - prisa * orilla * 0.18;   // las orillas se oscurecen un poco al correr
	// Vaho grisáceo y un poco cálido.
	c = mix(c, vec3(0.78, 0.76, 0.8), empa * 0.45);
	// La gota: casi transparente, apenas azulada, con brillo blanco en el lado de la luz
	// y una orilla un poco más oscura abajo, como una gota de verdad.
	c = mix(c, c * vec3(0.92, 0.97, 1.05) + vec3(0.02, 0.03, 0.05), gota * 0.6);
	float brillo = clamp(-gx - gy, 0.0, 1.0);
	float sombra = clamp(gx + gy, 0.0, 1.0);
	c += vec3(1.0, 1.0, 1.0) * brillo * gota * 0.55;
	c *= 1.0 - sombra * gota * 0.25;
	COLOR = vec4(c, 1.0);
}"""
	var m2 := ShaderMaterial.new()
	m2.shader = sh2
	m2.set_shader_parameter("sudor", load("res://assets/objetos/sudor_anim.png"))
	efecto_pantalla.material = m2
	capa2.add_child(efecto_pantalla)
	hud = CanvasLayer.new()
	add_child(hud)
	hud_ui = preload("res://scripts/hud.gd").new()
	hud_ui.main = self
	hud.add_child(hud_ui)
	hud_cuarto = hud_ui.cuarto
	# Mirilla encima de todo.
	var capa_m := CanvasLayer.new()
	capa_m.layer = 50
	add_child(capa_m)
	var mi = preload("res://scripts/mirilla.gd").new()
	mi.main = self
	capa_m.add_child(mi)
	hud_msg = hud_ui.msg

func _actualizar_hud() -> void:
	hud_ui.queue_redraw()

func mensaje(texto: String, segundos: float) -> void:
	hud_msg.text = texto
	msg_t = segundos

func game_over() -> void:
	fin = true
	Juego.musica("derrota")
	Juego.sonido("derrota", false)
	# Primero se ve la animación de derrota de Diana.
	await get_tree().create_timer(1.6).timeout
	# Con un Apartado activo, Diana reaparece ahí con la vida llena.
	if apartado_activo:
		fin = false
		player.revivir()
		_transicion("apartado", "")
		await get_tree().create_timer(0.4).timeout
		mensaje("Volviste a tu Apartado.", 2.0)
		return
	_pantalla("Diana se quedó sin brillo", "Inténtalo otra vez: cada intento aprendes el patrón de los enemigos.", Ui.ROSA_PALIDO,
		[["Reintentar", Juego.reintentar], ["Menú principal", Juego.ir_al_menu]])


# ---------- tina, Apartado y gemas ----------

func junto_a_tina(p: Vector2, margen := 6.0) -> bool:
	return TINAS.has(room_id) and TINAS[room_id].grow(margen).has_point(p)

# F junto al mostrador del Apartado: deja 10 destellos de anticipo.
func usar_mostrador() -> bool:
	if room_id != "apartado" or not MOSTRADOR.grow(52).has_point(player.position):
		return false
	if apartado_activo:
		mensaje("Ya tienes tu Apartado aquí.", 1.5)
	elif destellos >= 10:
		destellos -= 10
		apartado_activo = true
		player.curar(99)
		player.energia = player.energia_max
		player.alegria()
		Juego.sonido("curar", false)
		Fx.estallido(mundo, player.position + Vector2(0, -20), Color(1.0, 0.85, 0.4))
		mensaje("¡Apartado activo! Dejaste 10 destellos. Si pierdes, vuelves aquí.", 3.0)
	else:
		mensaje("Necesitas 10 destellos para apartar (tienes %d)." % destellos, 2.0)
	return true

func _poner_gema(id: String) -> void:
	if not GEMAS_CUARTO.has(id) or gemas_tomadas.has(GEMAS_CUARTO[id]):
		return
	if not gema_pos.has(id):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var zona := interior().grow(-24)
		var p := zona.get_center()
		for i in 60:
			p = Vector2(rng.randf_range(zona.position.x, zona.end.x), rng.randf_range(zona.position.y, zona.end.y))
			if not bloqueado(p) and not bloqueado(p + Vector2(0, -16)) and p.distance_to(zona.get_center()) > 80.0:
				break
		gema_pos[id] = p
	var g = preload("res://scripts/pickup.gd").new()
	g.main = self
	g.tipo = "gema"
	g.gema = GEMAS_CUARTO[id]
	g.position = gema_pos[id]
	mundo.add_child(g)

func gemas_ocultas() -> Array:
	return mundo.get_children().filter(func(c): return c.get("tipo") == "gema" and c.oculta)

func tomar_gema(g) -> void:
	gemas_tomadas[g.gema] = true
	Juego.sonido("pocion", false)
	Fx.estallido(mundo, g.position + Vector2(0, -8), Color(1.0, 0.8, 0.9))
	player.alegria()
	mensaje("Gema %s  (%d / 5)" % [g.gema, gemas_tomadas.size()], 2.0)
	g.queue_free()

# ---------- ambiente del cuarto ----------

func _poner_ambiente(id: String) -> void:
	for a in ambiente:
		a.queue_free()
	ambiente.clear()
	# Polvo que flota en el aire por todo el cuarto.
	var polvo := CPUParticles2D.new()
	var r: Array = room.rect
	polvo.position = Vector2((r[0] + r[2]) / 2.0, (r[1] + r[3]) / 2.0)
	polvo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	polvo.emission_rect_extents = Vector2((r[2] - r[0]) / 2.0, (r[3] - r[1]) / 2.0)
	polvo.amount = 45
	polvo.lifetime = 7.0
	polvo.preprocess = 7.0
	polvo.gravity = Vector2(4, -3)
	polvo.direction = Vector2(1, -0.3)
	polvo.spread = 180.0
	polvo.initial_velocity_min = 2.0
	polvo.initial_velocity_max = 8.0
	polvo.scale_amount_min = 0.8
	polvo.scale_amount_max = 1.8
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.85, 0.0))
	g.add_point(0.3, Color(1.0, 0.95, 0.85, 0.35))
	g.add_point(0.7, Color(1.0, 0.95, 0.85, 0.35))
	g.set_color(g.get_point_count() - 1, Color(1.0, 0.95, 0.85, 0.0))
	polvo.color_ramp = g
	polvo.z_index = 30
	add_child(polvo)
	ambiente.append(polvo)
	# Llamas de las antorchas.
	for fx in ANTORCHAS.get(id, []):
		var llama := CPUParticles2D.new()
		llama.position = Vector2(lerpf(r[0], r[2], fx), r[1] + T * 1.35)
		llama.amount = 16
		llama.lifetime = 0.55
		llama.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		llama.emission_sphere_radius = 2.5
		llama.direction = Vector2(0, -1)
		llama.spread = 18.0
		llama.gravity = Vector2(0, -50)
		llama.initial_velocity_min = 12.0
		llama.initial_velocity_max = 26.0
		llama.scale_amount_min = 1.5
		llama.scale_amount_max = 3.0
		var gl := Gradient.new()
		gl.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
		gl.add_point(0.4, Color(1.0, 0.55, 0.15, 0.9))
		gl.set_color(gl.get_point_count() - 1, Color(0.6, 0.15, 0.05, 0.0))
		llama.color_ramp = gl
		llama.z_index = 31
		add_child(llama)
		ambiente.append(llama)


# Sombra suave bajo cada objeto (cajas, estantes, tina): franja oscura en su base.
class Sombras extends Node2D:
	var main
	func _draw() -> void:
		if main.room.is_empty():
			return
		for c in main.bloques:
			if main.bloques.has(c + Vector2i(0, 1)):
				continue
			var base := Vector2(c.x * 16, c.y * 16 + 16)
			for i in 4:
				draw_rect(Rect2(base + Vector2(-1, i * 2), Vector2(18, 2)), Color(0, 0, 0, 0.22 - i * 0.05))


# Flechita dorada alrededor de Diana que señala una salida cuando el cuarto queda limpio.
class Flecha extends Node2D:
	const FLECHA := preload("res://assets/ui/flecha.png")
	var main
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if main.fin or main.cerrado or not (main.limpios.has(main.room_id) or not main.OLEADAS.has(main.room_id)):
			return
		var destino := Vector2.ZERO
		var mejor := INF
		var r: Array = main.room.rect
		for d in main.GRAFO[main.room_id]:
			if not main.room.exits.has(d) or main._candado(d) != "":
				continue
			var c: float = main.room.exits[d]
			var p: Vector2 = {"arriba": Vector2(c, r[1]), "abajo": Vector2(c, r[3]),
				"izquierda": Vector2(r[0], c), "derecha": Vector2(r[2], c)}[d]
			# Prefiere salidas a cuartos que aún no se visitan.
			var peso: float = p.distance_to(main.player.position) + (0.0 if not main.visitados.has(main.GRAFO[main.room_id][d]) else 2000.0)
			if peso < mejor:
				mejor = peso
				destino = p
		# Gira alrededor de los pies de Diana (sin taparla), siempre hacia la salida.
		var desde: Vector2 = main.player.position + Vector2(0, -24)
		if destino == Vector2.ZERO or desde.distance_to(destino) < 110.0:
			return
		var v := (destino - desde).normalized()
		var cuadro := int(t * 8.0) % 4
		var fw := FLECHA.get_width() / 4.0
		var fh := float(FLECHA.get_height())
		# Flecha junto a Diana: gira hacia la salida y va y viene.
		var centro := (desde + v * (66.0 + sin(t * 6.0) * 4.0)).round()
		draw_circle(centro, 9.0, Color(1.0, 0.6, 0.75, 0.15 + 0.08 * sin(t * 5.0)))
		draw_set_transform(centro, v.angle(), Vector2.ONE * 0.8)
		draw_texture_rect_region(FLECHA, Rect2(-fw / 2.0, -fh / 2.0, fw, fh), Rect2(cuadro * fw, 0, fw, fh))
		draw_set_transform(Vector2.ZERO)
		# Estela de chispitas detrás.
		for k in 3:
			var f := fmod(t * 2.0 + k * 0.33, 1.0)
			Ui.estrella(self, centro - v * (10.0 + f * 16.0) + v.orthogonal() * sin(t * 7.0 + k) * 3.0, 0.6, Color(1.0, 0.8, 0.9, 1.0 - f))
		# Flecha grande que late junto a la puerta de salida.
		var en_puerta := destino - v * 34.0
		var late := 1.1 + 0.15 * sin(t * 5.0)
		draw_set_transform(en_puerta + v * sin(t * 4.0) * 5.0, v.angle(), Vector2.ONE * late)
		draw_texture_rect_region(FLECHA, Rect2(-fw / 2.0, -fh / 2.0, fw, fh), Rect2(cuadro * fw, 0, fw, fh), Color(1, 1, 1, 0.85))
		draw_set_transform(Vector2.ZERO)

func _prueba_correr() -> void:
	await get_tree().create_timer(0.5).timeout
	var tecla := InputEventKey.new(); tecla.physical_keycode = KEY_D; tecla.pressed = true
	var ob := ""
	for o in ["corazon", "pocion"]:
		if OS.get_cmdline_user_args().has("--" + o): ob = o
	if ob != "":
		for i in 3: soltar(ob, player.position + Vector2(-20 + i * 20, 25))
		tecla.pressed = false
	if not OS.get_cmdline_user_args().has("--quieta") and ob == "":
		Input.parse_input_event(tecla)
	var raton := InputEventMouseButton.new(); raton.button_index = MOUSE_BUTTON_LEFT; raton.pressed = true
	if ob == "":
		Input.parse_input_event(raton)
	var t := 0.0
	var ultimo := ""
	while t < 3.5:
		if t < 1.2 and fmod(t, 0.18) < 0.02 != raton.pressed:   # toques rápidos al botón
			raton = raton.duplicate(); raton.pressed = fmod(t, 0.18) < 0.02; Input.parse_input_event(raton)
		if t >= 1.2 and tecla.pressed:
			tecla = tecla.duplicate(); tecla.pressed = false; Input.parse_input_event(tecla)
			raton = raton.duplicate(); raton.pressed = false; Input.parse_input_event(raton)
			print("--- suelta todo")
		var s: String = "%s f%d tiro%.2f acc%.2f otro%s vel%d" % [player.sprite.animation, player.sprite.frame, player.tiro_corriendo, player.accion_t, player.otro_tiro, int(player.vel.length())]
		var corto := "%s f%d" % [player.sprite.animation, player.sprite.frame]
		if corto != ultimo:
			print("%.3f  %s prog%.2f esc%.2f" % [t, s, player.sprite.frame_progress, player.sprite.speed_scale])
			ultimo = corto
		if absf(t - 0.45) < 0.01 or absf(t - 0.95) < 0.01:
			get_viewport().get_texture().get_image().save_png("user://sim_%d.png" % int(t * 100))
		await get_tree().process_frame
		t += get_process_delta_time()

# ---------- niveles 2 y 3 ----------
# Mismo mapa de 9 cuartos; cambian el piso, los muros, los objetos de cada cuarto, los enemigos,
# el jefe, las gemas y los diálogos.
var nivel := 1
const NIVEL_DATOS := {
	1: {"tema": "bodega", "piso": "piso_rocoso", "jefe": "vendedor", "jefe_nombre": "Vendedor de Humo", "joya": "el Anillo Alborada"},
	2: {"tema": "mina", "piso": "piso_mina", "jefe": "golem", "jefe_nombre": "Gólem de la Mina", "joya": "el Collar Luna de Plata"},
	3: {"tema": "taller", "piso": "piso_taller", "jefe": "guardia", "jefe_nombre": "Guardia del Taller", "joya": "la Esclava del Sol"},
}

func _configurar_nivel() -> void:
	nivel = Juego.nivel_actual + 1
	var a := OS.get_cmdline_user_args().find("--nivel")   # prueba: godot -- --nivel 2 ...
	if a >= 0 and OS.get_cmdline_user_args().size() > a + 1 and not Juego.has_meta("nivel_arg_usado"):
		Juego.set_meta("nivel_arg_usado", true)   # solo al arrancar: Continuar sí pasa al siguiente nivel
		nivel = int(OS.get_cmdline_user_args()[a + 1])
		Juego.nivel_actual = nivel - 1
	match nivel:
		2:
			NOMBRES = {"inicio": "Mina - Entrada", "pelea1": "Mina - Túnel de rieles", "pelea2": "Mina - Veta de cuarzo",
				"cofre": "Mina - Cueva del minero", "pelea3": "Mina - Derrumbe", "apartado": "Mina - Apartado",
				"descanso": "Mina - Campamento", "pelea4": "Mina - Almacén de explosivos", "jefe": "Mina - Caverna del Gólem"}
			OLEADAS = {
				"pelea1": [{"murcielago": 4, "gota": 3}, {"vagoneta": 2, "murcielago": 3, "gota": 2}],
				"pelea2": [{"cuarzo": 3, "gota": 3, "murcielago": 2}, {"cuarzo": 3, "murcielago": 4}, {"vagoneta": 2, "gota": 4, "cuarzo": 2}],
				"pelea3": [{"murcielago": 5, "cuarzo": 2, "gota": 2}, {"vagoneta": 3, "gota": 3, "murcielago": 2}, {"cuarzo": 4, "vagoneta": 2, "murcielago": 3}],
				"pelea4": [{"vagoneta": 3, "cuarzo": 2, "gota": 3}, {"murcielago": 5, "cuarzo": 3}, {"vagoneta": 3, "murcielago": 4, "gota": 3}],
				"jefe": [{"golem": 1}, {"murcielago": 4, "gota": 3, "cuarzo": 2}],
			}
			GEMAS_CUARTO = {"pelea1": "cuarzo rosa", "pelea2": "turmalina", "cofre": "aguamarina", "descanso": "granate", "pelea4": "obsidiana"}
		3:
			NOMBRES = {"inicio": "Taller - Bodega de recepción", "pelea1": "Taller - Línea de bandas", "pelea2": "Taller - Fundición",
				"cofre": "Taller - Oficina del dueño", "pelea3": "Taller - Pintura dorada", "apartado": "Taller - Apartado",
				"descanso": "Taller - Comedor", "pelea4": "Taller - Sala de máquinas", "jefe": "Taller - La forja"}
			OLEADAS = {
				"pelea1": [{"engrane": 4, "lingote": 2}, {"engrane": 3, "brillito": 3}],
				"pelea2": [{"lingote": 3, "engrane": 3}, {"brillito": 4, "lingote": 3}, {"engrane": 5, "brillito": 2}],
				"pelea3": [{"lingote": 3, "brillito": 4}, {"engrane": 5, "lingote": 2}, {"brillito": 3, "engrane": 3, "lingote": 3}],
				"pelea4": [{"engrane": 5, "lingote": 3}, {"brillito": 5, "lingote": 3}, {"engrane": 4, "brillito": 3, "lingote": 3}],
				"jefe": [{"guardia": 1}, {"engrane": 4, "lingote": 3, "brillito": 2}],
			}
			GEMAS_CUARTO = {"pelea1": "topacio", "pelea2": "rubí", "cofre": "esmeralda", "descanso": "perla", "pelea4": "diamante"}

# Objetos del cuarto (assets/objetos/deco/deco.json): sólidos, contra las orillas,
# el centro libre para pelear y nunca tapando las salidas.
static var _deco := {}
# Objetos planos del piso que se pisan sin chocar: las vías del tren y el charco de la caverna.
const PISABLES := ["n2_pelea1_0", "n2_pelea1_1", "n2_jefe_6", "n3_pelea3_2", "n3_pelea4_5", "n3_jefe_7"]
func _poner_objetos_nivel(id: String) -> void:
	if _deco.is_empty():
		_deco = JSON.parse_string(FileAccess.get_file_as_string("res://assets/objetos/deco/deco.json"))
	var lista: Array = _deco.get(str(nivel), {}).get(id, []).duplicate()
	if lista.is_empty():
		return
	lista.shuffle()
	# Todos los objetos del cuarto, y en cuartos grandes se repiten algunos chicos para llenar.
	var extra: Array = lista.filter(func(o): return maxf(float(o.w), float(o.h)) < 130.0)
	extra.shuffle()
	if OLEADAS.has(id):   # solo en cuartos de pelea (en la cueva no se repiten cofres ni camas)
		lista.append_array(extra.slice(0, 3))
	var z := interior()
	var centro := z.get_center()
	var libre_centro := Rect2(centro - z.size * Vector2(0.17, 0.15), z.size * Vector2(0.34, 0.3))
	var puestos: Array = []
	for o in lista:
		var esc := minf(0.5, 110.0 / maxf(float(o.w), float(o.h)))
		var ow: float = o.w * esc
		var oh: float = o.h * esc
		for intento in 60:
			var p: Vector2
			match intento % 5:
				0, 1:   # contra la pared de arriba
					p = Vector2(randf_range(z.position.x + ow * 0.5 + 8, z.end.x - ow * 0.5 - 8), z.position.y + oh * 0.45 + 10)
				2:      # esquinas y orilla de abajo
					p = Vector2(randf_range(z.position.x + ow * 0.5 + 8, z.end.x - ow * 0.5 - 8), z.end.y - 6)
				3:      # costados
					p = Vector2(z.position.x + ow * 0.5 + 8 if randf() < 0.5 else z.end.x - ow * 0.5 - 8, randf_range(z.position.y + oh + 20, z.end.y - 10))
				_:      # anillo alrededor del centro (cobertura para esquivar)
					var ang := randf() * TAU
					p = centro + Vector2(cos(ang) * z.size.x * 0.3, sin(ang) * z.size.y * 0.3 + oh * 0.5)
			p = p.round()
			var huella := Rect2(p.x - ow * 0.5, p.y - oh, ow, oh)
			if not z.grow(-2).encloses(huella) or huella.intersects(libre_centro) or p.distance_to(player.position) < 70.0:
				continue
			var choca := false
			for q in puestos:
				if huella.grow(10).intersects(q):
					choca = true
					break
			if choca or _cerca_de_salida(huella):
				continue
			var m = preload("res://scripts/mueble.gd").new()
			m.main = self
			m.tipo = "deco"
			m.img = "res://assets/objetos/deco/%s.png" % o.img
			m.esc = esc
			m.pisable = o.img in PISABLES
			m.position = p
			mundo.add_child(m)
			puestos.append(huella)
			break

func _cerca_de_salida(r: Rect2) -> bool:
	for d in room.exits:
		var c: float = room.exits[d]
		if d in ["arriba", "abajo"] and r.position.x < c + 56 and r.end.x > c - 56:
			if (d == "arriba" and r.position.y < interior().position.y + 60) or (d == "abajo" and r.end.y > interior().end.y - 60):
				return true
		if d in ["izquierda", "derecha"] and r.position.y < c + 50 and r.end.y > c - 50:
			if (d == "izquierda" and r.position.x < interior().position.x + 70) or (d == "derecha" and r.end.x > interior().end.x - 70):
				return true
	return false


# Epílogo del nivel 3: la pantalla se aclara a la luz del amanecer y hablan Diana, Quilate y Don Aurelio.
func _epilogo() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 30
	add_child(capa)
	var luz := ColorRect.new()
	luz.set_anchors_preset(Control.PRESET_FULL_RECT)
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	luz.color = Color(1.0, 0.95, 0.85, 0.0)
	capa.add_child(luz)
	var escena := TextureRect.new()
	escena.texture = load("res://assets/ui/epilogo.png")
	escena.set_anchors_preset(Control.PRESET_FULL_RECT)
	escena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	escena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	escena.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	escena.modulate.a = 0.0
	capa.add_child(escena)
	var lluvia := Ui.Lluvia.new()
	lluvia.modulate.a = 0.0
	capa.add_child(lluvia)
	var tw := create_tween()
	# Se funde en blanco y aparece la tienda al amanecer.
	tw.tween_property(luz, "color:a", 1.0, 1.4)
	tw.tween_property(escena, "modulate:a", 1.0, 0.1)
	tw.tween_property(luz, "color:a", 0.0, 1.6)
	tw.parallel().tween_property(lluvia, "modulate:a", 1.0, 2.0)
	Juego.musica("epilogo")
	await tw.finished
	await dialogo("epilogo")


# Música según el lugar: exploración de cada nivel, descanso, combate al cerrarse las puertas
# y la del jefe de cada nivel.
func _musica_cuarto(pelea := false) -> void:
	var exploracion: String = ["", "bodega", "mina", "taller"][nivel]
	if room_id == "jefe" and not limpios.has("jefe"):
		Juego.musica("jefe" if nivel == 1 else "jefe_%d" % nivel)
	elif pelea:
		Juego.musica("combate_%d" % nivel)
	elif room_id == "descanso":
		Juego.musica("descanso")
	else:
		Juego.musica(exploracion)
