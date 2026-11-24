# Autoload "Juego": cambia de escena con pantalla de carga y guarda las opciones.
extends Node

const MENU := "res://menu.tscn"
const NIVEL := "res://main.tscn"
const RUTA_OPCIONES := "user://opciones.cfg"
# Niveles en orden: escena y nombre que sale en la pantalla de carga.
# Cuando exista la Mina se agrega aquí y "Continuar" la abre.
const NIVELES := [
	{"escena": "res://main.tscn", "nombre": "Nivel 1: Bodega del Proveedor"},
	{"escena": "res://main.tscn", "nombre": "Nivel 2: Mina de Cuarzo"},
	{"escena": "res://main.tscn", "nombre": "Nivel 3: Taller de Imitaciones"},
]

var volumen := 0.8
var volumen_musica := 0.7
var volumen_efectos := 0.8
var silencio := false   # tecla M: quita todo el sonido (se recuerda al cerrar)
var pantalla_completa := false
var mirilla := 9   # estilo (la 10 por defecto) de mirilla (ver mirilla.gd)
var nivel_actual := 0
# Dificultad elegida al jugar (1 fácil, 2 intermedio, 3 difícil, 4 demoníaco).
# ritmo: qué tan rápido se mueven y atacan los enemigos; vida: aguante de los enemigos
# (Diana les quita menos en proporción); cantidad: cuántos salen por oleada;
# dano: medios corazones que quita cada golpe; invul: segundos de respiro tras un golpe.
const DIFICULTADES := {
	1: {"nombre": "Fácil", "texto": "Enemigos lentos y frágiles. Para conocer la historia.",
		"ritmo": 0.85, "vida": 0.75, "cantidad": 0.75, "dano": 1, "invul": 1.3},
	2: {"nombre": "Intermedio", "texto": "La experiencia pensada para el juego.",
		"ritmo": 1.0, "vida": 1.0, "cantidad": 1.0, "dano": 1, "invul": 1.0},
	3: {"nombre": "Difícil", "texto": "Más enemigos, más rápidos y más resistentes. Cada golpe quita un corazón.",
		"ritmo": 1.2, "vida": 1.35, "cantidad": 1.3, "dano": 2, "invul": 0.85},
	4: {"nombre": "Demoníaco", "texto": "Hordas furiosas y casi sin respiro. Solo para expertos.",
		"ritmo": 1.4, "vida": 1.75, "cantidad": 1.6, "dano": 2, "invul": 0.65},
}
var dificultad := 2

func dif() -> Dictionary:
	return DIFICULTADES.get(dificultad, DIFICULTADES[2])
# Mientras hay diálogo o pantalla final, Esc/P no abren la pausa.
var ocupado := false
# Solo para pruebas: godot -- --foto <pantalla> guarda una captura y cierra.
var foto := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_audio()
	cargar_opciones()
	# Todos los efectos se cargan al inicio: cargarlos la primera vez que suenan daba tirones.
	for f in DirAccess.get_files_at("res://assets/sonidos"):
		f = f.trim_suffix(".import").trim_suffix(".remap")
		if f.ends_with(".wav"):
			_cargar("res://assets/sonidos/" + f)
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--foto":
		foto = args[1]

# ---------- opciones ----------

func cargar_opciones() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_OPCIONES) == OK:
		volumen = cfg.get_value("sonido", "volumen", volumen)
		volumen_musica = cfg.get_value("sonido", "musica", volumen_musica)
		volumen_efectos = cfg.get_value("sonido", "efectos", volumen_efectos)
		silencio = cfg.get_value("sonido", "silencio", silencio)
		pantalla_completa = cfg.get_value("pantalla", "completa", pantalla_completa)
		mirilla = cfg.get_value("juego", "mirilla", mirilla)
		dificultad = cfg.get_value("juego", "dificultad", dificultad)
	aplicar_opciones()
	aplicar_ventana()

func guardar_opciones() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("sonido", "volumen", volumen)
	cfg.set_value("sonido", "musica", volumen_musica)
	cfg.set_value("sonido", "efectos", volumen_efectos)
	cfg.set_value("sonido", "silencio", silencio)
	cfg.set_value("pantalla", "completa", pantalla_completa)
	cfg.set_value("juego", "mirilla", mirilla)
	cfg.set_value("juego", "dificultad", dificultad)
	cfg.save(RUTA_OPCIONES)

func aplicar_opciones() -> void:
	for par in [["Master", volumen], ["Musica", volumen_musica], ["Efectos", volumen_efectos]]:
		var i := AudioServer.get_bus_index(par[0])
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(par[1], 0.0001)))
		AudioServer.set_bus_mute(i, par[1] <= 0.0 or (silencio and par[0] == "Master"))

# Solo se toca la ventana al iniciar o al cambiar "Pantalla completa" (si no, mover un volumen la achicaba).
func aplicar_ventana() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var modo := DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != modo:
		DisplayServer.window_set_mode(modo)

# cual: "volumen" (general), "musica" o "efectos".
func set_volumen(v: float, cual := "volumen") -> void:
	set(cual if cual == "volumen" else "volumen_" + cual, clampf(v, 0.0, 1.0))
	silencio = false   # mover un volumen quita el silencio de la tecla M
	aplicar_opciones()
	guardar_opciones()

func set_pantalla_completa(si: bool) -> void:
	pantalla_completa = si
	aplicar_ventana()
	guardar_opciones()

# ---------- cambios de escena ----------

func jugar() -> void:
	nivel_actual = 0
	cambiar_a(NIVELES[0].escena, NIVELES[0].nombre)

func reintentar() -> void:
	cambiar_a(NIVELES[nivel_actual].escena, NIVELES[nivel_actual].nombre)

func ir_al_menu() -> void:
	cambiar_a(MENU, "")

# Abre el siguiente nivel si ya existe; si no, devuelve false.
func siguiente_nivel() -> bool:
	if nivel_actual + 1 >= NIVELES.size():
		return false
	nivel_actual += 1
	cambiar_a(NIVELES[nivel_actual].escena, NIVELES[nivel_actual].nombre)
	return true

# Muestra la pantalla de carga mientras la escena se carga en otro hilo.
# Sin nombre de lugar (ir al menú) solo hace un fundido rápido.
func cambiar_a(ruta: String, lugar: String) -> void:
	get_tree().paused = false
	ocupado = false
	var carga = preload("res://scripts/carga.gd").new()
	carga.ruta = ruta
	carga.lugar = lugar
	add_child(carga)

# ---------- sonido ----------
# Efectos en assets/sonidos y música en assets/musica (WAV). Los reproductores viven
# aquí, así la música sigue sonando entre escenas y durante la pausa.

var _musica: AudioStreamPlayer
var musica_actual := ""
var _efectos: Array = []
var _siguiente := 0
var _cache := {}

func _crear_audio() -> void:
	for nombre in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, nombre)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	_musica = AudioStreamPlayer.new()
	_musica.bus = "Musica"
	add_child(_musica)
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "Efectos"
		add_child(p)
		_efectos.append(p)

func _cargar(ruta: String) -> AudioStream:
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _cache[ruta]

# Toca un efecto. variar: cambia un poco el tono para que no suene repetitivo.
func sonido(nombre: String, variar := true, vol_db := 0.0) -> void:
	var s := _cargar("res://assets/sonidos/%s.wav" % nombre)
	if s == null and nombre.begins_with("disparo_"):
		s = _cargar("res://assets/sonidos/disparo.wav")
	if s == null:
		return
	# Usa un reproductor libre; si todos suenan, el más viejo.
	var p: AudioStreamPlayer = _efectos[_siguiente]
	for i in _efectos.size():
		var q: AudioStreamPlayer = _efectos[(_siguiente + i) % _efectos.size()]
		if not q.playing:
			p = q
			break
	_siguiente = (_efectos.find(p) + 1) % _efectos.size()
	p.stream = s
	p.pitch_scale = randf_range(0.94, 1.06) if variar else 1.0
	p.volume_db = vol_db
	p.play()

# Cambia la música con un fundido corto; "" la apaga.
# Canciones que suenan una sola vez (victoria y derrota).
const SIN_REPETIR := ["victoria", "derrota"]

func musica(nombre: String) -> void:
	if nombre == musica_actual:
		return
	# La canción de suspenso (menu.mp3) suena en el menú y en todos los niveles: exploración,
	# peleas y jefes. Si ya está sonando no se reinicia al cambiar de cuarto.
	if nombre in ["bodega", "mina", "taller", "descanso", "derrota", "combate_1", "combate_2", "combate_3", "jefe", "jefe_2", "jefe_3"]:
		nombre = "menu"
	var antes := musica_actual
	musica_actual = nombre
	if nombre == antes and _musica.playing:
		return
	var tw := create_tween()
	if _musica.playing:
		tw.tween_property(_musica, "volume_db", -40.0, 0.4)
	tw.tween_callback(func():
		_musica.stop()
		if nombre == "":
			return
		# Si hay una canción .mp3 con ese nombre se usa esa; si no, la .wav generada.
		var s: AudioStream
		if ResourceLoader.exists("res://assets/musica/%s.mp3" % nombre):
			var m := load("res://assets/musica/%s.mp3" % nombre) as AudioStreamMP3
			m.loop = not nombre in SIN_REPETIR
			s = m
		else:
			var w := _cargar("res://assets/musica/%s.wav" % nombre) as AudioStreamWAV
			if w == null:
				return
			w.loop_mode = AudioStreamWAV.LOOP_DISABLED if nombre in SIN_REPETIR else AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)
			s = w
		_musica.stream = s
		_musica.volume_db = -40.0
		_musica.play())
	tw.tween_property(_musica, "volume_db", 0.0, 0.5)

# F12: guarda una captura del juego en el Escritorio (carpeta "Capturas juego").
# Funciona aunque el juego esté en pausa o congelado con el modo captura (F8).
var _f12 := false
var _m := false
var _f11 := false
func _process(_delta: float) -> void:
	var f11 := Input.is_physical_key_pressed(KEY_F11)
	if f11 and not _f11:
		set_pantalla_completa(not pantalla_completa)
	_f11 = f11
	var m := Input.is_physical_key_pressed(KEY_M)
	if m and not _m:
		silencio = not silencio
		aplicar_opciones()
		guardar_opciones()
		var main = get_tree().current_scene
		if main != null and main.has_method("mensaje"):
			main.mensaje("Sonido apagado (M para prender)" if silencio else "Sonido prendido", 1.5)
	_m = m
	var f12 := Input.is_physical_key_pressed(KEY_F12)
	if f12 and not _f12:
		var carpeta := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).path_join("Capturas juego")
		DirAccess.make_dir_recursive_absolute(carpeta)
		var nombre := "captura_%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
		get_viewport().get_texture().get_image().save_png(carpeta.path_join(nombre))
	_f12 = f12
