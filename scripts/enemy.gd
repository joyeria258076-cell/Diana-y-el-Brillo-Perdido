# Enemigos de la Bodega y el Vendedor de Humo. No mueren: se pulen.
# Cada uno ataca distinto: el escarabajo embiste, la polilla dispara polvo,
# el candado salta y aplasta, y el Vendedor tiene dos fases.
extends Node2D

const TIPOS := {
	# "mira_izq": el dibujo original ve hacia la izquierda.
	# "ojos": color de los ojos en el sprite (brillan en la penumbra); "color": partículas al pulirlo.
	"escarabajo": {"brillo_ojos": 0.0, "queda": true, "vida": 3, "vel": 45.0, "alto": 34.0, "radio": 20.0, "escala": 0.5,
		"ojos": Color(0.85, 0.78, 0.3), "color": Color(0.7, 0.42, 0.3),
		"pedazos": "fx_ped_esc", "polvo": Color(0.22, 0.36, 0.2), "luz": Color(0.5, 0.95, 0.45),
		"anims": {"mover": ["esc3_walk", 11, true], "reposo": ["esc3_idle", 4, true],
			"dano": ["esc3_dano", 12, false], "embiste": ["esc3_emb", 12, true],
			"prepara": ["esc3_prep", 6, false], "frena": ["esc3_frena", 8, false],
			"pulir": ["esc3_ko", 8, false]}},
	# Escarabajo que invoca el Vendedor: negro con verde, hecho de su humo (suelta humo y brasas).
	"escarabajo_humo": {"brillo_ojos": 0.0, "desarma": false, "vida": 3, "vel": 50.0, "alto": 34.0, "radio": 20.0, "escala": 0.125,
		"ojos": Color(1.0, 0.78, 0.25), "color": Color(0.2, 0.42, 0.25), "humo": true,
		"anims": {"mover": ["escj_walk", 9, true], "reposo": ["escj_walk", 3, true],
			"prepara": ["escj_prep", 6, false, 0.134], "embiste": ["escj_emb", 11, true], "frena": ["escj_prep", 8, false, 0.134], "dano": ["escj_dano", 13, false, 0.111],
			"pulir": ["escj_dano", 9, false, 0.111], "aparece": ["escj_walk", 9, false]}},
	# Polilla HD: de lejos escupe una bola de esencia; de cerca da un aletazo con ráfaga de polvo.
	"polilla": {"brillo_ojos": 0.0, "vida": 3, "vel": 60.0, "alto": 52.0, "radio": 15.0, "vuela": true, "escala": 1.0,
		"ojos": Color(0.72, 0.15, 0.18), "color": Color(0.6, 0.4, 0.85),
		"anims": {"mover": ["pol4_fly", 12, true], "ataque": ["pol4_escupe", 12, false],
			"aletazo": ["pol4_aletazo", 12, false], "dano": ["pol4_dano", 14, false],
			"pulir": ["pol4_ko", 9, false]}},
	# Candado poseído HD: flota, se carga, salta y cae aplastando; al morir se parte y se desmorona.
	"candado": {"brillo_ojos": 0.0, "vida": 5, "vel": 34.0, "alto": 48.0, "radio": 20.0, "escala": 0.5,
		"ojos": Color(1.0, 0.7, 0.25), "color": Color(0.85, 0.55, 0.2),
		"anims": {"mover": ["can5_brinco", 11, true], "ataque": ["can5_atk", 12, false],
			"dano": ["can5_dano", 12, false], "pulir": ["can5_ko", 8, false]}},
	"vendedor": {"brillo_ojos": 0.0, "vida": 40, "vel": 55.0, "alto": 58.0, "radio": 18.0,
		"ojos": Color(1.0, 0.88, 0.38), "color": Color(0.62, 0.62, 0.7),
		"anims": {"mover": ["ven_walk", 8, true, 0.25], "reposo": ["ven_idle", 7, true, 0.25],
			"ataque": ["ven_atk", 14, false, 0.25], "dano": ["ven_dano", 11, false, 0.25],
			"tele": ["ven_tele", 13, false, 0.25], "pulir": ["ven_ko", 7, false, 0.25]}},
	# ---- Enemigos nuevos. "ia": perseguir, volar, tanque, disparar o embestir. ----
	"cadena": {"brillo_ojos": 0.0, "vida": 4, "vel": 30.0, "alto": 34.0, "radio": 18.0, "escala": 0.5, "ia": "perseguir",
		"ojos": Color(1.0, 0.3, 0.2), "color": Color(0.55, 0.35, 0.2),
		"anims": {"mover": ["cad5_mover", 6, true], "ataque": ["cad5_atk", 9, false],
			"dano": ["cad5_dano", 12, false], "pulir": ["cad5_ko", 8, false]}},
	"nubecita": {"brillo_ojos": 0.0, "vida": 3, "vel": 42.0, "alto": 40.0, "radio": 20.0, "vuela": true, "escala": 0.5, "ia": "volar",
		"ojos": Color(0.8, 0.6, 1.0), "color": Color(0.5, 0.45, 0.6),
		"anims": {"mover": ["nub5_flota", 10, true], "ataque": ["nub5_atk", 11, false],
			"dano": ["nub5_dano", 12, false], "pulir": ["nub5_ko", 18, false]}},
	"golem": {"brillo_ojos": 0.0, "queda": true, "aura": Color(1.0, 0.6, 0.35), "vida": 9, "vel": 11.0, "alto": 120.0, "radio": 30.0, "ia": "tanque", "escala": 0.5,
		"ojos": Color(1.0, 0.45, 0.15), "color": Color(0.35, 0.3, 0.32),
		"pedazos": "fx_ped_gol", "polvo": Color(0.3, 0.28, 0.26), "luz": Color(1.0, 0.55, 0.2),
		"anims": {"mover": ["gol3_walk", 4, true], "reposo": ["gol3_reposo", 1, true], "ataque": ["gol3_atk", 9, false],
			"lanza": ["gol3_lanza", 8, false], "regreso": ["gol3_regreso", 4, false], "dano": ["gol3_dano", 9, false], "pulir": ["gol3_ko", 5, false],
			"aparece": ["gol3_aparece", 7, false]}},
	# Murciélago HD (cristales de las minas): chilla, se lanza en picada y muerde.
	"murcielago": {"brillo_ojos": 0.0, "vida": 3, "vel": 75.0, "alto": 44.0, "radio": 16.0, "vuela": true, "escala": 0.5,
		"ojos": Color(1.0, 0.63, 0.19), "color": Color(0.2, 0.75, 0.7),
		"anims": {"mover": ["mur4_fly", 10, true], "ataque": ["mur4_atk", 7, false],
			"dano": ["mur4_dano", 13, false], "pulir": ["mur4_ko", 8, false]}},
	"gota": {"brillo_ojos": 0.0, "vida": 3, "vel": 34.0, "alto": 30.0, "radio": 12.0, "escala": 0.28, "ia": "perseguir",
		"ojos": Color(0.85, 0.75, 0.2), "color": Color(0.5, 0.58, 0.16),
		"anims": {"mover": ["got5_salto", 14, true], "ataque": ["got5_explota", 22, false],
			"dano": ["got5_dano", 17, false], "pulir": ["got5_explota", 22, false]}},
	"cuarzo": {"brillo_ojos": 0.0, "vida": 5, "vel": 62.0, "alto": 34.0, "radio": 20.0, "escala": 0.3, "ia": "disparar",
		"ojos": Color(1.0, 0.65, 0.12), "color": Color(0.55, 0.4, 0.7),
		"anims": {"mover": ["cua5_mover", 12, true], "ataque": ["cua5_ataque", 12, false], "dano": ["cua5_dano", 12, false],
			"hunde": ["cua5_hunde", 12, false], "viaja": ["cua5_viaja", 12, true], "sale": ["cua5_sale", 12, false],
			"pulir": ["cua5_pulir", 12, false], "fx": ["cua5_fx", 1, false]}},
	"vagoneta": {"brillo_ojos": 0.0, "mira_izq": true, "vida": 5, "vel": 34.0, "alto": 46.0, "radio": 28.0, "escala": 0.5, "ia": "embestir",
		"ojos": Color(1.0, 0.6, 0.15), "color": Color(0.4, 0.32, 0.24),
		"anims": {"mover": ["vag5_mover", 12, true], "prepara": ["vag5_prepara", 12, false], "embiste": ["vag5_embiste", 14, true],
			"frena": ["vag5_frena", 12, false], "dano": ["vag5_dano", 14, false], "pulir": ["vag5_pulir", 12, false], "fx": ["vag5_fx", 1, false]}},
	"guardia": {"brillo_ojos": 0.0, "queda": true, "metal": true, "vida": 6, "vel": 34.0, "alto": 72.0, "radio": 22.0, "ia": "tanque", "escala": 0.25,
		"ojos": Color(0.15, 0.1, 0.05), "color": Color(0.85, 0.7, 0.35),
		"pedazos": "fx_ped_gua", "polvo": Color(0.36, 0.28, 0.2), "luz": Color(1.0, 0.35, 0.2),
		"anims": {"mover": ["gua3_walk", 5, true, 0.62], "reposo": ["gua3_idle", 4, true, 0.62], "ataque": ["gua3_atk", 9, false, 0.62],
			"dano": ["gua3_dano", 9, false, 0.62], "pulir": ["gua3_ko", 6, false, 0.62],
			"escudo_sube": ["gua3_esc_sube", 10, false, 0.62], "escudo": ["gua3_esc", 5, true, 0.62], "escudo_baja": ["gua3_esc_baja", 6, false, 0.62]}},
	"engrane": {"brillo_ojos": 0.0, "vida": 3, "vel": 42.0, "alto": 40.0, "radio": 17.0, "escala": 0.34, "ia": "embestir",
		"ojos": Color(1.0, 0.6, 0.15), "color": Color(0.35, 0.3, 0.26),
		"anims": {"mover": ["eng5_mover", 14, true], "prepara": ["eng5_prepara", 12, false], "embiste": ["eng5_embiste", 24, true],
			"frena": ["eng5_frena", 12, false], "dano": ["eng5_dano", 14, false], "pulir": ["eng5_pulir", 12, false], "fx": ["eng5_fx", 1, false], "dest": ["eng5_dest", 1, false]}},
	"lingote": {"brillo_ojos": 0.0, "mira_izq": true, "vida": 4, "vel": 40.0, "alto": 38.0, "radio": 16.0, "escala": 0.4, "ia": "perseguir",
		"ojos": Color(1.0, 0.6, 0.15), "color": Color(0.7, 0.55, 0.2),
		"anims": {"mover": ["lin5_mover", 12, true], "ataque": ["lin5_ataque", 14, false], "dano": ["lin5_dano", 14, false],
			"pulir": ["lin5_pulir", 12, false], "fx": ["lin5_fx", 1, false], "dest": ["lin5_dest", 1, false]}},
	"brillito": {"brillo_ojos": 0.0, "vida": 3, "vel": 50.0, "alto": 34.0, "radio": 14.0, "escala": 0.34, "vuela": true, "ia": "volar",
		"ojos": Color(1.0, 0.6, 0.15), "color": Color(0.85, 0.6, 0.7),
		"anims": {"mover": ["bri5_mover", 8, true], "ataque": ["bri5_ataque", 14, false], "dano": ["bri5_dano", 14, false],
			"pulir": ["bri5_pulir", 12, false], "fx": ["bri5_fx", 1, false], "dest": ["bri5_dest", 1, false]}},
}

var tipo := "escarabajo"
var main
var objetivo: Node2D
var vivo := true
var vida := 1
var vida_max := 1
var alto := 24.0
var radio := 12.0
var sprite: AnimatedSprite2D
var t := 0.0
var empuje := Vector2.ZERO
var pausa := 0.0
var cd_ataque := 2.0
var cd_tele := 5.0
var cd_llamar := 3.0
var estado := "seguir"  # seguir, aviso, embiste, salto
var estado_t := 0.0
var cubierto_t := 0.0     # guardia: segundos que se queda tras el escudo
var cd_escudo := 3.0
var rumbo := Vector2.ZERO
var fase := 1
var humo := false  # el Vendedor cubierto de humo no recibe daño
var furia := false  # segunda fase del gólem y el guardia (a media vida)
var llamados: Array = []
var golpe_cd := 0.0
var vel := Vector2.ZERO
# Animación por código encima del sprite: estirar/aplastar, balanceo y rebote.
var aplastar := Vector2.ONE   # se recupera solo hacia (1, 1)
var giro_golpe := 0.0         # giro breve al recibir un golpe
var sacudon := 0.0            # retroceso en pixeles al recibir un golpe (se apaga solo)
var emerge := 10.0            # al aparecer sale del piso: empieza 10 px abajo y sube
var fase_paso := 0.0          # avanza con la velocidad: marca el ritmo de los pasos
var personalidad := 1.0       # cada enemigo se mueve a un ritmo un poco distinto
var detecto := false          # aún no ve a Diana: espera en su lugar
var reaccion := 0.0           # lo que tarda en arrancar después de verla
var paciencia := 0.0          # si nunca la ve, la busca de todos modos al acabarse
var mat: ShaderMaterial
# Los enemigos van un poco más claros para que resalten en los cuartos en penumbra.
# El shader es unshaded: el enemigo se ve con los colores del dibujo.
const CLARO := Color(1.2 / 0.62, 1.2 / 0.58, 1.2 / 0.68)   # deshace la penumbra y suma lo que Diana recibe de su propia luz
var luz_aviso: PointLight2D   # resplandor rojo cuando se prepara para atacar
var polvo_t := 0.0
var escala_actual := 0.5      # cada animación puede traer su escala (4o dato en "anims"); si no, la del tipo
var tele_activo := false
var humo_t := 0.0
var anim_t := 0.0             # tiempo que dura una animación especial (daño o ataque)

func es_enemigo() -> bool:
	return true

# ¿Un disparo en p le pega? Círculo a media altura; el murciélago usa un óvalo ancho sobre su
# cuerpo dibujado (alas abiertas), así también le pegan los disparos de costado.
func impacta(p: Vector2, margen: float) -> bool:
	if tipo == "cadena" and sprite:
		var ck := position + Vector2(0, sprite.position.y - 16.0)
		var dk := p - ck
		return (dk.x * dk.x) / (40.0 + margen) ** 2 + (dk.y * dk.y) / (20.0 + margen) ** 2 <= 1.0
	if tipo == "cuarzo" and sprite:
		if not _cua_golpeable():
			return false
		var cq := position + Vector2(0, sprite.position.y - 16.0)
		var dq := p - cq
		return (dq.x * dq.x) / (30.0 + margen) ** 2 + (dq.y * dq.y) / (16.0 + margen) ** 2 <= 1.0
	if tipo == "gota" and sprite:
		var cg := position + Vector2(0, sprite.position.y - 10.0)
		var dg := p - cg
		return (dg.x * dg.x) / (17.0 + margen) ** 2 + (dg.y * dg.y) / (12.0 + margen) ** 2 <= 1.0
	if tipo == "nubecita" and sprite:
		var cn := position + Vector2(0, sprite.position.y - 33.0)
		var dn := p - cn
		return (dn.x * dn.x) / (32.0 + margen) ** 2 + (dn.y * dn.y) / (27.0 + margen) ** 2 <= 1.0
	if tipo == "candado" and sprite:
		var cc := position + Vector2(0, sprite.position.y - 26.0)
		var dd := p - cc
		return (dd.x * dd.x) / (26.0 + margen) ** 2 + (dd.y * dd.y) / (30.0 + margen) ** 2 <= 1.0
	if tipo == "brillito" and sprite:   # hitbox brillito: el cristal flota, se le pega donde se ve
		var cb := position + Vector2(0, sprite.position.y - 22.0)
		var db := p - cb
		return (db.x * db.x) / (20.0 + margen) ** 2 + (db.y * db.y) / (24.0 + margen) ** 2 <= 1.0
	if tipo == "murcielago" and sprite:
		var lado := -1.0 if sprite.flip_h else 1.0
		var c := position + sprite.position + sprite.offset * sprite.scale.y * Vector2(0, 1) + Vector2(lado * 6.0, 2.0)
		var d := p - c
		var rx := 30.0 + margen
		var ry := 16.0 + margen
		return (d.x * d.x) / (rx * rx) + (d.y * d.y) / (ry * ry) <= 1.0
	return p.distance_to(position + Vector2(0, -alto * 0.5)) < radio + margen

func _ready() -> void:
	var d: Dictionary = TIPOS[tipo]
	vida = maxi(1, ceili(d.vida * Juego.dif().vida))   # dificultad: aguante
	# Cada nivel los enemigos aguantan un poco más (mina +25 %, taller +50 %).
	if main and "nivel" in main:
		vida = maxi(1, roundi(vida * [1.0, 1.0, 1.25, 1.5][clampi(main.nivel, 1, 3)]))
	if has_meta("jefe") and tipo != "vendedor":
		# Vida fija de jefe (antes de la dificultad): el del taller es el más duro.
		vida = ceili({"golem": 60, "guardia": 80}.get(tipo, 50) * Juego.dif().vida)
		alto *= 1.35
		radio *= 1.35
	vida_max = vida
	alto = d.alto
	radio = d.radio
	sprite = Anim.sprite(d.anims, "mover")
	escala_actual = d.get("escala", 0.5)
	sprite.scale = Vector2.ONE * escala_actual
	sprite.modulate = CLARO
	# Cada tira puede traer espacio bajo los pies (pedacitos que caen): el piso queda en "pie".
	sprite.animation_changed.connect(func():
		var datos: Array = d.anims[sprite.animation]
		escala_actual = (datos[3] if datos.size() > 3 else d.get("escala", 0.5)) * (1.35 if has_meta("jefe") and tipo != "vendedor" else 1.0)
		sprite.scale = Vector2.ONE * escala_actual   # también al morir (ya no corre _animar)
		var inf: Dictionary = Anim.data.chars[datos[0]]
		sprite.offset.y = inf.h / 2.0 - inf.get("pie", inf.h)
		if sprite.animation == "pulir":
			# Pulido: colores tal cual el dibujo (sin aclarar ni brillo de ojos sobre los reflejos dorados)
			if sprite.material:
				sprite.material.set_shader_parameter("brillo_ojos", 0.0))
	add_child(sprite)
	sprite.animation_changed.emit()   # aplica la línea del pie desde la primera animación
	if tipo == "golem" and OS.get_cmdline_user_args().has("--registro"):   # diagnóstico: qué anima y cuándo
		var log_f := FileAccess.open("res://registro_golem.txt", FileAccess.WRITE)
		var anota := func(que: String):
			if is_instance_valid(self) and log_f:
				log_f.store_line("%.2f %s anim=%s cuadro=%d vel=%.1f escala_vel=%.2f dist=%.0f" % [Time.get_ticks_msec() / 1000.0, que, sprite.animation, sprite.frame, vel.length(), sprite.speed_scale, position.distance_to(objetivo.position)])
				log_f.flush()
		sprite.animation_changed.connect(func(): anota.call("CAMBIO"))
		sprite.frame_changed.connect(func(): anota.call("cuadro"))
	if tipo == "golem":
		# arrancar la roca es lento y pesado: los cuadros del esfuerzo duran más
		var dur_l := [1.1, 1.2, 1.4, 1.6, 1.5, 1.3, 1.1, 1.1, 1.2, 1.0]
		for i in mini(dur_l.size(), sprite.sprite_frames.get_frame_count("lanza")):
			sprite.sprite_frames.set_frame("lanza", i, sprite.sprite_frames.get_frame_texture("lanza", i), dur_l[i])
		var dur_a := [1.0, 1.0, 1.6, 0.8, 1.6, 1.2, 1.2]   # arriba se sostiene, baja de golpe y se queda en el impacto
		for i in mini(dur_a.size(), sprite.sprite_frames.get_frame_count("ataque")):
			sprite.sprite_frames.set_frame("ataque", i, sprite.sprite_frames.get_frame_texture("ataque", i), dur_a[i])
		_brasas_golem()
		_asentar_golem()
		_tenebroso_golem()
	if tipo == "polilla":
		_preparar_polilla()
	if tipo == "murcielago":
		_preparar_murcielago()
	if tipo == "candado":
		_preparar_candado()
	if tipo == "cadena":
		_preparar_cadena()
	if tipo == "nubecita":
		_preparar_nube()
	if tipo == "gota":
		_preparar_gota()
	if tipo == "cuarzo":
		_preparar_cuarzo()
	if tipo == "vagoneta":
		_preparar_vagoneta()
	if tipo == "engrane":
		_preparar_engrane()
	if tipo == "lingote":
		_preparar_lingote()
	if tipo == "brillito":
		_preparar_brillito()
	if tipo == "escarabajo":   # pegado al piso
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # reducción 2x suave, sin pixeles sueltos: sombra de contacto, polvo y granitos al caminar
		var sc := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 16:
			pts.append(Vector2(cos(TAU * i / 16.0) * 15.0, sin(TAU * i / 16.0) * 4.0))
		sc.polygon = pts
		sc.color = Color(0.05, 0.03, 0.02, 0.55)
		sc.z_index = -1
		add_child(sc)
		sprite.frame_changed.connect(func():
			if vivo and sprite.animation == "mover" and sprite.frame % 2 == 0:
				var atras := 1.0 if sprite.flip_h else -1.0
				_polvo_escarabajo(position + Vector2(atras * 10.0, 0), atras))
	if tipo == "guardia":   # pasos de armadura: polvo, óxido que se desprende, chispa de metal y temblor leve
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.frame_changed.connect(func():
			if vivo and sprite.animation == "mover" and sprite.frame in [0, 4]:
				var frente := -1.0 if sprite.flip_h else 1.0
				var pie := position + Vector2(frente * 8.0, 0)
				_polvo_gua(pie, 0.3)
				onda_piso(pie, 14.0, Color(0.4, 0.33, 0.25, 0.5), 0.3)
				if randf() < 0.5:
					_soltar_pedazos("fx_ped_gua", 1, pie + Vector2(0, -alto * 0.5), 0.5)
				if randf() < 0.35:
					_chispa_gua(pie + Vector2(frente * 4.0, -2), 0.25)
				if randf() < 0.3:
					_esencia_gua(position + Vector2(randf_range(-8, 8), -alto * randf_range(0.3, 0.7)), 0.22, 0.55)
				var cerca := clampf(1.0 - position.distance_to(objetivo.position) / 220.0, 0.0, 1.0)
				main.sacudir(0.6 + 1.6 * cerca * cerca)
				Juego.sonido("golpe", true, -18.0))
		var so := Polygon2D.new()   # sombra de contacto: pisa firme
		var pts := PackedVector2Array()
		for i in 20:
			pts.append(Vector2(cos(TAU * i / 20.0) * 16.0, sin(TAU * i / 20.0) * 4.5))
		so.polygon = pts
		so.color = Color(0.03, 0.02, 0.02, 0.5)
		so.z_index = -1
		add_child(so)
		var ox := PointLight2D.new()   # brillo rojo tenue de los ojos en la rendija del casco
		ox.texture = Fx.textura_luz()
		ox.texture_scale = 0.18
		ox.color = Color(1.0, 0.2, 0.15)
		ox.energy = 0.9
		ox.position = Vector2(0, -alto * 0.95)
		add_child(ox)
		set_meta("luz_ojo", ox)
		_aura_guardia()
	if tipo == "guardia":   # mazazo: brillo al levantar, impacto con polvo, pedazos y esencia
		sprite.frame_changed.connect(func():
			if not vivo or sprite.animation != "ataque":
				return
			var lado := -1.0 if sprite.flip_h else 1.0
			if sprite.frame == 3:
				_chispa_gua(position + Vector2(lado * 2.0, -alto * 1.25), 0.45)
				_esencia_gua(position + Vector2(0, -alto * 0.8), 0.25, 0.7)
			elif sprite.frame == 5:
				var p := position + Vector2(lado * (radio + 18.0), 0)
				_polvo_gua(p, 0.55)
				_polvo_gua(p + Vector2(lado * 10.0, 2), 0.4)
				_chispa_gua(p + Vector2(0, -4), 0.6)
				_soltar_pedazos("fx_ped_gua", 3, p, 0.9)
				onda_piso(p, 30.0, Color(0.5, 0.35, 0.8, 0.6), 0.4)
				onda_piso(p, 46.0, Color(0.45, 0.25, 0.85, 0.35), 0.55)
				_esencia_gua(p + Vector2(0, -2), 0.3, 0.8)
				_esencia_gua(p + Vector2(lado * 12.0, 0), 0.24, 0.7)
				_destellos_joya(p + Vector2(0, -6), 5, 20.0)
				_niebla_morada(p, 4, 22.0)
				main.sacudir(3.0)
				_abanico_espinas(p, Vector2(lado, 0))
				get_tree().create_timer(0.2).timeout.connect(func(): if is_instance_valid(self): _linea_espinas(p))
			elif sprite.frame == 4:   # estela morada mientras baja el mazo
				_esencia_gua(position + Vector2(lado * 20.0, -alto * 0.9), 0.2, 0.6)
				Fx.chispas(main.mundo, position + Vector2(lado * 24.0, -alto * 0.7), Color(0.75, 0.45, 1.0), 6))
	if tipo == "golem":   # martillazo: carga de lava y esencia al subir los puños
		sprite.frame_changed.connect(func():
			if not vivo or sprite.animation != "ataque":
				return
			var lado := -1.0 if sprite.flip_h else 1.0
			var fr := sprite.frame
			if fr == 1:
					_brasas_suben(position + Vector2(0, -alto * 0.7), 8, 30.0)
					_niebla_morada(position + Vector2(0, -alto * 0.8), 5, 26.0)
			elif fr == 2:   # arriba: brilla la lava y destella la esencia
					var lz := PointLight2D.new()
					lz.texture = Fx.textura_luz()
					lz.texture_scale = 1.2
					lz.color = Color(1.0, 0.5, 0.2)
					lz.energy = 0.0
					lz.position = Vector2(lado * 6.0, -alto * 0.95)
					add_child(lz)
					var tl := lz.create_tween()
					tl.tween_property(lz, "energy", 2.2, 0.15)
					tl.tween_property(lz, "energy", 0.0, 0.35)
					tl.tween_callback(lz.queue_free)
					Fx.chispas(main.mundo, position + Vector2(lado * 6.0, -alto * 1.0), Color(0.75, 0.4, 1.0), 10)
					_destellos_joya(position + Vector2(lado * 6.0, -alto * 0.95), 6, 24.0)
			elif fr == 3:   # baja de golpe: estela de chispas
					Fx.chispas(main.mundo, position + Vector2(lado * 30.0, -alto * 0.5), Color(1.0, 0.55, 0.2), 8)
			)
	if tipo == "golem":   # pisadas pesadas: polvo, piedritas y temblor leve
		sprite.frame_changed.connect(func():
			if vivo and sprite.animation == "mover" and sprite.frame in [0, 4]:
				var pie := position + Vector2(sprite.scale.x * 0.0 + (8.0 if sprite.flip_h else -8.0), 0)
				Fx.polvo(main.mundo, pie)
				Fx.polvo(main.mundo, pie + Vector2(10, 0))
				_soltar_pedazos("fx_ped_gol", 1)
				onda_piso(pie, 22.0, Color(0.45, 0.4, 0.32, 0.6), 0.35)
				var frente := -1.0 if sprite.flip_h else 1.0   # justo bajo el pie que se apoya (el de adelante)
				var hu := Vector2(position.x + frente * 26.0, position.y - 2.0)
				marca_piso("fx_gol_huella", hu, randf_range(1.2, 1.4), 7.0, 14.0, true)
				_soltar_pedazos("fx_ped_gol2", 2 + int(randf() < 0.5), hu, 0.6)
				var cerca := clampf(1.0 - position.distance_to(objetivo.position) / 260.0, 0.0, 1.0)
				main.sacudir(1.5 + 4.5 * cerca * cerca)
				_gotas_lava())
	if d.get("humo", false):
		_humo_propio()
	if d.has("aura"):   # resplandor propio para que no se pierda en la penumbra
		var au := PointLight2D.new()
		au.texture = Fx.textura_luz()
		au.texture_scale = 0.75 if tipo == "golem" else 0.6
		au.energy = 1.1 if tipo == "golem" else 0.8
		au.color = d.aura
		au.position = Vector2(0, -alto * 0.5)
		add_child(au)
	if d.anims.has("aparece"):   # sale de su nube de humo antes de moverse
		sprite.play("aparece")
		anim_t = sprite.sprite_frames.get_frame_count("aparece") / sprite.sprite_frames.get_animation_speed("aparece")
		if d.get("humo", false):
			sprite.modulate.a = 0.0
			sprite.create_tween().tween_property(sprite, "modulate:a", 1.0, anim_t * 0.6)
			_bocanadas(26, 1.0)
			get_tree().create_timer(anim_t * 0.55).timeout.connect(func(): if is_instance_valid(self): _bocanadas(16, 0.7))
		else:
			# Se arma desde el piso agrietado: polvo, brasas y un pisotón al terminar.
			var lc: Color = d.get("luz", Color(1.0, 0.55, 0.2))
			Fx.chispas(main.mundo, position, lc, 10)
			if tipo == "golem":   # revienta el piso: hoyo, losas que saltan y temblor
				marca_piso("fx_gol_hoyo", position + Vector2(0, 4), 1.0, anim_t + 2.5, 7.0)
				_soltar_pedazos("fx_ped_gol", 8)
				main.sacudir(5.0)
			_bocanadas(16, 0.8, d.get("polvo", Color(0.3, 0.28, 0.26)), lc)
			get_tree().create_timer(anim_t * 0.9).timeout.connect(func():
				if is_instance_valid(self):
					main.sacudir(4.0)
					Fx.polvo(main.mundo, position + Vector2(-8, 0))
					Fx.polvo(main.mundo, position + Vector2(8, 0)))
	t = randf() * 10.0
	cd_ataque = randf_range(1.5, 3.5)
	if d.get("vuela", false):
		sprite.position.y = -16
	if tipo != "nubecita" and tipo != "gota" and tipo != "cuarzo":   # la nube trae su propia sombra (se desvanece al morir)
		Fx.sombra(self, radio * (1.4 if d.get("vuela", false) else 2.0))
	personalidad = randf_range(0.85, 1.2)
	# Aparece saliendo del piso: delgado y alto, rebota hasta su forma.
	sprite.self_modulate = Color(0, 0, 0, 0)
	var tw_e := create_tween().set_parallel(true)
	tw_e.tween_property(self, "emerge", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_e.tween_property(sprite, "self_modulate", Color(0.1, 0.08, 0.1, 1), 0.12)
	tw_e.chain().tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
	Fx.polvo(main.mundo, position)
	Fx.polvo(main.mundo, position + Vector2(6, 0))
	# Contorno blanco, destello y ojos que brillan (assets/enemigo.gdshader).
	mat = ShaderMaterial.new()
	mat.shader = preload("res://assets/enemigo.gdshader")
	mat.set_shader_parameter("color_ojos", d.ojos)
	mat.set_shader_parameter("brillo_ojos", d.get("brillo_ojos", 0.9))
	sprite.material = mat
	if tipo == "golem":
		mat.set_shader_parameter("color_contorno", Color(0.55, 0.2, 0.9))   # al golpearlo, orilla morada (no franja blanca)
	luz_aviso = PointLight2D.new()
	luz_aviso.texture = Fx.textura_luz()
	luz_aviso.texture_scale = 0.7
	luz_aviso.color = Color(1.0, 0.25, 0.15)
	luz_aviso.energy = 0.0
	luz_aviso.visible = false
	luz_aviso.range_item_cull_mask = 3
	luz_aviso.position = Vector2(0, -alto_luz())
	add_child(luz_aviso)
	# Cada uno reacciona a su tiempo, para que la horda no se mueva igual.
	reaccion = randf_range(0.15, 0.7)
	paciencia = randf_range(1.2, 3.0)
	if tipo == "vendedor":
		detecto = true

func _physics_process(delta: float) -> void:
	if not vivo or main.fin:
		return
	delta *= Juego.dif().ritmo   # dificultad: se mueven, recargan y atacan más rápido
	if has_meta("jefe") and tipo != "vendedor":
		if not furia and vida <= vida_max / 2:
			_entrar_furia()
		if furia:
			delta *= 1.3   # segunda fase: todo más rápido
	t += delta
	golpe_cd -= delta
	cd_ataque -= delta
	var d: Dictionary = TIPOS[tipo]
	var hacia := objetivo.position - position
	var dir := hacia.normalized()
	var rapidez: float = d.vel
	# Antes de verla se queda en su lugar; al verla salta un "!" y arranca tras su reacción.
	if not detecto:
		paciencia -= delta
		if hacia.length() < 230.0 or paciencia <= 0.0:
			_descubrir()
		_quieto(d)
		_animar(delta, d)
		return
	if reaccion > 0.0:
		reaccion -= delta
		_quieto(d)
		_animar(delta, d)
		return

	match tipo:
		"escarabajo", "escarabajo_humo":
			dir = _escarabajo(delta, hacia, dir)
			if estado == "embiste":
				rapidez = 270.0
		"polilla":
			var dist_p := hacia.length()
			if anim_t > 0.0 and sprite.animation in ["ataque", "aletazo"]:
				dir = Vector2.ZERO   # se queda en el aire mientras ataca
			elif dist_p < 64.0 and cd_ataque <= 0.0:
				cd_ataque = randf_range(1.8, 2.6)
				especial("aletazo")
				_aletazo_polilla(hacia.normalized())
			elif dist_p < 110.0:
				dir = (-dir).rotated(sin(t * 3.0) * 0.6)   # de cerca y sin ataque listo: retrocede volando
			elif dist_p < 280.0 and cd_ataque <= 0.0:
				cd_ataque = randf_range(2.2, 3.2)
				especial("ataque")
				_escupir_polilla()
			else:
				dir = dir.rotated(sin(t * 3.0) * 0.9)
		"murcielago":
			var dist_m := hacia.length()
			if anim_t > 0.0 and sprite.animation == "ataque":
				dir = Vector2.ZERO   # el ataque lo mueve por su cuenta (retrocede, se lanza y rebota)
			elif dist_m < 230.0 and dist_m > 60.0 and cd_ataque <= 0.0:
				cd_ataque = randf_range(2.2, 3.2)
				especial("ataque")
				_ataque_murcielago(hacia.normalized(), dist_m)
			elif dist_m < 90.0:
				# no se pega a Diana: la rodea a distancia y se aleja para volver a lanzarse
				dir = (-dir + dir.orthogonal() * 0.8).normalized()
			else:
				dir = dir.rotated(sin(t * 2.6 * personalidad) * 0.8)
		"candado":
			if estado == "salto":
				dir = Vector2.ZERO
			elif hacia.length() < 210.0 and cd_ataque <= 0.0:
				cd_ataque = randf_range(2.8, 4.0)
				dir = Vector2.ZERO
				_salto_candado()
			else:
				# se arrastra por el piso a jalones: avanza al cargar el peso a un lado y casi se detiene entre jalón y jalón
				dir = dir.rotated(sin(t * 0.9 * personalidad) * 0.35)
				# avanza a brincos: solo se mueve mientras está en el aire (cuadros 6-12)
				rapidez *= 2.8 if (sprite.frame >= 6 and sprite.frame <= 12) else 0.0
				if hacia.length() < 36.0:
					rapidez = 0.0   # no se le encima a Diana
				doblez = Vector2.ONE

		"cadena":
			var dist_c := hacia.length()
			if anim_t > 0.0 and sprite.animation == "ataque":
				dir = Vector2.ZERO   # se queda quieta mientras escupe
			elif dist_c < 240.0 and dist_c > 50.0 and cd_ataque <= 0.0:
				cd_ataque = randf_range(2.6, 3.6)
				dir = Vector2.ZERO
				especial("ataque")
				_escupir_cadena()
			elif dist_c < 60.0:
				dir = -dir   # no se le encima: se aleja arrastrándose
			else:
				dir = dir.rotated(sin(t * 0.8 * personalidad) * 0.3)
			# avanza a jalones: cuando la joroba empuja (cuadros 1-3), casi quieta al asentarse
			rapidez *= 1.6 if (sprite.frame >= 1 and sprite.frame <= 3) else 0.25
		"gota":
			var dist_g := hacia.length()
			if dist_g < 40.0:
				# llega a Diana: se agrieta y revienta (muere en la explosión)
				cd_ataque = 99.0
				dir = Vector2.ZERO
				vida = 0
				_pulir()
				return
			else:
				dir = dir.rotated(sin(t * 0.9 * personalidad) * 0.35)
				# avanza solo mientras está en el aire (cuadros 7-13 del salto)
				rapidez *= 3.0 if (sprite.frame >= 7 and sprite.frame <= 13) else 0.2
				if dist_g < 100.0:
					rapidez = maxf(rapidez, 70.0)   # de cerca se le echa encima sin detenerse
					empuje *= 0.3
		"cuarzo":
			dir = _cuarzo(delta, hacia)
			rapidez = 62.0
		"nubecita":
			var dist_n := hacia.length()
			if anim_t > 0.0 and sprite.animation == "ataque":
				dir = Vector2.ZERO   # quieta mientras carga y suelta el rayo
			elif dist_n < 115.0 and dist_n > 45.0 and absf(hacia.y) < 70.0 and cd_ataque <= 0.0:
				cd_ataque = randf_range(3.0, 4.2)
				dir = Vector2.ZERO
				especial("ataque")
				_rayo_nube()
			elif dist_n < 60.0:
				dir = (-dir).rotated(sin(t * 1.3) * 0.6)   # no se le encima: se aleja flotando
			else:
				dir = dir.rotated(sin(t * 1.6 * personalidad) * 0.6)
		"lingote":
			dir = _ia_lin(hacia, dir)
		"brillito":
			dir = _ia_bri(hacia, dir)
		"vendedor":
			_jefe(delta, hacia)
			if hacia.length() < 90.0:
				dir = Vector2.ZERO
		_:
			match d.get("ia", "perseguir"):
				"volar":
					dir = dir.rotated(sin(t * 2.5 * personalidad) * 0.8)
				"disparar":
					# Se mantiene a distancia y lanza astillas.
					if hacia.length() < 120.0:
						dir = -dir
					elif hacia.length() < 220.0:
						dir = Vector2.ZERO
					if cd_ataque <= 0.0 and hacia.length() < 300.0:
						cd_ataque = randf_range(1.8, 2.8)
						_disparar("astilla", hacia.normalized())
				"embestir":
					dir = _escarabajo(delta, hacia, dir)
					if estado == "embiste":
						rapidez = 240.0
				"tanque":
					# Lento y pesado: sacude el piso al pisar.
					if int(fase_paso / PI) != int((fase_paso - delta * 6.0) / PI) and vel.length() > 5.0:
						main.sacudir(0.8)
					# De cerca golpea el piso; el gólem de lejos arranca y avienta rocas.
					if d.anims.has("ataque"):
						var dist := hacia.length()
						if anim_t > 0.0 and sprite.animation == "regreso":
							# retoma la marcha poco a poco mientras baja el brazo (sin frenón ni arrancón)
							rapidez *= 0.2 + 0.3 * (sprite.frame + sprite.frame_progress)
						elif anim_t > 0.0 and sprite.animation in ["ataque", "lanza"]:
							dir = Vector2.ZERO
						elif tipo == "golem" and dist < 170.0 and not (absf(hacia.y) < 36.0 and absf(hacia.x) < radio + 60.0):
							# Diana cerca pero de lado (arriba/abajo): camina a ponerla justo enfrente
							var lx := signf(hacia.x) if absf(hacia.x) > 1.0 else (-1.0 if sprite.flip_h else 1.0)
							var meta := objetivo.position - Vector2(lx * (radio + 30.0), 0)
							dir = (meta - position).normalized() if position.distance_to(meta) > 4.0 else Vector2.ZERO
						elif tipo == "golem" and absf(hacia.y) < 36.0 and absf(hacia.x) < radio + 60.0:
							# Diana enfrente: solo golpea, uno tras otro
							dir = Vector2.ZERO
							vel = Vector2.ZERO
							if anim_t <= 0.0:   # sin pausa: en cuanto termina un golpe empieza el siguiente
								cd_ataque = anim_t_de("ataque")
								especial("ataque")
								_golpe_suelo(hacia)
						elif tipo == "guardia" and cubierto_t > 0.0:
							# tras el escudo: quieto, encarando a Diana; al terminar lo baja y vuelve a la carga
							dir = Vector2.ZERO
							cubierto_t -= delta
							if cubierto_t <= 0.0:
								especial("escudo_baja")
								cd_escudo = randf_range(4.0, 6.5)
						elif tipo == "guardia" and cd_ataque <= 0.0 and dist > radio + 40.0 and dist < 190.0 and anim_t <= 0.0 and randf() < 0.02:
							# a media distancia también azota el piso para lanzarle la fila de espinas
							cd_ataque = 3.2
							especial("ataque")
							dir = Vector2.ZERO
							_golpe_suelo(hacia)
						elif tipo == "guardia" and cd_escudo <= 0.0 and dist > radio + 60.0 and anim_t <= 0.0:
							# de lejos, cuando le disparan, levanta el escudo
							cd_escudo = 99.0
							cubierto_t = randf_range(2.0, 3.0)
							especial("escudo_sube")
							dir = Vector2.ZERO
							Juego.sonido("golpe", true, -14.0)
						elif cd_ataque <= 0.0 and dist < radio + 40.0:
							cd_ataque = anim_t_de("ataque") + 0.05   # termina el golpe completo y enseguida el siguiente
							especial("ataque")
							dir = Vector2.ZERO
							_golpe_suelo(hacia)
						elif d.anims.has("lanza") and cd_ataque <= 0.0 and dist > 110.0 and dist < 620.0:
							# de lejos arranca rocas seguido (más seguido enfurecido)
							cd_ataque = 2.2 if furia else 3.4
							especial("lanza")
							dir = Vector2.ZERO
							_lanzar_roca(hacia)
	if estado == "salto":
		return

	# En horda se separan un poco para no quedar encimados.
	var separar := Vector2.ZERO
	for otro in main.enemigos():
		if otro != self:
			var lejos: Vector2 = position - otro.position
			if lejos.length() < radio * 2.0 and lejos.length() > 0.1:
				separar += lejos.normalized() * (radio * 2.0 - lejos.length())
	# Gira y acelera de a poco; el embiste arranca casi de golpe y frena suave.
	var suave := 14.0 if estado == "embiste" else 5.0
	vel = vel.lerp(dir * rapidez, 1.0 - exp(-suave * delta))
	var paso: Vector2 = vel * delta + empuje * delta + separar * 3.0 * delta
	empuje = empuje.lerp(Vector2.ZERO, 1.0 - exp(-6.0 * delta))
	var antes_v := position
	position = main.mover(position, paso, 0.0 if TIPOS[tipo].get("vuela", false) else minf(radio * 0.6, 9.0))
	if (tipo == "vagoneta" or tipo == "engrane") and estado == "embiste" and estado_t < 0.38 and (position.distance_to(antes_v) < 0.6 or hacia.length() < radio + 10.0):
		if hacia.length() < radio + 14.0:
			objetivo.herir(1, hacia)
			golpe_cd = 0.8
		vel = Vector2.ZERO
		empuje = -hacia.normalized() * 380.0   # rebota hacia atrás
		estado = "frena"
		estado_t = 0.7
		especial("frena")
	if tipo == "murcielago":
		position = _dentro_mur(position)
	if tipo != "vendedor" and not TIPOS[tipo].get("vuela", false) and main.junto_a_tina(position, 0.0):
		_pulir_en_tina()
		return
	anim_t -= delta
	# Resplandor rojo que late mientras se prepara para atacar.
	var meta := 0.0
	if estado == "aviso" and tipo != "vagoneta" and tipo != "engrane":
		meta = 1.2 + sin(t * 18.0) * 0.5
	luz_aviso.energy = lerpf(luz_aviso.energy, meta, 1.0 - exp(-14.0 * delta))
	luz_aviso.visible = luz_aviso.energy > 0.02  # apagada no cuesta nada
	# Polvito en las patas al caminar.
	if not d.get("vuela", false) and vel.length() > 15.0:
		polvo_t -= delta
		if polvo_t <= 0.0:
			polvo_t = randf_range(0.28, 0.4) if estado != "embiste" else 0.06
			Fx.polvo(main.mundo, position + Vector2(randf_range(-radio, radio) * 0.5, 0))
	if tipo == "guardia":
		cd_escudo -= delta
	if anim_t <= 0.0 and cubierto_t > 0.0:
		sprite.play("escudo")
	elif anim_t <= 0.0 and not (tipo == "cuarzo" and estado != "seguir"):
		if estado == "embiste" and d.anims.has("embiste"):
			sprite.play("embiste")
		elif estado == "aviso" and d.anims.has("prepara"):
			sprite.play("prepara")
		elif estado == "frena" and d.anims.has("frena"):
			sprite.play("frena")
		elif d.anims.has("reposo"):
			# el gólem camina a 11: con el umbral de 8 brincaba entre caminar y reposo cada cuadro
			# y la caminata se reiniciaba siempre en el cuadro 0 (se veía congelado a medio paso)
			var umbral := 2.0 if tipo == "golem" else 8.0
			var sig := "mover" if dir != Vector2.ZERO and vel.length() > umbral else "reposo"
			if tipo == "golem" and sprite.animation == "lanza":
				sig = "regreso"   # baja el brazo y retoma el paso (cuadros de transición)
			elif tipo == "golem" and dir != Vector2.ZERO and sprite.animation in ["regreso", "ataque", "dano"]:
				sig = "mover"   # al terminar un ataque sigue caminando sin detenerse de pie
			if sig == "regreso":
				especial("regreso")
			elif tipo == "golem" and sig == "mover" and sprite.animation != "mover":
				# de pie a caminar: arranca en el paso con las piernas juntas (el cuadro 0 es el paso más abierto)
				var venia := sprite.animation
				sprite.play("mover")
				sprite.frame = 2 if venia == "regreso" else 1   # sigue el paso donde lo dejó la transición
			else:
				sprite.play(sig)
		else:
			sprite.play("mover")
	# Flotan o rebotan al avanzar: así no se ven deslizándose tiesos.
	_animar(delta, d)
	if tipo == "cadena":
		_voltear_cadena(delta, hacia)
	elif absf(hacia.x) > 4.0 and estado != "embiste" and tipo != "brillito":   # el brillito gira solo y ataca de frente
		var a_la_izq := hacia.x < 0.0
		sprite.flip_h = not a_la_izq if d.get("mira_izq", false) else a_la_izq
	if hacia.length() < radio + 10.0 and golpe_cd <= 0.0 and tipo != "golem" and tipo != "murcielago" and tipo != "candado" and tipo != "cadena" and tipo != "gota" and tipo != "cuarzo":   # el gólem solo hiere con el golpe al frente; el murciélago solo con la mordida
		golpe_cd = 0.5
		objetivo.herir(1, hacia)

# Se detiene, parpadea en rojo y embiste en línea recta.
# Le da vida al sprite según cómo se mueve cada tipo.
# Sin moverse (antes de ver a Diana o mientras reacciona): su animación de reposo si la tiene.
func _quieto(d: Dictionary) -> void:
	if anim_t <= 0.0 and d.anims.has("reposo"):   # al terminar el daño vuelve a reposo (antes se quedaba en el último cuadro)
		sprite.play("reposo")

var esfuerzo := 0.0
var giro_cad := 1.0        # cadena: ancho al voltearse (se encoge, cambia de lado y se estira)
var lado_cad_t := 0.0      # cadena: cuánto lleva Diana del otro lado
var volteando_cad := false
var doblez := Vector2.ONE   # candado: se aplasta/estira de verdad (se agacha antes del salto, se estira al saltar)
func _animar(delta: float, d: Dictionary) -> void:
	var rapidez := vel.length()
	var k := clampf(rapidez / maxf(d.vel, 1.0), 0.0, 2.0)
	fase_paso += delta * (4.0 + 9.0 * k) * personalidad
	aplastar = aplastar.lerp(Vector2.ONE, 1.0 - exp(-10.0 * delta))
	giro_golpe = lerpf(giro_golpe, 0.0, 1.0 - exp(-9.0 * delta))
	sprite.speed_scale = clampf(0.6 + k * 0.5, 0.6, 1.2)
	if tipo == "golem" and sprite.animation == "mover":
		sprite.speed_scale = clampf(0.85 + k * 0.15, 0.85, 1.0)   # acelera de a poco, sin que se note el cambio
	if not sprite.animation in ["mover", "reposo"]:
		sprite.speed_scale = 1.0   # ataques, daño y lanzamiento: completos, a su velocidad (si no, anim_t los cortaba a la mitad)
	var sx := 1.0
	var sy := 1.0
	var giro := 0.0
	var alto_y := 0.0
	match tipo:
		"escarabajo", "escarabajo_humo":
			# Camina contoneándose de lado a lado; quieto, respira.
			# Sin rebote de cuerpo: al moverse el sprite completo parecía que brincaba.
			# El paso lo dan solo las patas de la animación.
			giro = 0.0
			alto_y = 2.0   # patas dentro de la sombra
			sy = 1.0 + sin(t * 3.0) * 0.03 * (1.0 - k)
			if estado == "embiste":
				sx = 1.18
				sy = 0.86
				giro = 0.0
		"golem":
			# Peso: entre cuadros el cuerpo sube y baja de forma continua (no a saltos);
			# baja al apoyar el pie (cuadros 1 y 5) y sube al pasar la pierna. Quieto, respira.
			if sprite.animation == "mover":
				var fase := (sprite.frame + sprite.frame_progress) / 4.0 * PI
				alto_y = 4.0 - absf(sin(fase)) * 3.0   # hundido en el piso; el paso apenas lo levanta
			elif sprite.animation == "reposo":
				alto_y = 4.0 + sin(t * 1.6) * 0.5
			else:
				alto_y = 4.0
				if sprite.animation == "lanza" and sprite.frame >= 2 and sprite.frame <= 4:
					esfuerzo = float(randi_range(-1, 1))   # tiembla del esfuerzo
		"polilla":
			# Aletea (se ensancha y angosta) y sube y baja en ochos.
			var aleteo := sin(t * 22.0 * personalidad)
			sx = 1.0 + aleteo * 0.14
			sy = 1.0 - aleteo * 0.06
			alto_y = -2.0 + sin(t * 4.0) * 3.0 + sin(t * 8.0) * 1.0   # el cuerpo queda a la altura de los disparos de Diana
			giro = clampf(vel.x / 120.0, -1.0, 1.0) * 0.25
		"lingote":
			alto_y = _alto_lin()
		"brillito":
			alto_y = _alto_bri()
		"murcielago":
			alto_y = -2.0 + sin(t * 5.0) * 3.0   # flota a la altura de los disparos de Diana
			if sprite.animation == "dano":
				giro_golpe = sin(t * 18.0) * 0.25 * clampf(anim_t * 3.0, 0.0, 1.0)   # tambaleo mientras está aturdido
		"candado":
			# flota pesado, subiendo y bajando despacio (en la derrota queda en el piso)
			alto_y = 0.0   # va pegado al piso, arrastrándose
			if sprite.animation == "dano":
				esfuerzo = float(randi_range(-2, 2)) * clampf(anim_t * 4.0, 0.0, 1.0)   # tiembla aturdido
		_ when TIPOS[tipo].get("vuela", false):
			alto_y = -14.0 + sin(t * 4.0 * personalidad) * 4.0
			giro = clampf(vel.x / 120.0, -1.0, 1.0) * 0.2
		"vendedor":
			# Flota ondulando la túnica.
			alto_y = -4.0 + sin(t * 2.0) * 3.0
			sx = 1.0 + sin(t * 3.0) * 0.03
			giro = sin(t * 1.5) * 0.05
	# Lo que antes era estirar/aplastar/girar ahora se traduce a pixeles enteros:
	# aplastado = se hunde, estirado = se levanta, golpe = se sacude hacia atrás.
	sacudon = move_toward(sacudon, 0.0, 30.0 * delta)
	var hundir := clampf((1.0 - aplastar.y) * 10.0, -6.0, 6.0)
	var temblor_x := sacudon * (1.0 if Engine.get_physics_frames() % 4 < 2 else -0.4) + esfuerzo
	esfuerzo = 0.0
	sprite.position.x = roundf(temblor_x + giro_golpe * 6.0)
	if tipo == "golem":   # pegado a la rejilla de pixeles: al avanzar no tiemblan ni se cortan las orillas
		sprite.position.x += roundf(global_position.x) - global_position.x
	if estado != "salto":
		sprite.position.y = roundf(alto_y + hundir + emerge)
		if tipo == "golem":
			sprite.position.y += roundf(global_position.y) - global_position.y
	# Solo sube y baja en pixeles enteros: girar o estirar el sprite embarra el pixel art.
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE * escala_actual
	if tipo == "cadena":
		sprite.scale = Vector2(escala_actual * giro_cad, escala_actual * (1.0 + (1.0 - giro_cad) * 0.12))
	if tipo == "gota":
		_sync_borde_got()
		if sprite.animation == "mover" and (sprite.frame <= 3 or sprite.frame >= 18):
			# respira como gelatina mientras está en el piso
			var r_g := sin(t * 5.0 * personalidad) * 0.035
			sprite.scale = Vector2(escala_actual * (1.0 + r_g), escala_actual * (1.0 - r_g))
	if tipo == "candado" and sprite.animation != "pulir":
		# se encorva al avanzar: se aplasta al bajar y se estira al subir, más el doblez del salto
		sprite.scale = Vector2(escala_actual * doblez.x, escala_actual * doblez.y)

func _escarabajo(delta: float, hacia: Vector2, dir: Vector2) -> Vector2:
	estado_t -= delta
	match estado:
		"seguir":
			if cd_ataque <= 0.0 and hacia.length() < 170.0:
				estado = "aviso"
				estado_t = 0.8  # se alcanza a ver que se agacha antes de embestir
			return dir
		"aviso":
			# Se encoge y tiembla preparándose antes de embestir.
			if tipo != "vagoneta" and tipo != "engrane":
				sprite.modulate = Color(1.8, 0.5, 0.5) if int(estado_t * 14) % 2 == 0 else CLARO
			if estado_t <= 0.0:
				sprite.modulate = CLARO
				estado = "embiste"
				estado_t = 0.45
				rumbo = dir
				Juego.sonido("mover", true, -2.0)
			return Vector2.ZERO
		"embiste":
			if int(estado_t * 30) % 2 == 0:
				Fx.polvo(main.mundo, position)
			if estado_t <= 0.0:
				estado = "frena"
				estado_t = 0.3
				if tipo == "vagoneta" or tipo == "engrane":
					estado_t = 0.7
					especial("frena")
			return rumbo
		"frena":
			if estado_t <= 0.0:
				estado = "seguir"
				cd_ataque = randf_range(2.5, 4.0)
			return Vector2.ZERO
	return dir

# Avanza a saltitos; cada tanto marca el piso, salta hacia Diana y aplasta.
func _candado(delta: float, hacia: Vector2, dir: Vector2) -> Vector2:
	if estado == "salto":
		return Vector2.ZERO
	if cd_ataque <= 0.0 and hacia.length() < 220.0:
		cd_ataque = randf_range(3.0, 4.5)
		_saltar(objetivo.position)
		return Vector2.ZERO
	pausa -= delta
	if pausa < -0.8:
		pausa = 0.6
	return Vector2.ZERO if pausa > 0.0 else dir

func _saltar(destino: Vector2) -> void:
	estado = "salto"
	var marca := Marca.new()
	marca.position = destino
	main.mundo.add_child(marca)
	var desde := position
	var tw := create_tween()
	aplastar = Vector2(1.25, 0.75)
	tw.tween_interval(0.6)
	tw.tween_callback(func(): aplastar = Vector2(0.75, 1.3))
	tw.tween_method(func(k: float):
		position = desde.lerp(destino, k)
		sprite.position.y = -sin(k * PI) * 50.0, 0.0, 1.0, 0.45)
	tw.tween_callback(func():
		if is_instance_valid(marca):
			marca.queue_free()
		if not main.permitido(position):
			position = desde
		sprite.position.y = 0.0
		aplastar = Vector2(1.45, 0.6)
		main.sacudir(5.0)
		Juego.sonido("golpe", false)
		Fx.estallido(main.mundo, position, Color(0.9, 0.8, 0.5))
		Fx.chispas(main.mundo, position, Color(0.8, 0.7, 0.5), 12)
		if objetivo.position.distance_to(position) < 40.0:
			objetivo.herir(1, objetivo.position - position)
		estado = "seguir")

func _disparar(clase: String, direccion: Vector2) -> void:
	var s = preload("res://scripts/shot.gd").new()
	s.main = main
	s.enemigo = true
	s.tipo = clase
	s.direccion = direccion
	s.position = position + Vector2(0, -alto * 0.6)
	main.agregar(s)
	Juego.sonido("disparo_enemigo", true, -8.0)

# Fase 1: bolas de niebla y teletransporte. Fase 2 (menos de la mitad de vida):
# se cubre de humo y llama escarabajos; el humo se va cuando los pules.
func _jefe(delta: float, hacia: Vector2) -> void:
	cd_tele -= delta
	if fase == 1 and vida <= vida_max / 2:
		fase = 2
		main.mensaje("¡El Vendedor de Humo se cubre de niebla!", 2.0)
		cd_llamar = 0.5
	if cd_ataque <= 0.0 and not tele_activo:
		cd_ataque = 1.6 if fase == 1 else 1.1
		var abanico := [-0.3, 0.0, 0.3] if fase == 1 else [-0.5, -0.25, 0.0, 0.25, 0.5]
		if not (sprite.animation == "dano" and anim_t > 0.0):   # no le corta la reacción al golpe
			especial("ataque")
		# Las bolas salen cuando abre la capa (cuadro 4), con fogonazo de brasas y humo.
		var dir_ataque := hacia.normalized()
		get_tree().create_timer(0.22).timeout.connect(func():
			if not vivo:
				return
			_fogonazo(dir_ataque)
			for a in abanico:
				_disparar("niebla", dir_ataque.rotated(a)))
	if fase == 2:
		llamados = llamados.filter(func(e): return is_instance_valid(e) and e.vivo)
		cd_llamar -= delta
		if llamados.is_empty() and cd_llamar <= 0.0:
			cd_llamar = 6.0
			for i in 3:
				var p: Vector2 = position + Vector2.RIGHT.rotated(TAU * i / 3.0) * 60.0
				if main.permitido(p):
					llamados.append(main.aparecer_ya("escarabajo_humo", p))
		# El humo dura mientras vivan los escarabajos, pero nunca más de 8 s (por si uno se atora).
		humo_t = humo_t + get_process_delta_time() if not llamados.is_empty() else 0.0
		if humo_t > 8.0:
			for e in llamados:
				if is_instance_valid(e) and e.vivo:
					e.danar(99, Vector2.ZERO)
			llamados.clear()
			humo_t = 0.0
			cd_llamar = 6.0
		humo = not llamados.is_empty()
		sprite.modulate = Color(0.6, 0.6, 0.7, 0.55) if humo else CLARO
		if humo and int(t * 10) % 3 == 0:
			Fx.polvo(main.mundo, position + Vector2(randf_range(-16, 16), randf_range(-40, 0)))
	if cd_tele <= 0.0 and not tele_activo:
		cd_tele = 5.0
		tele_activo = true   # nada interrumpe el humo (ni el daño ni el ataque)
		var zona: Rect2 = main.interior().grow(-48)
		var tw := create_tween()
		# Destello negro, se deshace en humo, cambia de lugar y se vuelve a formar (la animación al revés).
		tw.tween_callback(func():
			_destello_negro()
			sprite.play("tele")
			anim_t = anim_tele())
		tw.tween_interval(anim_tele())
		tw.tween_callback(func():
			sprite.visible = false
			var p := Vector2(randf_range(zona.position.x, zona.end.x), randf_range(zona.position.y, zona.end.y))
			if main.permitido(p):
				position = p)
		tw.tween_interval(0.3)
		tw.tween_callback(func():
			sprite.visible = true
			_destello_negro()
			sprite.play_backwards("tele")
			anim_t = anim_tele())
		tw.tween_interval(anim_tele())
		tw.tween_callback(func(): tele_activo = false)

# Estallido de oscuridad: apaga la luz alrededor y suelta humo negro y chispas moradas.
func _destello_negro() -> void:
	var centro := position + Vector2(0, -alto * 0.5)
	var sombra := PointLight2D.new()
	sombra.texture = Fx.textura_luz()
	sombra.blend_mode = Light2D.BLEND_MODE_SUB
	sombra.texture_scale = 1.3
	sombra.energy = 1.6
	sombra.color = Color(1, 1, 1)
	sombra.position = centro
	main.mundo.add_child(sombra)
	var tw := sombra.create_tween()
	tw.tween_property(sombra, "energy", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(sombra.queue_free)
	_fx_vendedor(centro, "fx_ven_sombra", 11.0, 0.34, false)
	Fx.chispas(main.mundo, centro, Color(0.45, 0.25, 0.6), 6)
	main.sacudir(2.5)

func _descubrir() -> void:
	if detecto:
		return
	detecto = true
	Fx.alerta(self, alto)
	aplastar = Vector2(0.8, 1.25)

# Reproduce una animación de un solo uso (daño, ataque) si el sprite la tiene.
# Polilla: al bajar las alas (cuadro 4 del ataque) suelta una nube de polvo que avanza hacia Diana y la daña si la toca.
func _nube_al_aletear(dir: Vector2) -> void:
	var ya := [false]
	var al_cuadro := func():
		if ya[0] or sprite.animation != "ataque" or sprite.frame < 3:
			return
		ya[0] = true
		var lado := -1.0 if dir.x < 0.0 else 1.0
		var inicio := position + Vector2(lado * 18.0, sprite.position.y - 6.0)
		var nube: AnimatedSprite2D = Fx.animar(main.mundo, inicio, "pol_polvo", 11.0, Color.WHITE, 0.5, lado > 0.0)
		var sin_luz := CanvasItemMaterial.new()
		sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # colores tal cual el dibujo (sin aclarar ni penumbra)
		nube.material = sin_luz
		var golpeo := [false]
		var morado := Color(0.7, 0.45, 0.95)
		Fx.chispas(main.mundo, inicio, morado, 7)
		var suelta := [0.0]
		var tw := nube.create_tween()
		tw.tween_method(func(k: float):
			if not is_instance_valid(nube):
				return
			nube.position = inicio + dir * 70.0 * (1.0 - pow(1.0 - k, 2.0))   # sale rápido y frena
			if k - suelta[0] > 0.12:   # va soltando motitas de polvo y escamas
				suelta[0] = k
				Fx.confeti(main.mundo, nube.position + Vector2(randf_range(-10, 10), randf_range(-6, 6)), Color(0.55, 0.5, 0.62), 3)
				Fx.chispas(main.mundo, nube.position, morado, 2)
			if not golpeo[0] and k < 0.7 and is_instance_valid(objetivo) 					and objetivo.position.distance_to(nube.position + Vector2(0, 8)) < 22.0:
				golpeo[0] = true
				objetivo.herir(1, objetivo.position - nube.position), 0.0, 1.0, 0.72)
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(sprite) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

# Efecto dibujado del Vendedor, con sus colores tal cual (sin la penumbra del cuarto).
func _fx_vendedor(pos: Vector2, clave: String, fps: float, escala: float, voltear: bool) -> void:
	var fx: AnimatedSprite2D = Fx.animar(main.mundo, pos, clave, fps, Color.WHITE, escala, voltear)
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	fx.material = sin_luz
	fx.z_index = 5

# Estallido de impacto (dibujo en grises) teñido del color de cada enemigo; el crítico es más grande.
func _fx_golpe(critico: bool, color: Color) -> void:
	var pos := position + Vector2(randf_range(-4, 4), -alto * 0.5 + randf_range(-4, 4))
	var tinte := color.lerp(Color.WHITE, 0.2)
	var fx: AnimatedSprite2D = Fx.animar(main.mundo, pos, "fx_golpe_fuerte" if critico else "fx_golpe", 16.0, tinte, 0.33 if critico else 0.24, randf() < 0.5)
	# Brilla (se suma a lo de atrás) en vez de verse pegado encima.
	var brillo := CanvasItemMaterial.new()
	brillo.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	brillo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = brillo
	fx.z_index = 5
	fx.rotation = randf_range(-0.3, 0.3)
	# Rebote: sale grande y se asienta; al final se desvanece.
	var base: Vector2 = fx.scale
	fx.scale = base * 1.45
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", base, 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(fx, "modulate:a", 0.0, 0.14).set_delay(0.06)
	# Copia sólida debajo para que el dibujo no se pierda sobre fondos claros.
	var solido: AnimatedSprite2D = Fx.animar(main.mundo, pos, "fx_golpe_fuerte" if critico else "fx_golpe", 16.0, Color(tinte, 0.55), 0.33 if critico else 0.24, fx.flip_h)
	solido.rotation = fx.rotation
	solido.z_index = 4
	var sl := CanvasItemMaterial.new()
	sl.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	solido.material = sl
	# Destello de luz del color del enemigo que ilumina el piso y se apaga.
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.7 if critico else 0.45
	luz.energy = 1.6 if critico else 1.0
	luz.color = tinte
	luz.position = pos
	main.mundo.add_child(luz)
	var tl := luz.create_tween()
	tl.tween_property(luz, "energy", 0.0, 0.25 if critico else 0.18)
	tl.tween_callback(luz.queue_free)
	Fx.estallido(main.mundo, pos, Color(tinte, 0.7))
	Fx.chispas(main.mundo, pos, tinte, 10 if critico else 5)
	Fx.chispas(main.mundo, pos, Color(1, 1, 1), 3 if critico else 1)

func _fogonazo(dir: Vector2) -> void:
	var brasa := Color(1.0, 0.78, 0.25)
	var boca := position + Vector2(signf(dir.x) * 14.0, -alto * 0.5)
	_fx_vendedor(boca, "fx_ven_fogonazo", 12.0, 0.25, dir.x > 0.0)
	Fx.chispas(main.mundo, boca, brasa, 6)
	var fl := PointLight2D.new()
	fl.texture = Fx.textura_luz()
	fl.texture_scale = 0.9
	fl.color = brasa
	fl.energy = 1.4
	fl.position = boca
	main.mundo.add_child(fl)
	var tw := fl.create_tween()
	tw.tween_property(fl, "energy", 0.0, 0.4)
	tw.tween_callback(fl.queue_free)
	main.sacudir(2.0)

# Nube de humo negro-verde que brota, gira, sube y se desvanece; con destello verde y brasas.
func _bocanadas(cuantas: int, fuerza: float, base := Color(0.19, 0.24, 0.19), luz_col := Color(0.5, 1.0, 0.55)) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = cuantas * 2
	p.lifetime = 1.1 * fuerza
	p.explosiveness = 0.75
	p.texture = Fx.textura_luz()
	p.position = position + Vector2(0, -alto * 0.45)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 16.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 38.0 * fuerza
	p.gravity = Vector2(0, -22)
	p.damping_min = 10.0
	p.damping_max = 25.0
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.09 * fuerza
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.3))
	curva.add_point(Vector2(0.35, 1.0))
	curva.add_point(Vector2(1, 0.6))
	p.scale_amount_curve = curva
	var g := Gradient.new()
	g.set_color(0, Color(base.darkened(0.45), 0.0))
	g.add_point(0.15, Color(base.darkened(0.25), 0.55))
	g.add_point(0.6, Color(base.lightened(0.1), 0.35))
	g.set_color(g.get_point_count() - 1, Color(base.lightened(0.4), 0.0))
	p.color_ramp = g
	p.z_index = 3
	main.mundo.add_child(p)
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.8
	luz.color = luz_col
	luz.energy = 1.3 * fuerza
	luz.position = p.position
	main.mundo.add_child(luz)
	var tw := luz.create_tween()
	tw.tween_property(luz, "energy", 0.0, 0.5)
	tw.tween_callback(luz.queue_free)
	Fx.chispas(main.mundo, p.position, Color(1.0, 0.75, 0.25), int(6 * fuerza))
	Fx.chispas(main.mundo, p.position, luz_col, int(5 * fuerza))

# Humo negro que le sale del caparazón todo el tiempo y una brasa en el ojo (escarabajos del Vendedor).
func _humo_propio() -> void:
	var p := CPUParticles2D.new()
	p.amount = 14
	p.lifetime = 1.1
	p.position = Vector2(0, -alto * 0.75)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(16, 4)
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(0, -18)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.texture = Fx.textura_luz()   # bocanada redonda y suave
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.1
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.4))
	curva.add_point(Vector2(0.3, 1.0))
	curva.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = curva
	var g := Gradient.new()
	g.set_color(0, Color(0.22, 0.26, 0.22, 0.7))
	g.set_color(1, Color(0.3, 0.42, 0.3, 0.0))
	p.color_ramp = g
	p.show_behind_parent = true
	add_child(p)
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.18
	luz.energy = 0.5
	luz.color = Color(1.0, 0.75, 0.25)
	luz.position = Vector2(0, -alto * 0.55)
	add_child(luz)
	# Resplandor verde venenoso para que el caparazón negro se lea en la penumbra.
	var aura := PointLight2D.new()
	aura.texture = Fx.textura_luz()
	aura.texture_scale = 0.55
	aura.energy = 0.9
	aura.color = Color(0.55, 0.95, 0.6)
	aura.position = Vector2(0, -alto * 0.5)
	add_child(aura)

# Pedazos dibujados del enemigo: saltan en arco, giran, rebotan y se quedan en el piso un rato.
func _soltar_pedazos(clave: String, cuantos: int, desde := Vector2.INF, fuerza := 1.0) -> void:
	if tipo == "golem" and clave == "fx_ped_gol":
		clave = "fx_ped_gol2"
	if tipo == "guardia" and clave == "fx_ped_gua":
		clave = "fx_gua_ped"
	var m := Fx.meta(clave)
	var centro := position + Vector2(0, -alto * 0.5) if desde == Vector2.INF else desde
	for i in cuantos:
		var s := Sprite2D.new()
		s.texture = Fx.cuadro(clave, randi() % int(m.n))
		s.scale = Vector2.ONE * (0.35 if clave == "fx_ped_gol2" else (0.22 if clave == "fx_gua_ped" else 0.11))
		s.position = centro + (Vector2(randf_range(-radio * 0.5, radio * 0.5), randf_range(-alto * 0.3, alto * 0.2)) if desde == Vector2.INF else Vector2(randf_range(-6, 6), randf_range(-4, 2)))
		s.z_index = 2
		main.mundo.add_child(s)
		var ini := s.position
		var base := position if desde == Vector2.INF else Vector2(desde.x, desde.y + 4.0)
		var fin := Vector2(base.x + randf_range(-radio * 1.7, radio * 1.7) * fuerza, base.y + randf_range(-5.0, 6.0))
		var altura := randf_range(10.0, 28.0) * fuerza
		var dur := randf_range(0.45, 0.75)
		var tw := s.create_tween()
		tw.tween_method(func(k: float): s.position = ini.lerp(fin, k) + Vector2(0, -altura * 4.0 * k * (1.0 - k)), 0.0, 1.0, dur)
		tw.parallel().tween_property(s, "rotation", randf_range(-6.0, 6.0), dur)
		tw.tween_method(func(k: float): s.position = fin + Vector2(0, -altura * k * (1.0 - k)), 0.0, 1.0, dur * 0.4)
		tw.tween_interval(randf_range(2.0, 3.2))
		tw.tween_property(s, "modulate:a", 0.0, 0.8)
		tw.tween_callback(s.queue_free)

# Chispas de metal al rojo vivo (armaduras).
func _chispas_metal(pos: Vector2) -> void:
	if tipo == "guardia":
		_chispa_gua(pos, 0.5)
		return
	var fx: AnimatedSprite2D = Fx.animar(main.mundo, pos, "fx_chispa_metal", 16.0, Color.WHITE, 0.38, randf() < 0.5)
	var brillo := CanvasItemMaterial.new()
	brillo.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	brillo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = brillo
	fx.z_index = 5
	Fx.chispas(main.mundo, pos, Color(1.0, 0.6, 0.2), 6)
	Fx.chispas(main.mundo, pos, Color(1.0, 0.95, 0.8), 3)

# Golpe contra el piso al frente (gólem y guardia): grietas, polvo, chispas y daño en esa zona.
func _golpe_suelo(hacia: Vector2) -> void:
	var lado := signf(hacia.x) if absf(hacia.x) > 1.0 else 1.0
	var t_imp := (1.0 + 1.0 + 1.6 + 0.8) if tipo == "golem" else 5.0   # guardia: el mazo pega en el cuadro 6
	get_tree().create_timer(t_imp / sprite.sprite_frames.get_animation_speed("ataque")).timeout.connect(func():   # cuando los puños tocan el piso (cuadro 5)
		if not vivo:
			return
		var p := position + Vector2(lado * (radio + 16.0), 0)
		var fx: AnimatedSprite2D = Fx.animar(main.mundo, p + Vector2(0, -16), "fx_gua_impacto", 13.0, Color.WHITE, 0.42 if tipo == "golem" else 0.34, lado < 0.0)
		var sin_luz := CanvasItemMaterial.new()
		sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		fx.material = sin_luz
		fx.z_index = 4
		var fl := PointLight2D.new()   # destello del golpe que ilumina el piso
		fl.texture = Fx.textura_luz()
		fl.texture_scale = 0.7
		fl.color = Color(1.0, 0.7, 0.35)
		fl.energy = 1.4
		fl.position = p
		main.mundo.add_child(fl)
		var tf := fl.create_tween()
		tf.tween_property(fl, "energy", 0.0, 0.35)
		tf.tween_callback(fl.queue_free)
		Fx.chispas(main.mundo, p, Color(1.0, 0.75, 0.35), 8)
		Fx.polvo(main.mundo, p)
		Fx.polvo(main.mundo, p + Vector2(8, 0))
		main.sacudir(5.0 if tipo == "golem" else 3.0)
		if tipo == "golem":
			marca_piso("fx_gol_crater", p + Vector2(0, 6), 1.0)
			_soltar_pedazos("fx_ped_gol2", 5, p, 1.4)                       # losas y piedra del piso
			_soltar_pedazos("fx_ped_gol2", 3, p + Vector2(-lado * 6.0, -14.0), 0.8)   # se le desprende del puño
			particulas_gol(p, 8)
		else:
			_grietas(p, 1.0)
		_soltar_pedazos("fx_ped_gol", 5)
		if objetivo.position.distance_to(p) < 30.0 and not main.PRUEBAS:
			objetivo.herir(1, objetivo.position - position))

# El gólem arranca una roca del piso y se la avienta a Diana.
func _lanzar_roca(hacia: Vector2) -> void:
	var lado := signf(hacia.x) if absf(hacia.x) > 1.0 else 1.0
	var piso := position + Vector2(lado * 36.0, -5)
	# la tierra y la roca del dibujo van encima del piso: se borran las marcas viejas de ese lugar
	for viejo in get_tree().get_nodes_in_group("marca_golem"):
		if is_instance_valid(viejo) and viejo.position.distance_to(piso) < (18.0 if viejo.has_meta("huella") else 60.0):
			viejo.remove_from_group("marca_golem")
			var tv := viejo.create_tween()
			tv.tween_property(viejo, "modulate:a", 0.0, 0.3)
			tv.tween_callback(viejo.queue_free)
	var hechos := {}
	var al_cuadro := func():
		if not vivo or sprite.animation != "lanza":
			return
		var f := sprite.frame
		if f == 1 and not hechos.has(1):   # al agarrarla el piso empieza a agrietarse alrededor
			hechos[1] = true
			marca_piso("fx_gol_arranca", piso, 1.0, 4.0, sprite.sprite_frames.get_animation_speed("lanza") * 1.4)
			main.sacudir(1.5)
		elif f == 2 and not hechos.has(2):   # las manos aprietan: crujido y polvo
			hechos[2] = true
			Fx.polvo(main.mundo, piso)
			particulas_gol(piso, 3)
			main.sacudir(2.0)
		elif f == 3 and not hechos.has(3):   # la roca se despega: revientan las losas
			hechos[3] = true
			Fx.chispas(main.mundo, piso + Vector2(0, -6), Color(1.0, 0.55, 0.2), 16)
			for k in 4:
				Fx.polvo(main.mundo, piso + Vector2(randf_range(-20, 20), randf_range(-4, 4)))
			_soltar_pedazos("fx_ped_gol2", 8, piso, 1.3)
			particulas_gol(piso, 8)
			onda_piso(piso, 44.0, Color(0.5, 0.45, 0.38, 0.8), 0.5)
			_brasas_suben(piso, 10, 18.0)
			_niebla_morada(piso, 8, 18.0)
			main.sacudir(5.0)
		elif f == 5 and not hechos.has(5):   # queda el hueco y le cae tierra a la roca
			hechos[5] = true
			_tierra_cayendo(piso, lado, 3.0 / sprite.sprite_frames.get_animation_speed("lanza"))
		elif f == 8 and not hechos.has(8):   # toma impulso
			hechos[8] = true
			Fx.polvo(main.mundo, position + Vector2(-lado * 12.0, 0))
			main.sacudir(1.5)
		elif f == 9 and not hechos.has(9):   # la suelta
			hechos[9] = true
			var r = preload("res://scripts/shot.gd").new()
			r.main = main
			r.enemigo = true
			r.tipo = "roca"
			r.set_meta("lanzador", self)
			r.position = position + Vector2(lado * 49.0, -99.0)
			r.direccion = (objetivo.position + Vector2(0, -20) - r.position).normalized()
			r.vida = maxf(0.4, r.position.distance_to(objetivo.position + Vector2(0, -20)) / 150.0)
			main.agregar(r)
			Fx.chispas(main.mundo, r.position, Color(1.0, 0.6, 0.2), 10)
			particulas_gol(r.position + Vector2(0, 10), 4)
			Fx.polvo(main.mundo, position + Vector2(-lado * 10.0, 0))
			onda_piso(position, 30.0, Color(0.5, 0.45, 0.38, 0.6), 0.4)
			main.sacudir(3.5)
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(sprite) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

func anim_tele() -> float:
	return sprite.sprite_frames.get_frame_count("tele") / sprite.sprite_frames.get_animation_speed("tele")

func anim_t_de(nombre: String) -> float:
	var total := 0.0
	for i in sprite.sprite_frames.get_frame_count(nombre):
		total += sprite.sprite_frames.get_frame_duration(nombre, i)
	return total / sprite.sprite_frames.get_animation_speed(nombre)

func especial(nombre: String) -> void:
	if tele_activo:
		return
	if not sprite.sprite_frames.has_animation(nombre):
		return
	sprite.play(nombre)
	var total := 0.0
	for i in sprite.sprite_frames.get_frame_count(nombre):
		total += sprite.sprite_frames.get_frame_duration(nombre, i)
	anim_t = total / sprite.sprite_frames.get_animation_speed(nombre)

func danar(n: int, desde: Vector2, critico := false) -> void:
	if not vivo:
		return
	if tipo == "cuarzo" and not _cua_golpeable():
		return   # bajo tierra no le pegan
	_descubrir()
	reaccion = 0.0
	if tipo == "guardia" and cubierto_t > 0.0 and signf(desde.x - position.x) == (-1.0 if sprite.flip_h else 1.0):
		_rebote_escudo(desde)   # de frente al escudo: rebota, sin daño
		return
	if tipo == "guardia" and cd_escudo > 1.5 and cd_escudo < 90.0:
		cd_escudo = 1.5   # si le disparan, pronto se cubre
	# el gólem es pesado: un golpe no le corta el ataque ni el lanzamiento (antes se quedaba trabado en la pose)
	# y pegado a Diana tampoco se tambalea: solo destella y suelta pedazos, y sigue golpeando
	var golem_firme := tipo == "golem" and ((anim_t > 0.0 and sprite.animation in ["ataque", "lanza"]) or position.distance_to(objetivo.position) < 260.0)
	if estado != "embiste" and not golem_firme and not (tipo == "cuarzo" and (estado != "seguir" or (sprite.animation == "ataque" and anim_t > 0.0))):
		especial("dano")
	if humo:
		Fx.chispas(main.mundo, position + Vector2(0, -alto * 0.5), Color(0.6, 0.6, 0.65), 3)
		_fx_golpe(false, Color(0.6, 0.6, 0.68))
		return
	vida -= n
	_fx_golpe(critico, TIPOS[tipo].color)
	if TIPOS[tipo].get("metal", false):
		_chispas_metal(position + Vector2(0, -alto * 0.55))
	if tipo == "guardia":
		_esencia_gua(position + Vector2(randf_range(-6, 6), -alto * 0.6), 0.28, 0.8)
		_soltar_pedazos("fx_ped_gua", 2, position + Vector2(0, -alto * 0.6), 0.6)
	if TIPOS[tipo].has("pedazos") and vida > 0:
		_soltar_pedazos(TIPOS[tipo].pedazos, 3)
		# Nubecita de su polvo (verdín en el escarabajo, roca en el gólem) con su luz.
		_bocanadas(6, 0.5, TIPOS[tipo].get("polvo", Color(0.3, 0.3, 0.3)), TIPOS[tipo].get("luz", Color(1, 0.8, 0.5)))
	Fx.numero(main.mundo, position + Vector2(0, -alto), n, critico)
	empuje = desde * (60.0 if tipo == "vendedor" else 220.0)
	# Destello blanco con contorno blanco de 1 pixel que se apaga.
	mat.set_shader_parameter("destello", 0.45)  # suave: que se vea la animación de daño debajo
	mat.set_shader_parameter("contorno", 1.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v): mat.set_shader_parameter("destello", v), 0.45, 0.0, 0.12)
	tw.tween_method(func(v): mat.set_shader_parameter("contorno", v), 1.0, 0.0, 0.25)
	# Se aplasta con el golpe y suelta chispas de óxido.
	aplastar = Vector2(1.35, 0.7)
	giro_golpe = (0.35 if desde.x >= 0.0 else -0.35) * (1.6 if critico else 1.0)
	sacudon = 4.0 * (1.0 if desde.x >= 0.0 else -1.0) * (1.5 if critico else 1.0)
	if tipo == "polilla":
		# Golpe de polilla: destello, retroceso fuerte, chispazo de esencia, escamas y polvo de alas.
		var centro := position + Vector2(0, sprite.position.y - 8.0)
		mat.set_shader_parameter("destello", 0.75)
		create_tween().tween_method(func(v): mat.set_shader_parameter("destello", v), 0.75, 0.0, 0.22)
		sacudon *= 2.5
		empuje *= 1.5
		_golpe_polilla(centro, desde, critico)
		aplastar = Vector2(1.0, 1.6)   # salta 6 pixeles hacia arriba y vuelve sola (se traduce en _animar)
	elif tipo == "candado":
		_golpe_candado(position + Vector2(0, sprite.position.y - 26.0), desde, critico)
	elif tipo == "cadena":
		_golpe_cadena(desde, critico)
	elif tipo == "nubecita":
		_golpe_nube(desde, critico)
	elif tipo == "gota":
		_golpe_gota(desde, critico)
	elif tipo == "cuarzo":
		_golpe_cuarzo(desde, critico)
	elif tipo == "vagoneta":
		_golpe_vagoneta(desde, critico)
	elif tipo == "engrane":
		_golpe_engrane(desde, critico)
	elif tipo == "lingote":
		_golpe_lingote(desde, critico)
	elif tipo == "brillito":
		_golpe_brillito(desde, critico)
	elif tipo == "murcielago":
		var centro_m := position + Vector2(0, sprite.position.y - 20.0)
		mat.set_shader_parameter("destello", 0.7)
		create_tween().tween_method(func(v): mat.set_shader_parameter("destello", v), 0.7, 0.0, 0.2)
		sacudon *= 2.0
		empuje *= 1.4
		_golpe_murcielago(centro_m, desde, critico)
	else:
		Fx.chispas(main.mundo, position + Vector2(0, -alto * 0.5), Color(0.95, 0.6, 0.3), 6)
	Juego.sonido("golpe", true, -6.0)
	main.sacudir(2.0 if critico else 1.2, desde)
	main.pausa_impacto(0.05 if critico else 0.03)
	if vida <= 0:
		_pulir()
	elif critico:
		main.logro("critico")

# La tina del limpiador ultrasónico pule de golpe al enemigo que cae en ella.
# Ahora es una piscina hundida: el enemigo se hunde, hace remolino y sale pulido.
func _pulir_en_tina() -> void:
	vivo = false
	if tipo == "gota":
		_tina_gota()
	luz_aviso.visible = false
	var agua := Color(0.35, 0.85, 0.8)
	Juego.sonido("pulir", true, -8.0)
	Fx.chispas(main.mundo, position + Vector2(0, -6), agua, 14)
	Fx.estallido(main.mundo, position, agua)
	Fx.burbujas(main.mundo, position + Vector2(0, -4), 10, 10.0)
	var tw := create_tween()
	tw.tween_property(sprite, "position:y", sprite.position.y + alto * 0.8, 0.6).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "modulate", Color(0.3, 0.6, 0.6, 0.0), 0.6)
	tw.parallel().tween_property(sprite, "rotation", 0.6, 0.6)
	tw.tween_callback(func():
		Fx.burbujas(main.mundo, position + Vector2(0, -4), 14, 12.0)
		Fx.chispas(main.mundo, position + Vector2(0, -10), Color(1.0, 0.9, 0.5), 12)
		Fx.numero(main.mundo, position + Vector2(0, -alto), vida, true)
		main.mensaje("¡Se hundió en la piscina!", 1.0)
		vida = 0
		vivo = true
		sprite.modulate = Color(1, 1, 1, 0)
		_pulir())

func _pulir() -> void:
	vivo = false
	main.pulidos += 1
	main.enemigo_pulido()
	var centro := position + Vector2(0, -alto * 0.5)
	Juego.sonido("pulir", true, -2.0)
	Fx.estallido(main.mundo, centro, Color(1.0, 0.9, 0.6))
	Fx.chispas(main.mundo, centro, Color(1.0, 0.95, 0.7), 10)
	Fx.confeti(main.mundo, centro, TIPOS[tipo].color, 14 if tipo != "vendedor" else 40)
	main.sacudir(3.0 if tipo != "vendedor" else 10.0)
	main.pausa_impacto(0.05 if tipo != "vendedor" else 0.25)
	# Recompensas.
	for i in (randi_range(1, 3) if tipo != "vendedor" else 20):
		main.soltar("destello", position)
	if randf() < 0.12:
		main.soltar("corazon", position)
	if randf() < 0.1:
		main.soltar("pocion", position)
	luz_aviso.visible = false
	sprite.rotation = 0.0
	# Saltito sin girar (girar embarra el pixel art).
	var y0 := sprite.position.y
	if tipo != "murcielago" and tipo != "candado" and tipo != "cadena" and tipo != "nubecita" and tipo != "gota" and tipo != "cuarzo" and tipo != "vagoneta" and tipo != "engrane" and tipo != "lingote" and tipo != "brillito":   # el murciélago ya trae su sacudida dibujada (si no, parecía agacharse dos veces)
		var tw0 := create_tween()
		tw0.tween_property(sprite, "position:y", y0 - 6.0, 0.1).set_ease(Tween.EASE_OUT)
		tw0.tween_property(sprite, "position:y", y0, 0.12).set_ease(Tween.EASE_IN)
	sprite.speed_scale = 0.6   # eliminación más lenta para que se aprecie (pulir y fin)
	if TIPOS[tipo].get("humo", false):
		_bocanadas(30, 1.2)
		var dur := sprite.sprite_frames.get_frame_count("pulir") / sprite.sprite_frames.get_animation_speed("pulir") / 0.6
		get_tree().create_timer(dur * 0.4).timeout.connect(func(): if is_instance_valid(self): _bocanadas(24, 1.0))
		sprite.create_tween().tween_property(sprite, "modulate:a", 0.0, dur * 0.7).set_delay(dur * 0.3)
	var dd: Dictionary = TIPOS[tipo]
	if dd.has("pedazos"):
		# Al romperse: pedazos que saltan y quedan regados, polvo/humo de su color, brasas y sacudida.
		var durp: float = sprite.sprite_frames.get_frame_count("pulir") / sprite.sprite_frames.get_animation_speed("pulir") / 0.6
		get_tree().create_timer(durp * 0.5).timeout.connect(func():
			if not is_instance_valid(self):
				return
			_soltar_pedazos(dd.pedazos, 18 if tipo == "golem" else 12)
			_bocanadas(22, 1.0, dd.get("polvo", Color(0.3, 0.3, 0.3)), dd.get("luz", Color(1, 0.8, 0.5)))
			if dd.get("metal", false):
				_chispas_metal(position + Vector2(0, -alto * 0.5))
			if tipo == "golem":
				_estallido_golem()
			main.sacudir(5.0 if tipo == "golem" else 2.5))
	if sprite.sprite_frames.has_animation("pulir"):
		sprite.play("pulir")
		var cuadro: int = TIPOS[tipo].get("desarma_cuadro", -1)
		if cuadro >= 0:
			# Se desarma desde un cuadro a mitad del pulido (ya limpio y completo).
			sprite.frame_changed.connect(func():
				if sprite.animation == "pulir" and sprite.frame > cuadro and sprite.is_playing():
					sprite.pause()
					sprite.frame = cuadro
					_despedirse())
		else:
			sprite.animation_finished.connect(_despedirse, CONNECT_ONE_SHOT)
	else:
		_despedirse()


# Ya limpio: se queda un momento brillando, sube un poco y se desvanece entre destellos.
func _despedirse() -> void:
	if tipo == "guardia":
		_desarmar_guardia()
		return
	if tipo == "polilla":
		_deshacer_polilla()
		return
	if tipo == "murcielago":
		_deshacer_murcielago()
		return
	if tipo == "candado":
		_deshacer_candado()
		return
	if tipo == "cadena":
		_deshacer_cadena()
		return
	if tipo == "nubecita":
		_deshacer_nube()
		return
	if tipo == "gota":
		_deshacer_gota()
		return
	if tipo == "cuarzo":
		_deshacer_cuarzo()
		return
	if tipo == "vagoneta":
		_deshacer_vagoneta()
		return
	if tipo == "engrane":
		_deshacer_engrane()
		return
	if tipo == "lingote":
		_deshacer_lingote()
		return
	if tipo == "brillito":
		_deshacer_brillito()
		return
	# Si su animación ya termina deshecha en destellos, se va sin desvanecerse otra vez.
	var centro := position + Vector2(0, -alto * 0.5)
	if sprite.sprite_frames.has_animation("fin"):
		_desaparecer()
		return
	if TIPOS[tipo].get("desarma", false):
		# Brilla un instante y se desarma en pedacitos que quedan en el piso.
		var tw2 := create_tween()
		tw2.tween_interval(0.6)
		tw2.tween_callback(func():
			Fx.chispas(main.mundo, centro, Color(1.0, 0.85, 0.4), 8)
			Fx.desintegrar(main.mundo, sprite, position.y, CLARO)
			queue_free())
		return
	if tipo == "vendedor" or TIPOS[tipo].get("queda", false):
		# Sus restos (capa vacía, piezas) quedan; su capa vacía se queda en el piso un momento y se desvanece sin moverse.
		var tv := create_tween()
		tv.tween_interval(1.4)
		tv.tween_property(sprite, "modulate:a", 0.0, 1.2)
		tv.tween_callback(queue_free)
		return
	var tw := create_tween()
	tw.tween_interval(0.7)
	tw.tween_callback(func():
		Fx.chispas(main.mundo, centro, Color(1.0, 0.85, 0.4), 8)
		Fx.confeti(main.mundo, centro, Color(1.0, 0.85, 0.4), 6))
	tw.tween_property(sprite, "position:y", sprite.position.y - 12.0, 1.0).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "modulate", Color(1.6, 1.5, 1.1, 0.0), 1.0)
	tw.tween_callback(queue_free)


# Animación propia de desaparición + efectos de apoyo; el último cuadro queda en el piso como restos.
func _desaparecer() -> void:
	var piso := Vector2(position.x, position.y)
	var medio := position + Vector2(0, -alto * 0.5)
	sprite.play("fin")
	if TIPOS[tipo].get("vuela", false):
		# Las alas caen hasta el piso mientras se deshace.
		create_tween().tween_property(sprite, "position:y", 0.0, 0.7).set_delay(0.35)
	sprite.frame_changed.connect(func():
		if sprite.animation == "fin":
			_efecto_fin(sprite.frame, piso, medio))
	sprite.animation_finished.connect(func():
		var tw := create_tween()
		tw.tween_interval(3.5)   # los restos se quedan un rato
		tw.tween_property(sprite, "modulate:a", 0.0, 0.8)
		tw.tween_callback(queue_free), CONNECT_ONE_SHOT)


# Efectos que acompañan cada cuadro de la desaparición.
func _efecto_fin(f: int, piso: Vector2, medio: Vector2) -> void:
	if tipo == "escarabajo":
		match f:
			0, 1:
				sprite.position.x = 1.0 if f == 0 else -1.0   # tiembla
			2, 3:
				sprite.position.x = 0.0
				if f == 2:
					Fx.chispas(main.mundo, medio, Color(1.0, 0.8, 0.3), 6)
			4:
				# Revienta el caparazón
				Juego.sonido("golpe", true, -4.0)
				main.sacudir(4.0)
				main.pausa_impacto(0.04)
				Fx.estallido(main.mundo, medio, Color(1.0, 0.8, 0.35))
				Fx.chispas(main.mundo, medio, Color(1.0, 0.85, 0.4), 14)
				Fx.confeti(main.mundo, medio, Color(0.8, 0.5, 0.25), 10)
			6:
				Fx.polvo(main.mundo, piso + Vector2(-8, 0))
				Fx.polvo(main.mundo, piso + Vector2(8, 0))
	else:
		match f:
			1:
				Fx.chispas(main.mundo, medio + Vector2(0, -16), Color(1.0, 0.9, 0.5), 5)
			2, 3:
				Fx.confeti(main.mundo, medio + Vector2(0, -12), Color(1.0, 0.85, 0.45), 8)
			6:
				Fx.polvo(main.mundo, piso)


# Círculo rojo en el piso donde va a caer el candado.
class Marca extends Node2D:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
		draw_circle(Vector2.ZERO, 36.0, Color(1, 0.2, 0.2, 0.18 + 0.12 * sin(t * 20.0)))
		draw_arc(Vector2.ZERO, 36.0, 0, TAU, 28, Color(1, 0.3, 0.3, 0.8), 2.0)

# Altura media del enemigo (para poner luces a la mitad del cuerpo).
func alto_luz() -> float:
	return TIPOS[tipo].alto * 0.5

# Grietas que quedan en el piso tras un golpe fuerte; se desvanecen solas.
func _grietas(p: Vector2, tam: float) -> void:
	var nodo := Node2D.new()
	nodo.position = p
	nodo.z_index = -1
	main.mundo.add_child(nodo)
	for i in 7:
		var ln := Line2D.new()
		ln.width = 1.5 if i % 2 == 0 else 1.0
		ln.default_color = Color(0.06, 0.05, 0.05, 0.9)
		var ang := TAU * i / 7.0 + randf_range(-0.3, 0.3)
		var q := Vector2.ZERO
		ln.add_point(q)
		for k in 3:
			q += Vector2.from_angle(ang + randf_range(-0.5, 0.5)) * randf_range(5.0, 9.0) * tam * Vector2(1.0, 0.55)
			ln.add_point(q)
		nodo.add_child(ln)
	var t := nodo.create_tween()
	t.tween_interval(2.5)
	t.tween_property(nodo, "modulate:a", 0.0, 1.5)
	t.tween_callback(nodo.queue_free)

# Marca en el piso (cráter u hoyo): se abre desde el centro, las grietas corren hacia
# afuera, brilla la lava un instante y luego todo se apaga y se desvanece.
func marca_piso(clave: String, p: Vector2, esc: float, dura := 3.0, fps := 12.0, leve := false) -> void:
	for off in [Vector2.ZERO, Vector2(-24, 0), Vector2(24, 0), Vector2(0, -16), Vector2(0, 16)]:
		if main.bloqueado(p + off):
			return   # sobre la pared no se marca el piso
	# no se enciman ni parpadean: si ya hay un cráter ahí, ese mismo se queda (se le alarga la vida)
	# y solo salen los efectos del golpe; las huellas viejas en el mismo punto se desvanecen
	var existente: Node2D = null
	for viejo in get_tree().get_nodes_in_group("marca_golem"):
		if not is_instance_valid(viejo):
			continue
		var dist: float = viejo.position.distance_to(p)
		if not leve and not viejo.has_meta("huella") and dist < 56.0:
			existente = viejo
		elif dist < (24.0 if leve else 48.0) and viejo.has_meta("huella"):
			viejo.remove_from_group("marca_golem")
			var tv := viejo.create_tween()
			tv.tween_property(viejo, "modulate:a", 0.0, 0.4)
			tv.tween_callback(viejo.queue_free)
	if leve and existente == null:
		for viejo in get_tree().get_nodes_in_group("marca_golem"):
			if is_instance_valid(viejo) and not viejo.has_meta("huella") and viejo.position.distance_to(p) < 40.0:
				return   # no se pone una huella encima de un cráter
	if existente != null:
		existente.set_meta("hasta", Time.get_ticks_msec() + int(dura * 1000.0))
		p = existente.position
		var r1: float = float(Fx.meta(clave).w) * 0.5 * esc * 0.4
		var lz2 := PointLight2D.new()
		lz2.texture = Fx.textura_luz()
		lz2.texture_scale = 1.8 * esc
		lz2.color = Color(1.0, 0.5, 0.15)
		lz2.energy = 1.6
		lz2.position = p
		main.mundo.add_child(lz2)
		var tl2 := lz2.create_tween()
		tl2.tween_property(lz2, "energy", 0.0, 0.8)
		tl2.tween_callback(lz2.queue_free)
		Fx.polvo(main.mundo, p + Vector2(-r1 * 0.6, 0))
		Fx.polvo(main.mundo, p + Vector2(r1 * 0.6, 0))
		onda_piso(p, r1 * 2.4, Color(1.0, 0.6, 0.25, 0.8), 0.45)
		Fx.chispas(main.mundo, p + Vector2(0, -4), Color(1.0, 0.6, 0.2), 14)
		_brasas_suben(p, 10, r1)
		return
	var nodo := Node2D.new()
	nodo.position = p
	nodo.z_index = -1
	nodo.add_to_group("marca_golem")
	main.mundo.add_child(nodo)
	var m := Fx.meta(clave)
	var sf := SpriteFrames.new()
	sf.set_animation_loop("default", false)
	sf.set_animation_speed("default", fps)
	for i in int(m.n):
		sf.add_frame("default", Fx.cuadro(clave, i))
	# para que no parezca pegado: halo oscuro suave que hunde el piso alrededor y grava regada que se queda
	var ancho_m: float = float(m.w) * 0.5 * esc
	for k in 2:
		var hl := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := ancho_m * (0.62 if k == 0 else 0.48)
		for i in 20:
			pts.append(Vector2(cos(TAU * i / 20.0) * rx, sin(TAU * i / 20.0) * rx * 0.42))
		hl.polygon = pts
		hl.color = Color(0.0, 0.0, 0.0, 0.10 if k == 0 else 0.12)
		nodo.add_child(hl)
	for i in (3 if leve else 7):
		var g := Sprite2D.new()
		g.texture = Fx.cuadro("fx_ped_gol2", 8 + randi() % 4)
		g.scale = Vector2.ONE * 0.25
		g.rotation = randf() * TAU
		var ang := randf() * TAU
		g.position = (Vector2(cos(ang), sin(ang) * 0.42) * ancho_m * randf_range(0.45, 0.75)).round()
		g.modulate = Color(0.7, 0.68, 0.66)
		nodo.add_child(g)
	if leve:
		Fx.polvo(main.mundo, p + Vector2(-ancho_m * 0.3, 0))
		Fx.polvo(main.mundo, p + Vector2(ancho_m * 0.3, 0))
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = sf
	sp.scale = Vector2.ONE * 0.5   # escala fija: 1 pixel del dibujo = 1 del juego, nítido (sin borrosidad)
	sp.flip_h = randf() < 0.5
	nodo.add_child(sp)
	sp.play()
	if leve:   # huella: solo la marca (más oscura que el piso), que se desvanece
		nodo.set_meta("huella", true)
		sp.modulate = Color(0.75, 0.7, 0.68)
		nodo.z_index = 0
		var tl := nodo.create_tween()
		tl.tween_interval(dura)
		tl.tween_property(nodo, "modulate:a", 0.0, 1.2)
		tl.tween_callback(nodo.queue_free)
		return
	var r0: float = float(m.w) * 0.5 * esc * 0.4
	# destello de lava que se apaga
	var lz := PointLight2D.new()
	lz.texture = Fx.textura_luz()
	lz.texture_scale = 0.9 * esc * 2.0
	lz.color = Color(1.0, 0.5, 0.15)
	lz.energy = 1.8
	nodo.add_child(lz)
	lz.create_tween().tween_property(lz, "energy", 0.0, 0.9)
	Fx.polvo(main.mundo, p + Vector2(-r0 * 0.6, 0))
	Fx.polvo(main.mundo, p + Vector2(r0 * 0.6, 0))
	onda_piso(p, r0 * 2.4, Color(1.0, 0.6, 0.25, 0.8), 0.45)
	onda_piso(p, r0 * 1.6, Color(0.5, 0.45, 0.38, 0.7), 0.6)
	Fx.chispas(main.mundo, p + Vector2(0, -4), Color(1.0, 0.6, 0.2), 14)
	_brasas_suben(p, 10, r0)
	_niebla_morada(p, 8, r0)
	# se queda mientras siga golpeando ahí; luego se desvanece una sola vez
	nodo.set_meta("hasta", Time.get_ticks_msec() + int(dura * 1000.0))
	_apagar_marca(nodo)

func _apagar_marca(nodo: Node2D) -> void:
	while is_instance_valid(nodo) and Time.get_ticks_msec() < int(nodo.get_meta("hasta")):
		await get_tree().create_timer(0.25).timeout
		if not is_inside_tree():
			break
	if not is_instance_valid(nodo):
		return
	nodo.remove_from_group("marca_golem")
	var tf := nodo.create_tween()
	tf.tween_property(nodo, "modulate:a", 0.0, 1.5)
	tf.tween_callback(nodo.queue_free)

# Anillo que se abre sobre el piso (onda de choque), aplanado por la perspectiva.
func onda_piso(p: Vector2, radio_f: float, col: Color, dur: float) -> void:
	var ln := Line2D.new()
	ln.width = 3.0
	ln.default_color = col
	ln.closed = true
	for k in 28:
		ln.add_point(Vector2.from_angle(TAU * k / 28.0) * Vector2(1, 0.38))
	ln.position = p
	ln.z_index = -1
	main.mundo.add_child(ln)
	ln.scale = Vector2.ONE * 4.0
	var t := ln.create_tween().set_parallel()
	t.tween_property(ln, "scale", Vector2.ONE * radio_f, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(ln, "modulate:a", 0.0, dur)
	t.tween_property(ln, "width", 0.6, dur)
	t.chain().tween_callback(ln.queue_free)

# Brasas de lava que suben y se apagan.
func _brasas_suben(p: Vector2, n: int, ancho: float) -> void:
	for i in n:
		var b := ColorRect.new()
		b.size = Vector2(2, 2)
		b.color = [Color(1.0, 0.75, 0.3), Color(1.0, 0.45, 0.1), Color(1.0, 0.9, 0.5)].pick_random()
		b.position = p + Vector2(randf_range(-ancho, ancho), randf_range(-6, 4))
		b.z_index = 6
		main.mundo.add_child(b)
		var t := b.create_tween().set_parallel()
		var dur := randf_range(0.6, 1.4)
		t.tween_property(b, "position", b.position + Vector2(randf_range(-12, 12), -randf_range(25, 60)), dur).set_ease(Tween.EASE_OUT)
		t.tween_property(b, "modulate:a", 0.0, dur).set_delay(dur * 0.4)
		t.chain().tween_callback(b.queue_free)

# El gólem suelta brasas de sus grietas todo el tiempo y su ojo palpita.
func _brasas_golem() -> void:
	var pt := CPUParticles2D.new()
	pt.amount = 10
	pt.lifetime = 1.4
	pt.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pt.emission_rect_extents = Vector2(14, 10)
	pt.position = Vector2(4, -alto * 0.62)
	pt.direction = Vector2(0, -1)
	pt.spread = 25.0
	pt.gravity = Vector2(0, -18)
	pt.initial_velocity_min = 6.0
	pt.initial_velocity_max = 16.0
	pt.scale_amount_min = 1.5
	pt.scale_amount_max = 2.5
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	g.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	pt.color_ramp = g
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	pt.material = mat
	pt.z_index = 1
	add_child(pt)
	var ojo := PointLight2D.new()
	ojo.texture = Fx.textura_luz()
	ojo.texture_scale = 0.25
	ojo.color = Color(1.0, 0.45, 0.1)
	ojo.position = Vector2(14, -alto * 0.85)
	add_child(ojo)
	var t := ojo.create_tween().set_loops()
	t.tween_property(ojo, "energy", 1.6, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(ojo, "energy", 0.7, 0.6).set_trans(Tween.TRANS_SINE)
	tree_exiting.connect(func(): pass)
	set_meta("brasas", pt)
	# esencia misteriosa: motas moradas que flotan lentas alrededor de su cuerpo
	var mo := CPUParticles2D.new()
	mo.amount = 14
	mo.lifetime = 3.0
	mo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mo.emission_rect_extents = Vector2(radio * 1.6, alto * 0.45)
	mo.position = Vector2(0, -alto * 0.45)
	mo.direction = Vector2(0, -1)
	mo.spread = 180.0
	mo.gravity = Vector2(0, -6)
	mo.initial_velocity_min = 2.0
	mo.initial_velocity_max = 7.0
	mo.scale_amount_min = 1.0
	mo.scale_amount_max = 2.0
	var gm := Gradient.new()
	gm.set_color(0, Color(0.75, 0.45, 1.0, 0.0))
	gm.add_point(0.3, Color(0.7, 0.4, 1.0, 0.9))
	gm.set_color(1, Color(0.35, 0.15, 0.6, 0.0))
	mo.color_ramp = gm
	mo.material = mat
	mo.z_index = 2
	add_child(mo)
	set_meta("motas", mo)

# Al desmoronarse: destello de lava, onda, muchas brasas y las brasas propias se apagan.
func _estallido_golem() -> void:
	var p := position
	var fl := PointLight2D.new()
	fl.texture = Fx.textura_luz()
	fl.texture_scale = 2.0
	fl.color = Color(1.0, 0.5, 0.15)
	fl.energy = 2.5
	fl.position = p + Vector2(0, -alto * 0.4)
	main.mundo.add_child(fl)
	var tf := fl.create_tween()
	tf.tween_property(fl, "energy", 0.0, 1.2)
	tf.tween_callback(fl.queue_free)
	onda_piso(p, 90.0, Color(1.0, 0.55, 0.2, 0.9), 0.6)
	onda_piso(p, 60.0, Color(0.5, 0.45, 0.38, 0.8), 0.8)
	_brasas_suben(p + Vector2(0, -alto * 0.3), 30, 40.0)
	Fx.chispas(main.mundo, p + Vector2(0, -alto * 0.4), Color(1.0, 0.6, 0.2), 24)
	marca_piso("fx_gol_crater", p + Vector2(0, 6), 1.0, 2.5)
	if has_meta("brasas"):
		(get_meta("brasas") as CPUParticles2D).emitting = false
	if has_meta("motas"):
		(get_meta("motas") as CPUParticles2D).emitting = false
	if has_meta("polvo_pies"):
		(get_meta("polvo_pies") as CPUParticles2D).emitting = false
	_niebla_morada(p, 18, 50.0)

# Niebla morada en cuadritos (retro) que sale del piso roto y se disipa despacio.
func _niebla_morada(p: Vector2, n: int, ancho: float) -> void:
	for i in n:
		var b := ColorRect.new()
		var t0 := randi_range(3, 5)
		b.size = Vector2(t0, t0)
		b.color = [Color(0.45, 0.25, 0.7, 0.55), Color(0.3, 0.15, 0.5, 0.5), Color(0.6, 0.4, 0.85, 0.45)].pick_random()
		b.position = p + Vector2(randf_range(-ancho, ancho), randf_range(-4, 6))
		b.z_index = 3
		b.modulate.a = 0.0
		main.mundo.add_child(b)
		var dur := randf_range(1.5, 2.8)
		var t := b.create_tween().set_parallel()
		t.tween_property(b, "modulate:a", 1.0, 0.3).set_delay(randf() * 0.4)
		t.tween_property(b, "position", b.position + Vector2(randf_range(-10, 10), -randf_range(15, 35)), dur).set_trans(Tween.TRANS_SINE)
		t.tween_property(b, "modulate:a", 0.0, dur * 0.6).set_delay(dur * 0.4)
		t.chain().tween_callback(b.queue_free)

# Partículas dibujadas (llamas, chispa, polvo y niebla) que saltan del golpe.
func particulas_gol(p: Vector2, n: int) -> void:
	for i in n:
		var s := Sprite2D.new()
		var idx := [0, 1, 4, 0, 1, 4, 2, 3].pick_random() as int
		s.texture = Fx.cuadro("fx_part_gol", idx)
		s.scale = Vector2.ONE * (0.35 if idx < 2 or idx == 4 else 0.5)
		s.position = p + Vector2(randf_range(-14, 14), randf_range(-6, 2))
		s.z_index = 5
		if idx != 2 and idx != 3:
			var mt := CanvasItemMaterial.new()
			mt.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			s.material = mt
		main.mundo.add_child(s)
		var dur := randf_range(0.5, 1.1)
		var t := s.create_tween().set_parallel()
		var sube := Vector2(randf_range(-22, 22), -randf_range(14, 40) if idx != 2 else -randf_range(4, 12))
		t.tween_property(s, "position", s.position + sube, dur).set_ease(Tween.EASE_OUT)
		if idx == 2 or idx == 3:
			t.tween_property(s, "scale", s.scale * 1.8, dur)
		t.tween_property(s, "modulate:a", 0.0, dur * 0.6).set_delay(dur * 0.4)
		t.chain().tween_callback(s.queue_free)

# Tierra y piedritas que se le caen a la roca recién arrancada mientras la sube.
func _tierra_cayendo(piso: Vector2, lado: float, dura: float) -> void:
	var veces := 10
	for i in veces:
		get_tree().create_timer(dura * i / veces).timeout.connect(func():
			if not vivo:
				return
			var alto_roca := lerpf(10.0, alto * 0.9, float(i) / veces)
			var desde := position + Vector2(lado * lerpf(66.0, 30.0, float(i) / veces), -alto_roca)
			for k in 3:
				var b := ColorRect.new()
				var tam := randi_range(2, 3)
				b.size = Vector2(tam, tam)
				b.color = [Color(0.32, 0.24, 0.16), Color(0.22, 0.17, 0.12), Color(0.4, 0.33, 0.24)].pick_random()
				b.position = desde + Vector2(randf_range(-14, 14), randf_range(-4, 4))
				b.z_index = 4
				main.mundo.add_child(b)
				var caida := position.y + randf_range(-2, 6) - b.position.y
				var t := b.create_tween()
				t.tween_property(b, "position:y", b.position.y + caida, sqrt(maxf(caida, 1.0)) * 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				t.tween_interval(randf_range(0.6, 1.4))
				t.tween_property(b, "modulate:a", 0.0, 0.5)
				t.tween_callback(b.queue_free)
			if i % 3 == 0:
				_soltar_pedazos("fx_ped_gol2", 1, desde, 0.5))

# Para que no parezca pegado encima del piso: sombra de contacto ancha y oscura bajo los pies,
# luz de su lava que tiñe el piso a su alrededor y polvo que se arrastra a sus pies.
func _asentar_golem() -> void:
	for k in 2:
		var o := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := radio * (1.5 if k == 0 else 1.05)
		var ry := rx * 0.3
		for i in 24:
			pts.append(Vector2(cos(TAU * i / 24.0) * rx, sin(TAU * i / 24.0) * ry))
		o.polygon = pts
		o.color = Color(0.02, 0.0, 0.04, 0.35 if k == 0 else 0.55)   # sombra de contacto marcada: los pies se ven apoyados
		o.position = Vector2(0, 2)
		o.z_index = -1
		add_child(o)
	var lz := PointLight2D.new()
	lz.texture = Fx.textura_luz()
	lz.texture_scale = 1.1
	lz.color = Color(1.0, 0.45, 0.15)
	lz.energy = 0.7
	lz.position = Vector2(0, -6)
	add_child(lz)
	var t := lz.create_tween().set_loops()
	t.tween_property(lz, "energy", 0.95, 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(lz, "energy", 0.6, 0.9).set_trans(Tween.TRANS_SINE)
	var pv := CPUParticles2D.new()
	pv.amount = 8
	pv.lifetime = 1.2
	pv.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pv.emission_rect_extents = Vector2(radio * 1.3, 2)
	pv.direction = Vector2(0, -1)
	pv.spread = 70.0
	pv.gravity = Vector2(0, 4)
	pv.initial_velocity_min = 4.0
	pv.initial_velocity_max = 10.0
	pv.scale_amount_min = 2.0
	pv.scale_amount_max = 3.0
	var g := Gradient.new()
	g.set_color(0, Color(0.42, 0.36, 0.28, 0.6))
	g.set_color(1, Color(0.42, 0.36, 0.28, 0.0))
	pv.color_ramp = g
	pv.z_index = 1
	add_child(pv)
	set_meta("polvo_pies", pv)

# La roca revienta en mil pedazos: destello de lava y de brillo, pedazos en arco que rebotan,
# llamas, polvo, niebla morada y destellos como de joya que titilan (la esencia del juego).
func estallido_roca(p: Vector2, en_piso: bool) -> void:
	var fl := PointLight2D.new()
	fl.texture = Fx.textura_luz()
	fl.texture_scale = 1.6
	fl.color = Color(1.0, 0.55, 0.2)
	fl.energy = 2.8
	fl.position = p
	main.mundo.add_child(fl)
	var tf := fl.create_tween()
	tf.tween_property(fl, "energy", 0.0, 0.7)
	tf.tween_callback(fl.queue_free)
	var fm := PointLight2D.new()   # resplandor morado que queda un momento
	fm.texture = Fx.textura_luz()
	fm.texture_scale = 1.2
	fm.color = Color(0.6, 0.35, 1.0)
	fm.energy = 0.0
	fm.position = p
	main.mundo.add_child(fm)
	var tm := fm.create_tween()
	tm.tween_property(fm, "energy", 1.2, 0.25)
	tm.tween_property(fm, "energy", 0.0, 1.2)
	tm.tween_callback(fm.queue_free)
	var suelo := p + Vector2(0, 20)
	_soltar_pedazos("fx_ped_gol2", 16, p, 2.4)
	particulas_gol(p, 16)
	Fx.chispas(main.mundo, p, Color(1.0, 0.65, 0.25), 24)
	for k in 5:
		Fx.polvo(main.mundo, suelo + Vector2(randf_range(-26, 26), randf_range(-6, 6)))
	if en_piso:
		onda_piso(suelo, 80.0, Color(1.0, 0.6, 0.25, 0.9), 0.45)
		onda_piso(suelo, 55.0, Color(0.6, 0.4, 0.9, 0.7), 0.7)
	_brasas_suben(p, 22, 30.0)
	_niebla_morada(suelo, 16, 34.0)
	_destellos_joya(p, 12, 40.0)
	var cerca := clampf(1.0 - p.distance_to(objetivo.position) / 220.0, 0.0, 1.0)
	main.sacudir(4.0 + 5.0 * cerca)

# Destellos en cruz, blancos y morados, que titilan como el brillo de una gema y se apagan.
func _destellos_joya(p: Vector2, n: int, ancho: float) -> void:
	for i in n:
		var d := Node2D.new()
		d.position = p + Vector2(randf_range(-ancho, ancho), randf_range(-ancho * 0.7, ancho * 0.3))
		d.z_index = 7
		var col: Color = [Color(1, 1, 1), Color(0.8, 0.6, 1.0), Color(1.0, 0.85, 0.5)].pick_random()
		var mt := CanvasItemMaterial.new()
		mt.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		for v in [Rect2(-3, 0, 7, 1), Rect2(0, -3, 1, 7), Rect2(-1, -1, 3, 3)]:
			var r := ColorRect.new()
			r.position = (v as Rect2).position
			r.size = (v as Rect2).size
			r.color = col
			r.material = mt
			d.add_child(r)
		d.scale = Vector2.ZERO
		main.mundo.add_child(d)
		var dl := randf() * 0.5
		var t := d.create_tween()
		t.tween_interval(dl)
		t.tween_property(d, "scale", Vector2.ONE * randf_range(0.8, 1.5), 0.12)
		t.tween_property(d, "scale", Vector2.ONE * 0.4, 0.15)
		t.tween_property(d, "scale", Vector2.ONE, 0.12)
		t.tween_property(d, "modulate:a", 0.0, 0.4)
		t.tween_callback(d.queue_free)


# Polvito de tierra que levanta el escarabajo con las patas, con granos que saltan hacia atrás.
func _polvo_escarabajo(p: Vector2, atras: float) -> void:
	var nube := CPUParticles2D.new()
	nube.position = p
	nube.z_index = -1
	nube.one_shot = true
	nube.emitting = true
	nube.amount = 6
	nube.lifetime = 0.55
	nube.explosiveness = 0.9
	nube.direction = Vector2(atras, -0.6)
	nube.spread = 35.0
	nube.initial_velocity_min = 8.0
	nube.initial_velocity_max = 22.0
	nube.gravity = Vector2(0, -6)
	nube.damping_min = 15.0
	nube.damping_max = 25.0
	nube.scale_amount_min = 2.0
	nube.scale_amount_max = 3.5
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(1, 1.4))
	nube.scale_amount_curve = sc
	var g := Gradient.new()
	g.set_color(0, Color(0.55, 0.42, 0.3, 0.55))
	g.set_color(1, Color(0.45, 0.35, 0.25, 0.0))
	nube.color_ramp = g
	main.mundo.add_child(nube)
	var gr := CPUParticles2D.new()
	gr.position = p
	gr.one_shot = true
	gr.emitting = true
	gr.amount = 4
	gr.lifetime = 0.4
	gr.explosiveness = 1.0
	gr.direction = Vector2(atras, -1.2)
	gr.spread = 30.0
	gr.initial_velocity_min = 25.0
	gr.initial_velocity_max = 45.0
	gr.gravity = Vector2(0, 220)
	gr.scale_amount_min = 1.0
	gr.scale_amount_max = 1.5
	gr.color = Color(0.35, 0.24, 0.15)
	main.mundo.add_child(gr)
	get_tree().create_timer(1.0).timeout.connect(func():
		nube.queue_free()
		gr.queue_free())



# Presencia tenebrosa: oscurece el piso a su alrededor, niebla morada que se arrastra
# a sus pies, jirones de sombra que le suben del cuerpo y un contraluz morado que lo despega del fondo.
func _tenebroso_golem() -> void:
	var os := PointLight2D.new()   # penumbra que lo rodea (resta luz)
	os.texture = Fx.textura_luz()
	os.blend_mode = Light2D.BLEND_MODE_SUB
	os.texture_scale = 1.5
	os.color = Color(0.5, 0.55, 0.4)
	os.energy = 0.55
	os.position = Vector2(0, -10)
	add_child(os)
	var cl := PointLight2D.new()   # contraluz morado que late
	cl.texture = Fx.textura_luz()
	cl.texture_scale = 0.9
	cl.color = Color(0.6, 0.25, 1.0)
	cl.energy = 0.6
	cl.position = Vector2(0, -alto * 0.55)
	add_child(cl)
	var tc := cl.create_tween().set_loops()
	tc.tween_property(cl, "energy", 1.0, 1.6).set_trans(Tween.TRANS_SINE)
	tc.tween_property(cl, "energy", 0.45, 1.6).set_trans(Tween.TRANS_SINE)
	# niebla morada pegada al piso
	var nb := CPUParticles2D.new()
	nb.amount = 14
	nb.lifetime = 2.6
	nb.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	nb.emission_rect_extents = Vector2(radio * 1.4, 3)
	nb.direction = Vector2(1, 0)
	nb.spread = 180.0
	nb.gravity = Vector2(0, -1.5)
	nb.initial_velocity_min = 3.0
	nb.initial_velocity_max = 9.0
	nb.scale_amount_min = 6.0
	nb.scale_amount_max = 10.0
	var gn := Gradient.new()
	gn.set_color(0, Color(0.35, 0.15, 0.55, 0.0))
	gn.add_point(0.35, Color(0.32, 0.12, 0.5, 0.28))
	gn.set_color(gn.get_point_count() - 1, Color(0.2, 0.08, 0.35, 0.0))
	nb.color_ramp = gn
	nb.z_index = -1
	add_child(nb)
	# jirones de sombra que le suben del cuerpo
	var ji := CPUParticles2D.new()
	ji.amount = 10
	ji.lifetime = 1.8
	ji.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ji.emission_rect_extents = Vector2(radio * 0.8, alto * 0.3)
	ji.position = Vector2(0, -alto * 0.45)
	ji.direction = Vector2(0, -1)
	ji.spread = 15.0
	ji.gravity = Vector2(0, -6)
	ji.initial_velocity_min = 6.0
	ji.initial_velocity_max = 14.0
	ji.scale_amount_min = 2.0
	ji.scale_amount_max = 4.0
	var gj := Gradient.new()
	gj.set_color(0, Color(0.08, 0.03, 0.12, 0.0))
	gj.add_point(0.3, Color(0.12, 0.04, 0.2, 0.55))
	gj.set_color(gj.get_point_count() - 1, Color(0.45, 0.2, 0.7, 0.0))
	ji.color_ramp = gj
	ji.z_index = 1
	add_child(ji)



# Gotas de lava que se le escurren de las grietas del pecho con cada pisada y chisporrotean en el piso.
func _gotas_lava() -> void:
	var lado := -1.0 if sprite.flip_h else 1.0
	for i in randi_range(1, 2):
		var gota := Polygon2D.new()
		gota.polygon = PackedVector2Array([Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)])
		gota.color = Color(1.0, 0.6, 0.2)
		var mat_g := CanvasItemMaterial.new()
		mat_g.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		gota.material = mat_g
		var desde := position + Vector2(lado * randf_range(-6.0, 14.0), -alto * randf_range(0.45, 0.6))
		gota.position = desde
		gota.z_index = 2
		main.mundo.add_child(gota)
		var piso := Vector2(desde.x + lado * randf_range(2.0, 8.0), position.y + randf_range(-2.0, 3.0))
		var t := gota.create_tween()
		t.tween_property(gota, "position", piso, randf_range(0.35, 0.5)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.tween_callback(func():
			Fx.chispas(main.mundo, piso, Color(1.0, 0.55, 0.2), 3)
			gota.queue_free())



# La armadura se deshace: cada pieza (casco, hombreras, pecho, guanteletes, escudo, mazo) sale volando
# en arco girando, rebota en el piso y queda tirada; polvo, chispas de óxido y esencia morada que se escapa.
func _desarmar_guardia() -> void:
	var info: Dictionary = Anim.data.chars["gua3_piezas"]
	var tex: Texture2D = load("res://assets/chars/gua3_piezas.png")
	var lado := -1.0 if sprite.flip_h else 1.0
	var centro := position + Vector2(0, -alto * 0.35)
	sprite.visible = false
	Juego.sonido("golpe", true, -4.0)
	main.sacudir(4.5)
	main.pausa_impacto(0.05)
	var fl := PointLight2D.new()
	fl.texture = Fx.textura_luz()
	fl.texture_scale = 1.0
	fl.color = Color(0.65, 0.3, 1.0)
	fl.energy = 2.0
	fl.position = centro
	main.mundo.add_child(fl)
	var tf := fl.create_tween()
	tf.tween_property(fl, "energy", 0.0, 0.6)
	tf.tween_callback(fl.queue_free)
	_niebla_morada(centro, 14, 34.0)
	_destellos_joya(centro, 12, 34.0)
	Fx.chispas(main.mundo, centro, Color(0.85, 0.5, 0.25), 14)
	_chispa_gua(centro, 0.8)
	_soltar_pedazos("fx_ped_gua", 10, centro, 1.3)
	for k in 3:
		_polvo_gua(position + Vector2((k - 1) * 18.0, 2), 0.5)
	# la esencia se escapa de la armadura vacía en varios jirones, uno tras otro
	for k in 6:
		get_tree().create_timer(0.08 * k).timeout.connect(func():
			_esencia_gua(position + Vector2(randf_range(-20, 20), randf_range(-alto * 0.5, 0)), randf_range(0.3, 0.42), 1.0))
	for pz in info.piezas:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(pz[0], pz[1], pz[2], pz[3])
		var s := Sprite2D.new()
		s.texture = at
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2.ONE * 0.5
		s.flip_h = sprite.flip_h
		var ox: float = pz[4] * 0.5 * (-1.0 if sprite.flip_h else 1.0)
		var inicio := position + Vector2(ox, pz[5] * 0.5 - 6.0)
		s.position = inicio
		main.mundo.add_child(s)
		var dx := (ox * 1.6 + randf_range(-14.0, 14.0))
		var fin := Vector2(position.x + dx, position.y + randf_range(-6.0, 8.0))
		var alto_arco := randf_range(26.0, 44.0)
		var dur := randf_range(0.5, 0.7)
		var giro := randf_range(-1.0, 1.0) * PI * 0.5
		var tw := s.create_tween()
		tw.tween_method(func(k: float):
			if is_instance_valid(s):
				s.position = inicio.lerp(fin, k) + Vector2(0, -sin(k * PI) * alto_arco)
				s.rotation = giro * k, 0.0, 1.0, dur)
		# rebote corto y polvito al caer
		tw.tween_callback(func():
			Fx.polvo(main.mundo, fin)
			Fx.chispas(main.mundo, fin, Color(0.8, 0.45, 0.2), 2))
		tw.tween_property(s, "position:y", fin.y - 5.0, 0.12).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "position:y", fin.y, 0.12).set_ease(Tween.EASE_IN)
		tw.tween_interval(2.2)
		tw.tween_property(s, "modulate:a", 0.0, 0.8)
		tw.tween_callback(s.queue_free)
	var tq := create_tween()
	tq.tween_interval(1.2)
	tq.tween_callback(func():
		_niebla_morada(position + Vector2(0, -4), 6, 26.0)
		for k in 3:
			_esencia_gua(position + Vector2(randf_range(-24, 24), 0), 0.3, 0.9)
		_destellos_joya(position + Vector2(0, -6), 6, 26.0))
	tq.tween_interval(2.0)
	tq.tween_callback(queue_free)



# Efectos del guardia (hoja fx_gua_*): polvo de impacto, chispa de metal y jirón de esencia morada.
func _polvo_gua(p: Vector2, esc: float) -> void:
	var fx := Fx.animar(main.mundo, p, "fx_gua_polvo", 12.0, Color(1, 1, 1, 0.9), esc, randf() < 0.5)
	fx.offset = Vector2(0, -fx.sprite_frames.get_frame_texture("default", 0).get_height() * 0.5)
	fx.z_index = 1

func _chispa_gua(p: Vector2, esc: float) -> void:
	var fx := Fx.animar(main.mundo, p, "fx_gua_chispa", 18.0, Color.WHITE, esc, randf() < 0.5)
	var brillo := CanvasItemMaterial.new()
	brillo.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	brillo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = brillo
	var lz := PointLight2D.new()
	lz.texture = Fx.textura_luz()
	lz.texture_scale = 0.35 * esc / 0.5
	lz.color = Color(1.0, 0.65, 0.3)
	lz.energy = 1.6
	lz.position = p
	main.mundo.add_child(lz)
	var t := lz.create_tween()
	t.tween_property(lz, "energy", 0.0, 0.3)
	t.tween_callback(lz.queue_free)

func _esencia_gua(p: Vector2, esc: float, fuerza: float) -> void:
	var fx := Fx.animar(main.mundo, p, "fx_gua_esencia", 10.0, Color(1, 1, 1, fuerza), esc, randf() < 0.5)
	fx.offset = Vector2(0, -fx.sprite_frames.get_frame_texture("default", 0).get_height() * 0.5)
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	fx.material = sin_luz
	var lz := PointLight2D.new()
	lz.texture = Fx.textura_luz()
	lz.texture_scale = 0.5 * esc / 0.3
	lz.color = Color(0.6, 0.3, 1.0)
	lz.energy = 0.0
	lz.position = p + Vector2(0, -10)
	main.mundo.add_child(lz)
	var t := lz.create_tween()
	t.tween_property(lz, "energy", 1.1 * fuerza, 0.2)
	t.tween_property(lz, "energy", 0.0, 0.5)
	t.tween_callback(lz.queue_free)



# Presencia del guardia: la esencia morada vive dentro de la armadura vacía y se le escapa
# por las juntas y la rendija del casco; motas que suben, contraluz morado que late y bruma a los pies.
func _aura_guardia() -> void:
	var cl := PointLight2D.new()
	cl.texture = Fx.textura_luz()
	cl.texture_scale = 0.55
	cl.color = Color(0.6, 0.3, 1.0)
	cl.energy = 0.5
	cl.position = Vector2(0, -alto * 0.55)
	add_child(cl)
	var tc := cl.create_tween().set_loops()
	tc.tween_property(cl, "energy", 0.9, 1.3).set_trans(Tween.TRANS_SINE)
	tc.tween_property(cl, "energy", 0.4, 1.3).set_trans(Tween.TRANS_SINE)
	var mo := CPUParticles2D.new()   # motas de esencia que suben de las juntas
	mo.amount = 10
	mo.lifetime = 1.6
	mo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mo.emission_rect_extents = Vector2(radio * 0.6, alto * 0.35)
	mo.position = Vector2(0, -alto * 0.5)
	mo.direction = Vector2(0, -1)
	mo.spread = 20.0
	mo.gravity = Vector2(0, -8)
	mo.initial_velocity_min = 4.0
	mo.initial_velocity_max = 10.0
	mo.scale_amount_min = 1.0
	mo.scale_amount_max = 2.0
	var gm := Gradient.new()
	gm.set_color(0, Color(0.85, 0.6, 1.0, 0.0))
	gm.add_point(0.25, Color(0.8, 0.55, 1.0, 0.9))
	gm.set_color(gm.get_point_count() - 1, Color(0.5, 0.25, 0.9, 0.0))
	mo.color_ramp = gm
	var sl := CanvasItemMaterial.new()
	sl.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mo.material = sl
	mo.z_index = 1
	add_child(mo)
	var br := CPUParticles2D.new()   # bruma morada a ras del piso
	br.amount = 8
	br.lifetime = 2.2
	br.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	br.emission_rect_extents = Vector2(radio * 1.2, 2)
	br.direction = Vector2(1, 0)
	br.spread = 180.0
	br.gravity = Vector2(0, -1)
	br.initial_velocity_min = 2.0
	br.initial_velocity_max = 6.0
	br.scale_amount_min = 4.0
	br.scale_amount_max = 7.0
	var gb := Gradient.new()
	gb.set_color(0, Color(0.35, 0.15, 0.55, 0.0))
	gb.add_point(0.35, Color(0.32, 0.12, 0.5, 0.22))
	gb.set_color(gb.get_point_count() - 1, Color(0.2, 0.08, 0.35, 0.0))
	br.color_ramp = gb
	br.z_index = -1
	add_child(br)
	# cada tanto se le escapa un jirón de esencia por una junta o por el casco
	var fuga := Timer.new()
	fuga.wait_time = 1.4
	fuga.autostart = true
	add_child(fuga)
	fuga.timeout.connect(func():
		fuga.wait_time = randf_range(0.9, 1.8)
		if not vivo:
			return
		var donde := [Vector2(0, -alto * 0.95), Vector2(-6, -alto * 0.7), Vector2(6, -alto * 0.45), Vector2(-4, -alto * 0.3)]
		_esencia_gua(position + donde[randi() % donde.size()], randf_range(0.14, 0.2), 0.6))
	var brote := Timer.new()
	brote.wait_time = 4.0
	brote.autostart = true
	add_child(brote)
	brote.timeout.connect(func():
		brote.wait_time = randf_range(3.0, 5.5)
		if vivo and detecto and position.distance_to(objetivo.position) < 320.0:
			_brote_espina(objetivo.position + Vector2(randf_range(-50, 50), randf_range(-30, 30))))



# Disparo que pega de frente al escudo: abanico de chispas, arco de esencia morada sobre el escudo,
# chispas que rebotan, sonido metálico y el guardia empuja el escudo (cuadro de aguante).
func _rebote_escudo(desde: Vector2) -> void:
	var lado := -1.0 if sprite.flip_h else 1.0
	var p := position + Vector2(lado * 14.0, -alto * 0.5)
	p.y = clampf(desde.y, position.y - alto * 0.9, position.y - alto * 0.15)
	var imp := Fx.animar(main.mundo, p, "fx_esc_impacto", 20.0, Color.WHITE, 0.5, lado > 0.0)
	var ad := CanvasItemMaterial.new()
	ad.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ad.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	imp.material = ad
	var onda := Fx.animar(main.mundo, position + Vector2(lado * 12.0, -alto * 0.5), "fx_esc_onda", 14.0, Color(1, 1, 1, 0.9), 0.5, lado < 0.0)
	var sl := CanvasItemMaterial.new()
	sl.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	onda.material = sl
	for i in 5:
		var ch := Sprite2D.new()
		ch.texture = Fx.cuadro("fx_esc_chispa", randi() % 6)
		ch.scale = Vector2.ONE * 0.3
		ch.position = p
		ch.material = ad
		ch.z_index = 21
		main.mundo.add_child(ch)
		var ang := (PI if lado > 0.0 else 0.0) + randf_range(-0.9, 0.9)
		var v := Vector2.RIGHT.rotated(ang) * randf_range(25.0, 50.0)
		ch.rotation = v.angle()
		var t := ch.create_tween().set_parallel()
		t.tween_property(ch, "position", p + v + Vector2(0, 10), 0.35).set_ease(Tween.EASE_OUT)
		t.tween_property(ch, "modulate:a", 0.0, 0.35)
		t.chain().tween_callback(ch.queue_free)
	var lz := PointLight2D.new()
	lz.texture = Fx.textura_luz()
	lz.texture_scale = 0.6
	lz.color = Color(0.75, 0.45, 1.0)
	lz.energy = 2.0
	lz.position = p
	main.mundo.add_child(lz)
	var tl := lz.create_tween()
	tl.tween_property(lz, "energy", 0.0, 0.35)
	tl.tween_callback(lz.queue_free)
	Juego.sonido("golpe", true, -10.0)
	main.sacudir(1.0)
	sprite.frame = 1   # empuja el escudo (aguanta el golpe)
	empuje += Vector2(-lado * 25.0, 0)



# Desde el golpe del mazo brota una fila de espinas de esencia en línea recta hacia Diana,
# una tras otra, irregulares (alturas, formas e inclinación distintas), con una grieta morada que las une.
func _linea_espinas(desde: Vector2) -> void:
	var hacia := objetivo.position - desde
	var largo := clampf(hacia.length() + 16.0, 40.0, 230.0)
	var dirv := hacia.normalized() if hacia.length() > 1.0 else Vector2(-1.0 if sprite.flip_h else 1.0, 0)
	var paso := 19.0
	var n := int(largo / paso)
	for i in n:
		var t := 0.055 * i
		get_tree().create_timer(t).timeout.connect(func():
			if not is_instance_valid(self):
				return
			var lado := dirv.orthogonal() * randf_range(-4.0, 4.0)
			var pos := desde + dirv * (paso * (i + 1)) + lado
			if main.bloqueado(pos):
				return
			_poner_espina(pos, -1 if randf() < 0.4 else (randi() % 5 if randf() < 0.7 else 10 + randi() % 3))
			onda_piso(pos, 10.0, Color(0.55, 0.3, 0.9, 0.5), 0.25)
			if i % 2 == 0:
				main.sacudir(0.8))


func _poner_espina(pos: Vector2, variante: int) -> void:
	if get_tree().get_nodes_in_group("espinas").size() >= 40 or main.bloqueado(pos):
		return
	var e = preload("res://scripts/espina.gd").new()
	e.main = main
	e.objetivo = objetivo
	e.variante = variante
	e.position = pos
	main.mundo.add_child(e)

# Abanico de espinas pegadas junto al mazo: altas al centro, cortas a los lados (como el boceto).
func _abanico_espinas(p: Vector2, frente: Vector2) -> void:
	var formas := [11, 12, 2, 0, -1, 3, 1, 12, 10]
	for k in formas.size():
		var off := (k - 4) * 8.0
		var pos := p + frente * (off + 6.0) + Vector2(0, randf_range(-2.0, 2.0))
		var v: int = formas[k]
		get_tree().create_timer(0.025 * absf(k - 4)).timeout.connect(func():
			if is_instance_valid(self):
				_poner_espina(pos, v))
	Fx.chispas(main.mundo, p + Vector2(0, -10), Color(0.8, 0.5, 1.0), 10)

# Espina que brota sola del piso: primero la grieta morada avisa, luego sale.
func _brote_espina(pos: Vector2) -> void:
	if main.bloqueado(pos):
		return
	onda_piso(pos, 12.0, Color(0.6, 0.3, 1.0, 0.7), 0.6)
	var gr := Fx.animar(main.mundo, pos, "fx_esp_grieta", 10.0, Color.WHITE, 0.9, randf() < 0.5)   # la grieta avisa
	gr.offset = Vector2(0, -Fx.meta("fx_esp_grieta").h * 0.5 + 3.0)
	gr.z_index = 0
	var gm := CanvasItemMaterial.new()
	gm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	gr.material = gm
	var lz := PointLight2D.new()
	lz.texture = Fx.textura_luz()
	lz.texture_scale = 0.3
	lz.color = Color(0.65, 0.3, 1.0)
	lz.energy = 0.0
	lz.position = pos
	main.mundo.add_child(lz)
	var t := lz.create_tween()
	t.tween_property(lz, "energy", 1.4, 0.6)
	t.tween_callback(func():
		if is_instance_valid(self):
			_poner_espina(pos, -1 if randf() < 0.5 else randi() % 5)
		lz.queue_free())


# ---------------- Polilla HD ----------------
const MORADO_POL := Color(0.62, 0.32, 1.0)

# Efecto dibujado de la polilla: pixel nítido (1 pixel del dibujo = 1 del mundo), sin la penumbra del cuarto.
func _fx_pol(clave: String, pos: Vector2, fps: float, voltear := false, sumar := false, z := 21) -> AnimatedSprite2D:
	var fx: AnimatedSprite2D = Fx.animar(main.mundo, pos, clave, fps, Color.WHITE, 2.0, voltear)
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	if sumar:
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = m
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.z_index = z
	return fx

func _luz_pol(pos: Vector2, energia: float, tam: float, dur: float) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.textura_luz()
	l.texture_scale = tam
	l.color = MORADO_POL
	l.energy = energia
	l.position = pos
	main.mundo.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, dur)
	tw.tween_callback(l.queue_free)

func _preparar_polilla() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Luz morada tenue que late con las manchas de las alas.
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.35
	luz.color = MORADO_POL
	luz.energy = 0.5
	luz.position = Vector2(0, -24)
	add_child(luz)
	var lat := luz.create_tween().set_loops()
	lat.tween_property(luz, "energy", 0.85, 0.7).set_trans(Tween.TRANS_SINE)
	lat.tween_property(luz, "energy", 0.4, 0.7).set_trans(Tween.TRANS_SINE)
	set_meta("luz_pol", luz)
	# Polvo de alas que cae al volar y destellos en las manchas, de vez en cuando.
	var reloj := Timer.new()
	reloj.wait_time = 0.55
	reloj.autostart = true
	add_child(reloj)
	reloj.timeout.connect(func():
		reloj.wait_time = randf_range(0.45, 0.9)
		if not vivo or not is_instance_valid(main):
			return
		var cuerpo := position + Vector2(randf_range(-8, 8), sprite.position.y - randf_range(14, 26))
		var pv := _fx_pol("fx_pol_polvo", cuerpo + Vector2(0, 6), 8.0, randf() < 0.5)
		pv.z_index = 19
		if randf() < 0.35:
			_fx_pol("fx_pol_brillo", cuerpo + Vector2(randf_range(-6, 4), -4), 14.0, false, true))
	# Muerte: cae, choca con el piso y suelta su esencia.
	sprite.frame_changed.connect(func():
		if sprite.animation != "pulir":
			return
		var piso := position + Vector2(0, -2)
		var f := sprite.frame
		var cuerpo := position + Vector2(0, sprite.position.y - 20)
		if f == 1:
			# golpe final: estallido de esencia, muchas escamas y luz fuerte
			_fx_pol("fx_pol_chispazo", cuerpo, 18.0, sprite.flip_h, true)
			_fx_pol("fx_pol_espiral", cuerpo, 14.0, randf() < 0.5, true)
			_fx_pol("fx_pol_brillo", cuerpo + Vector2(-4, -6), 14.0, false, true)
			_escamas_pol(cuerpo, 5)
			_luz_pol(position + Vector2(0, -24), 2.2, 0.7, 0.5)
			Fx.chispas(main.mundo, cuerpo, MORADO_POL, 10)
			main.pausa_impacto(0.06)
		elif f >= 2 and f <= 4:
			# va cayendo: suelta escamas y una estela de polvo de alas
			_escamas_pol(cuerpo + Vector2(0, 4), 2)
			_fx_pol("fx_pol_polvo", cuerpo + Vector2(randf_range(-6, 6), -4), 10.0, randf() < 0.5)
			_fx_pol("fx_pol_brillo", cuerpo + Vector2(randf_range(-8, 8), randf_range(-6, 4)), 16.0, false, true)
		elif f == 5:
			onda_piso(piso, 16.0, Color(0.45, 0.3, 0.6, 0.6), 0.35)
			Fx.polvo(main.mundo, piso)
			_escamas_pol(piso + Vector2(0, -6), 3)
			main.sacudir(1.5)
			Juego.sonido("golpe", true, -10.0)
		elif f >= 6:
			var p := piso + Vector2(randf_range(-10, 10), 0)
			var es := _fx_pol("fx_pol_esencia", p + Vector2(0, -9), 9.0, randf() < 0.5, true)
			es.z_index = 22
			_luz_pol(p + Vector2(0, -10), 0.9, 0.35, 0.6))

# Escamas de ala que saltan en arco y caen girando.
func _escamas_pol(p: Vector2, n: int, lado := 0.0) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_pol_escama", randi() % int(Fx.meta("fx_pol_escama").n))
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		e.material = m
		e.position = p
		e.z_index = 22
		main.mundo.add_child(e)
		var dx := randf_range(8, 26) * (lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0))
		var fin := p + Vector2(dx, randf_range(10, 22))
		var alt := randf_range(8, 18)
		var dur := randf_range(0.5, 0.75)
		var giro := randf_range(-6.0, 6.0)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round()
				e.rotation = snappedf(k * giro, PI / 4.0), 0.0, 1.0, dur)
		t.tween_property(e, "modulate:a", 0.0, 0.35)
		t.tween_callback(e.queue_free)

# Golpe recibido: chispazo de esencia hacia el lado contrario al disparo, escamas, remolino de polvo y luz.
func _golpe_polilla(centro: Vector2, desde: Vector2, critico: bool) -> void:
	var lado := signf(desde.x) if absf(desde.x) > 0.01 else 1.0   # hacia dónde sale empujada
	_fx_pol("fx_pol_chispazo", centro, 20.0, lado > 0.0, true)
	_luz_pol(centro, 1.8 if critico else 1.2, 0.5, 0.3)
	_escamas_pol(centro, 4 if critico else 3, lado)
	var es := _fx_pol("fx_pol_espiral", centro + Vector2(lado * 6.0, -4), 14.0, lado < 0.0, true)
	es.z_index = 20
	Fx.chispas(main.mundo, centro, MORADO_POL, 5)

# Aletazo: al bajar las alas (cuadro 5) suelta la ráfaga; hiere a Diana si está enfrente y cerca.
func _aletazo_polilla(dir: Vector2) -> void:
	var lado := -1.0 if dir.x < 0.0 else 1.0
	var ya := [false, false]
	var al_cuadro := func():
		if sprite.animation != "aletazo":
			return
		if sprite.frame == 1 and not ya[0]:
			ya[0] = true
			_fx_pol("fx_pol_brillo", position + Vector2(-lado * 4.0, sprite.position.y - 22), 16.0, false, true)
			_luz_pol(position + Vector2(0, -24), 0.9, 0.4, 0.3)
		if sprite.frame >= 4 and not ya[1]:
			ya[1] = true
			var frente := position + Vector2(lado * 20.0, sprite.position.y - 12.0)
			_fx_pol("fx_pol_rafaga", frente + Vector2(lado * 10.0, 0), 14.0, lado < 0.0, true)
			_luz_pol(frente, 1.4, 0.5, 0.35)
			Fx.chispas(main.mundo, frente, MORADO_POL, 6)
			for k in 3:
				var pv := _fx_pol("fx_pol_polvo", frente + Vector2(lado * randf_range(8, 30), randf_range(-8, 8)), 10.0, lado < 0.0)
				pv.z_index = 22
			main.sacudir(1.2)
			Juego.sonido("mover", true, -6.0)
			# se lanza un poco hacia Diana con el golpe
			empuje = Vector2(lado * 120.0, 0)
			if is_instance_valid(objetivo):
				var d: Vector2 = objetivo.position - position
				if signf(d.x) == lado and absf(d.x) < 58.0 and absf(d.y) < 34.0:
					objetivo.herir(1, Vector2(lado, 0))
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(sprite) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

# Escupitajo: en el cuadro 5 sale una bola de esencia que vuela hacia donde está Diana.
func _escupir_polilla() -> void:
	var ya := [false, false]
	var al_cuadro := func():
		if sprite.animation != "ataque":
			return
		var lado := -1.0 if sprite.flip_h else 1.0
		# la boca: justo delante del ojo (el ojo está en el centro del cuadro, 24 px sobre la línea del pie)
		var boca := position + Vector2(lado * 16.0, sprite.position.y - 22.0)
		if sprite.frame == 1 and not ya[0]:
			ya[0] = true
			_cargar_escupitajo(boca)
		if sprite.frame >= 5 and not ya[1]:
			ya[1] = true
			var dir := Vector2(lado, 0)
			if is_instance_valid(objetivo):
				dir = (objetivo.position + Vector2(0, -12) - boca).normalized()
			# fogonazo en la boca: chispazo hacia adelante, destello y luz
			_fx_pol("fx_pol_brillo", boca, 18.0, false, true)
			_fx_pol("fx_pol_polvo", boca + dir * 6.0, 12.0, lado < 0.0, true)
			_luz_pol(boca, 1.6, 0.45, 0.3)
			Fx.chispas(main.mundo, boca, MORADO_POL, 5)
			Juego.sonido("disparo_enemigo", true, -8.0)
			_bola_pol(boca, dir)
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(sprite) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

# Antes de escupir: la esencia se junta en la boca (motas que se acercan y un brillo que crece).
func _cargar_escupitajo(boca: Vector2) -> void:
	var ma := CanvasItemMaterial.new()
	ma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var brillo := Sprite2D.new()
	brillo.texture = Fx.textura_luz()
	brillo.scale = Vector2.ZERO
	brillo.modulate = Color(0.75, 0.4, 1.0, 0.8)
	brillo.material = ma
	brillo.position = boca
	brillo.z_index = 22
	main.mundo.add_child(brillo)
	var tb := brillo.create_tween()
	tb.tween_property(brillo, "scale", Vector2.ONE * 0.07, 0.35).set_ease(Tween.EASE_IN)
	tb.tween_property(brillo, "scale", Vector2.ONE * 0.11, 0.06)
	tb.tween_property(brillo, "modulate:a", 0.0, 0.12)
	tb.tween_callback(brillo.queue_free)
	_luz_pol(boca, 0.8, 0.35, 0.45)
	for i in 7:
		var a := randf() * TAU
		var desde := boca + Vector2(cos(a), sin(a)) * randf_range(12, 20)
		var mota := Sprite2D.new()
		mota.texture = Fx.cuadro("fx_pol_brillo", 4)
		mota.position = desde
		mota.material = ma
		mota.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mota.z_index = 22
		main.mundo.add_child(mota)
		var tm := mota.create_tween()
		tm.tween_interval(randf_range(0.0, 0.12))
		tm.tween_property(mota, "position", boca, randf_range(0.2, 0.3)).set_ease(Tween.EASE_IN)
		tm.tween_callback(mota.queue_free)

func _bola_pol(desde: Vector2, dir: Vector2) -> void:
	var bola := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 10.0)
	for i in int(Fx.meta("fx_pol_bola_p").n):
		sf.add_frame("default", Fx.cuadro("fx_pol_bola_p", i))
	bola.sprite_frames = sf
	bola.play()
	bola.scale = Vector2.ONE   # versión reducida nítida: 1 pixel del dibujo = 1 del mundo
	bola.flip_h = dir.x < 0.0
	bola.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	bola.material = m
	bola.position = desde
	bola.z_index = 21
	main.mundo.add_child(bola)
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.3
	luz.color = MORADO_POL
	luz.energy = 1.0
	bola.add_child(luz)
	# estela de gotitas y motas moradas
	var est := CPUParticles2D.new()
	est.amount = 14
	est.lifetime = 0.45
	est.local_coords = false
	est.gravity = Vector2(0, 40)
	est.initial_velocity_min = 4.0
	est.initial_velocity_max = 12.0
	est.direction = -dir
	est.spread = 30.0
	est.scale_amount_min = 2.0
	est.scale_amount_max = 4.0
	var gr := Gradient.new()
	gr.set_color(0, Color(0.85, 0.6, 1.0, 1.0))
	gr.set_color(1, Color(0.35, 0.1, 0.6, 0.0))
	est.color_ramp = gr
	est.material = m
	bola.add_child(est)
	# halo que suma luz alrededor de la bola
	var halo := Sprite2D.new()
	halo.texture = Fx.textura_luz()
	halo.scale = Vector2.ONE * 0.09
	halo.modulate = Color(0.7, 0.35, 1.0, 0.55)
	var ma := CanvasItemMaterial.new()
	ma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = ma
	halo.z_index = -1
	bola.add_child(halo)
	# rastro: copias de la bola que se quedan atrás y se apagan, y polvo que cae
	var rastro := Timer.new()
	rastro.wait_time = 0.045
	rastro.autostart = true
	bola.add_child(rastro)
	var cuenta := [0]
	rastro.timeout.connect(func():
		if not is_instance_valid(bola):
			return
		cuenta[0] += 1
		var c := Sprite2D.new()
		c.texture = sf.get_frame_texture("default", bola.frame)
		c.flip_h = bola.flip_h
		c.scale = bola.scale * 0.85
		c.position = bola.position
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.material = ma
		c.modulate = Color(0.75, 0.45, 1.0, 0.5)
		c.z_index = 20
		main.mundo.add_child(c)
		var tc := c.create_tween().set_parallel(true)
		tc.tween_property(c, "modulate:a", 0.0, 0.22)
		tc.tween_property(c, "scale", c.scale * 0.5, 0.22)
		tc.chain().tween_callback(c.queue_free)
		if cuenta[0] % 4 == 0:
			_fx_pol("fx_pol_polvo", bola.position + Vector2(0, 4), 10.0, randf() < 0.5).z_index = 19)
	var reventar := func(golpe: bool):
		if not is_instance_valid(bola):
			return
		var p := bola.position.round()
		# reventón nítido que se apaga suave en sus últimos cuadros (no se corta de golpe)
		var rv := _fx_pol("fx_pol_revienta_p", p, 12.0, dir.x < 0.0)
		rv.animation_finished.disconnect(rv.queue_free)
		var trv := rv.create_tween()
		trv.tween_interval(0.22)
		trv.tween_property(rv, "modulate:a", 0.0, 0.3)
		trv.tween_callback(rv.queue_free)
		_fx_pol("fx_pol_salpica", p + Vector2(0, 8), 10.0, dir.x < 0.0).z_index = 18
		_fx_pol("fx_pol_brillo", p, 16.0, false, true)
		_fx_pol("fx_pol_espiral", p + Vector2(0, -4), 14.0, randf() < 0.5, true)
		_luz_pol(p, 1.8 if golpe else 1.1, 0.55, 0.4)
		Fx.chispas(main.mundo, p, MORADO_POL, 8)
		# gotitas que salpican y caen
		for i in 6:
			var g := Sprite2D.new()
			g.texture = Fx.cuadro("fx_pol_brillo", 4 + randi() % 2)
			g.position = p
			g.material = rv.material
			g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			g.z_index = 21
			main.mundo.add_child(g)
			var fin := p + Vector2(randf_range(-18, 18) - dir.x * 8.0, randf_range(4, 14))
			var alt := randf_range(6, 14)
			var tg := g.create_tween()
			tg.tween_method(func(k: float):
				if is_instance_valid(g):
					g.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round(), 0.0, 1.0, randf_range(0.35, 0.5))
			tg.tween_property(g, "modulate:a", 0.0, 0.2)
			tg.tween_callback(g.queue_free)
		if golpe:
			main.sacudir(1.0)
		bola.queue_free()
	var vel_b := 150.0
	var recorrido := [0.0]
	# altura sobre el piso: sale de la boca y llega a la altura del pecho de Diana
	var alto0 := position.y - desde.y
	var largo := 200.0
	if is_instance_valid(objetivo):
		largo = maxf(desde.distance_to(objetivo.position + Vector2(0, -12)), 40.0)
	var tw := bola.create_tween()
	tw.tween_method(func(_k: float):
		if not is_instance_valid(bola):
			return
		var paso := vel_b * get_process_delta_time()
		bola.position += dir * paso
		recorrido[0] += paso
		var alto_b := lerpf(alto0, 12.0, clampf(recorrido[0] / largo, 0.0, 1.0))
		var suelo := bola.position + Vector2(0, alto_b)
		if is_instance_valid(objetivo) and objetivo.position.distance_to(bola.position + Vector2(0, 10)) < 13.0:
			objetivo.herir(1, dir)
			reventar.call(true)
		elif not main.interior().has_point(suelo) or main.bloqueado(suelo):
			reventar.call(false)   # choca con la pared o un mueble: revienta ahí
		elif recorrido[0] > 340.0:
			reventar.call(false), 0.0, 1.0, 3.0)
	tw.tween_callback(func(): reventar.call(false))

# Tras caer: la esencia termina de salir y el cuerpo se apaga.
func _deshacer_polilla() -> void:
	if has_meta("luz_pol"):
		var l: PointLight2D = get_meta("luz_pol")
		l.create_tween().tween_property(l, "energy", 0.0, 0.6)
	var piso := position + Vector2(0, -2)
	# la esencia sigue saliendo del cuerpo un momento
	for k in 4:
		get_tree().create_timer(0.22 * k).timeout.connect(func():
			if is_instance_valid(self):
				_fx_pol("fx_pol_esencia", piso + Vector2(randf_range(-10, 10), -9), 9.0, randf() < 0.5, true)
				_fx_pol("fx_pol_polvo", piso + Vector2(randf_range(-8, 8), -10), 8.0)
				_luz_pol(piso + Vector2(0, -8), 0.7, 0.35, 0.4))
	# chispitas moradas que suben de los restos
	var sube := CPUParticles2D.new()
	sube.position = piso + Vector2(0, -6)
	sube.amount = 18
	sube.lifetime = 1.3
	sube.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sube.emission_rect_extents = Vector2(12, 4)
	sube.direction = Vector2(0, -1)
	sube.spread = 20.0
	sube.gravity = Vector2(0, -16)
	sube.initial_velocity_min = 6.0
	sube.initial_velocity_max = 16.0
	sube.scale_amount_min = 1.0
	sube.scale_amount_max = 2.0
	var gs := Gradient.new()
	gs.set_color(0, Color(1.0, 0.9, 1.0, 1.0))
	gs.add_point(0.3, Color(0.75, 0.5, 1.0, 0.9))
	gs.set_color(gs.get_point_count() - 1, Color(0.4, 0.15, 0.7, 0.0))
	sube.color_ramp = gs
	var ma := CanvasItemMaterial.new()
	ma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sube.material = ma
	sube.z_index = 22
	main.mundo.add_child(sube)
	get_tree().create_timer(1.6).timeout.connect(func(): sube.emitting = false)
	get_tree().create_timer(3.2).timeout.connect(sube.queue_free)
	# los restos se quedan un momento y luego se deshacen en polvo de luz (no desaparecen de golpe)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		_fx_pol("fx_pol_espiral", piso + Vector2(0, -8), 12.0, randf() < 0.5, true)
		_escamas_pol(piso + Vector2(0, -6), 3)
		_luz_pol(piso + Vector2(0, -8), 1.2, 0.45, 0.6)
		Fx.desintegrar(main.mundo, sprite, position.y, Color(1.1, 0.95, 1.25))
		queue_free())


# ---------------- Murciélago HD ----------------
const TURQ := Color(0.25, 0.95, 0.85)

# Chispas del murciélago siempre por encima de Diana (las normales se ordenan por altura
# y como salen del cuerpo en el aire, a veces quedaban detrás y a veces delante de ella).
func _chispas_mur(pos: Vector2, color: Color, cuantas: int) -> void:
	var antes: int = main.mundo.get_child_count()
	Fx.chispas(main.mundo, pos, color, cuantas)
	for k in range(antes, main.mundo.get_child_count()):
		main.mundo.get_child(k).z_index = 21

func _luz_mur(pos: Vector2, energia: float, tam: float, dur: float, col := TURQ) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.textura_luz()
	l.texture_scale = tam
	l.color = col
	l.energy = energia
	l.position = pos
	main.mundo.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, dur)
	tw.tween_callback(l.queue_free)

func _preparar_murcielago() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 3   # vuela: siempre se dibuja por encima de Diana (antes cambiaba de adelante a atrás al cruzarse)
	# brillo tenue de los cristales del lomo
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.3
	luz.color = TURQ
	luz.energy = 0.45
	luz.position = Vector2(-6, -26)
	add_child(luz)
	var lat := luz.create_tween().set_loops()
	lat.tween_property(luz, "energy", 0.75, 0.8).set_trans(Tween.TRANS_SINE)
	lat.tween_property(luz, "energy", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	set_meta("luz_mur", luz)
	# brillo ámbar de los ojos
	var ojo := PointLight2D.new()
	ojo.texture = Fx.textura_luz()
	ojo.texture_scale = 0.12
	ojo.color = Color(1.0, 0.6, 0.2)
	ojo.energy = 0.7
	ojo.position = Vector2(14, -22)
	add_child(ojo)
	sprite.frame_changed.connect(func(): ojo.position.x = -14.0 if sprite.flip_h else 14.0)
	# motas de cristal turquesa que se desprenden mientras vuela y quedan flotando atrás
	var mo := CPUParticles2D.new()
	mo.amount = 10
	mo.lifetime = 1.1
	mo.local_coords = false
	mo.position = Vector2(-6, -24)
	mo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mo.emission_rect_extents = Vector2(12, 6)
	mo.direction = Vector2(0, 1)
	mo.spread = 40.0
	mo.gravity = Vector2(0, 10)
	mo.initial_velocity_min = 2.0
	mo.initial_velocity_max = 8.0
	mo.scale_amount_min = 1.0
	mo.scale_amount_max = 2.0
	var gm := Gradient.new()
	gm.set_color(0, Color(0.85, 1.0, 1.0, 0.0))
	gm.add_point(0.2, Color(0.5, 1.0, 0.9, 0.95))
	gm.set_color(gm.get_point_count() - 1, Color(0.1, 0.45, 0.4, 0.0))
	mo.color_ramp = gm
	var mm := CanvasItemMaterial.new()
	mm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mo.material = mm
	add_child(mo)
	set_meta("motas_mur", mo)
	# polvo de cristal que se desprende al aletear
	sprite.frame_changed.connect(func():
		if vivo and sprite.animation == "mover" and sprite.frame == 3 and randf() < 0.45:
			var p := position + Vector2(randf_range(-10, 4), sprite.position.y - randf_range(18, 28))
			_fx_pol("fx_mur_polvo", p, 10.0, randf() < 0.5, true).z_index = 19)
	# muerte: golpe final, caída y choque contra el piso
	sprite.frame_changed.connect(func():
		if sprite.animation != "pulir":
			return
		var f := sprite.frame
		var cuerpo := position + Vector2(-6, sprite.position.y - 26)
		var piso := position + Vector2(0, -2)
		if f == 0:
			_fx_pol("fx_mur_mordida", cuerpo, 16.0, sprite.flip_h, true)
			_astillas_mur(cuerpo, 5)
			_luz_mur(cuerpo, 2.0, 0.6, 0.45)
			_chispas_mur(cuerpo, TURQ, 8)
			main.pausa_impacto(0.06)
		elif f >= 1 and f <= 3:
			# va cayendo: suelta astillas, polvo de cristal, chispas y deja estela
			_astillas_mur(cuerpo, 2)
			_fx_pol("fx_mur_polvo", cuerpo + Vector2(randf_range(-8, 8), randf_range(-4, 4)), 12.0, randf() < 0.5, true)
			_chispas_mur(cuerpo, TURQ, 3)
			_sombra_mur()
			_luz_mur(cuerpo, 0.8, 0.4, 0.3)
		elif f == 4:
			# choca contra el piso: se aplasta un instante, polvo, cristales y sacudida
			aplastar = Vector2(1.25, 0.75)
			onda_piso(piso, 18.0, Color(0.3, 0.6, 0.55, 0.6), 0.35)
			Fx.polvo(main.mundo, piso)
			_astillas_mur(piso + Vector2(0, -6), 7)
			_fx_pol("fx_mur_mordida", piso + Vector2(0, -8), 14.0, randf() < 0.5, true)
			for k in 3:
				_fx_pol("fx_mur_polvo", piso + Vector2(randf_range(-16, 16), -6), 10.0, randf() < 0.5, true)
			_chispas_mur(piso + Vector2(0, -6), TURQ, 10)
			_luz_mur(piso + Vector2(0, -8), 1.8, 0.6, 0.5)
			main.pausa_impacto(0.04)
			main.sacudir(2.2)
			Juego.sonido("golpe", true, -10.0)
		elif f == 5:
			_fx_pol("fx_mur_polvo", piso + Vector2(4, -12), 10.0, false, true))

# Astillas de cristal que saltan en arco y caen girando.
func _astillas_mur(p: Vector2, n: int, lado := 0.0) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_mur_astilla", randi() % int(Fx.meta("fx_mur_astilla").n))
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		e.material = m
		e.position = p
		e.z_index = 22
		main.mundo.add_child(e)
		var dx := randf_range(8, 26) * (lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0))
		var fin := p + Vector2(dx, randf_range(10, 22))
		var alt := randf_range(8, 18)
		var dur := randf_range(0.5, 0.75)
		var giro := randf_range(-6.0, 6.0)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round()
				e.rotation = snappedf(k * giro, PI / 4.0), 0.0, 1.0, dur)
		t.tween_property(e, "modulate:a", 0.0, 0.35)
		t.tween_callback(e.queue_free)

func _golpe_murcielago(centro: Vector2, desde: Vector2, critico: bool) -> void:
	var lado := signf(desde.x) if absf(desde.x) > 0.01 else 1.0
	_fx_pol("fx_mur_mordida", centro, 18.0, lado > 0.0, true)
	_fx_pol("fx_mur_polvo", centro + Vector2(lado * 4.0, -4), 12.0, lado < 0.0, true)
	_astillas_mur(centro, 4 if critico else 3, lado)
	_luz_mur(centro, 1.8 if critico else 1.2, 0.5, 0.3)
	_chispas_mur(centro, TURQ, 5)

# Ataque: chilla (retrocede), se lanza en picada larga hacia Diana dejando estela verde, muerde y rebota.
func _ataque_murcielago(dir: Vector2, dist: float = 150.0) -> void:
	var lado := -1.0 if dir.x < 0.0 else 1.0
	var ya := [false, false, false]
	var mordio := [false]
	var al_cuadro := func():
		if sprite.animation != "ataque":
			return
		var boca := position + Vector2(lado * 14.0, sprite.position.y - 22.0)
		if sprite.frame == 1 and not ya[0]:
			ya[0] = true
			for k in 2:
				var ch := _fx_pol("fx_mur_chillido", boca + Vector2(lado * (8.0 + k * 10.0), 0), 12.0, lado < 0.0, true)
				ch.modulate.a = 1.0 - k * 0.35
			_luz_mur(boca, 1.0, 0.45, 0.4)
			empuje = -dir * 70.0
			Juego.sonido("disparo_enemigo", true, -10.0)
		if sprite.frame == 2 and not ya[1]:
			ya[1] = true
			# picada: recorre la distancia hasta Diana (y un poco más)
			var destino := position + dir * (dist + 24.0)
			var inicio := position
			var tw := create_tween()
			tw.tween_method(func(k: float):
				if not is_instance_valid(self) or not vivo:
					return
				position = _dentro_mur(main.mover(position, inicio.lerp(destino, k) - position, 0.0))
				if not mordio[0] and is_instance_valid(objetivo) and objetivo.position.distance_to(position) < 26.0:
					mordio[0] = true
					objetivo.herir(1, dir)
					main.sacudir(1.4), 0.0, 1.0, 0.32).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			# estela verde: copias del murciélago que se quedan atrás y se apagan, más viento y polvo
			for k in 8:
				get_tree().create_timer(0.04 * k).timeout.connect(func():
					if not is_instance_valid(self):
						return
					_sombra_mur()
					if k % 2 == 0:
						_fx_pol("fx_mur_estela", position + Vector2(-lado * 14.0, sprite.position.y - 20.0), 16.0, lado < 0.0, true).z_index = 19
					if k % 3 == 0:
						_fx_pol("fx_mur_polvo", position + Vector2(-lado * 10.0, sprite.position.y - 18.0), 12.0, randf() < 0.5, true).z_index = 19)
			_luz_mur(position + Vector2(0, -24), 1.0, 0.5, 0.4)
		if sprite.frame == 3 and not ya[2]:
			ya[2] = true
			_fx_pol("fx_mur_mordida", boca + Vector2(lado * 6.0, 0), 16.0, lado < 0.0, true)
			_luz_mur(boca, 1.3, 0.4, 0.3, Color(1.0, 0.65, 0.25))
			_chispas_mur(boca, Color(1.0, 0.7, 0.3), 5)
			if not mordio[0] and is_instance_valid(objetivo) and objetivo.position.distance_to(position) < 32.0:
				mordio[0] = true
				objetivo.herir(1, dir)
				main.sacudir(1.2)
			empuje = -dir * 110.0   # rebota tras morder
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(sprite) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

# El murciélago vuela, pero su cuerpo se dibuja ~45 px arriba de su punto en el piso:
# se mantiene lejos de las paredes para que nunca se vea encima de ellas.
func _dentro_mur(p: Vector2) -> Vector2:
	var r: Rect2 = main.interior()
	return Vector2(clampf(p.x, r.position.x + 26.0, r.end.x - 26.0), clampf(p.y, r.position.y + 52.0, r.end.y - 6.0))

# Copia verde translúcida del cuadro actual que se queda atrás y se apaga (estela de la picada).
func _sombra_mur() -> void:
	var c := Sprite2D.new()
	c.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	c.flip_h = sprite.flip_h
	c.scale = sprite.scale
	c.offset = sprite.offset
	c.position = position + sprite.position
	c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	c.material = m
	c.modulate = Color(0.2, 0.9, 0.55, 0.55)
	c.z_index = 18
	main.mundo.add_child(c)
	var t := c.create_tween()
	t.tween_property(c, "modulate:a", 0.0, 0.3)
	t.tween_callback(c.queue_free)

# Tras deshacerse en el piso: se convierte en polvo de cristal que sube y se apaga.
func _deshacer_murcielago() -> void:
	if has_meta("motas_mur"):
		(get_meta("motas_mur") as CPUParticles2D).emitting = false
	if has_meta("luz_mur"):
		var l: PointLight2D = get_meta("luz_mur")
		l.create_tween().tween_property(l, "energy", 0.0, 0.6)
	var piso := position + Vector2(0, -2)
	for k in 4:
		get_tree().create_timer(0.18 * k).timeout.connect(func():
			if is_instance_valid(self):
				_fx_pol("fx_mur_polvo", piso + Vector2(randf_range(-14, 14), -8), 9.0, randf() < 0.5, true)
				_luz_mur(piso + Vector2(0, -6), 0.6, 0.35, 0.4))
	var sube := CPUParticles2D.new()
	sube.position = piso + Vector2(0, -4)
	sube.amount = 20
	sube.lifetime = 1.3
	sube.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sube.emission_rect_extents = Vector2(18, 3)
	sube.direction = Vector2(0, -1)
	sube.spread = 20.0
	sube.gravity = Vector2(0, -16)
	sube.initial_velocity_min = 6.0
	sube.initial_velocity_max = 16.0
	sube.scale_amount_min = 1.0
	sube.scale_amount_max = 2.0
	var gs := Gradient.new()
	gs.set_color(0, Color(0.9, 1.0, 1.0, 1.0))
	gs.add_point(0.3, Color(0.35, 0.95, 0.85, 0.9))
	gs.set_color(gs.get_point_count() - 1, Color(0.1, 0.4, 0.4, 0.0))
	sube.color_ramp = gs
	var ma := CanvasItemMaterial.new()
	ma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sube.material = ma
	sube.z_index = 22
	main.mundo.add_child(sube)
	get_tree().create_timer(1.4).timeout.connect(func(): sube.emitting = false)
	get_tree().create_timer(3.0).timeout.connect(sube.queue_free)
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		Fx.desintegrar(main.mundo, sprite, position.y, Color(0.95, 1.15, 1.1))
		_humo_restos_mur(piso)
		queue_free())


# Humo oscuro verde azulado que sale de los restos y se disipa poco a poco.
func _humo_restos_mur(piso: Vector2) -> void:
	var h := CPUParticles2D.new()
	h.position = piso + Vector2(0, -4)
	h.amount = 30
	h.lifetime = 2.6
	h.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	h.emission_rect_extents = Vector2(20, 4)
	h.direction = Vector2(0, -1)
	h.spread = 18.0
	h.gravity = Vector2(0, -8)
	h.initial_velocity_min = 5.0
	h.initial_velocity_max = 12.0
	h.scale_amount_min = 4.0
	h.scale_amount_max = 9.0
	h.angular_velocity_min = -20.0
	h.angular_velocity_max = 20.0
	var g := Gradient.new()
	g.set_color(0, Color(0.12, 0.22, 0.22, 0.0))
	g.add_point(0.15, Color(0.16, 0.32, 0.3, 0.8))
	g.add_point(0.6, Color(0.11, 0.22, 0.21, 0.5))
	g.set_color(g.get_point_count() - 1, Color(0.08, 0.12, 0.12, 0.0))
	h.color_ramp = g
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	h.material = m
	h.z_index = 2
	main.mundo.add_child(h)
	# unas chispitas turquesa que todavía brillan entre el humo
	var ch := CPUParticles2D.new()
	ch.position = piso + Vector2(0, -4)
	ch.amount = 10
	ch.lifetime = 1.2
	ch.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ch.emission_rect_extents = Vector2(14, 2)
	ch.direction = Vector2(0, -1)
	ch.spread = 25.0
	ch.gravity = Vector2(0, -12)
	ch.initial_velocity_min = 4.0
	ch.initial_velocity_max = 10.0
	var gc := Gradient.new()
	gc.set_color(0, Color(0.7, 1.0, 0.95, 1.0))
	gc.set_color(1, Color(0.2, 0.6, 0.55, 0.0))
	ch.color_ramp = gc
	var mc := CanvasItemMaterial.new()
	mc.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mc.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ch.material = mc
	ch.z_index = 3
	main.mundo.add_child(ch)
	var t: SceneTree = main.mundo.get_tree()
	t.create_timer(5.5).timeout.connect(func():
		h.emitting = false
		ch.emitting = false)
	t.create_timer(8.5).timeout.connect(func():
		h.queue_free()
		ch.queue_free())


# ---------------- Candado poseído HD ----------------
const AMBAR := Color(0.95, 0.85, 0.5)

func _luz_can(pos: Vector2, energia: float, tam: float, dur: float) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.textura_luz()
	l.texture_scale = tam
	l.color = AMBAR
	l.energy = energia
	l.position = pos
	main.mundo.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, dur)
	tw.tween_callback(l.queue_free)

func _chispas_can(pos: Vector2, cuantas: int) -> void:
	var antes: int = main.mundo.get_child_count()
	Fx.chispas(main.mundo, pos, AMBAR, cuantas)
	for k in range(antes, main.mundo.get_child_count()):
		main.mundo.get_child(k).z_index = 21

# Pedazos de óxido y hierro que saltan en arco y caen girando.
func _pedazos_can(p: Vector2, n: int, lado := 0.0) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_can5_pedazo", randi() % int(Fx.meta("fx_can5_pedazo").n))
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		e.material = m
		e.position = p
		e.z_index = 0
		main.mundo.add_child(e)
		var dx := randf_range(8, 30) * (lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0))
		var fin := p + Vector2(dx, randf_range(12, 26))
		var alt := randf_range(10, 22)
		var dur := randf_range(0.5, 0.75)
		var giro := randf_range(-6.0, 6.0)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round()
				e.rotation = snappedf(k * giro, PI / 4.0), 0.0, 1.0, dur)
		t.tween_interval(0.4)
		t.tween_property(e, "modulate:a", 0.0, 0.4)
		t.tween_callback(e.queue_free)

func _humo_can(p: Vector2) -> void:
	# humo de pixel: cuadritos grises que suben ondulando, se agrandan y se deshacen
	for i in 14:
		var e := ColorRect.new()
		var t2 := 2.0 if randf() < 0.6 else 3.0
		e.size = Vector2(t2, t2)
		e.color = Color(0.22, 0.2, 0.2).lerp(Color(0.42, 0.4, 0.38), randf())
		var ini := (p + Vector2(randf_range(-6, 6), randf_range(-3, 3))).round()
		e.position = ini
		e.z_index = 19
		e.modulate.a = 0.0
		main.mundo.add_child(e)
		var sube := randf_range(14, 30)
		var onda := randf_range(-6, 6)
		var dur := randf_range(0.7, 1.2)
		var t := e.create_tween()
		t.tween_interval(randf_range(0.0, 0.25))
		t.tween_property(e, "modulate:a", 0.7, 0.1)
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (ini + Vector2(sin(k * PI * 1.5) * onda, -sube * k)).round(), 0.0, 1.0, dur)
		t.parallel().tween_property(e, "modulate:a", 0.0, dur * 0.6).set_delay(dur * 0.45)
		t.tween_callback(e.queue_free)

func _preparar_candado() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# brillo tenue de los ojos verdes
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.3
	luz.color = Color(0.5, 1.0, 0.45)
	luz.energy = 0.3
	luz.position = Vector2(0, -40)
	add_child(luz)
	var lat := luz.create_tween().set_loops()
	lat.tween_property(luz, "energy", 0.45, 0.9).set_trans(Tween.TRANS_SINE)
	lat.tween_property(luz, "energy", 0.22, 0.9).set_trans(Tween.TRANS_SINE)
	set_meta("luz_can", luz)
	# reflejo dorado tenue en el piso: le da volumen sin aclarar la pantalla
	var piso_luz := PointLight2D.new()
	piso_luz.texture = Fx.textura_luz()
	piso_luz.texture_scale = 0.45
	piso_luz.color = Color(0.85, 0.65, 0.3)
	piso_luz.energy = 0.35
	piso_luz.position = Vector2(0, -4)
	add_child(piso_luz)
	# humito verde que sube de los ojos
	var ojos := CPUParticles2D.new()
	ojos.amount = 10
	ojos.lifetime = 0.9
	ojos.local_coords = false
	ojos.position = Vector2(0, -42)
	ojos.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ojos.emission_rect_extents = Vector2(12, 2)
	ojos.direction = Vector2(0, -1)
	ojos.spread = 15.0
	ojos.gravity = Vector2(0, -10)
	ojos.initial_velocity_min = 4.0
	ojos.initial_velocity_max = 9.0
	ojos.scale_amount_min = 1.0
	ojos.scale_amount_max = 2.0
	var go := Gradient.new()
	go.set_color(0, Color(0.6, 1.0, 0.45, 0.8))
	go.set_color(go.get_point_count() - 1, Color(0.15, 0.4, 0.1, 0.0))
	ojos.color_ramp = go
	var mo := CanvasItemMaterial.new()
	mo.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ojos.material = mo
	add_child(ojos)
	set_meta("ojos_can", ojos)
	# motas de óxido flotando alrededor
	var motas := CPUParticles2D.new()
	motas.amount = 12
	motas.lifetime = 2.2
	motas.local_coords = false
	motas.position = Vector2(0, -28)
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motas.emission_rect_extents = Vector2(30, 24)
	motas.direction = Vector2(0, -1)
	motas.spread = 180.0
	motas.gravity = Vector2(0, 4)
	motas.initial_velocity_min = 2.0
	motas.initial_velocity_max = 6.0
	motas.scale_amount_min = 1.0
	motas.scale_amount_max = 1.0
	var gm := Gradient.new()
	gm.set_color(0, Color(0.6, 0.35, 0.15, 0.0))
	gm.add_point(0.3, Color(0.7, 0.45, 0.2, 0.9))
	gm.set_color(gm.get_point_count() - 1, Color(0.35, 0.2, 0.1, 0.0))
	motas.color_ramp = gm
	motas.z_index = -1
	add_child(motas)
	set_meta("motas_can", motas)
	# destellos amarillos que se le desprenden del cuerpo, suben un poco y se apagan
	var dest := Timer.new()
	dest.wait_time = 0.12
	dest.autostart = true
	add_child(dest)
	dest.timeout.connect(func():
		if not vivo or sprite.animation == "pulir" or randf() < 0.4:
			return
		var lado2 := -1.0 if randf() < 0.5 else 1.0
		var ini := (position + Vector2(lado2 * randf_range(16, 26), sprite.position.y - randf_range(10, 60))).round()
		var d := ColorRect.new()
		d.size = Vector2(1, 1) if randf() < 0.6 else Vector2(2, 2)
		d.color = Color(1.0, 0.86, 0.4) if randf() < 0.6 else Color(0.85, 0.62, 0.2)
		d.position = ini
		d.z_index = 0
		main.mundo.add_child(d)
		var fin := ini + Vector2(lado2 * randf_range(2, 8), -randf_range(8, 18))
		var t3 := d.create_tween()
		t3.tween_method(func(q: float):
			if is_instance_valid(d):
				d.position = ini.lerp(fin, q).round()
				d.visible = q < 0.6 or int(q * 20.0) % 2 == 0, 0.0, 1.0, randf_range(0.4, 0.7))
		t3.tween_callback(d.queue_free))
	# sombra pegada al piso: se achica y aclara mientras está en el aire
	# sombra de contacto en dos capas (orilla y centro oscuro): se ve apoyado en el piso
	var sombra := Node2D.new()
	sombra.z_index = -1
	sombra.position = Vector2(0, 1)
	add_child(sombra)
	for capa in 2:
		var o := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := 30.0 if capa == 0 else 21.0
		var ry := rx * 0.28
		for i in 24:
			pts.append(Vector2(cos(TAU * i / 24.0) * rx, sin(TAU * i / 24.0) * ry).round())
		o.polygon = pts
		o.color = Color(0.02, 0.0, 0.03, 0.35 if capa == 0 else 0.6)
		sombra.add_child(o)
	set_meta("sombra_can", sombra)
	# vida constante: escamas de óxido que se le caen, destellos en el metal y polvito a sus pies
	var vida := Timer.new()
	vida.wait_time = 0.35
	vida.autostart = true
	add_child(vida)
	vida.timeout.connect(func():
		if not vivo or sprite.animation == "pulir":
			return
		var r := randf()
		if r < 0.3:
			# escama de óxido que se desprende y cae girando
			var e := Sprite2D.new()
			e.texture = Fx.cuadro("fx_can5_pedazo", randi() % 2)
			e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			e.modulate = Color(0.8, 0.5, 0.3)
			var ini := position + Vector2(randf_range(-20, 20), sprite.position.y - randf_range(14, 40))
			e.position = ini.round()
			e.z_index = 0
			main.mundo.add_child(e)
			var fin := Vector2(ini.x + randf_range(-6, 6), position.y)
			var t := e.create_tween()
			t.tween_method(func(k: float):
				if is_instance_valid(e):
					e.position = ini.lerp(fin, k * k).round()
					e.rotation = snappedf(k * 6.0, PI / 2.0), 0.0, 1.0, 0.6)
			t.tween_property(e, "modulate:a", 0.0, 0.3)
			t.tween_callback(e.queue_free)
		elif r < 0.5:
			# destello en una orilla del metal
			var d := Sprite2D.new()
			d.texture = Fx.cuadro("fx_can5_chispa", randi() % int(Fx.meta("fx_can5_chispa").n))
			d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var m := CanvasItemMaterial.new()
			m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			d.material = m
			d.position = (position + Vector2(randf_range(-22, 22), sprite.position.y - randf_range(16, 54))).round()
			d.z_index = 0
			main.mundo.add_child(d)
			var t2 := d.create_tween()
			t2.tween_property(d, "modulate:a", 0.0, 0.3).set_delay(0.08)
			t2.tween_callback(d.queue_free)
		elif r < 0.7 and sprite.position.y > -4.0:
			_polvo5_can(position + Vector2(randf_range(-14, 14), 0), randf() < 0.5, 3, 0.5))
	var ALTOS := [0, 0, 0, 0, 0, 3, 12, 22, 32, 40, 44, 32, 4, 0, 0, 0, 0, 0]
	var ALTOS_ATK := [0, 0, 0, 0, 0, 0, 0, 10, 30, 52, 58, 40, 0, 0, 0, 0, 0]
	sprite.frame_changed.connect(func():
		if not is_instance_valid(sombra):
			return
		var h := 0.0
		if sprite.animation == "mover" and sprite.frame < ALTOS.size():
			h = ALTOS[sprite.frame]
		elif sprite.animation == "ataque" and sprite.frame < ALTOS_ATK.size():
			h = ALTOS_ATK[sprite.frame]
		var k := 1.0 - clampf(h / 70.0, 0.0, 0.6)
		sombra.scale = Vector2(k, k)
		sombra.modulate.a = k
		if sprite.animation == "pulir":
			sombra.scale = Vector2(1.5, 1.0)
		# en el aire suelta polvito que cae
		if vivo and h > 15.0:
			var p := position + Vector2(randf_range(-10, 10), -h * 0.5 - 6.0)
			var e := Sprite2D.new()
			e.texture = Fx.cuadro("fx_can5_pedazo", randi() % 2)
			e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			e.position = p
			e.z_index = 0
			main.mundo.add_child(e)
			var t := e.create_tween()
			t.tween_property(e, "position:y", position.y - 2.0, 0.35).set_ease(Tween.EASE_IN)
			t.parallel().tween_property(e, "modulate:a", 0.0, 0.35)
			t.tween_callback(e.queue_free))
	# brinco: se impulsa, vuela y cae con un clac
	sprite.frame_changed.connect(func():
		if not vivo or sprite.animation != "mover":
			return
		var f := sprite.frame
		var lado := signf(vel.x) if absf(vel.x) > 1.0 else 1.0
		var piso := position + Vector2(0, -2)
		if f == 5:
			# se empuja del piso: polvo y terrones hacia atrás
			_polvo5_can(piso + Vector2(-lado * 12.0, 0), lado > 0.0)
			_polvo5_can(piso + Vector2(lado * 8.0, 0), lado < 0.0)
			_fx6("fx_can6_polvo", piso + Vector2(-lado * 10.0, -8), 14.0)
			_piedras_can(piso + Vector2(-lado * 8.0, -4), 2, -lado)
		if f >= 8 and f <= 11:
			_sombra_can()   # estela del cuerpo en el aire
		if f == 12:
			# cae de esquina: chispas del roce
			_chispitas_can(piso + Vector2(lado * 14.0, -4), 4)
		elif f == 13:
			# aterriza y muerde el aire: polvo a los lados, piedritas, destello y sacudida leve
			_polvo5_can(piso + Vector2(-16, 0), false)
			_polvo5_can(piso + Vector2(16, 0), true)
			_piedras_can(piso + Vector2(0, -4), 3)
			_raspon_can(piso)
			_impacto_piso_can(piso + Vector2(0, 4), false)
			if randf() < 0.5:
				_fx6("fx_can6_oxido", position + Vector2(randf_range(-10, 10), -26), 14.0)
			_chispitas_can(position + Vector2(lado * 6.0, -24), 5)
			_pedazos_can(piso + Vector2(0, -8), 2)
			_fx6("fx_can6_oxido", position + Vector2(randf_range(-8, 8), -24), 14.0)
			_destello_can(0.25)
			main.sacudir(2.6)
			Juego.sonido("golpe", true, -14.0))
	# derrota: se agrieta, suelta el arco, se parte en dos, caen las mitades y se desmorona
	sprite.frame_changed.connect(func():
		if sprite.animation != "pulir":
			return
		var f := sprite.frame
		var cuerpo := position + Vector2(0, -34)
		var piso := position + Vector2(0, -2)
		if f == 0:
			_fx6("fx_can6_oxido", cuerpo, 14.0)
			_fx6("fx_can6_engrane", cuerpo, 16.0, false)
			_destello_can(0.9)
			_chispitas_can(cuerpo, 10)
			_pedazos_can(cuerpo, 3)
			main.pausa_impacto(0.07)
			main.sacudir(2.0)
		elif f == 2 or f == 3:
			# se agrieta: chispazos que salen de las grietas
			_chispitas_can(cuerpo + Vector2(randf_range(-14, 14), randf_range(-10, 10)), 5)
			_pedazos_can(cuerpo, 2)
			_fx6("fx_can6_oxido", cuerpo + Vector2(randf_range(-12, 12), randf_range(-8, 8)), 14.0)
			Juego.sonido("golpe", true, -12.0)
		elif f == 4:
			_pedazos_can(cuerpo, 4)
			_chispitas_can(cuerpo, 6)
			_polvo5_can(cuerpo + Vector2(0, 6), randf() < 0.5)
		elif f == 5:
			# el arco sale volando
			_destello_can(0.6)
			_piezas_can(cuerpo + Vector2(10, -26), 2, 1.0)
			_fx6("fx_can6_llave", cuerpo + Vector2(12, -24), 14.0, false)
			_chispitas_can(cuerpo + Vector2(8, -28), 8)
			main.sacudir(1.5)
		elif f == 6:
			# se parte en dos: destello fuerte, pausa, lluvia de pedazos y humo
			_destello_can(1.0)
			_chispitas_can(cuerpo, 14)
			_pedazos_can(cuerpo + Vector2(0, -6), 7)
			_piezas_can(cuerpo, 3)
			_humo_can(cuerpo + Vector2(0, -8))
			_fx6("fx_can6_engrane", cuerpo, 15.0, false)
			_fx6("fx_can6_llave", cuerpo + Vector2(-10, -6), 13.0, false)
			_impacto_piso_can(piso + Vector2(0, 4), true)
			main.pausa_impacto(0.09)
			main.sacudir(3.5)
			Juego.sonido("golpe", false)
		elif f >= 8 and f <= 11:
			_pedazos_can(cuerpo + Vector2(randf_range(-20, 20), 0), 2)
			_chispitas_can(cuerpo + Vector2(randf_range(-24, 24), 4), 2)
		elif f == 12:
			# las mitades chocan contra el piso
			_polvo5_can(piso + Vector2(-26, 0), false)
			_polvo5_can(piso + Vector2(26, 0), true)
			_polvo5_can(piso, randf() < 0.5)
			_impacto_piso_can(piso + Vector2(0, 4), true)
			_fx6("fx_can6_oxido", piso + Vector2(0, -12), 14.0)
			_piedras_can(piso + Vector2(0, -6), 6)
			_pedazos_can(piso + Vector2(0, -8), 5)
			_piezas_can(piso + Vector2(0, -10), 2)
			_chispitas_can(piso + Vector2(0, -6), 8)
			main.pausa_impacto(0.05)
			main.sacudir(3.0)
			Juego.sonido("golpe", false)
		elif f >= 13:
			# se desmorona: polvo y humo que suben
			_humo_can(piso + Vector2(randf_range(-26, 26), -10))
			_fx6("fx_can6_polvo", piso + Vector2(randf_range(-20, 20), -12), 12.0)
			_polvo5_can(piso + Vector2(randf_range(-20, 20), 0), randf() < 0.5)
			_pedazos_can(piso + Vector2(randf_range(-16, 16), -8), 2))

# Efecto animado de la hoja nueva del candado (clanc, óxido, llave, engranes, polvo).
func _fx6(clave: String, p: Vector2, fps := 16.0, sumar := false, z := 0) -> void:
	if clave == "fx_can6_polvo":
		_polvo5_can(p + Vector2(0, 8), randf() < 0.5, 8)
		return
	_fx_pol(clave, p, fps, randf() < 0.5, sumar, z)

# Destello blanco sobre el cuerpo.
func _destello_can(fuerza: float) -> void:
	mat.set_shader_parameter("destello", fuerza)
	create_tween().tween_method(func(v): mat.set_shader_parameter("destello", v), fuerza, 0.0, 0.22)

# Chispas dibujadas (cruces y rayitas) que saltan y se apagan.
func _chispitas_can(p: Vector2, n: int) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_can5_chispa", randi() % int(Fx.meta("fx_can5_chispa").n))
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		e.material = m
		e.position = p
		e.z_index = 0
		main.mundo.add_child(e)
		var ang := randf_range(-PI, 0.0)
		var fin := p + Vector2(cos(ang), sin(ang)) * randf_range(10, 30) + Vector2(0, randf_range(2, 10))
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = p.lerp(fin, 1.0 - (1.0 - k) * (1.0 - k)).round(), 0.0, 1.0, randf_range(0.2, 0.4))
		t.parallel().tween_property(e, "modulate:a", 0.0, 0.4).set_delay(0.12)
		t.tween_callback(e.queue_free)
	Fx.chispas(main.mundo, p, Color(1.0, 0.92, 0.55), maxi(1, n / 2))

# Piezas sueltas (colmillos, remaches, placa, ojo) que saltan alto y rebotan.
func _piezas_can(p: Vector2, n: int, lado := 0.0) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_can5_pieza", randi() % int(Fx.meta("fx_can5_pieza").n))
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.position = p
		e.z_index = 0
		main.mundo.add_child(e)
		var dx := randf_range(14, 40) * (lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0))
		var fin := Vector2(p.x + dx, position.y - randf_range(0, 6))
		var alt := randf_range(18, 34)
		var giro := randf_range(-8.0, 8.0)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round()
				e.rotation = snappedf(k * giro, PI / 2.0), 0.0, 1.0, randf_range(0.55, 0.8))
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (fin + Vector2(dx * 0.2 * k, -sin(k * PI) * 5.0)).round(), 0.0, 1.0, 0.25)
		t.tween_interval(0.8)
		t.tween_property(e, "modulate:a", 0.0, 0.5)
		t.tween_callback(e.queue_free)

# Polvo de pixel: cuadritos cafés que salen a ras del piso hacia los lados, suben un poco y se asientan.
func _polvo5_can(p: Vector2, voltear: bool, n := 10, ancho := 1.0) -> void:
	var lado := -1.0 if voltear else 1.0
	for i in n:
		var e := ColorRect.new()
		var t2 := 1.0 if randf() < 0.7 else 2.0
		e.size = Vector2(t2, t2)
		var tono := randf_range(0.0, 1.0)
		e.color = Color(0.42, 0.36, 0.28).lerp(Color(0.62, 0.55, 0.42), tono)
		e.position = (p + Vector2(randf_range(-4, 4), randf_range(-2, 1))).round()
		e.z_index = -1
		main.mundo.add_child(e)
		var dx := randf_range(4, 22) * ancho * (lado if randf() < 0.75 else -lado)
		var sube := randf_range(3, 10)
		var ini := e.position
		var dur := randf_range(0.45, 0.8)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				var ease_k := 1.0 - (1.0 - k) * (1.0 - k)
				e.position = (ini + Vector2(dx * ease_k, -sin(k * PI * 0.8) * sube)).round(), 0.0, 1.0, dur)
		t.parallel().tween_property(e, "modulate:a", 0.0, dur * 0.6).set_delay(dur * 0.5)
		t.tween_callback(e.queue_free)

# Destello de impacto contra el piso: golpe aplastado, grietas de luz y chispas rasantes.
func _impacto_piso_can(p: Vector2, fuerte: bool) -> void:
	_fx_pol("fx_can7_golpe", p + Vector2(0, -4), 18.0, false, false, 4)
	if fuerte:
		_fx_pol("fx_can7_grieta", p + Vector2(0, -2), 16.0, randf() < 0.5, false, -1)
	_fx_pol("fx_can7_rasante", p + Vector2(14, -3), 18.0, false, false, 4)
	_fx_pol("fx_can7_rasante", p + Vector2(-14, -3), 18.0, false, true, 4)
	_polvo5_can(p, false, 12 if fuerte else 8)
	_polvo5_can(p, true, 12 if fuerte else 8)

# Golpe recibido: destello, chispazo, pedazos de latón y una bocanada de humo.
func _golpe_candado(centro: Vector2, desde: Vector2, critico: bool) -> void:
	var lado := signf(desde.x) if absf(desde.x) > 0.01 else 1.0
	_destello_can(0.8 if critico else 0.6)
	sacudon *= 1.5
	_fx6("fx_can6_oxido", centro, 16.0)
	if critico:
		_fx6("fx_can6_engrane", centro, 18.0, false)
	_chispitas_can(centro, 7 if critico else 5)
	_pedazos_can(centro, 3 if critico else 2, lado)
	if critico:
		_piezas_can(centro, 1, lado)
	get_tree().create_timer(0.12).timeout.connect(func():
		if is_instance_valid(self):
			_humo_can(centro + Vector2(-lado * 6.0, -6)))

# Ataque: aprieta los dientes, abre la boca (aviso), se lanza alto y cae mordiendo.
func _salto_candado() -> void:
	estado = "salto"
	especial("ataque")
	var destino: Vector2 = objetivo.position
	var r: Rect2 = main.interior()
	var hacia_d := destino - position
	if hacia_d.length() > 1.0:
		destino -= hacia_d.normalized() * minf(30.0, hacia_d.length())   # cae justo frente a Diana, sin atravesarla
	destino = Vector2(clampf(destino.x, r.position.x + 24, r.end.x - 24), clampf(destino.y, r.position.y + 40, r.end.y - 6))
	var marca := Node2D.new()   # (solo para compatibilidad con el resto del salto)
	main.mundo.add_child(marca)
	# aviso: el piso se agrieta y brilla rojo-dorado donde va a caer; al caer, las grietas se apagan
	var fps_m: float = sprite.sprite_frames.get_animation_speed("ataque")
	var aviso := _fx_pol("fx_can_marca", destino + Vector2(0, -2), 6.0 * fps_m / 12.0 / 1.0, false, false, -1)
	aviso.scale = Vector2(2, 2)
	var desde := position
	var fps: float = sprite.sprite_frames.get_animation_speed("ataque")
	var ya := [false, false, false, false]
	var al_cuadro := func():
		if sprite.animation != "ataque" or not vivo:
			return
		var f := sprite.frame
		if f == 1 and not ya[0]:
			ya[0] = true
			_polvo5_can(position + Vector2(-14, -2), false)
			_polvo5_can(position + Vector2(14, -2), true)
		if f == 3 and not ya[1]:
			# abre la boca: aviso para esquivar
			ya[1] = true
			_destello_can(0.35)
			_chispitas_can(position + Vector2(0, -22), 4)
			_fx6("fx_can6_oxido", position + Vector2(0, -30), 14.0)
			Juego.sonido("disparo_enemigo", true, -10.0)
		if f == 7 and not ya[2]:
			# se lanza: recorre el camino hasta Diana mientras vuela
			ya[2] = true
			_polvo5_can(position + Vector2(-12, -2), false)
			_polvo5_can(position + Vector2(12, -2), true)
			_piedras_can(position + Vector2(0, -4), 4)
			_fx6("fx_can6_polvo", position + Vector2(0, -10), 14.0)
			_impacto_piso_can(position, false)
			var tw := create_tween()
			tw.tween_method(func(k: float):
				if is_instance_valid(self) and vivo:
					position = desde.lerp(destino, k), 0.0, 1.0, 5.0 / fps).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			for k in 4:
				get_tree().create_timer(0.07 * k).timeout.connect(func():
					if is_instance_valid(self) and vivo:
						_sombra_can())
		if f == 12 and not ya[3]:
			# mordida: clac, onda, polvo, chispas, piezas y sacudida
			ya[3] = true
			if is_instance_valid(marca):
				marca.queue_free()
			var piso := position + Vector2(0, -2)
			_destello_can(0.5)
			_impacto_piso_can(piso + Vector2(0, 4), true)
			_fx6("fx_can6_engrane", position + Vector2(0, -22), 16.0, false)
			_fx6("fx_can6_oxido", position + Vector2(0, -28), 14.0)
			_polvo5_can(piso + Vector2(-20, 0), false)
			_polvo5_can(piso + Vector2(20, 0), true)
			_polvo5_can(piso, randf() < 0.5)
			_piedras_can(piso + Vector2(0, -6), 6)
			_pedazos_can(piso + Vector2(0, -10), 3)
			_raspon_can(piso)
			_chispitas_can(position + Vector2(0, -22), 10)
			main.sacudir(5.0)
			main.pausa_impacto(0.05)
			Juego.sonido("golpe", false)
			if objetivo.position.distance_to(position) < 44.0:
				objetivo.herir(1, objetivo.position - position)
	sprite.frame_changed.connect(al_cuadro)
	var total: float = sprite.sprite_frames.get_frame_count("ataque") / fps
	get_tree().create_timer(total + 0.1).timeout.connect(func():
		if is_instance_valid(marca):
			marca.queue_free()
		if not is_instance_valid(self):
			return
		if sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro)
		if not vivo:
			return
		estado = "seguir"
		anim_t = 0.0
		sprite.play("mover"))

# Copia translúcida que se queda atrás durante el salto de ataque.
func _sombra_can() -> void:
	var c := Sprite2D.new()
	c.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	c.flip_h = sprite.flip_h
	c.scale = sprite.scale
	c.offset = sprite.offset
	c.centered = sprite.centered
	c.position = position + sprite.position
	c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	c.material = m
	c.modulate = Color(0.55, 0.45, 0.2, 0.35)
	c.z_index = z_index - 1
	main.mundo.add_child(c)
	var t := c.create_tween()
	t.tween_property(c, "modulate:a", 0.0, 0.25)
	t.tween_callback(c.queue_free)

# Al terminar de desmoronarse: humo, polvo, motas que suben y se desvanece.
func _deshacer_candado() -> void:
	for k in ["ojos_can", "motas_can"]:
		if has_meta(k):
			get_meta(k).emitting = false
	if has_meta("luz_can"):
		var l: PointLight2D = get_meta("luz_can")
		l.create_tween().tween_property(l, "energy", 0.0, 0.5)
	var piso := position + Vector2(0, -2)
	var h := CPUParticles2D.new()
	h.position = piso + Vector2(0, -4)
	h.amount = 30
	h.lifetime = 2.6
	h.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	h.emission_rect_extents = Vector2(30, 4)
	h.direction = Vector2(0, -1)
	h.spread = 18.0
	h.gravity = Vector2(0, -8)
	h.initial_velocity_min = 5.0
	h.initial_velocity_max = 12.0
	h.scale_amount_min = 4.0
	h.scale_amount_max = 8.0
	var g := Gradient.new()
	g.set_color(0, Color(0.3, 0.27, 0.25, 0.0))
	g.add_point(0.15, Color(0.35, 0.32, 0.3, 0.75))
	g.add_point(0.6, Color(0.25, 0.23, 0.22, 0.45))
	g.set_color(g.get_point_count() - 1, Color(0.15, 0.14, 0.13, 0.0))
	h.color_ramp = g
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	h.material = m
	h.z_index = 2
	main.mundo.add_child(h)
	# motas de latón que suben brillando y se apagan
	var sube := CPUParticles2D.new()
	sube.position = piso + Vector2(0, -6)
	sube.amount = 22
	sube.lifetime = 1.5
	sube.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sube.emission_rect_extents = Vector2(26, 4)
	sube.direction = Vector2(0, -1)
	sube.spread = 22.0
	sube.gravity = Vector2(0, -14)
	sube.initial_velocity_min = 6.0
	sube.initial_velocity_max = 16.0
	sube.scale_amount_min = 1.0
	sube.scale_amount_max = 2.0
	var gs := Gradient.new()
	gs.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	gs.add_point(0.35, Color(0.85, 0.75, 0.35, 0.9))
	gs.set_color(gs.get_point_count() - 1, Color(0.4, 0.35, 0.15, 0.0))
	sube.color_ramp = gs
	var ma := CanvasItemMaterial.new()
	ma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sube.material = ma
	sube.z_index = 0
	main.mundo.add_child(sube)
	for k in 6:
		get_tree().create_timer(0.25 * k).timeout.connect(func():
			if is_instance_valid(h):
				_humo_can(piso + Vector2(randf_range(-24, 24), -10))
				_polvo5_can(piso + Vector2(randf_range(-20, 20), 0), randf() < 0.5)
				_fx6("fx_can6_polvo", piso + Vector2(randf_range(-22, 22), -14), 12.0))
	var t: SceneTree = main.mundo.get_tree()
	t.create_timer(1.6).timeout.connect(func(): sube.emitting = false)
	t.create_timer(3.5).timeout.connect(sube.queue_free)
	t.create_timer(5.0).timeout.connect(func(): h.emitting = false)
	t.create_timer(8.0).timeout.connect(h.queue_free)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func(): Fx.desintegrar(main.mundo, sprite, position.y, Color(1.1, 1.0, 0.75)))
	tw.tween_property(sprite, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


# Polvo de arrastre (dibujado) a ras del piso, saliendo hacia atrás.
func _polvo_can(p: Vector2, voltear: bool) -> void:
	var f := _fx_pol("fx_can_polvo", p + Vector2(0, -8), 10.0, voltear)
	f.z_index = 4

# Raspón de tierra que se queda un momento en el piso y se borra.
func _raspon_can(p: Vector2) -> void:
	var r := Sprite2D.new()
	r.texture = Fx.cuadro("fx_can_raspon", 2)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.position = p + Vector2(0, -2)
	r.z_index = -1
	r.flip_h = randf() < 0.5
	main.mundo.add_child(r)
	var t := r.create_tween()
	t.tween_interval(1.2)
	t.tween_property(r, "modulate:a", 0.0, 1.0)
	t.tween_callback(r.queue_free)

# Piedritas y terrones que saltan y quedan rodando.
func _piedras_can(p: Vector2, n: int, lado := 0.0) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_can_piedra", randi() % 6)
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.scale = Vector2.ONE * 0.5
		e.position = p
		e.z_index = 4
		main.mundo.add_child(e)
		var dx := randf_range(6, 20) * (lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0))
		var fin := p + Vector2(dx, randf_range(2, 6))
		var alt := randf_range(4, 10)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round(), 0.0, 1.0, randf_range(0.3, 0.45))
		t.tween_interval(0.6)
		t.tween_property(e, "modulate:a", 0.0, 0.5)
		t.tween_callback(e.queue_free)


# ---------------- Cadena viva HD ----------------
const ACIDO := Color(0.62, 1.0, 0.25)

# Boca de la cadena (punta del hocico) en el mundo.
func _boca_cad() -> Vector2:
	var lado := -1.0 if sprite.flip_h else 1.0
	return position + Vector2(lado * 33.0, sprite.position.y - 43.0)

func _preparar_cadena() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# sombra de contacto larga, a lo largo del cuerpo tendido
	var sombra := Node2D.new()
	sombra.z_index = -1
	sombra.position = Vector2(0, 1)
	add_child(sombra)
	for capa in 2:
		var o := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := 58.0 if capa == 0 else 44.0
		var ry := 7.0 if capa == 0 else 4.5
		for i in 24:
			pts.append(Vector2(cos(TAU * i / 24.0) * rx, sin(TAU * i / 24.0) * ry).round())
		o.polygon = pts
		o.color = Color(0.02, 0.0, 0.03, 0.3 if capa == 0 else 0.5)
		sombra.add_child(o)
	# motas de óxido flotando alrededor
	var motas := CPUParticles2D.new()
	motas.amount = 14
	motas.lifetime = 2.2
	motas.local_coords = false
	motas.position = Vector2(0, -14)
	motas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motas.emission_rect_extents = Vector2(50, 12)
	motas.direction = Vector2(0, -1)
	motas.spread = 180.0
	motas.gravity = Vector2(0, -3)
	motas.initial_velocity_min = 2.0
	motas.initial_velocity_max = 6.0
	var gm := Gradient.new()
	gm.set_color(0, Color(0.6, 0.32, 0.12, 0.0))
	gm.add_point(0.3, Color(0.75, 0.42, 0.18, 0.9))
	gm.set_color(gm.get_point_count() - 1, Color(0.35, 0.18, 0.08, 0.0))
	motas.color_ramp = gm
	add_child(motas)
	set_meta("motas_cad", motas)
	# humito rojo de los ojos y ácido que gotea mientras se arrastra
	var ojos := Timer.new()
	ojos.wait_time = 0.12
	ojos.autostart = true
	add_child(ojos)
	ojos.timeout.connect(func():
		if not vivo or sprite.animation == "pulir":
			return
		var lado := -1.0 if sprite.flip_h else 1.0
		var cab := position + Vector2(lado * 34.0 * giro_cad, -14.0)
		if sprite.animation == "ataque":
			cab = _boca_cad() + Vector2(-lado * 6.0, -6.0)
		if randf() < 0.5:
			var e := ColorRect.new()
			e.size = Vector2(1, 1)
			e.color = Color(1.0, 0.3, 0.2) if randf() < 0.6 else Color(0.6, 0.12, 0.1)
			var ini := (cab + Vector2(randf_range(-3, 3), randf_range(-2, 1))).round()
			e.position = ini
			e.z_index = 0
			main.mundo.add_child(e)
			var t := e.create_tween()
			t.tween_method(func(k: float):
				if is_instance_valid(e):
					e.position = (ini + Vector2(-lado * k * 6.0 + sin(k * 6.0), -k * 10.0)).round()
					e.visible = k < 0.6 or int(k * 20.0) % 2 == 0, 0.0, 1.0, randf_range(0.5, 0.8))
			t.tween_callback(e.queue_free)
		if randf() < 0.12:
			var c := ColorRect.new()
			c.size = Vector2(1, 1)
			c.color = Color(1.0, 0.45, 0.3)
			c.position = (position + Vector2(randf_range(-44, 44) * giro_cad, -randf_range(3, 20))).round()
			c.z_index = 0
			main.mundo.add_child(c)
			var tc := c.create_tween()
			tc.tween_property(c, "modulate:a", 0.0, 0.25).set_delay(0.1)
			tc.tween_callback(c.queue_free)
		if sprite.animation == "mover" and randf() < 0.08:
			_gota_acido(cab + Vector2(lado * 4.0, 6.0)))
	# escamas de óxido que se le caen de vez en cuando
	var vida := Timer.new()
	vida.wait_time = 0.4
	vida.autostart = true
	add_child(vida)
	vida.timeout.connect(func():
		if not vivo or sprite.animation == "pulir" or randf() < 0.55:
			return
		var p := position + Vector2(randf_range(-40, 40), -randf_range(4, 14))
		_fx_pol("fx_cad_oxido", p, 10.0, randf() < 0.5, false, 0).modulate = Color(0.55, 0.5, 0.46))
	# arrastre: rayones, polvo y escamas cuando la joroba empuja y la cabeza se asienta
	sprite.frame_changed.connect(func():
		if not vivo or sprite.animation != "mover":
			return
		var lado := -1.0 if sprite.flip_h else 1.0
		var f := sprite.frame
		_polvo5_can(position + Vector2(randf_range(-36, 36), -1), randf() < 0.5, 3, 0.5)
		if f == 2 or f == 3:
			_fx_pol("fx_cad_oxido", position + Vector2(randf_range(-20, 20), -12), 10.0, randf() < 0.5, false, 0)
		if f == 1:
			_polvo5_can(position + Vector2(-lado * 30.0, -1), lado > 0.0, 6, 0.8)
			_fx_pol("fx_cad_raya", position + Vector2(-lado * 26.0, -2), 10.0, lado < 0.0, false, -1)
		elif f == 4:
			# la cabeza se asienta y el cuerpo queda plano: golpecito metálico
			_polvo5_can(position + Vector2(lado * 30.0, -1), lado < 0.0, 7, 0.9)
			_polvo5_can(position + Vector2(-lado * 20.0, -1), lado > 0.0, 5, 0.7)
			_fx_pol("fx_cad_raya", position + Vector2(lado * 10.0, -2), 10.0, lado < 0.0, false, -1)
			if randf() < 0.5:
				_chispas_cad(position + Vector2(lado * 32.0, -4), 2)
			main.sacudir(0.4)
			Juego.sonido("golpe", true, -20.0))
	# derrota: se agrieta, se parte, cae en tramos y se deshace en polvo de óxido
	sprite.frame_changed.connect(func():
		if sprite.animation != "pulir":
			return
		var f := sprite.frame
		var lado := -1.0 if sprite.flip_h else 1.0
		var cabeza := position + Vector2(lado * 30.0, -30)
		var piso := position + Vector2(0, -2)
		if f == 0:
			_destello_can(0.9)
			_chispas_cad(cabeza, 8)
			main.pausa_impacto(0.07)
			main.sacudir(2.0)
		elif f == 4 or f == 5:
			_fx_pol("fx_cad_oxido", cabeza + Vector2(-lado * 10.0, 6), 12.0, randf() < 0.5, false, 0)
			_polvo5_can(cabeza + Vector2(0, 20), randf() < 0.5, 5, 0.6)
		elif f == 6:
			# se parte el cuello
			_destello_can(1.0)
			_fx_pol("fx_cad_eslabon", cabeza + Vector2(-lado * 8.0, -4), 12.0, lado < 0.0, false, 0)
			_chispas_cad(cabeza, 10)
			main.pausa_impacto(0.08)
			main.sacudir(3.0)
			Juego.sonido("golpe", false)
		elif f == 7:
			# los tramos caen al piso
			_polvo5_can(piso + Vector2(-30, 0), false, 10)
			_polvo5_can(piso + Vector2(30, 0), true, 10)
			_fx_pol("fx_cad_eslabon", piso + Vector2(randf_range(-20, 20), -12), 12.0, randf() < 0.5, false, 0)
			_chispas_cad(piso + Vector2(0, -6), 6)
			main.sacudir(2.0)
		elif f == 8 or f == 9:
			_fx_pol("fx_cad_oxido", piso + Vector2(randf_range(-36, 36), -10), 12.0, randf() < 0.5, false, 0)
			_polvo5_can(piso + Vector2(randf_range(-30, 30), 0), randf() < 0.5, 6)
		elif f >= 12:
			# se deshace en polvo de óxido
			_polvo5_can(piso + Vector2(randf_range(-34, 34), 0), randf() < 0.5, 10, 1.2)
			_humo_can(piso + Vector2(randf_range(-26, 26), -8)))

# Chispazo de hierro dibujado + chispitas.
func _chispas_cad(p: Vector2, n: int) -> void:
	_fx_pol("fx_cad_chispa", p, 16.0, randf() < 0.5, false, 0)
	Fx.chispas(main.mundo, p, Color(1.0, 0.7, 0.35), n)

func _golpe_cadena(desde: Vector2, critico: bool) -> void:
	var lado := signf(desde.x) if absf(desde.x) > 0.01 else 1.0
	var centro := position + Vector2(-lado * 10.0, -24)
	_destello_can(0.75 if critico else 0.55)
	sacudon *= 1.5
	_fx_pol("fx_cad_chispa", centro, 16.0, randf() < 0.5, false, 22)
	Fx.chispas(main.mundo, centro, Color(1.0, 0.7, 0.35), 6 if critico else 4)
	_fx_pol("fx_cad_oxido", centro, 14.0, lado < 0.0, false, 22).modulate = Color(0.55, 0.5, 0.46)
	if critico:
		_fx_pol("fx_cad_eslabon", centro, 14.0, lado < 0.0, false, 22).modulate = Color(0.55, 0.5, 0.46)
	_polvo5_can(position + Vector2(0, -1), randf() < 0.5, 6, 0.7)
	_rafaga_cad(centro, lado, 14 if critico else 10)
	_eslabones_cad(centro, lado, 2 if critico else 1)
	_destello_acido(centro + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.6)
	if randf() < 0.6:
		_gota_acido(_boca_cad())
	_fx_pol("fx_cad_eslabon", centro + Vector2(lado * 6.0, -4), 16.0, lado < 0.0, false, 22).modulate = Color(0.55, 0.5, 0.46)

# Ataque: se levanta, infla los cachetes (gotea ácido) y escupe una bola de ácido.
func _escupir_cadena() -> void:
	var ya := [false, false, false]
	var al_cuadro := func():
		if sprite.animation != "ataque" or not vivo:
			return
		var f := sprite.frame
		var boca := _boca_cad()
		if f == 3 and not ya[0]:
			ya[0] = true
			Juego.sonido("disparo_enemigo", true, -14.0)
		if (f == 3 or f == 4 or f == 5):
			_gota_acido(boca + Vector2(randf_range(-4, 4), 6))   # escurre ácido entre los colmillos
		if f == 6 and not ya[1]:
			ya[1] = true
			var dir := Vector2(-1.0 if sprite.flip_h else 1.0, 0)
			var destino := boca + dir * 120.0 + Vector2(0, 43)
			if is_instance_valid(objetivo):
				destino = objetivo.position
			# fogonazo verde en la boca y gotas hacia atrás
			_destello_acido(boca, 1.0)
			for k in 3:
				_gota_acido(boca + Vector2(-dir.x * 4.0, 0))
			main.sacudir(0.8)
			Juego.sonido("disparo_enemigo", true, -6.0)
			_bola_cadena(boca, destino)
		if f == 8 and not ya[2]:
			ya[2] = true
			for k in 2:
				_gota_acido(boca + Vector2(randf_range(-3, 3), 4))
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(sprite) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

# Gota de ácido que cae de la boca y chisporrotea en el piso.
func _gota_acido(p: Vector2) -> void:
	var g := ColorRect.new()
	g.size = Vector2(2, 2)
	g.color = ACIDO
	g.position = p.round()
	g.z_index = 0
	main.mundo.add_child(g)
	var suelo := position.y - 1.0
	var t := g.create_tween()
	t.tween_property(g, "position:y", suelo, randf_range(0.25, 0.4)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func():
		if is_instance_valid(g):
			_vapor_acido(g.position, 2))
	t.tween_property(g, "modulate:a", 0.0, 0.3)
	t.tween_callback(g.queue_free)

# Destello verde de pixel: cruz que se abre y se apaga.
func _destello_acido(p: Vector2, fuerza: float) -> void:
	var largo := roundf(4.0 + fuerza * 5.0)
	for horizontal in [true, false]:
		var r := ColorRect.new()
		r.size = Vector2(largo * 2.0 + 1.0, 1.0) if horizontal else Vector2(1.0, largo * 2.0 + 1.0)
		r.position = (p - r.size * 0.5).round()
		r.color = Color(0.85, 1.0, 0.55)
		r.z_index = 1
		main.mundo.add_child(r)
		var t := r.create_tween()
		t.tween_property(r, "modulate:a", 0.0, 0.18).set_delay(0.06)
		t.tween_callback(r.queue_free)
	var c := ColorRect.new()
	c.size = Vector2(3, 3)
	c.position = (p - Vector2(1, 1)).round()
	c.color = Color(1, 1, 0.85)
	c.z_index = 1
	main.mundo.add_child(c)
	var tc := c.create_tween()
	tc.tween_property(c, "modulate:a", 0.0, 0.2)
	tc.tween_callback(c.queue_free)

# Vapor verde de pixel: cuadritos que suben ondulando y se deshacen.
func _vapor_acido(p: Vector2, n: int) -> void:
	for i in n:
		var e := ColorRect.new()
		var t2 := 1.0 if randf() < 0.5 else 2.0
		e.size = Vector2(t2, t2)
		e.color = Color(0.35, 0.6, 0.2).lerp(Color(0.6, 0.85, 0.35), randf())
		var ini := (p + Vector2(randf_range(-4, 4), -randf_range(0, 3))).round()
		e.position = ini
		e.z_index = 0
		main.mundo.add_child(e)
		var sube := randf_range(8, 20)
		var onda := randf_range(-4, 4)
		var dur := randf_range(0.6, 1.1)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (ini + Vector2(sin(k * PI * 1.5) * onda, -sube * k)).round(), 0.0, 1.0, dur)
		t.parallel().tween_property(e, "modulate:a", 0.0, dur * 0.6).set_delay(dur * 0.4)
		t.tween_callback(e.queue_free)

# Bola de ácido: vuela en arco hacia donde estaba Diana, vibra y gotea; al caer salpica y deja un charco.
func _bola_cadena(desde: Vector2, destino: Vector2) -> void:
	var bola := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 12.0)
	for i in range(1, 5):
		sf.add_frame("default", Fx.cuadro("fx_cad_bola", i))
	bola.sprite_frames = sf
	bola.play()
	bola.scale = Vector2.ONE * 0.55
	bola.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	bola.material = m
	bola.position = desde
	bola.z_index = 0
	main.mundo.add_child(bola)
	var piso_ini := position.y
	var dist := maxf(desde.distance_to(destino), 30.0)
	var dur := clampf(dist / 190.0, 0.35, 0.9)
	var alto := 18.0 + dist * 0.12
	var ya := [false]
	var caer := func(golpe: bool):
		if ya[0] or not is_instance_valid(bola):
			return
		ya[0] = true
		var p := Vector2(bola.position.x, bola.get_meta("suelo", bola.position.y)).round()
		bola.queue_free()
		_charco_acido(p, golpe)
	var tw := bola.create_tween()
	tw.tween_method(func(k: float):
		if not is_instance_valid(bola) or ya[0]:
			return
		var base := desde.lerp(destino, k)
		var suelo_y := lerpf(piso_ini, destino.y, k)
		var y_boca := lerpf(desde.y, suelo_y - 4.0, k)
		bola.position = Vector2(base.x, y_boca - sin(k * PI) * alto).round()
		bola.set_meta("suelo", suelo_y)
		bola.rotation = snappedf((destino - desde).angle() + (k - 0.5) * 1.2, PI / 4.0)
		bola.flip_h = destino.x < desde.x
		if bola.flip_h:
			bola.rotation += PI
		# goteritas que caen detrás, vapor y motitas brillantes
		if randf() < 0.45:
			_gota_acido(bola.position)
		if randf() < 0.5:
			_vapor_acido(bola.position, 1)
		if randf() < 0.3:
			_destello_acido(bola.position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.1)
		var suelo := Vector2(bola.position.x, suelo_y)
		if is_instance_valid(objetivo) and objetivo.position.distance_to(Vector2(bola.position.x, suelo_y)) < 12.0 and k > 0.4:
			objetivo.herir(1, (destino - desde).normalized())
			caer.call(true)
		elif not main.interior().has_point(suelo) or main.bloqueado(suelo):
			caer.call(false), 0.0, 1.0, dur)
	tw.tween_callback(func(): caer.call(false))

# Charco de ácido: salpica, se queda esparcido burbujeando con vapor verde y destellos; hiere al pisarlo.
func _charco_acido(p: Vector2, golpe: bool) -> void:
	var sal := _fx_pol("fx_cad_salpica", p + Vector2(0, -8), 14.0, randf() < 0.5, false, 0)
	sal.scale = Vector2.ONE * 1.4
	_destello_acido(p + Vector2(0, -4), 1.6)
	_destello_acido(p + Vector2(-10, -2), 0.6)
	_destello_acido(p + Vector2(10, -2), 0.6)
	_vapor_acido(p + Vector2(0, -2), 14)
	_polvo5_can(p, false, 6, 0.8)
	_polvo5_can(p, true, 6, 0.8)
	var sal2 := _fx_pol("fx_cad_salpica", p + Vector2(0, -6), 12.0, randf() < 0.5, false, 0)
	sal2.scale = Vector2(1.9, 1.0)
	sal2.modulate.a = 0.7
	for i in 16:
		var g := ColorRect.new()
		g.size = Vector2(2, 2) if randf() < 0.6 else Vector2(1, 1)
		g.color = ACIDO if randf() < 0.6 else Color(0.35, 0.7, 0.15)
		g.position = p
		g.z_index = 0
		main.mundo.add_child(g)
		var fin := p + Vector2(randf_range(-22, 22), randf_range(-4, 5))
		var alt := randf_range(6, 16)
		var tg := g.create_tween()
		tg.tween_method(func(k: float):
			if is_instance_valid(g):
				g.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round(), 0.0, 1.0, randf_range(0.3, 0.5))
		tg.tween_property(g, "modulate:a", 0.0, 0.4)
		tg.tween_callback(g.queue_free)
	main.sacudir(1.2 if golpe else 0.8)
	Juego.sonido("golpe", true, -14.0)
	# el charco: cuadros del 0 al 2 (lleno y burbujeando) en bucle, luego se encoge (3-5)
	var ch := Sprite2D.new()
	ch.texture = Fx.cuadro("fx_cad_charco", 0)
	ch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ch.scale = Vector2(1.5, 1.2)
	ch.position = p + Vector2(0, -6)
	ch.z_index = -1
	ch.modulate.a = 0.0
	main.mundo.add_child(ch)
	var mancha := Polygon2D.new()   # mancha oscura quemada debajo
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(Vector2(cos(TAU * i / 16.0) * 26.0, sin(TAU * i / 16.0) * 7.0).round())
	mancha.polygon = pts
	mancha.color = Color(0.05, 0.08, 0.02, 0.45)
	mancha.position = p
	mancha.z_index = -1
	main.mundo.add_child(mancha)
	var vivo_ch := [true]
	var tick := Timer.new()
	tick.wait_time = 0.15
	tick.autostart = true
	ch.add_child(tick)
	var cuenta := [0]
	tick.timeout.connect(func():
		if not is_instance_valid(ch) or not vivo_ch[0]:
			return
		cuenta[0] += 1
		ch.texture = Fx.cuadro("fx_cad_charco", cuenta[0] % 3)
		_vapor_acido(p + Vector2(randf_range(-22, 22), -3), 2)
		if randf() < 0.35:
			_gota_burbuja(p + Vector2(randf_range(-18, 18), randf_range(-5, 2)))
		if randf() < 0.3:
			_destello_acido(p + Vector2(randf_range(-18, 18), randf_range(-6, 2)), 0.3)
		# daña a Diana si lo pisa (cada medio segundo)
		if cuenta[0] % 4 == 0 and is_instance_valid(objetivo):
			var dd: Vector2 = objetivo.position - p
			if (dd.x * dd.x) / (28.0 * 28.0) + (dd.y * dd.y) / (9.0 * 9.0) <= 1.0:
				objetivo.herir(1, dd.normalized())
				_vapor_acido(objetivo.position, 6))
	var t := ch.create_tween()
	t.tween_property(ch, "modulate:a", 1.0, 0.15)
	t.tween_interval(3.6)
	t.tween_callback(func(): vivo_ch[0] = false)
	for k in range(3, 6):
		t.tween_callback(func():
			if is_instance_valid(ch):
				ch.texture = Fx.cuadro("fx_cad_charco", k)
				_vapor_acido(p + Vector2(randf_range(-12, 12), -3), 3))
		t.tween_interval(0.22)
	t.tween_property(ch, "modulate:a", 0.0, 0.3)
	t.tween_callback(ch.queue_free)
	var tm := mancha.create_tween()
	tm.tween_interval(4.6)
	tm.tween_property(mancha, "modulate:a", 0.0, 1.5)
	tm.tween_callback(mancha.queue_free)

# Al terminar de deshacerse: polvo de óxido y humo que suben y se desvanece.
func _deshacer_cadena() -> void:
	if has_meta("motas_cad"):
		get_meta("motas_cad").emitting = false
	var piso := position + Vector2(0, -2)
	for k in 6:
		get_tree().create_timer(0.22 * k).timeout.connect(func():
			if is_instance_valid(self):
				_polvo5_can(piso + Vector2(randf_range(-30, 30), 0), randf() < 0.5, 8, 1.1)
				_humo_can(piso + Vector2(randf_range(-24, 24), -8))
				_fx_pol("fx_cad_oxido", piso + Vector2(randf_range(-30, 30), -10), 10.0, randf() < 0.5, false, 0))
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)

# La cadena solo se voltea si Diana lleva un momento del otro lado; al hacerlo se encoge,
# cambia de lado a la mitad y se vuelve a estirar, levantando polvo (sin corte brusco).
func _voltear_cadena(delta: float, hacia: Vector2) -> void:
	if volteando_cad or not vivo or sprite.animation == "pulir" or (anim_t > 0.0 and sprite.animation == "ataque"):
		return
	var quiere_izq := hacia.x < -6.0
	var quiere_der := hacia.x > 6.0
	var mira_izq := sprite.flip_h
	if (quiere_izq and not mira_izq) or (quiere_der and mira_izq):
		lado_cad_t += delta
	else:
		lado_cad_t = 0.0
	if lado_cad_t < 0.35:
		return
	lado_cad_t = 0.0
	volteando_cad = true
	var tw := create_tween()
	tw.tween_property(self, "giro_cad", 0.15, 0.14).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		sprite.flip_h = not sprite.flip_h
		_polvo5_can(position + Vector2(-20, -1), false, 8, 0.8)
		_polvo5_can(position + Vector2(20, -1), true, 8, 0.8)
		_fx_pol("fx_cad_raya", position + Vector2(0, -2), 12.0, sprite.flip_h, false, -1)
		_fx_pol("fx_cad_oxido", position + Vector2(randf_range(-12, 12), -16), 12.0, randf() < 0.5, false, 0))
	tw.tween_property(self, "giro_cad", 1.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func(): volteando_cad = false)

# Ráfaga de escamas de óxido y chispitas de pixel que saltan en arco hacia atrás del golpe.
func _rafaga_cad(p: Vector2, lado: float, n: int) -> void:
	for i in n:
		var e := ColorRect.new()
		var chispa := randf() < 0.4
		e.size = Vector2(1, 1) if chispa or randf() < 0.5 else Vector2(2, 2)
		e.color = Color(0.95, 0.6, 0.3) if chispa else (Color(0.42, 0.22, 0.1) if randf() < 0.6 else Color(0.22, 0.2, 0.2))
		e.position = p.round()
		e.z_index = 22
		main.mundo.add_child(e)
		var fin := p + Vector2(-lado * randf_range(8, 30), randf_range(10, 26))
		var alt := randf_range(8, 22)
		var dur := randf_range(0.35, 0.6)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round()
				if chispa:
					e.visible = k < 0.5 or int(k * 24.0) % 2 == 0, 0.0, 1.0, dur)
		t.tween_property(e, "modulate:a", 0.0, 0.25)
		t.tween_callback(e.queue_free)

# Burbuja de ácido que crece en el charco y revienta en gotitas.
func _gota_burbuja(p: Vector2) -> void:
	var b := ColorRect.new()
	b.size = Vector2(2, 2)
	b.color = Color(0.75, 1.0, 0.4)
	b.position = p.round()
	b.z_index = -1
	main.mundo.add_child(b)
	var t := b.create_tween()
	t.tween_property(b, "size", Vector2(3, 3), 0.2)
	t.tween_callback(func():
		if is_instance_valid(b):
			for k in 3:
				_gota_acido(b.position + Vector2(randf_range(-2, 2), -randf_range(3, 7)))
			b.queue_free())

# Eslabones sueltos que salen volando del golpe, giran, rebotan en el piso y se apagan.
func _eslabones_cad(p: Vector2, lado: float, n: int) -> void:
	for i in n:
		var e := Sprite2D.new()
		e.texture = Fx.cuadro("fx_cad_eslabon", 0)
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.scale = Vector2.ONE * 0.45
		e.position = p
		e.z_index = 22
		e.modulate = Color(0.5, 0.46, 0.42)
		main.mundo.add_child(e)
		var so := Polygon2D.new()
		so.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(-3, -2), Vector2(3, -2), Vector2(5, 0), Vector2(3, 2), Vector2(-3, 2)])
		so.color = Color(0, 0, 0, 0.45)
		so.z_index = -1
		main.mundo.add_child(so)
		var fin := Vector2(p.x - lado * randf_range(18, 40), position.y - randf_range(0, 4))
		var alt := randf_range(14, 26)
		var giro := randf_range(-8.0, 8.0)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)).round()
				e.rotation = snappedf(k * giro, PI / 4.0)
				if is_instance_valid(so):
					so.position = Vector2(e.position.x, lerpf(p.y + 24.0, fin.y, k)).round()
					so.scale = Vector2.ONE * (0.6 + 0.4 * (1.0 - sin(k * PI))), 0.0, 1.0, randf_range(0.45, 0.6))
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (fin + Vector2(-lado * 6.0 * k, -sin(k * PI) * 5.0)).round(), 0.0, 1.0, 0.2)
		t.tween_callback(func():
			if is_instance_valid(e):
				e.z_index = 0
				_polvo5_can(e.position, randf() < 0.5, 3, 0.5))
		t.tween_interval(0.6)
		t.tween_property(e, "modulate:a", 0.0, 0.4)
		t.parallel().tween_property(so, "modulate:a", 0.0, 0.4)
		t.tween_callback(e.queue_free)
		t.tween_callback(so.queue_free)

# ---------------- Nube de tormenta HD ----------------
const MORADO_NUB := Color(0.72, 0.5, 0.95)

func _preparar_nube() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# sombra en el piso (la nube flota)
	var sombra := Node2D.new()
	sombra.z_index = -1
	add_child(sombra)
	for capa in 2:
		var o := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := 26.0 if capa == 0 else 18.0
		var ry := 5.0 if capa == 0 else 3.0
		for i in 20:
			pts.append(Vector2(cos(TAU * i / 20.0) * rx, sin(TAU * i / 20.0) * ry).round())
		o.polygon = pts
		o.color = Color(0.02, 0.0, 0.04, 0.25 if capa == 0 else 0.4)
		sombra.add_child(o)
	set_meta("sombra_nub", sombra)
	var jirones: Array = []
	set_meta("jirones_nub", jirones)
	# jirones de humo que le dan vueltas: unos por detrás y otros por delante (profundidad)
	for j in 4:
		var jiron := Node2D.new()
		jiron.z_index = -1 if j % 2 == 0 else 1
		add_child(jiron)
		for q in 4:
			var p := Sprite2D.new()
			var claro := Color(0.3, 0.26, 0.36) if j % 2 == 0 else Color(0.38, 0.33, 0.44)
			p.texture = _tex_bola(2 if q < 2 else 1, claro, claro.darkened(0.35), Color(0.06, 0.03, 0.08, 0.85), claro.lightened(0.2))
			p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			p.position = Vector2(-q * 4, randf_range(-1, 1)).round()
			jiron.add_child(p)
		jirones.append(jiron)
		var fase := TAU * j / 4.0
		var tj := jiron.create_tween().set_loops()
		tj.tween_method(func(k: float):
			if is_instance_valid(jiron):
				var ang := fase + k * TAU
				jiron.position = Vector2(cos(ang) * 32.0, sprite.position.y - 18.0 + sin(ang) * 9.0).round()
				jiron.z_index = 1 if sin(ang) > 0.0 else -1
				jiron.modulate.a = 0.55 + 0.35 * absf(sin(ang)), 0.0, 1.0, randf_range(3.2, 4.2))
	# relámpago dentro de la nube cada tanto: varios rayitos a la vez y chispas
	var tormenta := Timer.new()
	tormenta.wait_time = 1.8
	tormenta.autostart = true
	add_child(tormenta)
	tormenta.timeout.connect(func():
		tormenta.wait_time = randf_range(1.2, 2.6)
		if not vivo or sprite.animation == "pulir":
			return
		var c := Vector2(randf_range(-14, 14), sprite.position.y - 24.0 + randf_range(-8, 6))
		for k in 3:
			get_tree().create_timer(0.05 * k).timeout.connect(func():
				if is_instance_valid(self):
					_arco_nub(self, c + Vector2(randf_range(-10, 10), randf_range(-6, 6)), randf_range(14, 22), 1))
		for k in 4:
			_chispa_nub(position + c + Vector2(randf_range(-12, 12), randf_range(-6, 6)), 22)
		if randf() < 0.4:
			Juego.sonido("disparo_enemigo", true, -28.0))
	# llovizna: rayitas grises que caen de la panza a la sombra
	var lluvia := Timer.new()
	lluvia.wait_time = 0.09
	lluvia.autostart = true
	add_child(lluvia)
	lluvia.timeout.connect(func():
		if not vivo or sprite.animation == "pulir" or randf() < 0.45:
			return
		var e := ColorRect.new()
		e.size = Vector2(1, 3)
		e.color = Color(0.42, 0.4, 0.5, 0.8)
		var x := randf_range(-20, 20)
		e.position = (position + Vector2(x, sprite.position.y - 8.0)).round()
		e.z_index = 0
		main.mundo.add_child(e)
		var piso := position.y - 1.0 + randf_range(-3, 2)
		var t := e.create_tween()
		t.tween_property(e, "position:y", piso, clampf((piso - e.position.y) / 110.0, 0.08, 0.4))
		t.tween_callback(func():
			if is_instance_valid(e):
				if randf() < 0.5:
					_salpica_nub(e.position + Vector2(0, 2), 2)
				e.queue_free()))
	# chispitas moradas que se desprenden, gotitas que caen y jirones de humo
	var vida := Timer.new()
	vida.wait_time = 0.12
	vida.autostart = true
	add_child(vida)
	vida.timeout.connect(func():
		if not vivo or sprite.animation == "pulir":
			return
		var cuerpo := position + Vector2(0, sprite.position.y - 22.0)
		var carga := sprite.animation == "ataque"
		if randf() < (0.7 if carga else 0.3):
			_chispa_nub(cuerpo + Vector2(randf_range(-24, 24), randf_range(-12, 10)), 0)
		# rayitos que chisporrotean sobre el cuerpo
		if randf() < 0.35:
			_arco_nub(self, Vector2(randf_range(-24, 24), sprite.position.y - 22.0 + randf_range(-12, 8)), randf_range(12, 20), 1)
		# humo oscuro que se desprende de las orillas (más al moverse) y queda atrás
		if randf() < (0.6 if vel.length() > 10.0 else 0.3):
			var a := randf_range(0.0, PI)
			_humo_nub(cuerpo + Vector2(cos(a) * 26.0, sin(a) * 12.0 + 4.0) - vel.normalized() * 6.0)
		# brillo de los ojos: chispita amarilla tenue que se escapa
		if randf() < 0.08:
			var lado := -1.0 if sprite.flip_h else 1.0
			var ojo := position + Vector2(lado * (9.0 if randf() < 0.5 else 25.0), sprite.position.y - 43.0)
			var e := ColorRect.new()
			e.size = Vector2(1, 1)
			e.color = Color(0.85, 0.75, 0.25)
			e.position = ojo.round()
			e.z_index = 22
			main.mundo.add_child(e)
			var te := e.create_tween()
			te.tween_property(e, "position", (ojo + Vector2(-lado * randf_range(3, 7), -randf_range(2, 5))).round(), 0.4)
			te.parallel().tween_property(e, "modulate:a", 0.0, 0.2).set_delay(0.2)
			te.tween_callback(e.queue_free)
		if randf() < 0.07:
			_gota_nub(position + Vector2(randf_range(-16, 16), sprite.position.y - 6.0))
		if randf() < 0.04:
			var h := _fx_pol("fx_nub_humo", cuerpo + Vector2(randf_range(-22, 22), randf_range(-4, 8)), 9.0, randf() < 0.5, false, 0)
			h.modulate = Color(0.6, 0.56, 0.66, 0.8))
	# derrota: golpe, se apaga, se deshace en jirones y llueve hasta quedar en charco
	sprite.frame_changed.connect(func():
		if sprite.animation != "pulir":
			return
		var f := sprite.frame
		var piso := position + Vector2(0, -1)
		var cuerpo := position + Vector2(0, sprite.position.y - 24.0)
		if f == 1:   # (el cuadro 0 no avisa al empezar)
			_destello_can(0.9)
			for k in 6:
				_chispa_nub(cuerpo + Vector2(randf_range(-14, 14), randf_range(-10, 10)), 22)
			_fx_pol("fx_nub_chispa", cuerpo, 14.0, randf() < 0.5, false, 22)
			main.pausa_impacto(0.07)
			main.sacudir(2.0)
			# baja hasta el piso mientras se deshace
			create_tween().tween_property(sprite, "position:y", 0.0, 1.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			for jr in get_meta("jirones_nub", []):
				if is_instance_valid(jr):
					jr.create_tween().tween_property(jr, "modulate:a", 0.0, 0.4).finished.connect(jr.queue_free)
			if has_meta("sombra_nub"):
				var so: Node2D = get_meta("sombra_nub")
				var tso := so.create_tween()
				tso.tween_property(so, "modulate:a", 0.0, 0.5)
				tso.tween_callback(so.queue_free)
		elif f >= 5 and f <= 18 and f % 2 == 1:
			var h := _fx_pol("fx_nub_humo", cuerpo + Vector2(randf_range(-24, 24), randf_range(-8, 8)), 9.0, randf() < 0.5, false, 0)
			h.modulate = Color(0.55, 0.52, 0.6, 0.85)
			_humo_nub(cuerpo + Vector2(randf_range(-20, 20), 0))
			_arco_nub(self, Vector2(randf_range(-16, 16), sprite.position.y - 20.0), 12.0, 1)
		if f >= 9 and f <= 26:
			_gota_nub(cuerpo + Vector2(randf_range(-22, 22), randf_range(0, 10)))
		if f == 17:
			# ya es charco: queda en el piso, por debajo de Diana
			z_index = -1
			_chapuzon_nub(piso, 1.0)
		if f == 21 or f == 27:
			_chapuzon_nub(piso + Vector2(randf_range(-6, 6), 0), 1.4 if f == 27 else 1.0)
		if f >= 29 and f % 2 == 0:
			_brillo_charco(piso))

# Las gotas caen al charco: salpicadura dibujada, ondas que se abren y chispitas lila.
func _chapuzon_nub(p: Vector2, fuerza: float) -> void:
	_fx_pol("fx_nub_gota", p + Vector2(randf_range(-8, 8), -10), 16.0, randf() < 0.5, false, 22).modulate = Color(0.7, 0.66, 0.78)
	_destello_can(0.35 * fuerza)
	main.sacudir(0.8 * fuerza)
	for k in int(10 * fuerza):
		var gc := Color(0.62, 0.56, 0.74) if randf() < 0.4 else Color(0.48, 0.44, 0.58)
		var e := _sprite_forma(_tex_bola(1, gc, gc.darkened(0.3), Color(0.08, 0.04, 0.1, 0.9), gc.lightened(0.35)), p, 22)
		var fin := p + Vector2(randf_range(-22, 22), randf_range(-2, 3))
		var alt := randf_range(6, 16) * fuerza
		var t := e.create_tween()
		t.tween_method(func(k2: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k2) + Vector2(0, -sin(k2 * PI) * alt)).round(), 0.0, 1.0, randf_range(0.3, 0.5))
		t.tween_callback(e.queue_free)
	# dos ondas en el charco
	for r in 2:
		var onda := Line2D.new()
		onda.width = 1.0
		onda.default_color = Color(0.7, 0.62, 0.85, 0.9)
		onda.antialiased = false
		onda.z_index = -1
		onda.position = p.round()
		main.mundo.add_child(onda)
		var to := onda.create_tween()
		to.tween_interval(0.12 * r)
		to.tween_method(func(k2: float):
			if is_instance_valid(onda):
				var pts := PackedVector2Array()
				var rx := 4.0 + k2 * 22.0
				for i in 17:
					pts.append(Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * rx * 0.3).round())
				onda.points = pts
				onda.modulate.a = 1.0 - k2, 0.0, 1.0, 0.5)
		to.tween_callback(onda.queue_free)

# Destellito en cruz que parpadea en la superficie del charco.
func _brillo_charco(p: Vector2) -> void:
	var s2 := _sprite_forma(_tex_destello(false), p + Vector2(randf_range(-20, 20), randf_range(-3, 0)), 1)
	var t := s2.create_tween()
	t.tween_interval(0.08)
	t.tween_callback(func(): s2.visible = false)
	t.tween_interval(0.05)
	t.tween_callback(func(): s2.visible = true)
	t.tween_property(s2, "modulate:a", 0.0, 0.18)
	t.tween_callback(s2.queue_free)
# Gota gris que cae de la nube al piso y salpica.
func _gota_nub(p: Vector2) -> void:
	var e := ColorRect.new()
	e.size = Vector2(1, 2)
	e.color = Color(0.5, 0.48, 0.58)
	e.position = p.round()
	e.z_index = 0
	main.mundo.add_child(e)
	var piso := position.y - 1.0
	var dur := clampf((piso - p.y) / 90.0, 0.1, 0.5)
	var t := e.create_tween()
	t.tween_property(e, "position:y", piso, dur).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if is_instance_valid(e):
			_salpica_nub(e.position, 3)
			e.queue_free())

# Salpicadura de pixel: gotitas que brincan a los lados y se apagan.
func _salpica_nub(p: Vector2, n: int) -> void:
	for i in n:
		var gc := Color(0.55, 0.52, 0.62) if randf() < 0.7 else Color(0.42, 0.38, 0.5)
		var e := _sprite_forma(_tex_bola(1, gc, gc.darkened(0.3), Color(0.08, 0.04, 0.1, 0.85), gc.lightened(0.3)), p, 1)
		var dx := randf_range(-7, 7)
		var alt := randf_range(2, 5)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = (p + Vector2(dx * k, -sin(k * PI) * alt)).round(), 0.0, 1.0, randf_range(0.25, 0.4))
		t.tween_callback(e.queue_free)

# Golpe recibido: destello, la nube se desgarra soltando humo y chispas moradas hacia atrás.
func _golpe_nube(desde: Vector2, critico: bool) -> void:
	var lado := signf(desde.x) if absf(desde.x) > 0.01 else 1.0
	var centro := position + Vector2(-lado * 6.0, sprite.position.y - 22.0)
	_destello_can(0.75 if critico else 0.55)
	sacudon *= 1.5
	_fx_pol("fx_nub_chispa", centro, 16.0, randf() < 0.5, false, 22)
	_fx_pol("fx_nub_humo", centro + Vector2(-lado * 8.0, 0), 12.0, lado < 0.0, false, 22).modulate = Color(0.55, 0.52, 0.6, 0.9)
	for i in (12 if critico else 8):
		var e := ColorRect.new()
		var chispa := randf() < 0.4
		e.size = Vector2(1, 1) if chispa else Vector2(2, 2)
		e.color = MORADO_NUB if chispa else (Color(0.42, 0.4, 0.48) if randf() < 0.6 else Color(0.28, 0.26, 0.32))
		e.position = centro.round()
		e.z_index = 22
		main.mundo.add_child(e)
		var fin := centro + Vector2(-lado * randf_range(8, 26), randf_range(-8, 14))
		var dur := randf_range(0.3, 0.55)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e):
				e.position = centro.lerp(fin, 1.0 - (1.0 - k) * (1.0 - k)).round()
				if chispa:
					e.visible = k < 0.5 or int(k * 24.0) % 2 == 0, 0.0, 1.0, dur)
		t.tween_property(e, "modulate:a", 0.0, 0.2)
		t.tween_callback(e.queue_free)
	for k in (3 if critico else 2):
		_arco_nub(self, Vector2(randf_range(-20, 20), sprite.position.y - 22.0 + randf_range(-10, 8)), 14.0, 1)
		_humo_nub(centro + Vector2(randf_range(-10, 10), randf_range(-6, 6)))
		_gota_nub(centro + Vector2(randf_range(-10, 10), 8))

# Ataque: se oscurece y carga, marca el piso bajo Diana con chispitas y suelta un rayo en zigzag.
func _rayo_nube() -> void:
	var destino := [objetivo.position if is_instance_valid(objetivo) else position + Vector2(0, 40)]
	var ya := [false, false]
	var al_cuadro := func():
		if not vivo or sprite.animation != "ataque":
			return
		var f := sprite.frame
		if f >= 2 and f <= 11:
			# carga: rayitos en el cuerpo y chispas que se juntan en la boca
			_arco_nub(self, Vector2(randf_range(-26, 26), sprite.position.y - 22.0 + randf_range(-12, 10)), randf_range(10, 18), 1)
			var boca := _boca_nub() - Vector2(-1.0 if sprite.flip_h else 1.0, 0) * 18.0
			for k in 2:
				var a2 := randf() * TAU
				var ini := boca + Vector2(cos(a2), sin(a2)) * randf_range(12, 20)
				var c := ColorRect.new()
				c.size = Vector2(1, 1)
				c.color = MORADO_NUB
				c.position = ini.round()
				c.z_index = 22
				main.mundo.add_child(c)
				var tc := c.create_tween()
				tc.tween_method(func(k2: float):
					if is_instance_valid(c):
						c.position = ini.lerp(boca, k2 * k2).round(), 0.0, 1.0, 0.22)
				tc.tween_callback(c.queue_free)
			if f >= 9:
				main.sacudir(0.3)
			if is_instance_valid(objetivo) and f <= 8:
				destino[0] = destino[0].lerp(objetivo.position, 0.35)   # sigue a Diana mientras carga
			# aviso: chispitas que corren por el piso donde caerá
			for k in 2:
				var a := randf() * TAU
				_chispa_nub(destino[0] + Vector2(cos(a) * randf_range(3, 12), sin(a) * randf_range(1, 4)), -1)
			if f % 2 == 0:
				_polvo5_can(destino[0], randf() < 0.5, 2, 0.4)
		if f == 4 and not ya[0]:
			ya[0] = true
			Juego.sonido("disparo_enemigo", true, -16.0)
		if f >= 12 and f <= 15:
			# la boca sigue chisporroteando mientras sale el rayo
			var lado_b := -1.0 if sprite.flip_h else 1.0
			_arco_nub(self, _boca_nub() - position + Vector2(-lado_b * 3.0, randf_range(-3, 3)), 10.0, 1)
			for k in 3:
				_chispa_nub(_boca_nub() + Vector2(randf_range(-3, 3), randf_range(-3, 3)), 22)
			_humo_nub(_boca_nub() + Vector2(-lado_b * 4.0, -4))
		if f == 12 and not ya[1]:
			ya[1] = true
			_descarga_nube(_boca_nub(), destino[0])
	sprite.frame_changed.connect(al_cuadro)
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(self) and sprite.frame_changed.is_connected(al_cuadro):
			sprite.frame_changed.disconnect(al_cuadro))

# Punta del chorro que sale de la boca (cuadro "dispara"), en el mundo.
func _boca_nub() -> Vector2:
	var lado := -1.0 if sprite.flip_h else 1.0
	return position + Vector2(lado * 28.0, sprite.position.y - 30.0)

# Zigzag de pixel entre dos puntos: se tuerce de lado a lado del trayecto.
func _zigzag(a: Vector2, b: Vector2, n: int, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var normal := (b - a).normalized().orthogonal()
	var s := 1.0 if randf() < 0.5 else -1.0
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k)
		if i > 0 and i < n:
			s = -s
			p += normal * s * randf_range(amp * 0.4, amp) * sin(k * PI)
		pts.append(p.round())
	return pts

# Rayito chico que chisporrotea un instante (en el cuerpo o en el aire); hijo de 'padre'.
func _arco_nub(padre: Node, centro: Vector2, largo: float, z: int) -> void:
	var a := randf() * TAU
	var ini := centro + Vector2(cos(a), sin(a) * 0.6) * largo * 0.5
	var fin := centro - Vector2(cos(a), sin(a) * 0.6) * largo * 0.5
	var arco := Node2D.new()
	arco.z_index = z
	padre.add_child(arco)
	# 3 capas finas: sombra oscura, morado y centro casi blanco; más una ramita
	var capas: Array[Line2D] = []
	for c in 3:
		var l := Line2D.new()
		l.width = [2.0, 1.0, 1.0][c]
		l.default_color = [Color(0.06, 0.01, 0.1, 0.7), Color(0.6, 0.35, 0.9), Color(0.93, 0.86, 1.0)][c]
		l.antialiased = false
		l.joint_mode = Line2D.LINE_JOINT_SHARP
		arco.add_child(l)
		capas.append(l)
	var rama: Array[Line2D] = []
	for c in 2:
		var l := Line2D.new()
		l.width = 1.0
		l.default_color = Color(0.06, 0.01, 0.1, 0.0) if c == 0 else Color(0.7, 0.5, 0.95)
		l.antialiased = false
		arco.add_child(l)
		rama.append(l)
	var trazar := func():
		var pts := _zigzag(ini, fin, maxi(5, int(largo / 3.0)), 3.0)
		for l in capas:
			l.points = pts
		var m := pts[randi_range(1, pts.size() - 2)]
		var rp := _zigzag(m, m + Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * largo * 0.4, 3, 2.0)
		for l in rama:
			l.points = rp
	trazar.call()
	# chispitas en las puntas
	if padre == self:
		for p in [ini, fin]:
			_chispa_nub(position + p, 22)
	var t := arco.create_tween()
	t.tween_interval(0.04)
	t.tween_callback(func(): trazar.call())
	t.tween_interval(0.04)
	t.tween_callback(func(): arco.visible = false)
	t.tween_interval(0.03)
	t.tween_callback(func():
		arco.visible = true
		trazar.call())
	t.tween_interval(0.04)
	# estela: se queda solo el morado oscuro y se apaga
	t.tween_callback(func():
		capas[2].visible = false
		rama[1].visible = false
		capas[1].default_color = Color(0.38, 0.2, 0.58))
	t.tween_property(arco, "modulate:a", 0.0, 0.12)
	t.tween_callback(arco.queue_free)

# Humo oscuro de pixel que se desprende de la orilla de la nube y se queda atrás.
# Rayo de pixel: sale de la boca, se tuerce en zigzag con ramitas, parpadea cambiando de forma
# 6 veces, deja una quemada oscura en el piso y suelta chispas a lo largo.
func _descarga_nube(desde: Vector2, hasta: Vector2) -> void:
	var rayo := Node2D.new()
	rayo.z_index = 22
	main.mundo.add_child(rayo)
	var capas: Array[Line2D] = []
	for c in 3:
		var l := Line2D.new()
		l.width = [5.0, 3.0, 1.0][c]
		l.default_color = [Color(0.08, 0.02, 0.12, 0.9), Color(0.55, 0.3, 0.85), Color(0.9, 0.8, 1.0)][c]
		l.antialiased = false
		l.joint_mode = Line2D.LINE_JOINT_SHARP
		rayo.add_child(l)
		capas.append(l)
	var ramas: Array[Line2D] = []
	for r in 2:
		for c in 2:
			var l := Line2D.new()
			l.width = 3.0 if c == 0 else 1.0
			l.default_color = Color(0.08, 0.02, 0.12, 0.85) if c == 0 else MORADO_NUB
			l.antialiased = false
			rayo.add_child(l)
			ramas.append(l)
	var largo := desde.distance_to(hasta)
	var trazar := func():
		var pts := _zigzag(desde, hasta, maxi(8, int(largo / 7.0)), 7.0)
		for l in capas:
			l.points = pts
		for r in 2:
			var i := randi_range(2, pts.size() - 3)
			var dir := (hasta - desde).normalized().rotated(randf_range(-1.0, 1.0))
			var rp := _zigzag(pts[i], pts[i] + dir * randf_range(10, 20), 3, 4.0)
			ramas[r * 2].points = rp
			ramas[r * 2 + 1].points = rp
	trazar.call()
	var t := rayo.create_tween()
	for i in 6:
		t.tween_interval(0.045)
		t.tween_callback(func():
			trazar.call()
			rayo.visible = i != 1 and i != 4)
	t.tween_callback(func():
		capas[2].visible = false
		capas[1].default_color = Color(0.35, 0.18, 0.55))
	t.tween_interval(0.06)
	t.tween_property(rayo, "modulate:a", 0.0, 0.1)
	t.tween_callback(rayo.queue_free)
	# fogonazo en la boca: chispazo, chispitas y humo oscuro hacia atrás
	_fx_pol("fx_nub_chispa", desde, 18.0, randf() < 0.5, false, 22)
	for k in 6:
		_chispa_nub(desde + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 22)
	for k in 5:
		_humo_nub(desde + Vector2(randf_range(-6, 6), randf_range(-4, 4)))
	# lluvia de chispas que caen del rayo con gravedad, y rayitos sueltos en el trayecto
	for k in 18:
		var p0 := desde.lerp(hasta, randf())
		var e := ColorRect.new()
		e.size = Vector2(1, 1) if randf() < 0.7 else Vector2(2, 1)
		e.color = Color(0.93, 0.86, 1.0) if randf() < 0.35 else MORADO_NUB
		e.position = p0.round()
		e.z_index = 22
		main.mundo.add_child(e)
		var vx := randf_range(-30, 30)
		var vy := randf_range(-40, -10)
		var dur := randf_range(0.35, 0.7)
		var te := e.create_tween()
		te.tween_method(func(k2: float):
			if is_instance_valid(e):
				var tt := k2 * dur
				e.position = (p0 + Vector2(vx * tt, vy * tt + 140.0 * tt * tt)).round()
				e.visible = k2 < 0.6 or int(k2 * 24.0) % 2 == 0, 0.0, 1.0, dur)
		te.tween_callback(e.queue_free)
	for k in 3:
		_arco_nub(main.mundo, desde.lerp(hasta, randf_range(0.2, 0.8)), 12.0, 22)
	# estela: rayo fantasma oscuro que se queda un instante
	var fantasma := Line2D.new()
	fantasma.width = 2.0
	fantasma.default_color = Color(0.3, 0.15, 0.45, 0.7)
	fantasma.antialiased = false
	fantasma.z_index = 21
	fantasma.points = _zigzag(desde, hasta, maxi(6, int(largo / 12.0)), 7.0)
	main.mundo.add_child(fantasma)
	var tf := fantasma.create_tween()
	tf.tween_interval(0.3)
	tf.tween_property(fantasma, "modulate:a", 0.0, 0.25)
	tf.tween_callback(fantasma.queue_free)
	# chispitas que se desprenden a lo largo del rayo
	for k in 10:
		var p := desde.lerp(hasta, randf())
		_chispa_nub(p + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 22)
	# quemada oscura en el piso que se desvanece despacio
	var quema := Node2D.new()
	quema.position = hasta.round()
	quema.z_index = -1
	main.mundo.add_child(quema)
	for capa in 2:
		var o := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 12:
			var r := (22.0 if capa == 0 else 13.0) * randf_range(0.75, 1.1)
			pts.append(Vector2(cos(TAU * i / 12.0) * r, sin(TAU * i / 12.0) * r * 0.35).round())
		o.polygon = pts
		o.color = Color(0.05, 0.02, 0.07, 0.35 if capa == 0 else 0.5)
		quema.add_child(o)
	for k in 5:
		var g := ColorRect.new()
		g.size = Vector2(1, 1)
		g.color = Color(0.5, 0.3, 0.75)
		g.position = Vector2(randf_range(-9, 9), randf_range(-2, 2)).round()
		quema.add_child(g)
	var tq := quema.create_tween()
	tq.tween_interval(1.2)
	tq.tween_property(quema, "modulate:a", 0.0, 1.0)
	tq.tween_callback(quema.queue_free)
	for k in 3:
		get_tree().create_timer(0.15 + 0.2 * k).timeout.connect(func():
			if is_instance_valid(quema):
				_humo_nub(hasta + Vector2(randf_range(-8, 8), -1)))
	# impacto en el piso
	_fx_pol("fx_nub_rayo", hasta + Vector2(0, -13), 18.0, randf() < 0.5, false, 22)
	_fx_pol("fx_nub_impacto", hasta + Vector2(0, -3), 16.0, false, false, 0)
	_fx_pol("fx_nub_chispa", hasta + Vector2(0, -6), 16.0, randf() < 0.5, false, 22)
	for k in 10:
		_chispa_nub(hasta + Vector2(randf_range(-10, 10), randf_range(-4, 1)), 22)
	for k in 3:
		_arco_nub(main.mundo, hasta + Vector2(randf_range(-8, 8), -4), 14.0, 22)
	_impacto_rayo_nub(hasta)
	_polvo5_can(hasta, false, 10)
	_polvo5_can(hasta, true, 10)
	main.pausa_impacto(0.04)
	main.sacudir(2.0)
	Juego.sonido("golpe", true, -8.0)
	if is_instance_valid(objetivo) and objetivo.position.distance_to(hasta) < 18.0:
		objetivo.herir(1, objetivo.position - desde)

# Al terminar de deshacerse: el charco se queda vivo un rato (burbujas, electricidad,
# vapor y destellos) y luego se evapora en humito.
func _deshacer_nube() -> void:
	sprite.position.y = 0.0
	var piso := position + Vector2(0, -1)
	var vivo_t := [0.0]
	var tic := Timer.new()
	tic.wait_time = 0.1
	tic.autostart = true
	add_child(tic)
	tic.timeout.connect(func():
		vivo_t[0] += 0.1
		var fuerza := clampf(1.0 - vivo_t[0] / 3.6, 0.2, 1.0)
		if randf() < 0.75 * fuerza:
			_burbuja_charco(piso + Vector2(randf_range(-20, 20), randf_range(-2, 1)))
		if randf() < 0.4 * fuerza:
			_arco_nub(main.mundo, piso + Vector2(randf_range(-16, 16), -3), randf_range(10, 16), 0)
		if randf() < 0.5:
			_brillo_charco(piso)
		if randf() < 0.35:
			_vapor_charco(piso + Vector2(randf_range(-20, 20), -1)))
	var tw := create_tween()
	tw.tween_interval(3.4)
	tw.tween_callback(func():
		for k in 8:
			_vapor_charco(piso + Vector2(randf_range(-22, 22), -1))
			_humo_nub(piso + Vector2(randf_range(-18, 18), -2)))
	tw.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)

# Burbuja que crece en el charco, revienta y suelta gotitas y una chispa lila.
# Vapor: puntitos grises que suben ondulando desde el charco y se apagan.
func _impacto_rayo_nub(p: Vector2) -> void:
	# aro que se abre a ras del piso (contorno oscuro + lila), se rompe en parpadeo
	var aro := Node2D.new()
	aro.position = p.round()
	aro.z_index = 22
	main.mundo.add_child(aro)
	for c in 2:
		var l := Line2D.new()
		l.width = 4.0 if c == 0 else 2.0
		l.default_color = Color(0.08, 0.02, 0.12, 0.9) if c == 0 else MORADO_NUB
		l.antialiased = false
		var pts := PackedVector2Array()
		for i in 17:
			pts.append(Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0) * 0.35))
		l.points = pts
		aro.add_child(l)
	aro.scale = Vector2.ONE * 4.0
	var ta := aro.create_tween()
	ta.tween_property(aro, "scale", Vector2.ONE * 26.0, 0.28).set_ease(Tween.EASE_OUT)
	ta.parallel().tween_method(func(k: float):
		if is_instance_valid(aro):
			for l in aro.get_children():
				l.width = (4.0 if l.get_index() == 0 else 2.0) / aro.scale.x
			aro.visible = k < 0.6 or int(k * 16.0) % 2 == 0, 0.0, 1.0, 0.28)
	ta.tween_callback(aro.queue_free)
	# rayitos que corren por el piso hacia los lados
	for k in 4:
		var lado := -1.0 if k % 2 == 0 else 1.0
		var fin := p + Vector2(lado * randf_range(18, 32), randf_range(-5, 5))
		var r := Node2D.new()
		r.z_index = 22
		main.mundo.add_child(r)
		var pts := _zigzag(p, fin, 5, 4.0)
		for c in 2:
			var l := Line2D.new()
			l.width = 4.0 if c == 0 else 2.0
			l.default_color = Color(0.08, 0.02, 0.12, 0.9) if c == 0 else Color(0.85, 0.72, 1.0)
			l.antialiased = false
			l.points = pts
			r.add_child(l)
		var tr := r.create_tween()
		tr.tween_interval(0.06 + 0.04 * k)
		tr.tween_callback(func(): r.visible = false)
		tr.tween_interval(0.04)
		tr.tween_callback(func():
			r.visible = true
			_chispa_nub(fin, 22))
		tr.tween_interval(0.06)
		tr.tween_callback(r.queue_free)
	# chispas gruesas que saltan en arco, caen y rebotan con sombrita
	for k in 12:
		var e := _sprite_forma(_tex_destello(randf() < 0.4), p, 22)
		var fin := p + Vector2(randf_range(-30, 30), randf_range(-4, 6))
		var alt := randf_range(10, 26)
		var dur := randf_range(0.35, 0.6)
		var t := e.create_tween()
		t.tween_method(func(k2: float):
			if is_instance_valid(e):
				e.position = (p.lerp(fin, k2) + Vector2(0, -sin(k2 * PI) * alt)).round()
				if k2 > 0.6:
					e.texture = _tex_destello(false)
				e.visible = k2 < 0.7 or int(k2 * 20.0) % 2 == 0, 0.0, 1.0, dur)
		t.tween_property(e, "modulate:a", 0.0, 0.25)
		t.tween_callback(e.queue_free)
	_grietas_rayo(p)
	_piedritas_rayo(p, 7)
	# anillo de polvo redondo que se abre a ras del piso
	for k in 12:
		var ang := TAU * k / 12.0
		var dir := Vector2(cos(ang), sin(ang) * 0.35)
		var c := Color(0.36, 0.32, 0.3)
		var e := _sprite_forma(_tex_bola(randi_range(2, 3), c, c.darkened(0.3), Color(0.08, 0.06, 0.06, 0.85), c.lightened(0.15)), p, -1)
		var fin := p + dir * randf_range(20, 30)
		var t2 := e.create_tween()
		t2.tween_property(e, "position", fin.round(), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t2.parallel().tween_property(e, "modulate:a", 0.0, 0.3).set_delay(0.25)
		t2.tween_callback(e.queue_free)
	# electricidad que se queda chisporroteando en el piso un momento
	for k in 5:
		get_tree().create_timer(0.12 + 0.12 * k).timeout.connect(func():
			if is_instance_valid(main):
				_arco_nub(main.mundo, p + Vector2(randf_range(-12, 12), randf_range(-3, 2)), randf_range(8, 14), 0)
				_chispa_nub(p + Vector2(randf_range(-10, 10), -2), 22))
	# segundo golpe de humo oscuro que se levanta
	for k in 6:
		_humo_nub(p + Vector2(randf_range(-12, 12), randf_range(-3, 2)))

# ---- Formas de pixel dibujadas por código (en vez de cuadritos) ----
static var _tex_nub := {}

# Bolita redonda con contorno oscuro, sombra abajo y brillo arriba-izquierda.
static func _tex_bola(r: int, claro: Color, oscuro: Color, borde: Color, brillo: Color) -> ImageTexture:
	var clave := "b%d%s%s" % [r, claro.to_html(), brillo.to_html()]
	if _tex_nub.has(clave):
		return _tex_nub[clave]
	var n := r * 2 + 3
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r + 0.5:
				var col := claro if (y + 0.5 - c.y) < r * 0.35 else oscuro
				if Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(-r * 0.4, -r * 0.4)) < maxf(0.8, r * 0.3):
					col = brillo
				img.set_pixel(x, y, col)
			elif d <= r + 1.5:
				img.set_pixel(x, y, borde)
	var t := ImageTexture.create_from_image(img)
	_tex_nub[clave] = t
	return t

# Burbuja: aro con contorno, centro translúcido y brillito.
static func _tex_burbuja(r: int) -> ImageTexture:
	var clave := "u%d" % r
	if _tex_nub.has(clave):
		return _tex_nub[clave]
	var n := r * 2 + 3
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r - 0.5:
				img.set_pixel(x, y, Color(0.5, 0.42, 0.62, 0.45))
			elif d <= r + 0.5:
				img.set_pixel(x, y, Color(0.72, 0.62, 0.86))
			elif d <= r + 1.5:
				img.set_pixel(x, y, Color(0.1, 0.05, 0.14))
	if r >= 2:
		img.set_pixel(int(c.x - r * 0.45), int(c.y - r * 0.45), Color(0.95, 0.92, 1.0))
	var t := ImageTexture.create_from_image(img)
	_tex_nub[clave] = t
	return t

# Destello en cruz de pixel: centro claro y brazos morados.
static func _tex_destello(grande: bool) -> ImageTexture:
	var clave := "d%s" % grande
	if _tex_nub.has(clave):
		return _tex_nub[clave]
	var n := 7 if grande else 5
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var m := n / 2
	for i in n:
		var lejos := absi(i - m)
		var col := Color(0.95, 0.9, 1.0) if lejos == 0 else (Color(0.78, 0.6, 1.0) if lejos == 1 else Color(0.5, 0.3, 0.75))
		img.set_pixel(i, m, col)
		img.set_pixel(m, i, col)
	if grande:
		for k in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			img.set_pixel(m + k.x, m + k.y, Color(0.5, 0.3, 0.75))
	var t := ImageTexture.create_from_image(img)
	_tex_nub[clave] = t
	return t

func _sprite_forma(tex: Texture2D, p: Vector2, z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = p.round()
	s.z_index = z
	main.mundo.add_child(s)
	return s

# Chispita: destello en cruz que salta, parpadea, se achica a punto y se apaga.
func _chispa_nub(p: Vector2, z: int) -> void:
	var grande := randf() < 0.3
	var s := _sprite_forma(_tex_destello(grande), p, z)
	var ini := p.round()
	var dx := randf_range(-6, 6)
	var sube := randf_range(4, 9)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			s.position = (ini + Vector2(dx * k, -k * sube)).round()
			if k > 0.45 and s.texture != _tex_destello(false):
				s.texture = _tex_destello(false)
			s.visible = k < 0.55 or int(k * 20.0) % 2 == 0, 0.0, 1.0, randf_range(0.35, 0.6))
	t.tween_callback(s.queue_free)

# Humo: bolita oscura sombreada que sube, crece un poco, se achica y se apaga.
func _humo_nub(p: Vector2) -> void:
	var r := randi_range(2, 3)
	var claro := Color(0.32, 0.28, 0.38)
	var oscuro := Color(0.18, 0.15, 0.22)
	var s := _sprite_forma(_tex_bola(r, claro, oscuro, Color(0.06, 0.03, 0.08, 0.9), Color(0.42, 0.37, 0.5)), p, 0)
	var ini := p.round()
	var dx := randf_range(-5, 5)
	var sube := randf_range(6, 13)
	var dur := randf_range(0.6, 1.0)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			s.position = (ini + Vector2(dx * k + sin(k * 5.0), -sube * k)).round()
			var rr := clampi(int(round(r + (1.0 if k < 0.35 else -2.0 * (k - 0.35) / 0.65 * r))), 1, r + 1)
			s.texture = _tex_bola(rr, claro, oscuro, Color(0.06, 0.03, 0.08, 0.9), Color(0.42, 0.37, 0.5)), 0.0, 1.0, dur)
	t.parallel().tween_property(s, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
	t.tween_callback(s.queue_free)

# Burbuja redonda que crece en el charco, revienta y suelta gotitas y un destello.
func _burbuja_charco(p: Vector2) -> void:
	var s := _sprite_forma(_tex_burbuja(1), p, 1)
	s.centered = true
	var max_r := randi_range(2, 4)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			var r := 1 + int(k * max_r)
			s.texture = _tex_burbuja(r)
			s.position = (p - Vector2(0, r)).round(), 0.0, 1.0, randf_range(0.4, 0.7))
	t.tween_callback(func():
		if is_instance_valid(s):
			_salpica_nub(s.position + Vector2(0, max_r), 4)
			_chispa_nub(s.position, 1)
			s.queue_free())

# Vapor: bolitas grises muy chicas que suben ondulando y se apagan.
func _vapor_charco(p: Vector2) -> void:
	var s := _sprite_forma(_tex_bola(1, Color(0.5, 0.47, 0.58, 0.8), Color(0.38, 0.35, 0.45, 0.8), Color(0.1, 0.08, 0.12, 0.5), Color(0.6, 0.57, 0.68, 0.8)), p, 0)
	var ini := p.round()
	var sube := randf_range(10, 20)
	var fase := randf() * TAU
	var dur := randf_range(0.8, 1.3)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			s.position = (ini + Vector2(sin(fase + k * 6.0) * 2.0, -sube * k)).round(), 0.0, 1.0, dur)
	t.parallel().tween_property(s, "modulate:a", 0.0, dur * 0.5).set_delay(dur * 0.5)
	t.tween_callback(s.queue_free)

# Grietas que se iluminan en el piso desde el impacto: lila al centro, se apagan a oscuro.
func _grietas_rayo(p: Vector2) -> void:
	var nodo := Node2D.new()
	nodo.position = p.round()
	nodo.z_index = -1
	main.mundo.add_child(nodo)
	var lineas: Array[Line2D] = []
	for k in 6:
		var ang := TAU * k / 6.0 + randf_range(-0.3, 0.3)
		var largo := randf_range(12, 22)
		var pts := PackedVector2Array([Vector2.ZERO])
		var punto := Vector2.ZERO
		for i in 4:
			punto += Vector2(cos(ang), sin(ang) * 0.4) * largo / 4.0 + Vector2(randf_range(-1.5, 1.5), randf_range(-0.8, 0.8))
			pts.append(punto.round())
		for c in 2:
			var l := Line2D.new()
			l.points = pts
			l.width = 2.0 if c == 0 else 1.0
			l.default_color = Color(0.05, 0.02, 0.07, 0.9) if c == 0 else Color(0.85, 0.7, 1.0)
			l.antialiased = false
			nodo.add_child(l)
			if c == 1:
				lineas.append(l)
	var t := nodo.create_tween()
	t.tween_interval(0.15)
	t.tween_method(func(k: float):
		for l in lineas:
			if is_instance_valid(l):
				l.default_color = Color(0.85, 0.7, 1.0).lerp(Color(0.25, 0.12, 0.35), k), 0.0, 1.0, 0.6)
	t.tween_interval(0.6)
	t.tween_property(nodo, "modulate:a", 0.0, 0.6)
	t.tween_callback(nodo.queue_free)

# Piedritas del piso que saltan en arco, rebotan una vez con su sombrita y se quedan un instante.
func _piedritas_rayo(p: Vector2, n: int) -> void:
	for i in n:
		var c := Color(0.34, 0.31, 0.3) if randf() < 0.6 else Color(0.26, 0.24, 0.24)
		var e := _sprite_forma(_tex_bola(randi_range(1, 2), c, c.darkened(0.35), Color(0.05, 0.04, 0.04), c.lightened(0.2)), p, 22)
		var so := _sprite_forma(_tex_bola(1, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45)), p, -1)
		var fin := p + Vector2(randf_range(-28, 28), randf_range(-6, 6))
		var alt := randf_range(10, 22)
		var dur := randf_range(0.4, 0.6)
		var t := e.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(e) and is_instance_valid(so):
				var base := p.lerp(fin, k)
				e.position = (base + Vector2(0, -sin(k * PI) * alt)).round()
				so.position = base.round(), 0.0, 1.0, dur)
		var fin2 := fin + (fin - p).normalized() * 5.0
		t.tween_method(func(k: float):
			if is_instance_valid(e) and is_instance_valid(so):
				var base := fin.lerp(fin2, k)
				e.position = (base + Vector2(0, -sin(k * PI) * 3.0)).round()
				so.position = base.round(), 0.0, 1.0, 0.18)
		t.tween_interval(0.4)
		t.tween_property(e, "modulate:a", 0.0, 0.3)
		t.parallel().tween_property(so, "modulate:a", 0.0, 0.3)
		t.tween_callback(e.queue_free)
		t.tween_callback(so.queue_free)

# ---------------- Gota de ácido HD ----------------
const VERDE_GOT := Color(0.5, 0.58, 0.16)
const VERDE_GOT_CLARO := Color(0.72, 0.8, 0.28)
const VERDE_GOT_OSC := Color(0.2, 0.24, 0.06)

func _bola_got(r: int, claro := false) -> ImageTexture:
	var c := VERDE_GOT_CLARO if claro else VERDE_GOT
	return _tex_bola(r, c, c.darkened(0.4), Color(0.06, 0.07, 0.02, 0.95), c.lightened(0.35))

func _preparar_gota() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# cuerpo vivo: se mece como gelatina, luz arriba/sombra abajo, orilla iluminada y un brillo que lo recorre
	call_deferred("_mat_gota")
	# burbujas DENTRO del cuerpo: hijas del sprite recortadas a su silueta
	sprite.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var dentro := Timer.new()
	dentro.wait_time = 0.18
	dentro.autostart = true
	add_child(dentro)
	dentro.timeout.connect(func():
		if not vivo or sprite.animation == "pulir" or randf() < 0.3:
			return
		_burbuja_dentro_got())
	# piso mojado: aro oscuro de humedad alrededor de la base
	var moj := Polygon2D.new()
	var pm := PackedVector2Array()
	for i in 20:
		var r := 1.0 + 0.1 * sin(i * 1.7)
		pm.append(Vector2(cos(TAU * i / 20.0) * 28.0 * r, sin(TAU * i / 20.0) * 7.0 * r).round())
	moj.polygon = pm
	moj.color = Color(0.02, 0.04, 0.0, 0.35)
	moj.z_index = -1
	add_child(moj)
	set_meta("mojado_got", moj)
	# sombra de contacto: se achica cuando salta
	var sombra := Node2D.new()
	sombra.z_index = -1
	add_child(sombra)
	for capa in 2:
		var o := Polygon2D.new()
		var pts := PackedVector2Array()
		var rx := 18.0 if capa == 0 else 12.0
		var ry := 4.0 if capa == 0 else 2.5
		for i in 20:
			pts.append(Vector2(cos(TAU * i / 20.0) * rx, sin(TAU * i / 20.0) * ry).round())
		o.polygon = pts
		o.color = Color(0.01, 0.02, 0.0, 0.45 if capa == 0 else 0.7)
		sombra.add_child(o)
	set_meta("sombra_got", sombra)
	# aura ácida: chispitas y vapor que se desprenden de la orilla del cuerpo y suben
	var aura := Timer.new()
	aura.wait_time = 0.06
	aura.autostart = true
	add_child(aura)
	aura.timeout.connect(func():
		if not vivo or sprite.animation == "pulir":
			return
		var ang := randf_range(PI * 0.95, PI * 2.05)   # mitad de arriba y lados
		var lado := cos(ang)
		if absf(lado) < 0.35 and randf() < 0.7:
			return   # casi nada justo encima de la cara
		var orilla := position + Vector2(lado * 17.0, sprite.position.y - 13.0 + sin(ang) * 14.0)
		_chispa_aura_got(orilla, lado))
	# charquito propio bajo el cuerpo: pixel art que ondula cambiando de forma
	var base := Sprite2D.new()
	base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base.z_index = -1
	base.position = Vector2(0, 1)
	base.texture = _tex_charco_pix(19, 0)
	add_child(base)
	var semilla := [0]
	var ola := Timer.new()
	ola.wait_time = 0.22
	ola.autostart = true
	base.add_child(ola)
	ola.timeout.connect(func():
		semilla[0] = (semilla[0] + 1) % 4
		base.texture = _tex_charco_pix(19 + (semilla[0] % 2), semilla[0]))
	set_meta("base_got", base)
	# vida: burbujas que suben del cuerpo, vapor tóxico y brillitos ácidos
	var vida := Timer.new()
	vida.wait_time = 0.14
	vida.autostart = true
	add_child(vida)
	vida.timeout.connect(func():
		if not vivo or sprite.animation == "pulir":
			return
		var cuerpo := position + Vector2(randf_range(-10, 10), sprite.position.y - randf_range(6, 18))
		if randf() < 0.45:
			# salen por las orillas y la punta, no encima de la cara
			var lado := -1.0 if randf() < 0.6 else 1.0
			_burbuja_got(position + Vector2(lado * randf_range(12, 17), sprite.position.y - randf_range(10, 22)))
		if randf() < 0.06:
			var v := _fx_pol("fx_got_vapor", cuerpo + Vector2(0, -8), 8.0, randf() < 0.5, false, 0)
			v.modulate = Color(0.75, 0.8, 0.6, 0.75)
		if randf() < 0.1:
			_brillo_got(cuerpo))
	# rastro de ácido: manchas en el piso por donde pasa, ondas y goteo
	var rastro := Timer.new()
	rastro.wait_time = 0.07
	rastro.autostart = true
	add_child(rastro)
	var ultimo := [position]
	rastro.timeout.connect(func():
		if not vivo:
			return
		var aire := sprite.animation == "mover" and sprite.frame >= 8 and sprite.frame <= 13
		if not aire and position.distance_to(ultimo[0]) > 3.0:
			_mancha_rastro(position + Vector2(randf_range(-3, 3), randf_range(-1, 1)), randf_range(0.8, 1.2))
			ultimo[0] = position
		if aire and randf() < 0.5:
			# gotea mientras vuela
			_gotita_got(position + Vector2(randf_range(-6, 6), sprite.position.y - 4.0), position + Vector2(randf_range(-6, 6), 0), 0.0, 22, randf() < 0.3)
		if not aire and randf() < 0.12:
			_onda_got(position, 0.7)
		if not aire and randf() < 0.3:
			# goteo constante: escurre por los lados y cae al piso
			var lado := -1.0 if randf() < 0.5 else 1.0
			var de := position + Vector2(lado * randf_range(9, 14), sprite.position.y - randf_range(4, 10))
			_gotita_got(de, Vector2(de.x + lado * 2.0, position.y + randf_range(-1, 1)), 0.0, 22)
		if not aire and randf() < 0.18:
			_salpica_borde_got())
	var vig := Timer.new()
	vig.wait_time = 0.15
	vig.autostart = true
	add_child(vig)
	vig.timeout.connect(func():
		set_meta("dano_rastro", get_meta("dano_rastro", 0.0) - 0.15)
		_vigilar_rastro()
		# brillo que corre por la superficie del cuerpo (le da volumen)
		if vivo and randf() < 0.25:
			var lado := -1.0 if sprite.flip_h else 1.0
			_brillo_got(position + Vector2(lado * randf_range(2, 10), sprite.position.y - randf_range(18, 26))))
	# salto: despega (cuadro 7), en el aire (8-13), cae (14)
	sprite.frame_changed.connect(func():
		var f := sprite.frame
		if sprite.animation == "pulir":
			_explosion_cuadro(f)
			return
		if not vivo:
			return
		if has_meta("sombra_got"):
			var so: Node2D = get_meta("sombra_got")
			var aire := sprite.animation == "mover" and f >= 8 and f <= 13
			so.scale = Vector2.ONE * (0.6 if aire else 1.0)
			so.modulate.a = 0.6 if aire else 1.0
		if has_meta("base_got"):
			var bg: Node2D = get_meta("base_got")
			var en_aire := sprite.animation == "mover" and f >= 8 and f <= 13
			if en_aire and bg.visible:
				_mancha_rastro(position, 1.6)   # se despega: el charco se queda en el piso
			bg.visible = not en_aire and sprite.animation != "pulir"
		if sprite.animation == "mover":
			if f == 7:
				for k in 4:
					_gotita_got(position + Vector2(randf_range(-8, 8), -4), position + Vector2(randf_range(-18, 18), randf_range(-2, 3)), randf_range(4, 10))
			elif f == 14:
				_fx_pol("fx_got_salpica", position + Vector2(0, -6), 16.0, randf() < 0.5, false, 0)
				for k in 3:
					_mancha_rastro(position + Vector2(randf_range(-8, 8), randf_range(-2, 2)), randf_range(1.2, 1.7))
				_onda_got(position, 1.3)
				_onda_got(position, 0.9)
				_polvo5_can(position, false, 5, 0.7)
				_polvo5_can(position, true, 5, 0.7)
				for k in 5:
					_gotita_got(position + Vector2(0, -4), position + Vector2(randf_range(-26, 26), randf_range(-3, 4)), randf_range(6, 14))
				main.sacudir(0.5)
				Juego.sonido("golpe", true, -20.0)
		elif sprite.animation == "pulir":
			_explosion_cuadro(f))

# Textura de burbuja ácida: aro claro con contorno oscuro, centro translúcido y brillo.
static func _tex_burbuja_got(r: int) -> ImageTexture:
	var clave := "g%d" % r
	if _tex_nub.has(clave):
		return _tex_nub[clave]
	var n := r * 2 + 3
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= r - 0.5:
				var abajo := (y + 0.5) > c.y + r * 0.2
				img.set_pixel(x, y, Color(0.3, 0.38, 0.08, 0.55) if abajo else Color(0.45, 0.54, 0.14, 0.45))
			elif d <= r + 0.5:
				img.set_pixel(x, y, Color(0.66, 0.76, 0.26))
			elif d <= r + 1.5:
				img.set_pixel(x, y, Color(0.06, 0.08, 0.02))
	if r >= 2:
		img.set_pixel(int(c.x - r * 0.45), int(c.y - r * 0.45), Color(0.92, 0.96, 0.7))
		if r >= 3:
			img.set_pixel(int(c.x - r * 0.45) + 1, int(c.y - r * 0.45), Color(0.8, 0.88, 0.5))
	var t := ImageTexture.create_from_image(img)
	_tex_nub[clave] = t
	return t

# Burbuja que sube del cuerpo: crece, se bambolea, tiembla y revienta.
func _burbuja_got(p: Vector2) -> void:
	var max_r := randi_range(2, 4)
	var s := _sprite_forma(_tex_burbuja_got(1), p, 22)
	var ini := p.round()
	var sube := randf_range(8, 18)
	var dur := randf_range(0.6, 1.0)
	var fase := randf() * TAU
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			var r := 1 + int(round(minf(k * 1.6, 1.0) * (max_r - 1)))
			s.texture = _tex_burbuja_got(r)
			var temb := (1.0 if int(k * 30.0) % 2 == 0 else -1.0) if k > 0.8 else 0.0
			s.position = (ini + Vector2(sin(fase + k * 8.0) * 1.5 + temb, -sube * k)).round(), 0.0, 1.0, dur)
	t.tween_callback(func():
		if is_instance_valid(s):
			_revienta_burbuja_got(s.position, max_r)
			s.queue_free())

# Reventón: aro que se abre, gotitas en anillo, brillito y un poco de vapor.
func _revienta_burbuja_got(p: Vector2, r: int) -> void:
	var aro := Line2D.new()
	aro.width = 1.0
	aro.default_color = Color(0.72, 0.82, 0.3)
	aro.antialiased = false
	aro.z_index = 22
	aro.position = p.round()
	main.mundo.add_child(aro)
	var ta := aro.create_tween()
	ta.tween_method(func(k: float):
		if is_instance_valid(aro):
			var pts := PackedVector2Array()
			var rr := r + 1.0 + k * (r + 4.0)
			for i in 13:
				if i % 3 == 2:
					continue
				pts.append(Vector2(cos(TAU * i / 12.0) * rr, sin(TAU * i / 12.0) * rr).round())
			aro.points = pts
			aro.modulate.a = 1.0 - k, 0.0, 1.0, 0.18)
	ta.tween_callback(aro.queue_free)
	for k in 3 + r:
		var ang := TAU * k / (3.0 + r) + randf_range(-0.3, 0.3)
		var e := _sprite_forma(_bola_got(1, randf() < 0.4), p, 22)
		var fin := p + Vector2(cos(ang), sin(ang)) * randf_range(4, 8 + r * 2)
		var te := e.create_tween()
		te.tween_property(e, "position", fin.round(), 0.18).set_ease(Tween.EASE_OUT)
		te.tween_property(e, "position:y", fin.y + randf_range(3, 7), 0.2).set_ease(Tween.EASE_IN)
		te.parallel().tween_property(e, "modulate:a", 0.0, 0.2)
		te.tween_callback(e.queue_free)
	_brillo_got(p)
	if r >= 3:
		var v := _fx_pol("fx_got_vapor", p + Vector2(0, -6), 10.0, randf() < 0.5, false, 0)
		v.modulate = Color(0.7, 0.78, 0.55, 0.6)
		v.scale = Vector2.ONE * 0.6

# Brillito ácido: bolita clara que parpadea y se apaga.
func _brillo_got(p: Vector2) -> void:
	var s := _sprite_forma(_bola_got(1, true), p, 22)
	var t := s.create_tween()
	t.tween_interval(0.07)
	t.tween_callback(func(): s.visible = false)
	t.tween_interval(0.05)
	t.tween_callback(func(): s.visible = true)
	t.tween_property(s, "modulate:a", 0.0, 0.2)
	t.tween_callback(s.queue_free)

# Gotita de ácido que salta en arco con su sombrita y salpica al caer.
func _gotita_got(desde: Vector2, hasta: Vector2, alt: float, z := 22, charco := false) -> void:
	var s := _sprite_forma(_bola_got(randi_range(1, 2), randf() < 0.3), desde, z)
	var so := _sprite_forma(_tex_bola(1, Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.4), Color(0, 0, 0, 0), Color(0, 0, 0, 0.4)), hasta, -1)
	var dur := randf_range(0.3, 0.5)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s) and is_instance_valid(so):
			var b := desde.lerp(hasta, k)
			s.position = (b + Vector2(0, -sin(k * PI) * alt)).round()
			so.position = Vector2(b.x, lerpf(hasta.y, hasta.y, k)).round(), 0.0, 1.0, dur)
	t.tween_callback(func():
		if is_instance_valid(so):
			so.queue_free()
		if is_instance_valid(s):
			var sp := _fx_pol("fx_got_salpica", s.position + Vector2(0, -4), 18.0, randf() < 0.5, false, 0)
			sp.scale = Vector2.ONE * 0.45
			if charco:
				_mancha_rastro(s.position, 0.7)
			s.queue_free())

# Charco ácido: aparece, burbujea, hiere a Diana si lo pisa y se seca.
func _charco_got(p: Vector2, grande: bool, tam := 1.0) -> void:
	var esc := (1.9 if grande else 1.0) * tam
	var ch := Sprite2D.new()
	ch.texture = Fx.cuadro("fx_got_charco", 1)
	ch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ch.scale = Vector2.ONE * esc
	ch.position = (p + Vector2(0, -2)).round()
	ch.z_index = -1
	main.mundo.add_child(ch)
	var dura := (4.5 if grande else 2.6) * (0.7 + 0.3 * tam)
	var radio_d := 20.0 * esc
	var t_vivo := [0.0, 0.0]   # tiempo y enfriamiento del daño
	var tic := Timer.new()
	tic.wait_time = 0.12
	tic.autostart = true
	ch.add_child(tic)
	tic.timeout.connect(func():
		t_vivo[0] += 0.12
		t_vivo[1] -= 0.12
		if t_vivo[0] < dura - 0.6:
			ch.texture = Fx.cuadro("fx_got_charco", 1 + int(t_vivo[0] * 4.0) % 3)
		if randf() < 0.5 * esc:
			_burbuja_charco_got(ch.position + Vector2(randf_range(-14, 14) * esc, randf_range(-2, 2)))
		if randf() < 0.12 * esc:
			var v := _fx_pol("fx_got_vapor", ch.position + Vector2(randf_range(-10, 10) * esc, -8), 8.0, randf() < 0.5, false, 0)
			v.modulate = Color(0.7, 0.78, 0.55, 0.6)
		if randf() < 0.15:
			_brillo_got(ch.position + Vector2(randf_range(-14, 14) * esc, randf_range(-2, 1)))
		if is_instance_valid(objetivo) and t_vivo[1] <= 0.0 and t_vivo[0] < dura - 0.5:
			var d := objetivo.position - ch.position
			if (d.x * d.x) / (radio_d * radio_d) + (d.y * d.y) / (radio_d * radio_d * 0.16) <= 1.0:
				t_vivo[1] = 0.9
				objetivo.herir(1, d))
	var t := ch.create_tween()
	t.tween_interval(dura - 0.5)
	t.tween_callback(func(): ch.texture = Fx.cuadro("fx_got_charco", 4))
	t.tween_interval(0.25)
	t.tween_callback(func(): ch.texture = Fx.cuadro("fx_got_charco", 5))
	t.tween_property(ch, "modulate:a", 0.0, 0.25)
	t.tween_callback(ch.queue_free)

# Burbuja en el charco: crece pegada a la superficie, tiembla y revienta.
func _burbuja_charco_got(p: Vector2) -> void:
	var max_r := randi_range(2, 4)
	var s := _sprite_forma(_tex_burbuja_got(1), p, 0)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			var r := 1 + int(round(k * (max_r - 1)))
			s.texture = _tex_burbuja_got(r)
			var temb := (1.0 if int(k * 30.0) % 2 == 0 else -1.0) if k > 0.75 else 0.0
			s.position = (p + Vector2(temb, -r)).round(), 0.0, 1.0, randf_range(0.5, 0.9))
	t.tween_callback(func():
		if is_instance_valid(s):
			_revienta_burbuja_got(s.position, max_r)
			s.queue_free())

# Golpe recibido: destello, gotas que salen volando hacia atrás y salpicadura.
func _golpe_gota(desde: Vector2, critico: bool) -> void:
	var lado := signf(desde.x) if absf(desde.x) > 0.01 else 1.0
	var centro := position + Vector2(-lado * 4.0, sprite.position.y - 18.0)
	_destello_can(0.7 if critico else 0.5)
	var sp := _fx_pol("fx_got_salpica", centro, 18.0, lado < 0.0, false, 22)
	sp.scale = Vector2.ONE * 0.8
	for k in (8 if critico else 5):
		_gotita_got(centro + Vector2(randf_range(-4, 4), randf_range(-4, 4)), position + Vector2(-lado * randf_range(10, 34), randf_range(-4, 5)), randf_range(8, 18), 22, k == 0)
	for k in 3:
		_brillo_got(centro + Vector2(randf_range(-8, 8), randf_range(-8, 8)))
	_polvo5_can(position, lado > 0.0, 5, 0.6)

# Explosión (ataque y derrota): tiembla agrietada, revienta en gotas que hieren y deja un charco grande.
func _explosion_cuadro(f: int) -> void:
	if has_meta("en_tina"):
		return
	if f <= 2 and mat:
		mat.set_shader_parameter("volumen", 0.0)   # el charco final no se oscurece
		mat.set_shader_parameter("ondula", 0.0)
		mat.set_shader_parameter("vena", 0.0)
	if f >= 3 and f <= 7:
		sacudon = 2.0
		if f % 2 == 1:
			_brillo_got(position + Vector2(randf_range(-10, 10), sprite.position.y - randf_range(6, 18)))
			_burbuja_got(position + Vector2(randf_range(-12, 12), sprite.position.y - randf_range(10, 24)))
		if f == 3:
			Juego.sonido("disparo_enemigo", true, -14.0)
	if f == 8 and not has_meta("estallo"):
		set_meta("estallo", true)
		# su charquito, piso mojado y sombra se van: solo queda el charco pintado en el piso
		for k in ["base_got", "mojado_got", "sombra_got"]:
			if has_meta(k) and is_instance_valid(get_meta(k)):
				var n: CanvasItem = get_meta(k)
				n.visible = false
		var c := position + Vector2(0, -12)
		_destello_can(1.0)
		main.pausa_impacto(0.06)
		main.sacudir(3.0)
		Juego.sonido("golpe", false, -4.0)
		var sp := _fx_pol("fx_got_salpica", c, 16.0, false, false, 22)
		sp.scale = Vector2.ONE * 1.8
		var sp2 := _fx_pol("fx_got_salpica", c + Vector2(0, 4), 14.0, true, false, 22)
		sp2.scale = Vector2(2.4, 1.2)
		for k in 16:
			var ang := TAU * k / 16.0 + randf_range(-0.15, 0.15)
			var fin := position + Vector2(cos(ang), sin(ang) * 0.45) * randf_range(26, 58)
			_gotita_got(c, fin, randf_range(14, 30), 22, k % 3 == 0)
		for k in 6:
			var v := _fx_pol("fx_got_vapor", c + Vector2(randf_range(-20, 20), randf_range(-8, 4)), 9.0, randf() < 0.5, false, 0)
			v.modulate = Color(0.7, 0.78, 0.55, 0.8)
		_polvo5_can(position, false, 10)
		_polvo5_can(position, true, 10)
		for k in 12:
			var a2 := TAU * k / 12.0
			_mancha_rastro(position + Vector2(cos(a2) * randf_range(4, 24), sin(a2) * randf_range(2, 7)), randf_range(1.3, 2.0))
		for k in 3:
			_onda_got(position, 1.0 + k * 0.5)
		# hiere a Diana si está cerca de la explosión
		if is_instance_valid(objetivo) and objetivo.position.distance_to(position) < 48.0:
			objetivo.herir(1, objetivo.position - position)
	if f >= 12 and f % 3 == 0:
		_brillo_got(position + Vector2(randf_range(-24, 24), randf_range(-4, 0)))
	if f == 12 and not has_meta("charco_fuera"):
		# el charco dibujado del sprite (oscuro) se desvanece: queda el charco de pixel vivo
		set_meta("charco_fuera", true)
		create_tween().tween_property(sprite, "modulate:a", 0.0, 0.3)

# Al terminar: el charco que dejó se queda burbujeando un momento y se seca.
func _deshacer_gota() -> void:
	get_tree().create_timer(4.0).timeout.connect(func(): if is_instance_valid(self): _borrar_rastro())
	if has_meta("sombra_got"):
		get_meta("sombra_got").visible = false
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tw.tween_interval(3.5)
	tw.tween_callback(queue_free)

# Humo tóxico de pixel: bolitas verde oscuro que suben ondulando y se deshacen.
func _humo_rastro(p: Vector2) -> void:
	var c := Color(0.28, 0.34, 0.12, 0.85) if randf() < 0.6 else Color(0.36, 0.42, 0.16, 0.8)
	var r := randi_range(1, 2)
	var s := _sprite_forma(_tex_bola(r, c, c.darkened(0.3), Color(0.05, 0.06, 0.02, 0.6), c.lightened(0.2)), p, 0)
	var ini := p.round()
	var sube := randf_range(10, 22)
	var fase := randf() * TAU
	var dur := randf_range(0.9, 1.4)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			s.position = (ini + Vector2(sin(fase + k * 5.0) * 3.0, -sube * k)).round()
			if k > 0.5 and r > 1:
				s.texture = _tex_bola(1, c, c.darkened(0.3), Color(0.05, 0.06, 0.02, 0.6), c.lightened(0.2)), 0.0, 1.0, dur)
	t.parallel().tween_property(s, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
	t.tween_callback(s.queue_free)

# Onda que se abre en el líquido alrededor de su base.
func _onda_got(p: Vector2, tam: float) -> void:
	var onda := Line2D.new()
	onda.width = 1.0
	onda.default_color = Color(0.72, 0.8, 0.3, 0.9)
	onda.antialiased = false
	onda.z_index = -1
	onda.position = p.round()
	main.mundo.add_child(onda)
	var t := onda.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(onda):
			var pts := PackedVector2Array()
			var rx := (8.0 + k * 18.0) * tam
			for i in 17:
				pts.append(Vector2(cos(TAU * i / 16.0) * rx, sin(TAU * i / 16.0) * rx * 0.3).round())
			onda.points = pts
			onda.modulate.a = 1.0 - k, 0.0, 1.0, 0.55)
	t.tween_callback(onda.queue_free)

# Salpicadura chica en la orilla del charco de su base (el líquido se mueve).
func _salpica_borde_got() -> void:
	var lado := -1.0 if randf() < 0.5 else 1.0
	var p := position + Vector2(lado * randf_range(10, 16), randf_range(-1, 1))
	for k in 2:
		_gotita_got(p, p + Vector2(lado * randf_range(3, 9), randf_range(-1, 2)), randf_range(3, 7), 0)

# ---- Rastro de ácido: un solo lienzo de pixel donde se pinta el charco continuo ----
const LIENZO_GOT := 768
func _lienzo_got() -> Dictionary:
	if has_meta("lienzo_got"):
		return get_meta("lienzo_got")
	var img := Image.create(LIENZO_GOT, LIENZO_GOT, false, Image.FORMAT_RGBA8)
	var masc := PackedByteArray()
	masc.resize(LIENZO_GOT * LIENZO_GOT)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = -1
	var origen := (position - Vector2(LIENZO_GOT, LIENZO_GOT) * 0.5).round()
	spr.position = origen
	spr.texture = ImageTexture.create_from_image(img)
	main.mundo.add_child(spr)
	var l := {"img": img, "masc": masc, "spr": spr, "origen": origen, "puntos": []}
	set_meta("lienzo_got", l)
	return l

# ¿Hay ácido en este punto del mundo?
func _hay_acido(p: Vector2) -> bool:
	if not has_meta("lienzo_got"):
		return false
	var l: Dictionary = get_meta("lienzo_got")
	var q: Vector2 = (p - l.origen).round()
	if q.x < 0 or q.y < 0 or q.x >= LIENZO_GOT or q.y >= LIENZO_GOT:
		return false
	var m: PackedByteArray = l.masc
	return m[int(q.y) * LIENZO_GOT + int(q.x)] > 0

# Pinta ácido en el lienzo (óvalo de orilla irregular) y recolorea esa zona:
# contorno oscuro donde termina, 3 tonos por dentro, puntitos de luz.
func _mancha_rastro(p: Vector2, tam: float) -> void:
	var l := _lienzo_got()
	var masc: PackedByteArray = l.masc
	var c: Vector2 = (p - l.origen).round()
	var rx := randf_range(6, 9) * tam
	var ry := rx * randf_range(0.3, 0.42)
	var bordes: Array[float] = []
	for i in 12:
		bordes.append(randf_range(0.75, 1.1))
	var x0 := int(c.x - rx - 3)
	var x1 := int(c.x + rx + 3)
	var y0 := int(c.y - ry - 3)
	var y1 := int(c.y + ry + 3)
	if x0 < 3 or y0 < 3 or x1 >= LIENZO_GOT - 3 or y1 >= LIENZO_GOT - 3:
		return
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var d := Vector2((x - c.x) / rx, (y - c.y) / ry)
			var idx := int(fposmod(atan2(d.y, d.x), TAU) / TAU * 12.0) % 12
			if d.length() <= bordes[idx]:
				masc[y * LIENZO_GOT + x] = 1
	l.masc = masc
	_recolorear_got(l, x0 - 2, y0 - 2, x1 + 2, y1 + 2)
	var pts: Array = l.puntos
	pts.append(p)
	if pts.size() > 160:
		pts.pop_front()

func _recolorear_got(l: Dictionary, x0: int, y0: int, x1: int, y1: int) -> void:
	var img: Image = l.img
	var m: PackedByteArray = l.masc
	var med := Color(0.2, 0.26, 0.05, 0.92)
	var cla := Color(0.3, 0.37, 0.08, 0.95)
	var luz := Color(0.55, 0.64, 0.2)
	var orilla := Color(0.14, 0.18, 0.04, 0.75)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var i := y * LIENZO_GOT + x
			if m[i] == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			# distancia a la orilla (0 = orilla, 1 = segunda fila, 2 = dentro)
			var d := 2
			if m[i - 1] == 0 or m[i + 1] == 0 or m[i - LIENZO_GOT] == 0 or m[i + LIENZO_GOT] == 0:
				d = 0
			elif m[i - 2] == 0 or m[i + 2] == 0 or m[i - LIENZO_GOT * 2] == 0 or m[i + LIENZO_GOT * 2] == 0:
				d = 1
			var col := med
			if d == 0:
				# orilla tramada: un pixel sí y otro no, se mezcla con el piso
				col = orilla if ((x + y) & 1) == 0 else Color(0, 0, 0, 0)
			elif d == 1:
				col = orilla if ((x + y) & 1) == 1 else med
			else:
				var h := (x * 73856093) ^ (y * 19349663)
				var r := (h >> 4) & 63
				if r < 2:
					col = luz
				elif r < 26 and ((x + y) & 3) != 0:
					col = cla
			img.set_pixel(x, y, col)
	var tex: ImageTexture = l.spr.texture
	tex.update(img)

# Cada rato: el rastro se esparce, echa humo, burbujea, brilla en la orilla y daña si Diana lo pisa.
func _vigilar_rastro() -> void:
	if not has_meta("lienzo_got"):
		return
	var l: Dictionary = get_meta("lienzo_got")
	var pts: Array = l.puntos
	if pts.is_empty():
		return
	for k in 2:
		var p: Vector2 = pts[randi() % pts.size()]
		if randf() < 0.55:
			_humo_rastro(p + Vector2(randf_range(-6, 6), -1))
		if randf() < 0.25:
			_burbuja_charco_got(p + Vector2(randf_range(-5, 5), 0))
		if randf() < 0.2:
			_brillo_got(p + Vector2(randf_range(-8, 8), randf_range(-3, 1)))
		if randf() < 0.12:
			_gotita_got(p, p + Vector2(randf_range(-8, 8), randf_range(-2, 2)), randf_range(3, 7), 0)
	# se esparce despacio: manchitas nuevas pegadas a puntos viejos
	if randf() < 0.35 and pts.size() < 160:
		var p2: Vector2 = pts[randi() % pts.size()]
		_mancha_rastro(p2 + Vector2(randf_range(-7, 7), randf_range(-2, 2)), randf_range(0.5, 0.8))
	if is_instance_valid(objetivo) and get_meta("dano_rastro", 0.0) <= 0.0:
		var op: Vector2 = objetivo.position
		if _hay_acido(op) or _hay_acido(op + Vector2(-4, 0)) or _hay_acido(op + Vector2(4, 0)):
			objetivo.herir(1, Vector2(0, -1))
			set_meta("dano_rastro", 1.0)

# Al morir: el rastro se apaga y desaparece.
func _borrar_rastro() -> void:
	if not has_meta("lienzo_got"):
		return
	var l: Dictionary = get_meta("lienzo_got")
	var pts: Array = l.puntos
	for k in mini(10, pts.size()):
		_humo_rastro(pts[randi() % pts.size()])
	var spr: Sprite2D = l.spr
	var tw := spr.create_tween()
	tw.tween_property(spr, "modulate", Color(0.55, 0.55, 0.45, 0.6), 0.5)
	tw.tween_property(spr, "modulate:a", 0.0, 0.9)
	tw.tween_callback(spr.queue_free)
	remove_meta("lienzo_got")

# Contorno de luz ácida: copias del sprite en verde plano 1 px detrás.
func _borde_got() -> void:
	var sh := Shader.new()
	sh.code = "shader_type canvas_item; uniform vec4 tinte : source_color; void fragment(){ COLOR = vec4(tinte.rgb, texture(TEXTURE, UV).a * tinte.a); }"
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("tinte", Color(0.45, 0.55, 0.12, 0.85))
	var copias: Array = []
	for off in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]:
		var cp := AnimatedSprite2D.new()
		cp.sprite_frames = sprite.sprite_frames
		cp.material = mat
		cp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cp.show_behind_parent = true
		cp.z_index = -1
		cp.set_meta("off", off)
		add_child(cp)
		copias.append(cp)
	set_meta("borde_got", copias)

func _sync_borde_got() -> void:
	for cp in get_meta("borde_got", []):
		if not is_instance_valid(cp):
			continue
		cp.animation = sprite.animation
		cp.frame = sprite.frame
		cp.flip_h = sprite.flip_h
		cp.scale = sprite.scale
		cp.offset = sprite.offset
		cp.position = sprite.position + cp.get_meta("off")
		cp.visible = sprite.visible and sprite.animation != "pulir"
		cp.modulate.a = sprite.modulate.a

# Cae en la piscina: no explota; su ácido se diluye (rastro, borde, sombra y charquito se van).
func _tina_gota() -> void:
	set_meta("en_tina", true)
	_borrar_rastro()
	for k in ["sombra_got", "base_got", "mojado_got"]:
		if has_meta(k) and is_instance_valid(get_meta(k)):
			var n: Node2D = get_meta(k)
			n.create_tween().tween_property(n, "modulate:a", 0.0, 0.4)
	for cp in get_meta("borde_got", []):
		if is_instance_valid(cp):
			cp.queue_free()
	set_meta("borde_got", [])
	for k in 6:
		_burbuja_got(position + Vector2(randf_range(-12, 12), randf_range(-8, 0)))

# Chispa del aura: destellito verde de pixel que se suelta de la orilla, sube ondulando,
# parpadea y se apaga (detrás del cuerpo si sale por arriba, para no tapar la cara).
func _chispa_aura_got(p: Vector2, lado: float) -> void:
	var tipo_c := randf()
	var tex: Texture2D
	if tipo_c < 0.45:
		tex = _bola_got(1, randf() < 0.5)
	elif tipo_c < 0.75:
		tex = _tex_destello_got(randf() < 0.3)
	else:
		var c := Color(0.28, 0.34, 0.12, 0.8)
		tex = _tex_bola(1, c, c.darkened(0.3), Color(0.05, 0.06, 0.02, 0.5), c.lightened(0.2))
	var s := _sprite_forma(tex, p, 22 if absf(lado) > 0.5 else 0)
	var ini := p.round()
	var dx := lado * randf_range(3, 9)
	var sube := randf_range(8, 18)
	var fase := randf() * TAU
	var dur := randf_range(0.5, 0.9)
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			s.position = (ini + Vector2(dx * k + sin(fase + k * 7.0), -sube * k)).round()
			s.visible = k < 0.6 or int(k * 22.0) % 2 == 0, 0.0, 1.0, dur)
	t.tween_callback(s.queue_free)

# Destello en cruz verde ácido.
static func _tex_destello_got(grande: bool) -> ImageTexture:
	var clave := "dg%s" % grande
	if _tex_nub.has(clave):
		return _tex_nub[clave]
	var n := 5 if grande else 3
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var m := n / 2
	for i in n:
		var lejos := absi(i - m)
		var col := Color(0.86, 0.94, 0.5) if lejos == 0 else (Color(0.62, 0.72, 0.22) if lejos == 1 else Color(0.34, 0.42, 0.1))
		img.set_pixel(i, m, col)
		img.set_pixel(m, i, col)
	var t := ImageTexture.create_from_image(img)
	_tex_nub[clave] = t
	return t

# Burbuja que sube por DENTRO del cuerpo (se ve a través del ácido, recortada a la silueta).
func _burbuja_dentro_got() -> void:
	var inv := 1.0 / maxf(0.01, escala_actual)
	var lado := -1.0 if sprite.flip_h else 1.0
	# por la mitad trasera del cuerpo, lejos de la cara
	var x := -lado * randf_range(2, 13)
	var y0 := randf_range(-5, -2)
	var s := Sprite2D.new()
	s.texture = _tex_burbuja_got(randi_range(1, 2))
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * inv
	s.modulate = Color(1, 1, 1, 0.75)
	sprite.add_child(s)
	var sube := randf_range(10, 20)
	var dur := randf_range(0.9, 1.5)
	var fase := randf() * TAU
	var t := s.create_tween()
	t.tween_method(func(k: float):
		if is_instance_valid(s):
			var w := Vector2(x + sin(fase + k * 6.0) * 1.0, y0 - sube * k).round()
			s.position = w * inv, 0.0, 1.0, dur)
	t.tween_callback(s.queue_free)

func _mat_gota() -> void:
	if mat:
		mat.set_shader_parameter("ondula", 1.0)
		mat.set_shader_parameter("vena", 1.0)
		mat.set_shader_parameter("volumen", 0.35)
		mat.set_shader_parameter("reflejo", 0.12)

# Charco de pixel: orilla irregular con contorno oscuro, 3 tonos, orilla de arriba brillante y puntos de luz.
static func _tex_charco_pix(rx: int, semilla: int) -> ImageTexture:
	var clave := "cp%d_%d" % [rx, semilla]
	if _tex_nub.has(clave):
		return _tex_nub[clave]
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla + 77
	var ry := maxi(3, int(rx * 0.3))
	var w := rx * 2 + 5
	var h := ry * 2 + 5
	var bordes: Array[float] = []
	for i in 14:
		bordes.append(rng.randf_range(0.82, 1.06))
	var m := PackedByteArray()
	m.resize(w * h)
	for y in h:
		for x in w:
			var d := Vector2((x + 0.5 - w / 2.0) / rx, (y + 0.5 - h / 2.0) / ry)
			var idx := int(fposmod(atan2(d.y, d.x), TAU) / TAU * 14.0) % 14
			if d.length() <= bordes[idx]:
				m[y * w + x] = 1
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(2, h - 2):
		for x in range(2, w - 2):
			var i := y * w + x
			if m[i] == 0:
				continue
			var d := 2
			if m[i - 1] == 0 or m[i + 1] == 0 or m[i - w] == 0 or m[i + w] == 0:
				d = 0
			elif m[i - 2] == 0 or m[i + 2] == 0 or m[i - w * 2] == 0 or m[i + w * 2] == 0:
				d = 1
			var col := Color(0.2, 0.26, 0.05, 0.92)
			if d == 0:
				col = Color(0.14, 0.18, 0.04, 0.75) if ((x + y) & 1) == 0 else Color(0, 0, 0, 0)
			elif d == 1:
				col = Color(0.14, 0.18, 0.04, 0.75) if ((x + y) & 1) == 1 else Color(0.2, 0.26, 0.05, 0.92)
			elif rng.randf() < 0.04:
				col = Color(0.55, 0.64, 0.2)
			elif ((x + y) & 3) != 0 and y < h / 2:
				col = Color(0.3, 0.37, 0.08, 0.95)
			img.set_pixel(x, y, col)
	var t := ImageTexture.create_from_image(img)
	_tex_nub[clave] = t
	return t

# ---- Cuarzo: dispara su cristal, se hunde como topo y sale cerca de Diana ----
var cd_hundir_cua := 2.0
var esquivar_cua := false
var off_cua := Vector2.ZERO
var surco_cua := Vector2.INF
var tierra_t_cua := 0.0
var ult_obj_cua := Vector2.INF
var vel_obj_cua := Vector2.ZERO
const CRISTAL_CUA := Vector2(-0.4, -31.9)   # dónde está el cristal que sale disparado (respecto al pie)

func _preparar_cuarzo() -> void:
	_precalentar_cua()
	var tm := Timer.new()
	tm.wait_time = 0.07
	tm.autostart = true
	tm.timeout.connect(_mota_cua)
	add_child(tm)
	set_meta("sombra_cua", Fx.sombra(self, radio * 2.0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_mat_cua")
	sprite.frame_changed.connect(_cuadro_cua)

func _cuadro_cua() -> void:
	var f := sprite.frame
	match sprite.animation:
		"ataque":
			if f >= 3 and f <= 8 and randf() < 0.5:
				_pieza_cua(position + Vector2(randf_range(-22, 22), -2), randi_range(7, 11), Vector2(randf_range(-20, 20), randf_range(-55, -30)), 0.3, 0.5)
			if f >= 3 and f <= 8 and randf() < 0.6:
				_rafaga_motas_cua(position + CRISTAL_CUA + Vector2(0, 4), 1, 6.0)
			if f == 9:
				for i in 4:
					_pieza_cua(position + CRISTAL_CUA + Vector2(randf_range(-4, 4), 8), randi_range(7, 11), Vector2(randf_range(-40, 40), randf_range(-70, -30)), 0.25, 0.5)
			if f == 12 and vivo:
				_lanzar_cristal_cua()
		"hunde":
			if f == 4:
				_grietas_cua()
				_anillo_cua(main.mundo, position, 12.0, Color(0.45, 0.35, 0.28, 0.7), 0.45)
				main.sacudir(2.0)
				onda_piso(position, 26.0, Color(0.25, 0.2, 0.16, 0.6), 0.4)
				_terrones_cua(10, 1.0)
			elif f in [7, 9, 11, 13]:
				_terrones_cua(4, 0.7)
				_polvo_cua(position + Vector2(randf_range(-20, 20), 0))
			elif f >= 16:
				_terrones_cua(2, 0.3)
		"sale":
			if f in [1, 3, 5]:
				_terrones_cua(4, 0.8)
			if f == 7:
				_grietas_cua()
				_anillo_cua(main.mundo, position, 14.0, Color(0.65, 0.4, 0.95, 0.7), 0.5)
				_rafaga_motas_cua(position + Vector2(0, -16), 10, 24.0)
				main.sacudir(2.5)
				onda_piso(position, 30.0, Color(0.25, 0.2, 0.16, 0.6), 0.4)
				_terrones_cua(12, 1.2)
				_polvo_cua(position + Vector2(-14, 0))
				_polvo_cua(position + Vector2(14, 0))
		"mover":
			if randf() < 0.35:
				_anim_fx_cua(main.mundo, position + Vector2(randf_range(-26, 26), randf_range(-38, -16)), _cuadros_cua(17, 3), 12.0, 0.3)
		"viaja":
			# la tierra sube y baja al empujar desde abajo (pixeles enteros)
			aplastar = Vector2(1.0, 0.9 if f % 2 == 0 else 1.08)
		"pulir":
			if f == 1:
				mat.set_shader_parameter("destello", 0.5)
				create_tween().tween_method(func(v): mat.set_shader_parameter("destello", v), 0.5, 0.0, 0.3)
			if f == 6 or f == 11:
				_rafaga_motas_cua(position + Vector2(0, -20), 12, 26.0)
				_anillo_cua(main.mundo, position, 16.0, Color(0.7, 0.4, 1.0, 0.8), 0.5)
				for i in 10:
					_pieza_cua(position + Vector2(randf_range(-24, 24), randf_range(-34, -12)), randi_range(1, 6), Vector2(randf_range(-60, 60), randf_range(-80, -20)), 0.3, 0.7)
				_polvo_cua(position + Vector2(randf_range(-16, 16), -10))
				main.sacudir(1.5)
			if f == 16:
				for i in 3:
					_polvo_cua(position + Vector2(randf_range(-20, 20), -2))

func _mat_cua() -> void:
	if mat:
		mat.set_shader_parameter("vena", 0.0)
		mat.set_shader_parameter("color_vena", Vector3(0.16, 0.08, 0.22))
		mat.set_shader_parameter("volumen", 0.25)
		mat.set_shader_parameter("realce", 1.7)   # tierra y roca muy oscuras: que no se pierdan en la penumbra

# ¿Se le puede pegar? Bajo tierra no.
func _cua_golpeable() -> bool:
	if estado == "bajo":
		return false
	if estado == "hunde" and sprite.frame >= 11:
		return false
	if estado == "sale" and sprite.frame < 5:
		return false
	return true

func _cuarzo(delta: float, hacia: Vector2) -> Vector2:
	cd_hundir_cua -= delta
	# bajo tierra va a ras del piso: todo (Diana, muebles, cosas) se dibuja encima de él
	var abajo := not _cua_golpeable() or (estado == "hunde" and sprite.frame >= 9) or (estado == "sale" and sprite.frame < 7)
	var so_c = get_meta("sombra_cua", null)
	if so_c and is_instance_valid(so_c):
		so_c.visible = not abajo   # enterrado no proyecta sombra
	if mat and vivo:
		var late := 0.0 if abajo else 0.5 + 0.25 * sin(t * 3.2)
		mat.set_shader_parameter("color_contorno", Vector3(0.62, 0.32, 0.95))
		if sprite.animation != "dano":
			mat.set_shader_parameter("contorno", late)
	z_index = -1 if not _cua_golpeable() or (estado == "hunde" and sprite.frame >= 9) or (estado == "sale" and sprite.frame < 7) else 0
	if ult_obj_cua != Vector2.INF and delta > 0.0:
		vel_obj_cua = vel_obj_cua.lerp((objetivo.position - ult_obj_cua) / delta, 0.2)
	ult_obj_cua = objetivo.position
	var dist := hacia.length()
	match estado:
		"hunde":
			if sprite.frame <= 11:
				esfuerzo = float(randi_range(-1, 1))
			if anim_t <= 0.0:
				estado = "bajo"
				estado_t = 4.0
				off_cua = Vector2.from_angle(randf() * TAU) * Vector2(1.0, 0.6) * randf_range(70.0, 100.0)
				surco_cua = position
				sprite.play("viaja")
			return Vector2.ZERO
		"bajo":
			anim_t = 0.3
			estado_t -= delta
			if sprite.animation != "viaja":
				sprite.play("viaja")
			var meta: Vector2 = objetivo.position + off_cua
			if not main.permitido(meta):
				off_cua = off_cua.rotated(0.7)
			if position.distance_to(surco_cua) > 7.0:
				_surco_cua(position)
				surco_cua = position
			var falta := meta - position
			_tierra_viaje_cua(delta, falta.normalized())
			if falta.length() < 8.0 or estado_t <= 0.0:
				estado = "sale"
				especial("sale")
				return Vector2.ZERO
			return falta.normalized()
		"sale":
			if anim_t <= 0.0:
				estado = "seguir"
				cd_ataque = 0.5
				cd_hundir_cua = randf_range(3.0, 5.0)
			return Vector2.ZERO
	if anim_t > 0.0:
		if sprite.animation == "ataque" and sprite.frame >= 3 and sprite.frame <= 8:
			esfuerzo = float(randi_range(-1, 1))
		return Vector2.ZERO
	if (dist > 250.0 or esquivar_cua) and cd_hundir_cua <= 0.0:
		esquivar_cua = false
		estado = "hunde"
		especial("hunde")
		Juego.sonido("golpe", true, -14.0)
		return Vector2.ZERO
	if cd_ataque <= 0.0 and dist < 270.0:
		cd_ataque = randf_range(2.4, 3.4)
		especial("ataque")
	return Vector2.ZERO

func _golpe_cuarzo(desde: Vector2, critico: bool) -> void:
	empuje = Vector2.ZERO   # está enterrado en el piso: no sale volando, solo tiembla
	vel = Vector2.ZERO
	sacudon = 3.0 * (1.0 if desde.x >= 0.0 else -1.0)
	for i in (6 if critico else 4):
		_pieza_cua(position + Vector2(randf_range(-18, 18), randf_range(-30, -14)), randi_range(1, 6), Vector2(desde.x * 50.0 + randf_range(-30, 30), randf_range(-70, -30)), 0.28, 0.6)
	_polvo_cua(position + Vector2(0, -12))
	if vida > 0 and randf() < 0.5:
		esquivar_cua = true   # le disparan: se mete a la tierra para esquivar

# Pedacito (astilla de cristal, piedrita o terrón) que salta en arco, cae al piso y se apaga.
func _pieza_cua(p: Vector2, idx: int, v: Vector2, esc: float, dur: float, piso_y := INF) -> void:
	if not main.permitido(Vector2(p.x + v.x * dur, position.y)):
		v.x = -v.x * 0.3
		if not main.permitido(Vector2(p.x + v.x * dur, position.y)):
			return
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture("fx", idx)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * esc
	s.position = p
	s.z_index = 2
	s.flip_h = randf() < 0.5
	main.mundo.add_child(s)
	var piso: float = (position.y if piso_y == INF else piso_y) + randf_range(-2, 6)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		var y := p.y + v.y * tt + 260.0 * tt * tt
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(y, piso))), 0.0, 1.0, dur)
	if idx >= 1 and idx <= 6:
		_deshacer_astilla_cua(s, tw, main.mundo, _cuadros_cua(17, 3))   # cristal: brilla morado y se deshace en polvo de luz
	else:
		tw.tween_property(s, "modulate:a", 0.0, 0.5).set_delay(0.6)
		tw.tween_callback(s.queue_free)

func _terrones_cua(n: int, fuerza: float) -> void:
	for i in n:
		var lado := randf_range(-1, 1)
		_pieza_cua(position + Vector2(lado * 22.0, randf_range(-6, 0)), randi_range(12, 16), Vector2(lado * 60.0 * fuerza + randf_range(-15, 15), randf_range(-90, -40) * fuerza), 0.3, 0.55)

# Surco de tierra removida que deja al viajar bajo tierra (en el piso, se va apagando).
func _surco_cua(p: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = _tex_surco_cua(randi() % 6)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = (p + Vector2(randf_range(-1, 1), randf_range(-1, 1))).round()
	s.flip_h = randf() < 0.5
	s.z_index = -2
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(s, "modulate:a", 0.0, 2.0)
	tw.tween_callback(s.queue_free)

# Mancha de tierra removida en pixel: óvalo irregular, orilla tramada que se funde con el piso,
# tonos de tierra oscura con granitos claros. Plana: sin sombra ni volumen.
static var _tex_surco: Dictionary = {}
static func _tex_surco_cua(semilla: int) -> ImageTexture:
	if _tex_surco.has(semilla):
		return _tex_surco[semilla]
	var rng := RandomNumberGenerator.new()
	rng.seed = 777 + semilla
	var w := 22
	var h := 10
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var osc := Color(0.1, 0.08, 0.06, 0.8)
	var med := Color(0.17, 0.13, 0.1, 0.75)
	var cla := Color(0.27, 0.22, 0.17, 0.75)
	for y in h:
		for x in w:
			var d := Vector2((x - w / 2.0 + 0.5) / (w / 2.0), (y - h / 2.0 + 0.5) / (h / 2.0)).length() + rng.randf_range(-0.12, 0.12)
			if d > 1.0:
				continue
			if d > 0.75 and (x + y) % 2 == 0:
				continue   # orilla tramada
			var c := med
			var r := rng.randf()
			if r < 0.22:
				c = osc
			elif r < 0.34:
				c = cla
			if d > 0.75:
				c.a *= 0.6
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_tex_surco[semilla] = t
	return t

# El cristal grande sale disparado en arco hacia donde está Diana, con sombra, estela y se rompe al caer.
func _lanzar_cristal_cua() -> void:
	var desde := position + sprite.position + CRISTAL_CUA
	var suelo0 := position
	var meta: Vector2 = objetivo.position
	var tex_c := sprite.sprite_frames.get_frame_texture("fx", 0)
	var tex_p: Array = []
	for i in range(1, 7):
		tex_p.append(sprite.sprite_frames.get_frame_texture("fx", i))
	var tex_polvo := _cuadros_cua(20, 4)
	var tex_imp := _cuadros_cua(24, 4)
	var tex_brillo := _cuadros_cua(17, 3)
	var c := Sprite2D.new()
	c.texture = tex_c
	c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	c.scale = Vector2.ONE * 0.3
	c.z_index = 3
	c.position = desde
	main.mundo.add_child(c)
	var aura := Sprite2D.new()   # halo morado de pixel detrás del cristal, late mientras vuela
	aura.texture = tex_c
	aura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	aura.scale = Vector2.ONE * 1.3
	aura.modulate = Color(0.75, 0.5, 1.0, 0.45)
	aura.show_behind_parent = true
	c.add_child(aura)
	var so := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(Vector2(cos(TAU * i / 12.0) * 5.0, sin(TAU * i / 12.0) * 2.0).round())
	so.polygon = pts
	so.color = Color(0.05, 0.03, 0.06, 0.45)
	so.z_index = -1
	so.position = suelo0
	main.mundo.add_child(so)
	var alto0 := suelo0.y - desde.y
	var dur := clampf(suelo0.distance_to(meta) / 230.0, 0.45, 1.0)
	meta += vel_obj_cua.limit_length(120.0) * dur * 0.8   # apunta adonde va Diana
	if not main.permitido(meta):
		meta = objetivo.position
	var lejos := suelo0.distance_to(meta)
	var arco := 30.0 + lejos * 0.15
	var estela := [0]
	var mundo_n = main.mundo
	var principal = main
	var obj := objetivo
	Juego.sonido("disparo_enemigo", true, -6.0)
	var tw := c.create_tween()
	tw.tween_method(func(k: float):
		var piso := suelo0.lerp(meta, k)
		var h := lerpf(alto0, 0.0, k) + sin(k * PI) * arco
		var antes := c.position
		c.position = (piso - Vector2(0, h)).round()
		var mov := c.position - antes
		if mov.length() > 0.5:
			c.rotation = snappedf(mov.angle() + PI * 0.5, PI / 8.0)   # la punta va hacia donde vuela
		aura.modulate.a = 0.3 + 0.25 * sin(k * 40.0)
		aura.scale = Vector2.ONE * (1.25 + 0.1 * sin(k * 40.0))
		so.position = piso.round()
		so.scale = Vector2.ONE * (0.7 + 0.5 * k)
		estela[0] += 1
		var atras := -mov.normalized() if mov.length() > 0.5 else Vector2.ZERO
		_polvo_cristal_cua(mundo_n, c.position + atras * 5.0 + Vector2(randf_range(-2, 2), randf_range(-2, 2)), tex_p.pick_random())
		if estela[0] % 2 == 0:
			var eco := Sprite2D.new()   # copia que se queda atrás y se apaga: estela del cristal
			eco.texture = tex_c
			eco.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			eco.scale = c.scale
			eco.rotation = c.rotation
			eco.position = c.position
			eco.modulate = Color(0.75, 0.45, 1.1, 0.5)
			eco.z_index = 2
			mundo_n.add_child(eco)
			var twe := eco.create_tween()
			twe.tween_property(eco, "modulate:a", 0.0, 0.18)
			twe.tween_callback(eco.queue_free)
		if estela[0] % 4 == 0:
			_anim_fx_cua(mundo_n, c.position + Vector2(randf_range(-6, 6), randf_range(-6, 6)), tex_brillo, 16.0, 0.3), 0.0, 1.0, dur)
	tw.tween_callback(func():
		so.queue_free()
		c.visible = false
		if is_instance_valid(obj) and obj.position.distance_to(meta) < 18.0:
			obj.herir(1, (obj.position - meta).normalized())
		Juego.sonido("golpe", true, -10.0)
		principal.sacudir(1.5)
		_anim_fx_cua(mundo_n, meta + Vector2(0, -4), tex_polvo, 12.0, 0.3)
		_anim_fx_cua(mundo_n, meta + Vector2(0, -6), tex_imp, 14.0, 0.3)
		Fx.chispas(mundo_n, meta + Vector2(0, -4), Color(0.75, 0.55, 1.0), 10)
		_anillo_cua(mundo_n, meta, 9.0, Color(0.7, 0.4, 1.0, 0.8), 0.35)
		for i in 4:
			_anim_fx_cua(mundo_n, meta + Vector2(randf_range(-12, 12), randf_range(-14, 0)), tex_brillo, 14.0, 0.3)
		for i in 14:
			var va := Vector2(randf_range(-70, 70), randf_range(-110, -40))
			if not principal.permitido(meta + Vector2(va.x * 0.6, 0)):
				va.x = -va.x * 0.3   # junto a la pared: rebota hacia el cuarto
			if not principal.permitido(meta + Vector2(va.x * 0.6, 0)):
				continue
			_astilla_suelta_cua(mundo_n, meta + Vector2(randf_range(-4, 4), -4), tex_p.pick_random(), va, meta.y, tex_brillo)
		c.queue_free())

# Estas dos no dependen del cuarzo (el cristal sigue volando aunque él ya haya muerto).
static func _polvo_cristal_cua(mundo_n: Node, p: Vector2, tex: Texture2D) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * 0.16
	s.position = p.round()
	s.z_index = 2
	s.modulate = Color(0.8, 0.7, 0.95, 0.8)
	mundo_n.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position:y", p.y + 6.0, 0.35)
	tw.tween_property(s, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(s.queue_free)

static func _astilla_suelta_cua(mundo_n: Node, p: Vector2, tex: Texture2D, v: Vector2, piso_y: float, brillo: Array = []) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * 0.26
	s.position = p
	s.z_index = 0
	mundo_n.add_child(s)
	var piso := piso_y + randf_range(-3, 5)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * 0.6
		var y := p.y + v.y * tt + 260.0 * tt * tt
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(y, piso))), 0.0, 1.0, 0.6)
	_deshacer_astilla_cua(s, tw, mundo_n, brillo)

# Muerte: los escombros se hunden en la tierra con polvo y desaparecen.
func _deshacer_cuarzo() -> void:
	for i in 4:
		_polvo_cua(position + Vector2(randf_range(-22, 22), randf_range(-4, 2)))
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		_terrones_cua(5, 0.4)
		_rafaga_motas_cua(position + Vector2(0, -8), 14, 24.0))
	tw.tween_property(sprite, "position:y", sprite.position.y + 10.0, 1.4)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 1.4)
	tw.tween_callback(queue_free)

# Destello de cristal: astillita clara que sube un poco y se apaga.
static func _chispa_cristal_cua(mundo_n: Node, p: Vector2, tex: Texture2D) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * 0.12
	s.position = p.round()
	s.z_index = 4
	s.modulate = Color(1.6, 1.4, 1.9, 1.0)
	mundo_n.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position:y", p.y - 6.0, 0.3)
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(s.queue_free)

# Mientras viaja: la tierra de enfrente se levanta y se abre hacia los lados, y atrás quedan
# piedras y terrones removidos sobre el piso (se quedan un rato y se apagan).
func _tierra_viaje_cua(delta: float, rumbo: Vector2) -> void:
	tierra_t_cua -= delta
	if tierra_t_cua > 0.0 or rumbo == Vector2.ZERO:
		return
	tierra_t_cua = 0.07
	var lado := rumbo.orthogonal()
	var frente := position + rumbo * 16.0
	for k in [-1.0, 1.0]:
		if randf() < 0.75:
			var de: Vector2 = frente + lado * k * randf_range(4, 10)
			var v: Vector2 = lado * k * randf_range(30, 55) + Vector2(0, randf_range(-70, -40))
			_pieza_fija_cua(de, randi_range(12, 16), v, 0.3, 0.45, de.y + randf_range(-1, 3), 0.15)
	if randf() < 0.6:
		_surco_cua(position - rumbo * randf_range(10, 18) + lado * randf_range(-10, 10))
	if randf() < 0.25:
		_polvo_cua(frente + lado * randf_range(-8, 8))
	if randf() < 0.3:
		_rafaga_motas_cua(position + Vector2(0, -6), 1, 8.0)   # luz del cristal que se escapa por la tierra

# Pieza que brinca, cae al piso y se QUEDA ahí un rato (tierra removida), luego se apaga.
func _pieza_fija_cua(p: Vector2, idx: int, v: Vector2, esc: float, dur: float, piso: float, queda: float) -> void:
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture("fx", idx)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * esc
	s.position = p
	s.z_index = -1 if randf() < 0.5 else 0
	s.flip_h = randf() < 0.5
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		var y := p.y + v.y * tt + 260.0 * tt * tt
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(y, piso))), 0.0, 1.0, dur)
	tw.tween_interval(queda)
	tw.tween_property(s, "modulate:a", 0.0, 0.8)
	tw.tween_callback(s.queue_free)

func _cuadros_cua(ini: int, n: int) -> Array:
	var l: Array = []
	for i in n:
		l.append(sprite.sprite_frames.get_frame_texture("fx", ini + i))
	return l

# Animación corta de efecto (polvo, destello, impacto) con sus cuadros de pixel; se borra al terminar.
static func _anim_fx_cua(mundo_n: Node, p: Vector2, cuadros: Array, fps: float, esc: float, z := 3) -> void:
	var s := Sprite2D.new()
	s.texture = cuadros[0]
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * esc
	s.position = p.round()
	s.z_index = z
	s.flip_h = randf() < 0.5
	mundo_n.add_child(s)
	var tw := s.create_tween()
	for i in range(1, cuadros.size()):
		tw.tween_interval(1.0 / fps)
		tw.tween_callback(func(): s.texture = cuadros[i])
	tw.tween_interval(1.0 / fps)
	tw.tween_property(s, "modulate:a", 0.0, 0.15)
	tw.tween_callback(s.queue_free)

func _polvo_cua(p: Vector2) -> void:
	_anim_fx_cua(main.mundo, p + Vector2(0, -3), _cuadros_cua(20, 4), 10.0, 0.3, 2)

# Grietas negras en el piso alrededor de donde rompe la tierra; se quedan y se apagan despacio.
func _grietas_cua() -> void:
	for k in 3:
		var s := Sprite2D.new()
		s.texture = sprite.sprite_frames.get_frame_texture("fx", 28 + k)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2.ONE * (0.45 if k == 2 else 0.35)
		s.position = (position + (Vector2.ZERO if k == 2 else Vector2(randf_range(18, 26) * (1 if k == 0 else -1), randf_range(-3, 3)))).round()
		s.flip_h = randf() < 0.5
		s.modulate = Color(1, 1, 1, 0.75)
		s.z_index = -1
		main.mundo.add_child(s)
		var tw := s.create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(s, "modulate:a", 0.0, 1.5)
		tw.tween_callback(s.queue_free)

# La astilla ya en el piso no se queda tirada: titila en morado, suelta destellos y se deshace
# encogiéndose en polvo de luz lila (sin brillo aditivo: solo color).
static func _deshacer_astilla_cua(s: Sprite2D, tw: Tween, mundo_n: Node, brillo: Array) -> void:
	var lila := Color(1.5, 1.15, 1.9, 1.0)
	tw.tween_interval(randf_range(0.05, 0.35))
	for i in 2:
		tw.tween_property(s, "modulate", lila, 0.07)
		tw.tween_property(s, "modulate", Color(1.05, 0.9, 1.25, 1.0), 0.1)
	tw.tween_callback(func():
		if not brillo.is_empty():
			_anim_fx_cua(mundo_n, s.position + Vector2(randf_range(-2, 2), -3), brillo, 14.0, 0.3))
	tw.tween_property(s, "modulate", Color(0.85, 0.55, 1.2, 0.85), 0.12)
	tw.tween_property(s, "scale", s.scale * 0.5, 0.18)
	tw.parallel().tween_property(s, "position:y", s.position.y - 2.0, 0.18)
	tw.tween_property(s, "modulate", Color(0.7, 0.45, 1.0, 0.0), 0.2)
	tw.parallel().tween_property(s, "scale", s.scale * 0.2, 0.2)
	tw.tween_callback(s.queue_free)

# Motas de luz morada que se desprenden de los cristales y suben despacio (en la penumbra se ve vivo).
func _mota_cua() -> void:
	if not vivo or not sprite.visible or not _cua_golpeable() or estado != "seguir":
		return
	if randf() < 0.35:
		return
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture("fx", randi_range(17, 19))
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * randf_range(0.28, 0.4)
	var cerca := randf() < 0.4
	s.position = (position + Vector2(randf_range(-28, 28), randf_range(-40, -14) if not cerca else randf_range(-14, -4))).round()
	s.modulate = Color(0.95, 0.6, 1.3, 0.0)
	s.z_index = 1
	main.mundo.add_child(s)
	var sube := randf_range(10, 18)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.95, 0.15)
	tw.parallel().tween_property(s, "position:y", s.position.y - sube, 1.0)
	tw.parallel().tween_property(s, "position:x", s.position.x + randf_range(-4, 4), 1.0)
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.tween_callback(s.queue_free)

static var _cua_caliente := false
func _precalentar_cua() -> void:
	if _cua_caliente:
		return
	_cua_caliente = true
	var tmp: Array = []
	for an in sprite.sprite_frames.get_animation_names():
		var s := Sprite2D.new()
		s.texture = sprite.sprite_frames.get_frame_texture(an, 0)
		s.modulate = Color(1, 1, 1, 0.01)
		s.material = mat if mat else null
		s.position = position
		main.mundo.add_child(s)
		tmp.append(s)
	for k in 3:
		var g := Sprite2D.new()
		g.texture = _tex_surco_cua(k)
		g.modulate = Color(1, 1, 1, 0.01)
		g.position = position
		main.mundo.add_child(g)
		tmp.append(g)
	get_tree().create_timer(0.15).timeout.connect(func():
		for n in tmp:
			if is_instance_valid(n):
				n.queue_free())

# Halo de pixel morado en el piso (anillo que se abre y se apaga), sin brillo aditivo.
static func _anillo_cua(mundo_n: Node, p: Vector2, r: float, col: Color, dur: float) -> void:
	var ln := Line2D.new()
	ln.width = 2.0
	ln.default_color = col
	ln.closed = true
	ln.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for k in 20:
		ln.add_point((Vector2.from_angle(TAU * k / 20.0) * Vector2(1, 0.4)).round())
	ln.position = p.round()
	ln.z_index = -1
	mundo_n.add_child(ln)
	ln.scale = Vector2.ONE * 3.0
	var tw := ln.create_tween().set_parallel()
	tw.tween_property(ln, "scale", Vector2.ONE * r, dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(ln, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(ln.queue_free)

# Ráfaga de motas moradas que suben (para salir, morir y romper el cristal).
func _rafaga_motas_cua(p: Vector2, n: int, ancho: float) -> void:
	for i in n:
		var m := Sprite2D.new()
		m.texture = sprite.sprite_frames.get_frame_texture("fx", randi_range(17, 19))
		m.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		m.scale = Vector2.ONE * randf_range(0.25, 0.4)
		m.position = (p + Vector2(randf_range(-ancho, ancho), randf_range(-ancho * 0.6, 0))).round()
		m.modulate = Color(0.95, 0.6, 1.3, 1.0)
		m.z_index = 3
		main.mundo.add_child(m)
		var tw := m.create_tween()
		tw.tween_property(m, "position:y", m.position.y - randf_range(14, 30), randf_range(0.6, 1.1)).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(m, "modulate:a", 0.0, 1.0).set_delay(0.2)
		tw.tween_callback(m.queue_free)

# ---- Vagoneta: rueda, se prepara patinando, embiste y choca; muere desplomándose ----
# Tira de efectos vag5_fx: 0-5 astillas, 6-13 rocas/hierro, 14-16 chispa, 17-20 polvo, 21-24 impacto, 25-27 marcas
const RUEDAS_VAG := [Vector2(9, -4), Vector2(29, -6)]   # ruedas (mirando a la izquierda, sin voltear)
var marca_vag := Vector2.INF

func _preparar_vagoneta() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_mat_vag")
	var tm := Timer.new()
	tm.wait_time = 0.09
	tm.autostart = true
	tm.timeout.connect(_ambiente_vag)
	add_child(tm)
	var sol := Timer.new()
	sol.wait_time = 0.016
	sol.autostart = true
	sol.timeout.connect(_solida_vag)
	add_child(sol)
	sprite.frame_changed.connect(_cuadro_vag)
	sprite.animation_changed.connect(func():
		if sprite.animation == "frena" and vivo:
			_choque_vag()
		elif sprite.animation == "dano" and vivo:
			_astillas_vag(position + Vector2(_lado_vag() * -4.0, -16), 3, 0.7))

func _lado_vag() -> float:
	return -1.0 if sprite.flip_h else 1.0   # +1: las ruedas a la derecha del centro

func _rueda_vag(i: int) -> Vector2:
	var r: Vector2 = RUEDAS_VAG[i]
	return position + Vector2(r.x * _lado_vag(), r.y)

func _frente_vag() -> Vector2:
	return position + Vector2(-34.0 * _lado_vag(), -16)

func _cuadro_vag() -> void:
	if not is_instance_valid(sprite):
		return
	var f := sprite.frame
	match sprite.animation:
		"mover":
			if vel.length() > 6.0:
				_marcas_vag()
				if f % 2 == 0:
					_polvo_vag(_rueda_vag(randi() % 2), 0.22)
			if f == 4 or f == 5:
				for i in 2:
					_pz_vag(position + Vector2(randf_range(-12, 12), -30), randi_range(6, 9), Vector2(randf_range(-20, 20), randf_range(-60, -30)), 0.22, 0.45)
		"prepara":
			esfuerzo = float(randi_range(-1, 1))
			for i in 2:
				var w := _rueda_vag(i)
				_anim_vag(w + Vector2(randf_range(-2, 2), -2), 14, 3, 16.0, 0.3)
				if randf() < 0.6:
					_polvo_vag(w + Vector2(_lado_vag() * 4.0, 0), 0.22)
		"embiste":
			_marcas_vag()
			_polvo_vag(_rueda_vag(1) + Vector2(_lado_vag() * 6.0, 0), 0.26)
			_pz_vag(position + Vector2(_lado_vag() * 14.0, -30), randi_range(6, 9), Vector2(_lado_vag() * randf_range(40, 80), randf_range(-60, -30)), 0.24, 0.5)
			if randf() < 0.5:
				_anim_vag(_rueda_vag(0) + Vector2(0, -1), 14, 3, 18.0, 0.28)
		"pulir":
			if f >= 16:
				z_index = -1   # ya derrumbada: son restos en el piso, Diana pasa por encima
			match f:
				1:
					_astillas_vag(position + Vector2(0, -16), 6, 1.0)
					for i in 2:
						_pz_vag(position + Vector2(randf_range(-10, 10), -16), randi_range(10, 13), Vector2(randf_range(-60, 60), randf_range(-90, -50)), 0.24, 0.6)
					_anim_vag(position + Vector2(0, -16), 14, 3, 16.0, 0.32)
				7, 9:
					_astillas_vag(position + Vector2(_lado_vag() * 10.0, -14), 3, 0.7)
				14, 15:
					main.sacudir(2.0)
					_polvo_vag(position + Vector2(randf_range(-10, 10), -4), 0.3)
					for i in 4:
						_pz_vag(position + Vector2(randf_range(-14, 14), -22), randi_range(6, 9), Vector2(randf_range(-60, 60), randf_range(-50, -20)), 0.24, 0.5)
				16:
					main.sacudir(3.0)
					for k in 3:
						_polvo_vag(position + Vector2(randf_range(-22, 22), -2), 0.34)
					_astillas_vag(position + Vector2(0, -8), 5, 0.9)
				18:
					var rw := _rueda_vag(1)
					for i in 3:
						_anim_vag(rw + Vector2(randf_range(-3, 3), -2), 14, 3, 16.0, 0.28)
					_polvo_vag(rw, 0.26)
				21:
					main.sacudir(5.0)
					_anillo_vag(position, 34.0)
					for i in 10:
						_humo_vag(position + Vector2(randf_range(-30, 30), randf_range(-10, 0)))
					for i in 16:
						_brasa_vag(position + Vector2(randf_range(-24, 24), -10))
					for k in 5:
						_anim_vag(position + Vector2(randf_range(-26, 26), randf_range(-8, 0)), 17, 4, 9.0, 0.4, 3)
					for i in 6:
						_pz_vag(position + Vector2(randf_range(-20, 20), -6), randi_range(6, 9), Vector2(randf_range(-80, 80), randf_range(-60, -20)), 0.24, 0.5)

# Choque (contra pared o Diana): sacudida, impacto de polvo, astillas, tuercas y rocas hacia adelante.
func _choque_vag() -> void:
	var fr := _frente_vag()
	_destello_vag(fr, 1.6)
	for i in 4:
		_llama_vag(fr + Vector2(randf_range(-6, 6), randf_range(-4, 6)), 1.0)
	for i in 14:
		_brasa_vag(fr + Vector2(randf_range(-4, 4), randf_range(-8, 6)))
	for i in 3:
		_humo_vag(fr + Vector2(randf_range(-8, 8), 4))
	_anillo_vag(Vector2(fr.x, position.y), 22.0)
	main.sacudir(4.0)
	Juego.sonido("golpe", false, -4.0)
	_anim_vag(fr + Vector2(0, 6), 21, 4, 12.0, 0.4, 3)
	_polvo_vag(fr + Vector2(0, 8), 0.34)
	_astillas_vag(fr, 4, 1.0)
	for i in 3:
		_pz_vag(fr, randi_range(10, 13), Vector2(-_lado_vag() * randf_range(30, 70), randf_range(-80, -40)), 0.24, 0.55)
	for i in 4:
		_pz_vag(position + Vector2(randf_range(-10, 10), -30), randi_range(6, 9), Vector2(-_lado_vag() * randf_range(40, 90), randf_range(-70, -30)), 0.24, 0.55)
	for i in 2:
		_anim_vag(fr + Vector2(randf_range(-4, 4), randf_range(-6, 4)), 14, 3, 16.0, 0.3)

func _golpe_vagoneta(desde: Vector2, critico: bool) -> void:
	var pg := position + Vector2(randf_range(-14, 14), -randf_range(18, 34))
	_destello_vag(pg, 1.4 if critico else 1.0)
	for i in (10 if critico else 6):
		_brasa_vag(pg)
	_humo_vag(pg)
	empuje *= 0.25   # pesada: retrocede poquito
	_astillas_vag(position + Vector2(0, -16), 5 if critico else 3, 0.8)
	_anim_vag(position + Vector2(randf_range(-6, 6), -14), 14, 3, 16.0, 0.3)

func _astillas_vag(p: Vector2, n: int, fuerza: float) -> void:
	for i in n:
		_pz_vag(p + Vector2(randf_range(-6, 6), randf_range(-6, 4)), randi_range(0, 5), Vector2(randf_range(-70, 70), randf_range(-100, -40)) * fuerza, 0.22, 0.55)

# Pieza que salta en arco, cae al piso (sin salir del cuarto) y se apaga.
func _pz_vag(p: Vector2, idx: int, v: Vector2, esc: float, dur: float) -> void:
	var piso := position.y + randf_range(-3, 6)
	if not main.permitido(Vector2(p.x + v.x * dur, piso)):
		v.x = -v.x * 0.3
		if not main.permitido(Vector2(p.x + v.x * dur, piso)):
			return
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture("fx", idx)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * esc
	s.position = p
	s.flip_h = randf() < 0.5
	s.z_index = 0
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		var y := p.y + v.y * tt + 260.0 * tt * tt
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(y, piso))), 0.0, 1.0, dur)
	tw.tween_interval(randf_range(0.3, 0.8))
	tw.tween_property(s, "modulate:a", 0.0, 0.4)
	tw.tween_callback(s.queue_free)

# Efecto animado (chispa, polvo, impacto) con sus cuadros de pixel; se borra al terminar.
func _anim_vag(p: Vector2, ini: int, n: int, fps: float, esc: float, z := 1) -> void:
	var cuadros: Array = []
	for i in n:
		cuadros.append(sprite.sprite_frames.get_frame_texture("fx", ini + i))
	var s := Sprite2D.new()
	s.texture = cuadros[0]
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * esc
	s.position = p.round()
	s.offset.y = -8.0
	s.z_index = z
	s.flip_h = randf() < 0.5
	main.mundo.add_child(s)
	var tw := s.create_tween()
	for i in range(1, n):
		tw.tween_interval(1.0 / fps)
		tw.tween_callback(func(): s.texture = cuadros[i])
	tw.tween_interval(1.0 / fps)
	tw.tween_property(s, "modulate:a", 0.0, 0.15)
	tw.tween_callback(s.queue_free)

func _polvo_vag(p: Vector2, esc: float) -> void:
	_anim_vag(p, 17, 4, 10.0, esc, 0)

# Marcas de las ruedas: planas en el piso, sin sombra, se desvanecen.
func _marcas_vag() -> void:
	if marca_vag != Vector2.INF and position.distance_to(marca_vag) < 6.0:
		return
	marca_vag = position
	for i in 2:
		var s := Sprite2D.new()
		s.texture = sprite.sprite_frames.get_frame_texture("fx", 25 + randi() % 3)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(0.16, 0.12)
		s.position = (_rueda_vag(i) + Vector2(0, 1)).round()
		s.rotation = vel.angle() if vel.length() > 1.0 else 0.0
		s.modulate = Color(0.55, 0.5, 0.45, 0.55)
		s.z_index = -2
		main.mundo.add_child(s)
		var tw := s.create_tween()
		tw.tween_interval(1.5)
		tw.tween_property(s, "modulate:a", 0.0, 1.2)
		tw.tween_callback(s.queue_free)

# Muerte: los restos se quedan un momento y se desvanecen con polvo.
func _deshacer_vagoneta() -> void:
	z_index = -1
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(func():
		for k in 4:
			_polvo_vag(position + Vector2(randf_range(-24, 24), randf_range(-4, 2)), 0.34))
	tw.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)

func _mat_vag() -> void:
	if mat:
		mat.set_shader_parameter("realce", 1.6)   # madera y hierro muy oscuros: que no se pierdan en la penumbra
		mat.set_shader_parameter("volumen", 0.2)
		mat.set_shader_parameter("color_ojos", Vector3(1.0, 0.62, 0.15))
		mat.set_shader_parameter("brillo_ojos", 0.0)
		mat.set_shader_parameter("color_contorno", Vector3(0.95, 0.45, 0.12))

# Vida propia: brasas naranjas de las ruedas, ceniza/polvo que cae de las rocas, ojos que laten,
# y contorno naranja que se enciende al cargar el embiste.
func _ambiente_vag() -> void:
	if not vivo or not is_instance_valid(sprite):
		return
	var an := sprite.animation
	if mat:
		var c := 0.0
		if an == "prepara" or an == "embiste":
			c = 0.55 + 0.3 * sin(t * 18.0)
		if an != "dano":
			mat.set_shader_parameter("contorno", c)
	var rapido := vel.length() > 8.0 or an in ["prepara", "embiste"]
	if rapido and randf() < (0.8 if an in ["prepara", "embiste"] else 0.35):
		_brasa_vag(_rueda_vag(randi() % 2) + Vector2(randf_range(-3, 3), -1))
	if randf() < 0.45:
		_ceniza_vag(position + Vector2(randf_range(-30, 30), -randf_range(36, 46)))
	# chispas de mineral que suben del montón de rocas (la carga brilla)
	if randf() < 0.35:
		_chispa_sube_vag(position + Vector2(randf_range(-26, 26), -randf_range(40, 48)))
	# ascuas como de fogata: se desprenden de la carga y de las tablas, suben meciéndose y se apagan
	for i in (3 if an == "embiste" else 2):
		if randf() < 0.7:
			var de := position + Vector2(randf_range(-30, 30), -randf_range(22, 46))
			_ascua_vag(de)
	# humo oscuro de las ruedas al patinar o embestir
	if an in ["prepara", "embiste"] and randf() < 0.6:
		_humo_vag(_rueda_vag(randi() % 2) + Vector2(_lado_vag() * 4.0, -2))
	if an == "embiste":
		for i in 2:
			_llama_vag(_rueda_vag(randi() % 2) + Vector2(_lado_vag() * randf_range(4, 10), randf_range(-4, 0)), 1.0)
		if randf() < 0.5:
			_llama_vag(position + Vector2(_lado_vag() * 30.0, -randf_range(20, 40)), 0.8)
	elif an == "prepara" and randf() < 0.5:
		_llama_vag(_rueda_vag(randi() % 2) + Vector2(_lado_vag() * 3.0, -1), 0.6)
	# rastro continuo de polvo al rodar
	if vel.length() > 10.0 and randf() < 0.45:
		_polvo_vag(_rueda_vag(1) + Vector2(_lado_vag() * 6.0, 0), 0.2)
	# piedritas que traquetean y caen al rodar
	if vel.length() > 10.0 and randf() < 0.12:
		_pz_vag(position + Vector2(randf_range(-20, 20), -40), randi_range(6, 9), Vector2(randf_range(-30, 30), randf_range(-50, -20)), 0.18, 0.45)
	if randf() < 0.12:
		_destello_ojo_vag()

# Brasa de pixel naranja que salta de la rueda, cae y se apaga (sin brillo aditivo).
func _brasa_vag(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.8, 1.4))
	s.color = [Color(1.0, 0.7, 0.2), Color(1.0, 0.45, 0.1), Color(0.95, 0.85, 0.4)].pick_random()
	s.position = p.round()
	s.z_index = 2
	main.mundo.add_child(s)
	var v := Vector2(_lado_vag() * randf_range(10, 45), randf_range(-55, -20))
	var piso := p.y + randf_range(0, 3)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * 0.45
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(p.y + v.y * tt + 220.0 * tt * tt, piso)))
		s.color = s.color.lerp(Color(0.35, 0.12, 0.05), k * 0.08), 0.0, 1.0, 0.45)
	tw.tween_property(s, "modulate:a", 0.0, 0.2)
	tw.tween_callback(s.queue_free)

# Polvo de mina que se desprende de las rocas de arriba y cae despacio.
func _ceniza_vag(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	s.color = Color(0.45, 0.4, 0.34, 0.8)
	s.position = p.round()
	s.z_index = 1
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position", s.position + Vector2(randf_range(-5, 5), randf_range(14, 24)), 0.9)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.9)
	tw.tween_callback(s.queue_free)

# Destello ámbar en los ojos: cruz de pixel que aparece y se apaga.
func _destello_ojo_vag() -> void:
	if sprite.animation == "pulir":
		return
	var p := position + Vector2(-24.0 * _lado_vag() + randf_range(-6, 6), -30)
	for k in 2:
		var s := Polygon2D.new()
		s.polygon = PackedVector2Array([Vector2(-1.5, 0), Vector2(0, -0.5), Vector2(1.5, 0), Vector2(0, 0.5)]) if k == 0 else PackedVector2Array([Vector2(0, -1.5), Vector2(0.5, 0), Vector2(0, 1.5), Vector2(-0.5, 0)])
		s.color = Color(1.0, 0.8, 0.35)
		s.position = p.round()
		s.z_index = 3
		main.mundo.add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "scale", Vector2.ONE * 2.0, 0.15)
		tw.tween_property(s, "modulate:a", 0.0, 0.2)
		tw.tween_callback(s.queue_free)

# Chispa de mineral que sube despacio desde la carga y se apaga (pixel ámbar, sin brillo aditivo).
func _chispa_sube_vag(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.7, 1.2))
	s.color = [Color(1.0, 0.75, 0.3), Color(1.0, 0.55, 0.15), Color(0.9, 0.9, 0.6)].pick_random()
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position", s.position + Vector2(randf_range(-6, 6), -randf_range(10, 22)), randf_range(0.6, 1.0))
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.9).set_delay(0.2)
	tw.tween_callback(s.queue_free)

# Bocanada de humo gris oscuro de pixel que sube y se deshace.
func _humo_vag(p: Vector2) -> void:
	var s := Polygon2D.new()
	var r := randf_range(1.5, 3.0)
	var pts := PackedVector2Array()
	for k in 8:
		pts.append((Vector2.from_angle(TAU * k / 8.0) * r).round())
	s.polygon = pts
	s.color = Color(0.22, 0.2, 0.18, 0.7)
	s.position = p.round()
	s.z_index = 1
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position", s.position + Vector2(randf_range(-6, 6), -randf_range(8, 16)), 0.7)
	tw.parallel().tween_property(s, "scale", Vector2.ONE * 2.2, 0.7)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.7)
	tw.tween_callback(s.queue_free)

# Onda de polvo en el piso (anillo de pixel que se abre y se apaga).
func _anillo_vag(p: Vector2, r: float) -> void:
	var ln := Line2D.new()
	ln.width = 2.0
	ln.default_color = Color(0.4, 0.34, 0.27, 0.7)
	ln.closed = true
	for k in 20:
		ln.add_point((Vector2.from_angle(TAU * k / 20.0) * Vector2(1, 0.4)).round())
	ln.position = p.round()
	ln.z_index = -1
	main.mundo.add_child(ln)
	ln.scale = Vector2.ONE * 3.0
	var tw := ln.create_tween().set_parallel()
	tw.tween_property(ln, "scale", Vector2.ONE * r, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(ln, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(ln.queue_free)

# Círculo de pixel (no cuadro) para brasas y chispas.
static func _gota_pts_vag(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 8:
		pts.append(Vector2.from_angle(TAU * k / 8.0) * r)
	return pts

# Lengua de fuego: forma de gota que sube, pasa de amarillo a naranja a rojo y se vuelve humo.
func _llama_vag(p: Vector2, tam: float) -> void:
	var s := Polygon2D.new()
	var r := randf_range(1.6, 2.6) * tam
	var pts := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0
		var v := Vector2(cos(a) * r, sin(a) * r)
		if v.y < 0.0:
			v.y *= 2.2   # punta hacia arriba
			v.x *= 0.7
		pts.append(v)
	s.polygon = pts
	s.color = Color(1.0, 0.85, 0.35, 0.95)
	s.position = p.round()
	s.z_index = 2
	main.mundo.add_child(s)
	var dur := randf_range(0.35, 0.55)
	var dx := _lado_vag() * randf_range(4, 12)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position", s.position + Vector2(dx, -randf_range(10, 18) * tam), dur)
	tw.tween_property(s, "scale", Vector2(0.6, 1.2), dur)
	tw.tween_method(func(k: float):
		var c1 := Color(1.0, 0.85, 0.35).lerp(Color(1.0, 0.45, 0.1), clampf(k * 2.0, 0.0, 1.0))
		s.color = c1.lerp(Color(0.25, 0.2, 0.18), clampf(k * 2.0 - 1.0, 0.0, 1.0))
		s.color.a = 0.95 * (1.0 - k * k), 0.0, 1.0, dur)
	tw.chain().tween_callback(s.queue_free)

# Destello de golpe: estrella de 4 puntas que se abre rápido y se apaga, con anillo de chispas.
func _destello_vag(p: Vector2, tam: float) -> void:
	var s := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 8:
		var r := 6.0 if k % 2 == 0 else 1.6
		pts.append(Vector2.from_angle(TAU * k / 8.0) * r)
	s.polygon = pts
	s.color = Color(1.0, 0.9, 0.55)
	s.position = p.round()
	s.z_index = 4
	s.scale = Vector2.ONE * 0.3 * tam
	s.rotation = randf_range(-0.3, 0.3)
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2.ONE * 1.3 * tam, 0.07)
	tw.tween_property(s, "color", Color(1.0, 0.55, 0.15, 0.0), 0.18)
	tw.tween_callback(s.queue_free)
	for i in 6:
		var a := TAU * i / 6.0 + randf() * 0.5
		var ch := Polygon2D.new()
		ch.polygon = PackedVector2Array([Vector2(-2.5, 0), Vector2(0, -0.6), Vector2(2.5, 0), Vector2(0, 0.6)])
		ch.color = Color(1.0, 0.8, 0.35)
		ch.position = p.round()
		ch.rotation = a
		ch.z_index = 4
		main.mundo.add_child(ch)
		var t2 := ch.create_tween().set_parallel()
		t2.tween_property(ch, "position", p + Vector2.from_angle(a) * randf_range(8, 14) * tam, 0.2)
		t2.tween_property(ch, "modulate:a", 0.0, 0.2)
		t2.chain().tween_callback(ch.queue_free)

# Mientras la vagoneta sigue entera (viva o derrumbándose) es sólida: Diana no la atraviesa.
# Ya en restos en el piso (cuadro 16 de la muerte en adelante) sí se puede pasar por encima.
func _solida_vag() -> void:
	if not is_instance_valid(objetivo) or not is_instance_valid(sprite):
		return
	if sprite.animation == "pulir" and sprite.frame >= 16:
		return
	var d: Vector2 = objetivo.position - position
	var rx := radio * 1.1
	var ry := 9.0
	var e := (d.x * d.x) / (rx * rx) + (d.y * d.y) / (ry * ry)
	if e < 1.0:
		var n := Vector2(d.x / (rx * rx), d.y / (ry * ry))
		if n.length() < 0.0001:
			n = Vector2(0, 1)
		var k := sqrt(1.0 / maxf(e, 0.0001))
		var fuera := position + d * k
		if main.permitido(fuera):
			objetivo.position = fuera

# Ascua de fogata: punto redondo que sube meciéndose de lado a lado, parpadea,
# pasa de amarillo a naranja a rojo oscuro y se apaga (sin brillo aditivo).
func _ascua_vag(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.6, 1.3))
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var dur := randf_range(0.9, 1.6)
	var sube := randf_range(22, 40)
	var mece := randf_range(3, 7)
	var fase := randf() * TAU
	var arrastre := (-vel.x * 0.15) if vel.length() > 5.0 else 0.0   # el aire las empuja hacia atrás al moverse
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		s.position = Vector2(roundf(p.x + sin(fase + k * 9.0) * mece * k + arrastre * k), roundf(p.y - sube * k))
		var col := Color(1.0, 0.9, 0.45).lerp(Color(1.0, 0.5, 0.12), clampf(k * 1.8, 0.0, 1.0))
		col = col.lerp(Color(0.45, 0.1, 0.05), clampf(k * 2.0 - 1.0, 0.0, 1.0))
		col.a = (1.0 - k * k) * (0.55 + 0.45 * absf(sin(k * 30.0 + fase)))   # parpadea como brasa
		s.color = col, 0.0, 1.0, dur)
	tw.tween_callback(s.queue_free)

# ---- Engrane: rueda con la cara girando, se prepara rechinando, embiste y choca; muere partiéndose ----
# Tira de efectos eng5_fx: 0-7 tuercas/tornillos, 8-15 esquirlas, 16-19 chispa, 20-22 polvo, 23-26 impacto, 27-29 marcas
const CENTRO_ENG := Vector2(0, -21)   # centro del engrane respecto a los pies
const RADIO_ENG := 20.0
var marca_eng := Vector2.INF

func _preparar_engrane() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_mat_eng")
	var tm := Timer.new()
	tm.wait_time = 0.07
	tm.autostart = true
	tm.timeout.connect(_ambiente_eng)
	add_child(tm)
	sprite.frame_changed.connect(_cuadro_eng)
	var sol := Timer.new()
	sol.wait_time = 0.016
	sol.autostart = true
	sol.timeout.connect(_solida_eng)
	add_child(sol)
	sprite.animation_changed.connect(func():
		if sprite.animation == "frena" and vivo:
			_choque_eng()
		elif sprite.animation == "dano" and vivo:
			_tuercas_eng(_centro_eng(), 2, 0.7))

func _centro_eng() -> Vector2:
	return position + CENTRO_ENG

# Hacia dónde rueda (+1 derecha, -1 izquierda).
func _rumbo_eng() -> float:
	if absf(vel.x) > 3.0:
		return signf(vel.x)
	return -1.0 if sprite.flip_h else 1.0

func _mat_eng() -> void:
	if mat:
		mat.set_shader_parameter("realce", 1.5)   # hierro muy oscuro: que no se pierda en la penumbra
		mat.set_shader_parameter("volumen", 0.2)
		mat.set_shader_parameter("color_ojos", Vector3(1.0, 0.62, 0.15))
		mat.set_shader_parameter("brillo_ojos", 0.0)
		mat.set_shader_parameter("color_contorno", Vector3(1.0, 0.5, 0.12))

func _cuadro_eng() -> void:
	if not is_instance_valid(sprite):
		return
	var f := sprite.frame
	var c := _centro_eng()
	match sprite.animation:
		"mover":
			if vel.length() > 6.0:
				_marcas_eng()
				if f % 2 == 0:
					_polvo_eng(position + Vector2(-_rumbo_eng() * 6.0, 0), 0.16)
				if f % 4 == 2 and vel.length() > 25.0:
					_dest_eng(position + Vector2(-_rumbo_eng() * 6.0, -3), 12, 5, 18.0, 0.35, _rumbo_eng() > 0.0)
				if f % 4 == 0:
					_oxido_eng(c + Vector2.from_angle(randf() * TAU) * RADIO_ENG)
		"prepara":
			esfuerzo = float(randi_range(-1, 1))   # tiembla rechinando en su lugar
			for i in 3:
				_chispa_eng(position + Vector2(randf_range(-3, 3), -1), -_rumbo_eng(), 1.0)
			if f % 3 == 0:
				_dest_eng(position + Vector2(-_rumbo_eng() * 6.0, -3), 12, 5, 18.0, 0.45, _rumbo_eng() > 0.0)
			if f % 2 == 0:
				_polvo_eng(position + Vector2(-_rumbo_eng() * 5.0, 0), 0.18)
			if f == 6:
				for k in [-1.0, 1.0]:
					_dest_eng(c + Vector2(k * 5.0, -3), 17, 5, 14.0, 0.5)   # los ojos se encienden antes de salir
		"embiste":
			_marcas_eng()
			_eco_eng()
			if f % 2 == 0:
				_dest_eng(position + Vector2(-_rumbo_eng() * 7.0, -3), 12, 5, 20.0, 0.5, _rumbo_eng() > 0.0)
			for i in 2:
				_chispa_eng(position + Vector2(-_rumbo_eng() * 4.0, -1), -_rumbo_eng(), 1.3)
			if f % 2 == 0:
				_polvo_eng(position + Vector2(-_rumbo_eng() * 10.0, 0), 0.2)
		"pulir":
			if f >= 19:
				z_index = -1   # ya en el piso: son restos, Diana pasa por encima
			if f >= 10 and f <= 13:
				_tension_eng(f)
			elif f >= 15 and f <= 18:
				_orillas_eng(f)
			match f:
				1:
					_dest_eng(c, 0, 6, 20.0, 0.6)
					_chispas_aro_eng(6)
				4, 6:
					_chispas_aro_eng(4)
					_pz_vag(c + Vector2(randf_range(-RADIO_ENG, RADIO_ENG), -6), randi_range(8, 15), Vector2(randf_range(-60, 60), randf_range(-90, -50)), 0.2, 0.55)
				8:
					# la grieta baja por la cara: crujido, grieta de luz y esquirlas
					main.sacudir(1.5)
					_dest_eng(c + Vector2(0, -6), 22, 2, 10.0, 0.7)
					_pz_vag(c + Vector2(0, -RADIO_ENG + 2), randi_range(8, 15), Vector2(randf_range(-30, 30), randf_range(-90, -60)), 0.2, 0.55)
					_chispas_aro_eng(3)
				10, 12:
					_pz_vag(c + Vector2(randf_range(-4, 4), randf_range(-10, 4)), randi_range(8, 15), Vector2(randf_range(-50, 50), randf_range(-80, -40)), 0.2, 0.5)
					for i in 3:
						_chispa_eng(c + Vector2(randf_range(-2, 2), randf_range(-14, 10)), [-1.0, 1.0].pick_random(), 1.1)
				14:
					_estalla_eng()
					# se parte en dos: chasquido, tuercas que saltan del centro y humo
					main.sacudir(3.0)
					_dest_eng(c, 22, 6, 12.0, 0.9)
					_dest_eng(c, 6, 6, 18.0, 0.7)
					_tuercas_eng(c, 5, 1.1)
					for i in 6:
						_chispa_eng(c + Vector2(0, randf_range(-12, 12)), [-1.0, 1.0].pick_random(), 1.5)
					for i in 3:
						_humo_vag(c + Vector2(randf_range(-4, 4), randf_range(-10, 6)))
				18:
					for i in 4:
						_oxido_eng(c + Vector2(randf_range(-RADIO_ENG * 1.4, RADIO_ENG * 1.4), randf_range(-10, 4)))
				19:
					# las mitades pegan en el piso
					main.sacudir(4.0)
					_anillo_vag(position, 30.0)
					_dest_eng(position + Vector2(-14, -3), 12, 5, 16.0, 0.6, true)
					_dest_eng(position + Vector2(14, -3), 12, 5, 16.0, 0.6, false)
					for k in 3:
						_polvo_eng(position + Vector2(randf_range(-24, 24), 0), 0.3)
					for i in 6:
						_pz_vag(position + Vector2(randf_range(-20, 20), -6), randi_range(8, 15), Vector2(randf_range(-80, 80), randf_range(-70, -30)), 0.2, 0.5)
					for i in 8:
						_chispa_eng(position + Vector2(randf_range(-22, 22), -2), [-1.0, 1.0].pick_random(), 1.2)
					Juego.sonido("golpe", false, -6.0)
				21:
					for i in 4:
						_humo_vag(position + Vector2(randf_range(-22, 22), randf_range(-8, 0)))

# Choque (contra pared o Diana): impacto metálico, chispas, tuercas y esquirlas hacia atrás.
func _choque_eng() -> void:
	var fr := _centro_eng() + Vector2(_rumbo_eng() * RADIO_ENG, 4)
	_dest_eng(fr, 6, 6, 18.0, 0.8)
	_dest_eng(Vector2(fr.x, position.y - 3), 12, 5, 16.0, 0.6, _rumbo_eng() > 0.0)
	_anillo_vag(Vector2(fr.x, position.y), 20.0)
	main.sacudir(3.5)
	Juego.sonido("golpe", false, -4.0)
	_polvo_eng(Vector2(fr.x, position.y), 0.26)
	for i in 10:
		_chispa_eng(fr + Vector2(randf_range(-2, 2), randf_range(-8, 8)), -_rumbo_eng(), 1.5)
	_tuercas_eng(fr, 3, 1.0)
	for i in 2:
		_pz_vag(fr, randi_range(8, 15), Vector2(-_rumbo_eng() * randf_range(30, 70), randf_range(-80, -40)), 0.2, 0.5)

func _golpe_engrane(desde: Vector2, critico: bool) -> void:
	var pg := _centro_eng() + Vector2.from_angle(randf() * TAU) * RADIO_ENG * 0.6
	_dest_eng(pg, 0, 6, 22.0, 0.75 if critico else 0.55)
	var lejos := signf(position.x - desde.x) if absf(position.x - desde.x) > 1.0 else 1.0
	for i in (8 if critico else 5):
		_chispa_eng(pg, lejos, 1.2)
	_tuercas_eng(pg, 2 if critico else 1, 0.8)
	if critico:
		_pz_vag(pg, randi_range(8, 15), Vector2(lejos * randf_range(30, 70), randf_range(-90, -50)), 0.2, 0.5)

# Tuercas y tornillos que saltan en arco y caen al piso.
func _tuercas_eng(p: Vector2, n: int, fuerza: float) -> void:
	for i in n:
		_pz_vag(p + Vector2(randf_range(-4, 4), randf_range(-4, 4)), randi_range(0, 7), Vector2(randf_range(-70, 70), randf_range(-110, -50)) * fuerza, 0.18, 0.55)

# Chispas alrededor del aro (los dientes se aflojan).
func _chispas_aro_eng(n: int) -> void:
	for i in n:
		var a := randf() * TAU
		_chispa_eng(_centro_eng() + Vector2.from_angle(a) * RADIO_ENG, signf(cos(a)) if absf(cos(a)) > 0.1 else 1.0, 1.0)

# Chispa de metal: rayita de pixel que sale disparada, cae con gravedad, se enfría y se apaga.
func _chispa_eng(p: Vector2, hacia_x: float, fuerza: float) -> void:
	var s := Line2D.new()
	s.width = 1.0
	s.default_color = [Color(1.0, 0.85, 0.4), Color(1.0, 0.6, 0.15), Color(1.0, 0.95, 0.7)].pick_random()
	s.add_point(Vector2.ZERO)
	s.add_point(Vector2.ZERO)
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var v := Vector2(hacia_x * randf_range(30, 90), randf_range(-80, -25)) * fuerza
	var piso := position.y + randf_range(-2, 4)
	var dur := randf_range(0.25, 0.45)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		var y := minf(p.y + v.y * tt + 300.0 * tt * tt, piso)
		var pos := Vector2(p.x + v.x * tt, y)
		s.position = pos.round()
		var cola := Vector2(-v.x, -(v.y + 600.0 * tt)).normalized() * 2.0   # rayita en dirección del movimiento
		s.set_point_position(1, cola.round())
		s.default_color = s.default_color.lerp(Color(0.6, 0.2, 0.05), k * 0.06)
		s.modulate.a = 1.0 - k * k, 0.0, 1.0, dur)
	tw.tween_callback(s.queue_free)

# Hojuela de óxido que se desprende del aro y cae despacio.
func _oxido_eng(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	s.color = [Color(0.45, 0.22, 0.12), Color(0.35, 0.2, 0.14), Color(0.3, 0.28, 0.24)].pick_random()
	s.position = p.round()
	s.z_index = 1
	main.mundo.add_child(s)
	var piso := position.y + randf_range(-2, 3)
	var tw := s.create_tween()
	tw.tween_property(s, "position", Vector2(s.position.x + randf_range(-6, 6), piso).round(), randf_range(0.4, 0.7))
	tw.tween_interval(0.4)
	tw.tween_property(s, "modulate:a", 0.0, 0.5)
	tw.tween_callback(s.queue_free)

func _polvo_eng(p: Vector2, esc: float) -> void:
	_anim_vag(p, 20, 3, 9.0, esc, 0)
	# granitos de tierra y óxido que salen del polvo y se asientan, y motas que flotan
	for i in int(3 + esc * 12.0):
		_grano_eng(p + Vector2(randf_range(-4, 4), randf_range(-3, 0)), esc)
	for i in int(1 + esc * 6.0):
		_mota_eng(p + Vector2(randf_range(-6, 6), randf_range(-6, -1)))

func _grano_eng(p: Vector2, esc: float) -> void:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	s.color = [Color(0.42, 0.36, 0.3), Color(0.5, 0.42, 0.33), Color(0.45, 0.24, 0.14), Color(0.3, 0.27, 0.24)].pick_random()
	s.position = p.round()
	s.z_index = 0
	main.mundo.add_child(s)
	var v := Vector2(randf_range(-50, 50), randf_range(-55, -15)) * (0.6 + esc * 1.5)
	var piso := p.y + randf_range(0, 4)
	var dur := randf_range(0.3, 0.5)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(p.y + v.y * tt + 260.0 * tt * tt, piso))), 0.0, 1.0, dur)
	tw.tween_interval(randf_range(0.3, 0.7))
	tw.tween_property(s, "modulate:a", 0.0, 0.4)
	tw.tween_callback(s.queue_free)

# Mota de polvo que flota hacia arriba despacio y se desvanece.
func _mota_eng(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	s.color = Color(0.55, 0.5, 0.44, 0.7)
	s.position = p.round()
	s.z_index = 1
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position", (s.position + Vector2(randf_range(-8, 8) - vel.x * 0.05, -randf_range(6, 14))).round(), randf_range(0.6, 1.0))
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.9)
	tw.tween_callback(s.queue_free)

# Rayón de los dientes en el piso: plano, sin sombra, se desvanece.
func _marcas_eng() -> void:
	if marca_eng != Vector2.INF and position.distance_to(marca_eng) < 7.0:
		return
	marca_eng = position
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture("fx", 27 + randi() % 3)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(0.14, 0.1)
	s.position = (position + Vector2(0, 1)).round()
	s.rotation = vel.angle() if vel.length() > 1.0 else 0.0
	s.modulate = Color(0.5, 0.45, 0.4, 0.5)
	s.z_index = -2
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(s, "modulate:a", 0.0, 1.0)
	tw.tween_callback(s.queue_free)

# Estela del embiste: copia oscura del cuadro actual que se queda atrás y se apaga (rastro retro).
var eco_eng_n := 0
func _eco_eng() -> void:
	eco_eng_n += 1
	if eco_eng_n % 2 != 0:
		return
	var e := Sprite2D.new()
	e.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	e.centered = sprite.centered
	e.offset = sprite.offset
	e.flip_h = sprite.flip_h
	e.scale = sprite.scale
	e.global_position = sprite.global_position.round()
	e.modulate = Color(1.0, 0.15, 0.1, 0.45)   # estela roja al acelerar
	e.z_index = z_index - 1 if z_index > -1 else z_index
	main.mundo.add_child(e)
	var tw := e.create_tween()
	tw.tween_property(e, "modulate:a", 0.0, 0.2)
	tw.tween_callback(e.queue_free)

# Vida propia: chispas de los dientes al rodar, hojuelas de óxido, ojos que destellan
# y contorno naranja que se enciende al cargar el embiste.
func _ambiente_eng() -> void:
	if not vivo or not is_instance_valid(sprite):
		return
	var an := sprite.animation
	if mat and an != "dano":
		var c := 0.0
		if an == "prepara" or an == "embiste":
			c = 0.7 + 0.3 * sin(t * 24.0)
			mat.set_shader_parameter("color_contorno", Vector3(1.0, 0.12, 0.08))   # acelera: se pone al rojo
		else:
			mat.set_shader_parameter("color_contorno", Vector3(1.0, 0.5, 0.12))
		mat.set_shader_parameter("contorno", c)
	# rueda rápido: estela de polvo continua, tierra pateada hacia atrás y aire que se arrastra
	var rap := vel.length()
	if rap > 10.0:
		var atras := position + Vector2(-_rumbo_eng() * 8.0, 0)
		_bocanada_eng(atras + Vector2(0, randf_range(-3, 0)), clampf(rap / 60.0, 0.4, 1.6))
		for i in int(1 + rap / 25.0):
			_grano_eng(atras + Vector2(randf_range(-2, 2), -1), 0.3)
		if randf() < rap / 90.0:
			_viento_eng()
	if an == "prepara" or an == "embiste":
		for i in (3 if an == "embiste" else 1):
			_calor_eng(_centro_eng() + Vector2.from_angle(randf() * TAU) * RADIO_ENG * randf_range(0.8, 1.05))
	var rapido := vel.length() > 10.0
	if rapido and randf() < 0.45:
		_chispa_eng(position + Vector2(-_rumbo_eng() * 2.0, -1), -_rumbo_eng(), 0.7)
	if an == "embiste":
		_eco_eng()
	if randf() < 0.12:
		_oxido_eng(_centro_eng() + Vector2.from_angle(randf() * TAU) * RADIO_ENG)
	if randf() < 0.06 and an != "pulir":
		_destello_ojo_eng()

# Destello ámbar en un ojo: cruz de pixel que aparece y se apaga.
func _destello_ojo_eng() -> void:
	_dest_eng(_centro_eng() + Vector2([-5.0, 5.0].pick_random(), -3), 17, 5, 14.0, 0.45)

# Muerte: las dos mitades se quedan un momento en el piso, humean y se desvanecen con polvo.
func _deshacer_engrane() -> void:
	z_index = -1
	var tw := create_tween()
	tw.tween_interval(1.4)
	# los restos se deshacen en óxido: tiemblan, sueltan polvo, hojuelas, humo y brasas,
	# y se apagan a saltos (como en los juegos de 16 bits), no de golpe
	tw.tween_callback(func():
		for k in 3:
			_polvo_eng(position + Vector2(randf_range(-22, 22), randf_range(-3, 1)), 0.26))
	for paso in 8:
		tw.tween_callback(func():
			esfuerzo = float(randi_range(-1, 1))
			for i in 4:
				_oxido_eng(position + Vector2(randf_range(-26, 26), -randf_range(2, 12)))
			for i in 2:
				_mota_eng(position + Vector2(randf_range(-24, 24), -randf_range(1, 8)))
			if randf() < 0.6:
				_humo_vag(position + Vector2(randf_range(-20, 20), -randf_range(2, 8)))
			if randf() < 0.5:
				_calor_eng(position + Vector2(randf_range(-20, 20), -randf_range(2, 8)))
			if paso % 3 == 0:
				_polvo_eng(position + Vector2(randf_range(-20, 20), 0), 0.22))
		tw.tween_property(sprite, "modulate:a", 1.0 - (paso + 1) / 8.0, 0.0)
		tw.tween_interval(0.12)
	tw.tween_callback(func():
		_anillo_vag(position, 18.0)
		for k in 6:
			_mota_eng(position + Vector2(randf_range(-20, 20), -randf_range(1, 6))))
	tw.tween_interval(0.6)
	tw.tween_callback(queue_free)

# Destello animado dibujado (hoja eng5_dest): 0-5 golpe, 6-11 choque, 12-16 raspar (abanico a la derecha),
# 17-21 ojo, 22-27 ruptura. Cuadro por cuadro, sin brillo aditivo.
func _dest_eng(p: Vector2, ini: int, n: int, fps: float, esc: float, voltear := false, z := 4) -> void:
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture("dest", ini)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * esc
	s.flip_h = voltear
	s.position = p.round()
	s.z_index = z
	main.mundo.add_child(s)
	var tw := s.create_tween()
	for i in range(1, n):
		tw.tween_interval(1.0 / fps)
		tw.tween_callback(func(): s.texture = sprite.sprite_frames.get_frame_texture("dest", ini + i) if is_instance_valid(sprite) else s.texture)
	tw.tween_interval(1.0 / fps)
	tw.tween_callback(s.queue_free)

# Bocanada de polvo detrás de la rueda: bola de pixel café claro que crece, sube un poco y se deshace.
func _bocanada_eng(p: Vector2, tam: float) -> void:
	var s := Polygon2D.new()
	var r := randf_range(1.5, 2.5) * tam
	var pts := PackedVector2Array()
	for k in 8:
		pts.append((Vector2.from_angle(TAU * k / 8.0) * r).round())
	s.polygon = pts
	s.color = [Color(0.5, 0.44, 0.36, 0.6), Color(0.42, 0.37, 0.31, 0.6), Color(0.58, 0.52, 0.44, 0.5)].pick_random()
	s.position = p.round()
	s.z_index = 0
	main.mundo.add_child(s)
	var dur := randf_range(0.4, 0.7)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position", (s.position + Vector2(-_rumbo_eng() * randf_range(4, 12), -randf_range(3, 9))).round(), dur)
	tw.tween_property(s, "scale", Vector2.ONE * randf_range(2.0, 3.0), dur)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)

# Raya de aire que pasa junto a la rueda hacia atrás (velocidad), de pixel y muy corta.
func _viento_eng() -> void:
	var s := Line2D.new()
	s.width = 1.0
	s.default_color = Color(0.75, 0.7, 0.62, 0.55)
	var largo := randf_range(6, 12)
	s.add_point(Vector2.ZERO)
	s.add_point(Vector2(-_rumbo_eng() * largo, 0))
	s.position = (_centro_eng() + Vector2(-_rumbo_eng() * RADIO_ENG * 0.6, randf_range(-RADIO_ENG, RADIO_ENG * 0.8))).round()
	s.z_index = 2
	main.mundo.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position:x", s.position.x - _rumbo_eng() * randf_range(10, 18), 0.18)
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(s.queue_free)

# Chispa roja de calor que se suelta del aro al acelerar y se queda atrás apagándose.
func _calor_eng(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.7, 1.2))
	s.color = [Color(1.0, 0.2, 0.1), Color(0.9, 0.1, 0.08), Color(1.0, 0.45, 0.2)].pick_random()
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var dur := randf_range(0.3, 0.55)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position", (s.position + Vector2(-_rumbo_eng() * randf_range(8, 20), -randf_range(2, 10))).round(), dur)
	tw.tween_property(s, "color", Color(0.35, 0.05, 0.05, 0.0), dur)
	tw.chain().tween_callback(s.queue_free)

# IA del engrane: si está muy cerca de Diana rueda hacia atrás para tomar vuelo;
# a buena distancia y con el ataque listo, se prepara y embiste. Nunca se queda encimado.
func _seguir_eng(hacia: Vector2, dir: Vector2) -> Vector2:
	var d := hacia.length()
	if d < 70.0:
		var lado := Vector2(-dir.y, dir.x) * (1.0 if personalidad > 1.0 else -1.0)
		return (-dir + lado * 0.5).normalized()   # se aleja en diagonal para no pegarse a la pared
	if cd_ataque <= 0.0 and d < 190.0:
		estado = "aviso"
		estado_t = 0.8
		return Vector2.ZERO
	if cd_ataque > 0.0 and d < 110.0:
		return Vector2(-dir.y, dir.x) * (1.0 if personalidad > 1.0 else -1.0)   # la rodea esperando
	return dir

# Mientras está entero es sólido: Diana no lo atraviesa (los restos en el piso sí).
func _solida_eng() -> void:
	if not is_instance_valid(objetivo) or not is_instance_valid(sprite):
		return
	if sprite.animation == "pulir" and sprite.frame >= 19:
		return
	var d: Vector2 = objetivo.position - position
	var rx := radio * 1.1
	var ry := 7.0
	var e := (d.x * d.x) / (rx * rx) + (d.y * d.y) / (ry * ry)
	if e < 1.0:
		if d.length() < 0.001:
			d = Vector2(0, 1)
		var fuera := position + d * sqrt(1.0 / maxf(e, 0.0001))
		if main.permitido(fuera):
			objetivo.position = fuera

# Antes de partirse: el engrane tiembla cada vez más, la grieta escupe chispas y calor rojo
# y el metal se pone blanco por un instante (se siente la presión).
func _tension_eng(f: int) -> void:
	var c := _centro_eng()
	var fuerza := float(f - 9)   # 1..4
	esfuerzo = float(randi_range(-1, 1)) * minf(fuerza, 2.0)
	main.sacudir(0.6 + fuerza * 0.4)
	for i in int(fuerza * 2.0):
		_chispa_eng(c + Vector2(randf_range(-1, 1), randf_range(-RADIO_ENG, RADIO_ENG * 0.6)), [-1.0, 1.0].pick_random(), 0.8)
	for i in int(fuerza):
		_calor_eng(c + Vector2(randf_range(-2, 2), randf_range(-RADIO_ENG, RADIO_ENG * 0.6)))
	if f % 2 == 1:
		_humo_vag(c + Vector2(randf_range(-2, 2), -RADIO_ENG * 0.8))
	if mat and f == 13:
		mat.set_shader_parameter("destello", 0.6)
		create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 0.6, 0.0, 0.12)

# El momento en que se parte: se congela un instante (golpe seco de 16 bits), destello blanco,
# estallido grande con chispas a los dos lados, tuercas, esquirlas, humo y onda en el piso.
func _estalla_eng() -> void:
	var c := _centro_eng()
	sprite.pause()
	get_tree().create_timer(0.09).timeout.connect(func():
		if is_instance_valid(sprite):
			sprite.play())
	if mat:
		mat.set_shader_parameter("destello", 1.0)
		create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 1.0, 0.0, 0.3)
	main.sacudir(6.0)
	Juego.sonido("golpe", false, -2.0)
	_dest_eng(c, 6, 6, 16.0, 1.1)
	_dest_eng(c + Vector2(-8, 4), 12, 5, 14.0, 0.7, true)
	_dest_eng(c + Vector2(8, 4), 12, 5, 14.0, 0.7, false)
	_anillo_vag(position, 34.0)
	for lado in [-1.0, 1.0]:
		for i in 9:
			_chispa_eng(c + Vector2(lado * 2.0, randf_range(-RADIO_ENG, RADIO_ENG)), lado, randf_range(1.2, 2.0))
		for i in 4:
			_calor_eng(c + Vector2(lado * randf_range(2, 8), randf_range(-RADIO_ENG, RADIO_ENG)))
	_tuercas_eng(c, 4, 1.3)
	for i in 4:
		_pz_vag(c + Vector2(randf_range(-4, 4), randf_range(-12, 10)), randi_range(8, 15), Vector2(randf_range(-110, 110), randf_range(-120, -60)), 0.2, 0.6)
	for i in 5:
		_humo_vag(c + Vector2(randf_range(-6, 6), randf_range(-RADIO_ENG, 6)))
	for i in 3:
		_bocanada_eng(position + Vector2(randf_range(-14, 14), -1), 1.4)

# Mientras las mitades se abren y caen: chispas y brasas que gotean de las orillas rotas, y humo.
func _orillas_eng(f: int) -> void:
	var c := _centro_eng()
	var abre := float(f - 14) * 4.0
	for lado in [-1.0, 1.0]:
		var p := c + Vector2(lado * abre, randf_range(-RADIO_ENG * 0.6, RADIO_ENG * 0.6))
		for i in 2:
			_chispa_eng(p, lado, 0.6)
		if randf() < 0.6:
			_calor_eng(p)
	_humo_vag(c + Vector2(randf_range(-3, 3), -randf_range(0, RADIO_ENG)))
	if f % 2 == 0:
		_oxido_eng(c + Vector2(randf_range(-abre - 6, abre + 6), randf_range(-8, 8)))

# ---- Lingote: camina pesado, escupe pepitas de oro en arco; muere agrietándose y partiéndose ----
# Tira de efectos lin5_fx: 0-6 pepitas, 7-10 pepita rompiéndose, 11-18 pedazos, 19-22 chispa, 23-26 polvo, 27-30 destello de escupir
const BOCA_LIN := Vector2(-7, -16)   # boca dibujada mirando a la izquierda (sin voltear)

func _lado_lin() -> float:
	return 1.0 if sprite.flip_h else -1.0   # hacia donde mira la cara

func _boca_lin() -> Vector2:
	return position + Vector2(BOCA_LIN.x * -_lado_lin(), BOCA_LIN.y)
var escupio_lin := false
var tanda_lin := 0       # cuántas tandas lleva: las pares son 1 pepita, las nones ráfaga de 4
var n_tanda_lin := 1
var lado_golpe_lin := 1.0   # de qué lado le pegaron (para el sacudón hacia atrás)

func _preparar_lingote() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_mat_lin")
	var tm := Timer.new()
	tm.wait_time = 0.08
	tm.autostart = true
	tm.timeout.connect(_ambiente_lin)
	add_child(tm)
	sprite.frame_changed.connect(_cuadro_lin)
	var luz := PointLight2D.new()
	luz.name = "LuzLin"
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.6
	luz.color = Color(1.0, 0.75, 0.3)
	luz.energy = 0.35
	luz.position = Vector2(0, -18)
	add_child(luz)
	sprite.animation_changed.connect(func():
		if sprite.animation == "ataque":
			escupio_lin = false)

func _mat_lin() -> void:
	if mat:
		mat.set_shader_parameter("realce", 1.25)
		mat.set_shader_parameter("volumen", 0.2)
		mat.set_shader_parameter("brillo_ojos", 0.0)
		mat.set_shader_parameter("color_contorno", Vector3(1.0, 0.75, 0.2))

# IA: se acerca hasta media distancia, la rodea un poco y escupe; si Diana se le pega, retrocede.
func _ia_lin(hacia: Vector2, dir: Vector2) -> Vector2:
	if anim_t > 0.0 and sprite.animation == "ataque":
		return Vector2.ZERO
	var d := hacia.length()
	if cd_ataque <= 0.0 and d < 230.0:
		n_tanda_lin = 1 if tanda_lin % 2 == 0 else 4
		tanda_lin += 1
		cd_ataque = 3.0 + (0.7 if n_tanda_lin > 1 else 0.0)
		especial("ataque")
		return Vector2.ZERO
	if d < 70.0:
		return -dir
	if d < 140.0:
		return Vector2(-dir.y, dir.x) * (1.0 if personalidad > 1.0 else -1.0) * 0.7
	return dir

func _cuadro_lin() -> void:
	if not is_instance_valid(sprite):
		return
	var f := sprite.frame
	match sprite.animation:
		"mover":
			if f == 0 or f == 6:   # apoya la bota: polvo dorado, granitos y un temblorcito
				var lado := -1.0 if f == 0 else 1.0
				var bota := position + Vector2(lado * 10.0, 0)
				_anim_vag(bota, 23, 4, 12.0, 0.22, 0)
				for i in 5:
					_grano_lin(bota + Vector2(randf_range(-3, 3), -1))
				if randf() < 0.5:
					_mota_lin(bota + Vector2(0, -2), false)
				main.sacudir(0.4)
		"ataque":
			if f >= 2 and f <= 9 and f % 2 == 0:
				_destello_lin(_boca_lin() + Vector2(randf_range(-8, 8), randf_range(-6, 2)))   # junta brillo antes de escupir
				_mota_lin(_boca_lin() + Vector2(randf_range(-14, 14), randf_range(-4, 8)), true)
			if f == 11 and not escupio_lin:
				escupio_lin = true
				for i in n_tanda_lin:
					var desvio := 0.0 if n_tanda_lin == 1 else (float(i) - 1.5) * 0.16
					if i == 0:
						_escupir_lin(desvio)
					else:
						get_tree().create_timer(0.17 * i).timeout.connect(func():
							if is_instance_valid(self) and vivo:
								_escupir_lin(desvio))
		"dano":
			if f == 2:
				_anim_vag(position + Vector2(randf_range(-6, 6), -22), 19, 4, 16.0, 0.4, 3)
		"pulir":
			if f >= 16:
				z_index = -1
			match f:
				2:
					_anim_vag(position + Vector2(0, -20), 19, 4, 14.0, 0.35, 3)
					_luz_lin(position + Vector2(0, -20), Color(1.0, 0.8, 0.35), 0.6, 1.2, 0.3)
					for i in 6:
						_chispa_lin(position + Vector2(0, -20), Vector2(randf_range(-80, 80), randf_range(-100, -20)))
				7, 9:
					main.sacudir(1.0)
					for i in 3:
						_pz_vag(position + Vector2(randf_range(-14, 14), -26), randi_range(11, 18), Vector2(randf_range(-50, 50), randf_range(-80, -40)), 0.25, 0.5)
					_destello_lin(position + Vector2(randf_range(-12, 12), -24))
					_luz_lin(position + Vector2(0, -22), Color(1.0, 0.75, 0.3), 0.5, 0.9, 0.25)
					for i in 5:
						_chispa_lin(position + Vector2(randf_range(-10, 10), -24), Vector2(randf_range(-70, 70), randf_range(-90, -20)))
					for i in 2:
						_humo_lin(position + Vector2(randf_range(-12, 12), -20))
				11:
					for i in 4:
						_mota_lin(position + Vector2(randf_range(-20, 20), -randf_range(10, 30)), false)
					for i in 4:
						_pz_vag(position + Vector2(randf_range(-16, 16), -20), randi_range(11, 18), Vector2(randf_range(-60, 60), randf_range(-90, -40)), 0.25, 0.5)
				13:
					main.sacudir(2.0)
					for k in 2:
						_anim_vag(position + Vector2(k * 24.0 - 12.0, 0), 23, 4, 12.0, 0.3, 0)
				16:
					# pega en el piso
					main.sacudir(4.0)
					Juego.sonido("golpe", false, -4.0)
					_anillo_lin(position, 30.0)
					_anillo_lin(position, 22.0)
					_luz_lin(position + Vector2(0, -6), Color(1.0, 0.72, 0.3), 0.9, 1.4, 0.4)
					for i in 8:
						_humo_lin(position + Vector2(randf_range(-26, 26), randf_range(-6, 0)))
					for i in 10:
						_chispa_lin(position + Vector2(randf_range(-16, 16), -4), Vector2(randf_range(-90, 90), randf_range(-100, -30)))
					for k in 3:
						_anim_vag(position + Vector2(randf_range(-22, 22), 0), 23, 4, 10.0, 0.34, 0)
					for i in 6:
						_pz_vag(position + Vector2(randf_range(-16, 16), -8), randi_range(0, 3), Vector2(randf_range(-80, 80), randf_range(-90, -40)), 0.25, 0.55)
				20:
					# se parte: congela un instante, destello blanco, chispa, pepitas y pedazos
					sprite.pause()
					get_tree().create_timer(0.09).timeout.connect(func():
						if is_instance_valid(sprite):
							sprite.play())
					if mat:
						mat.set_shader_parameter("destello", 0.9)
						create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 0.9, 0.0, 0.3)
					main.sacudir(5.0)
					_anim_vag(position + Vector2(0, -12), 19, 4, 14.0, 0.6, 3)
					for i in 10:
						_pz_vag(position + Vector2(randf_range(-12, 12), -10), randi_range(0, 6) if i % 2 == 0 else randi_range(11, 18), Vector2(randf_range(-100, 100), randf_range(-120, -50)), 0.25, 0.6)
					for i in 8:
						_destello_lin(position + Vector2(randf_range(-26, 26), randf_range(-24, -2)))
					for i in 4:
						_humo_vag(position + Vector2(randf_range(-16, 16), randf_range(-10, 0)))
					for i in 14:
						_chispa_lin(position + Vector2(randf_range(-6, 6), -12), Vector2(randf_range(-110, 110), randf_range(-130, -30)))
					_anillo_lin(position, 26.0)
					_luz_lin(position + Vector2(0, -10), Color(1.0, 0.85, 0.45), 1.2, 2.2, 0.6)
					for k in 3:
						_dest_eng(position + Vector2(randf_range(-20, 20), randf_range(-14, -4)), 11, 6, 14.0, 0.55, randf() < 0.5, 4)
					for i in 10:
						_humo_lin(position + Vector2(randf_range(-28, 28), randf_range(-14, 0)))
					for i in 10:
						_mota_lin(position + Vector2(randf_range(-26, 26), -randf_range(2, 20)), false)
					for i in 8:   # lluvia de pepitas que caen del aire
						_pz_vag(position + Vector2(randf_range(-30, 30), -60), randi_range(0, 3), Vector2(randf_range(-20, 20), randf_range(-20, 10)), 0.22, 0.7)

# Escupe una pepita de oro en arco hacia donde va a estar Diana.
func _escupir_lin(desvio := 0.0) -> void:
	var boca := _boca_lin() + Vector2(_lado_lin() * 4.0, 0)
	_dest_eng(boca + Vector2(_lado_lin() * 6.0, 0), 17, 5, 18.0, 0.5, _lado_lin() > 0.0)
	for i in 5:
		_chispa_lin(boca, Vector2(_lado_lin() * randf_range(30, 70), randf_range(-50, 10)))
	esfuerzo = _lado_lin() * -2.0
	_luz_lin(boca, Color(1.0, 0.75, 0.3), 0.5, 1.1, 0.25)
	Juego.sonido("disparo_enemigo", true, -6.0)
	var meta: Vector2 = objetivo.position
	if objetivo.get("vel") is Vector2:
		meta += (objetivo.vel as Vector2).limit_length(110.0) * 0.45
	meta = position + (meta - position).rotated(desvio)
	if not main.permitido(meta):
		meta = objetivo.position
	# si hay pared en el camino, cae justo antes de ella
	var ini_p := position
	for q in range(1, 21):
		var pq := ini_p.lerp(meta, q / 20.0)
		if not main.permitido(pq):
			meta = ini_p.lerp(meta, (q - 1) / 20.0)
			break
	var cuadros: Array = []
	for i in 6:
		cuadros.append(sprite.sprite_frames.get_frame_texture("dest", i))
	var tex: Texture2D = cuadros[0]
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * 0.45
	s.z_index = 3
	main.mundo.add_child(s)
	var luz_p := PointLight2D.new()   # la pepita alumbra el piso mientras vuela
	luz_p.texture = Fx.textura_luz()
	luz_p.texture_scale = 0.35 / s.scale.x
	luz_p.color = Color(1.0, 0.78, 0.35)
	luz_p.energy = 0.7
	s.add_child(luz_p)
	var sombra := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 8:
		pts.append((Vector2.from_angle(TAU * k / 8.0) * Vector2(4, 1.6)).round())
	sombra.polygon = pts
	sombra.color = Color(0, 0, 0, 0.35)
	sombra.z_index = -1
	main.mundo.add_child(sombra)
	var mundo_n: Node = main.mundo
	var principal = main
	var obj = objetivo
	var inicio := boca
	var piso0 := position.y
	var dur := clampf(inicio.distance_to(meta) / 190.0, 0.4, 0.95)
	var alto := 40.0 + inicio.distance_to(meta) * 0.15
	var n := [0]
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var base := Vector2(lerpf(inicio.x, meta.x, k), lerpf(piso0, meta.y, k))
		var y_aire := lerpf(inicio.y - piso0, 0.0, k) - sin(k * PI) * alto
		s.position = (base + Vector2(0, y_aire)).round()
		sombra.position = base.round()
		sombra.scale = Vector2.ONE * (1.0 - sin(k * PI) * 0.4)
		s.texture = cuadros[int(k * 18.0) % 6]   # gira cuadro por cuadro con su brillo
		luz_p.energy = 0.55 + 0.25 * sin(k * 40.0)
		sombra.color.a = 0.2 + 0.25 * (1.0 - sin(k * PI))   # la sombra se marca más cerca del piso
		n[0] += 1
		if n[0] % 2 == 0 and is_instance_valid(self):
			_chispa_lin(s.position, Vector2(randf_range(-20, 20), randf_range(-20, 10)))
		if n[0] % 4 == 0 and is_instance_valid(self):
			_dest_eng(s.position, 6, 5, 20.0, 0.4, false, 2)   # estela animada de polvo dorado
		if n[0] % 3 == 0:
			var e := Sprite2D.new()   # estela: brillitos dorados que se quedan atrás
			e.texture = tex
			e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			e.scale = Vector2.ONE * 0.25
			e.position = s.position
			e.modulate = Color(1.0, 0.85, 0.35, 0.55)
			e.z_index = 2
			mundo_n.add_child(e)
			var te := e.create_tween()
			te.tween_property(e, "modulate:a", 0.0, 0.2)
			te.tween_callback(e.queue_free), 0.0, 1.0, dur)
	tw.tween_callback(func():
		sombra.queue_free()
		s.queue_free()
		if is_instance_valid(obj) and obj.position.distance_to(meta) < 16.0:
			obj.herir(1, (meta - inicio).normalized())
		_romper_pepita_lin(mundo_n, principal, meta))

# La pepita choca en el piso: se agrieta y se deshace en polvo de oro, con chispa y granitos.
func _romper_pepita_lin(mundo_n: Node, principal, p: Vector2) -> void:
	if not is_instance_valid(self) or not is_instance_valid(sprite):
		return
	_dest_eng(p + Vector2(0, -6), 11, 6, 14.0, 0.55, randf() < 0.5, 3)
	_luz_lin(p + Vector2(0, -4), Color(1.0, 0.72, 0.28), 0.8, 1.6, 0.35)
	for i in 4:
		_humo_lin(p + Vector2(randf_range(-6, 6), randf_range(-4, 1)))
	_anillo_lin(p, 12.0)
	for i in 3:   # fragmentos que rebotan
		_pz_vag(p + Vector2(0, -3), randi_range(0, 2), Vector2(randf_range(-70, 70), randf_range(-90, -50)), 0.22, 0.45)
	for i in 6:
		_chispa_lin(p + Vector2(0, -3), Vector2(randf_range(-70, 70), randf_range(-90, -20)))
	for i in 3:
		_mota_lin(p + Vector2(randf_range(-6, 6), -2), false)
	_anim_vag(p + Vector2(0, -3), 19, 4, 18.0, 0.35, 3)
	_anim_vag(p + Vector2(0, 2), 23, 4, 12.0, 0.22, 0)
	principal.sacudir(1.0)
	for i in 6:
		_grano_lin(p + Vector2(randf_range(-3, 3), -2))
	for i in 2:
		_destello_lin(p + Vector2(randf_range(-8, 8), randf_range(-8, 0)))

# Granito de oro que salta y se asienta.
func _grano_lin(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.45, 0.7))
	s.color = [Color(0.85, 0.65, 0.2), Color(0.6, 0.45, 0.15), Color(0.45, 0.35, 0.2)].pick_random()
	s.position = p.round()
	s.z_index = 0
	main.mundo.add_child(s)
	var v := Vector2(randf_range(-45, 45), randf_range(-60, -20))
	var piso := p.y + randf_range(0, 3)
	var dur := randf_range(0.3, 0.45)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(p.y + v.y * tt + 260.0 * tt * tt, piso))), 0.0, 1.0, dur)
	tw.tween_interval(randf_range(0.3, 0.6))
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.tween_callback(s.queue_free)

# Destello retro de 4 puntas (cruz de pixel dorada) que aparece, crece y se apaga a saltos.
func _destello_lin(p: Vector2) -> void:
	if not is_instance_valid(sprite):
		return
	_dest_eng(p, 22, 5, 16.0, 0.35, false, 4)

func _golpe_lingote(desde: Vector2, critico: bool) -> void:
	var pg := position + Vector2(randf_range(-10, 10), -randf_range(14, 30))
	_anim_vag(pg, 19, 4, 18.0, 0.45 if critico else 0.32, 3)
	var lejos := signf(position.x - desde.x) if absf(position.x - desde.x) > 1.0 else 1.0
	lado_golpe_lin = lejos
	for i in (4 if critico else 2):
		_pz_vag(pg, randi_range(11, 18), Vector2(lejos * randf_range(30, 80), randf_range(-100, -50)), 0.22, 0.5)
	for i in 3:
		_destello_lin(pg + Vector2(randf_range(-8, 8), randf_range(-8, 8)))
	for i in 6:
		_grano_lin(pg)
	for i in (8 if critico else 5):
		_chispa_lin(pg, Vector2(lejos * randf_range(20, 80), randf_range(-80, 0)))
	empuje *= 0.5
	if mat:
		mat.set_shader_parameter("destello", 0.7)
		create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 0.7, 0.0, 0.18)
	_luz_lin(pg, Color(1.0, 0.8, 0.35), 0.55, 1.3, 0.25)
	_dest_eng(pg, 0 if critico else 22, 6 if critico else 5, 18.0, 0.4, randf() < 0.5, 4)
	for i in 3:
		_humo_lin(pg + Vector2(randf_range(-4, 4), randf_range(-3, 3)))
	for i in (3 if critico else 2):
		_pz_vag(pg, randi_range(0, 3), Vector2(lejos * randf_range(40, 90), randf_range(-110, -60)), 0.2, 0.5)
	for i in 3:
		_mota_lin(pg + Vector2(randf_range(-6, 6), randf_range(-4, 4)), false)
	main.sacudir(1.5 if critico else 0.8)

# Vida propia: destellos dorados que guiñan en el oro, granitos que se desprenden,
# y contorno dorado que late mientras carga el escupitajo.
func _ambiente_lin() -> void:
	if not vivo or not is_instance_valid(sprite):
		return
	var an := sprite.animation
	if mat and an != "dano":
		var c := 0.0
		if an == "ataque" and sprite.frame <= 11:
			c = 0.45 + 0.3 * sin(t * 22.0)
		mat.set_shader_parameter("contorno", c)
	if randf() < 0.1:
		_destello_lin(position + Vector2(randf_range(-20, 20), -randf_range(20, 38)))
	var luz := get_node_or_null("LuzLin") as PointLight2D
	if luz:
		var meta_l := 0.3 + 0.08 * sin(t * 3.0)
		if an == "ataque" and sprite.frame <= 11:
			meta_l = 0.6 + 0.25 * sin(t * 24.0)   # la luz crece mientras junta el escupitajo
		luz.energy = lerpf(luz.energy, meta_l, 0.4)
	if randf() < 0.3:
		_mota_lin(position + Vector2(randf_range(-22, 22), -randf_range(4, 30)), false)
	if vel.length() > 10.0 and randf() < 0.25:
		_grano_lin(position + Vector2(randf_range(-14, 14), -randf_range(16, 30)))

# Muerte: los pedazos se quedan, sueltan polvo dorado, guiñan y se apagan a saltos.
func _deshacer_lingote() -> void:
	z_index = -1
	var tw := create_tween()
	tw.tween_interval(1.2)
	for paso in 8:
		tw.tween_callback(func():
			esfuerzo = float(randi_range(-1, 1))
			for i in 3:
				_mota_lin(position + Vector2(randf_range(-24, 24), -randf_range(2, 12)), false)
			for i in 3:
				_grano_lin(position + Vector2(randf_range(-26, 26), -randf_range(2, 14)))
			if randf() < 0.7:
				_destello_lin(position + Vector2(randf_range(-26, 26), -randf_range(2, 16)))
			if paso % 3 == 0:
				_anim_vag(position + Vector2(randf_range(-20, 20), 0), 23, 4, 10.0, 0.26, 0)
			if paso % 2 == 0:
				var pl := position + Vector2(randf_range(-22, 22), -randf_range(4, 14))
				_luz_lin(pl, Color(1.0, 0.75, 0.3), 0.35, 0.8, 0.3)
				for i in 3:
					_chispa_lin(pl, Vector2(randf_range(-40, 40), randf_range(-60, -10)))
			_humo_lin(position + Vector2(randf_range(-22, 22), -randf_range(0, 8))))
		tw.tween_property(sprite, "modulate:a", 1.0 - (paso + 1) / 8.0, 0.0)
		tw.tween_interval(0.12)
	tw.tween_callback(func():
		_anillo_lin(position, 18.0)
		_anillo_lin(position, 14.0)
		for i in 8:
			_mota_lin(position + Vector2(randf_range(-22, 22), -randf_range(1, 8)), false)
		for i in 4:
			_humo_lin(position + Vector2(randf_range(-20, 20), -randf_range(0, 6))))
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

# Chispa dorada: punto redondo de pixel que sale disparado, cae, se enfría de amarillo a ocre y se apaga.
func _chispa_lin(p: Vector2, v: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.45, 0.8))
	s.color = [Color(1.0, 0.9, 0.5), Color(1.0, 0.75, 0.25), Color(0.95, 0.6, 0.15)].pick_random()
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var piso := position.y + randf_range(-2, 4)
	var dur := randf_range(0.3, 0.5)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(minf(p.y + v.y * tt + 240.0 * tt * tt, piso)))
		s.color = s.color.lerp(Color(0.55, 0.35, 0.1), k * 0.06)
		s.modulate.a = 1.0 - k * k, 0.0, 1.0, dur)
	tw.tween_callback(s.queue_free)

# Mota de polvo de oro que sube meciéndose y parpadea (aura del lingote).
func _mota_lin(p: Vector2, hacia_boca: bool) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.4, 0.7))
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var dur := randf_range(0.7, 1.2)
	var fase := randf() * TAU
	var meta := _boca_lin() if hacia_boca else p + Vector2(randf_range(-4, 4), -randf_range(14, 26))
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var pos := p.lerp(meta, k) + Vector2(sin(fase + k * 8.0) * 2.0, 0)
		s.position = pos.round()
		var col := Color(1.0, 0.9, 0.5).lerp(Color(0.85, 0.55, 0.15), k)
		col.a = (1.0 - k * k) * (0.5 + 0.5 * absf(sin(k * 24.0 + fase)))
		s.color = col, 0.0, 1.0, dur)
	tw.tween_callback(s.queue_free)

# Aviso en el piso donde caerá la pepita: rombo dorado de pixel que se cierra.
func _aviso_lin(p: Vector2) -> void:
	var ln := Line2D.new()
	ln.width = 1.0
	ln.default_color = Color(1.0, 0.8, 0.3, 0.8)
	ln.closed = true
	for q in [Vector2(-6, 0), Vector2(0, -2.5), Vector2(6, 0), Vector2(0, 2.5)]:
		ln.add_point(q)
	ln.position = p.round()
	ln.z_index = -1
	ln.modulate.a = 0.0
	main.mundo.add_child(ln)
	ln.scale = Vector2.ONE * 1.8
	var tw := ln.create_tween()
	tw.tween_property(ln, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(ln, "scale", Vector2.ONE * 0.9, 0.6)
	tw.tween_property(ln, "modulate:a", 0.0, 0.15)
	tw.tween_callback(ln.queue_free)

# Onda dorada en el piso al chocar.
func _anillo_lin(p: Vector2, r: float) -> void:
	var n := int(6 + r * 0.25)
	for k in n:
		var a := TAU * k / n + randf() * 0.3
		var d := Vector2.from_angle(a) * Vector2(1, 0.4)
		_humo_lin(p + d * 3.0, p + d * r)

# Destello de luz cálida que se apaga (ilumina el piso y a Diana; no es brillo aditivo del sprite).
func _luz_lin(p: Vector2, col: Color, escala: float, energia: float, dur: float) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.textura_luz()
	l.texture_scale = escala
	l.color = col
	l.energy = energia
	l.position = p.round()
	main.mundo.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, dur).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)

# Bocanada de polvo dorado-café redonda que sube y se deshace (tapa la orilla del estallido).
func _humo_lin(p: Vector2, hasta := Vector2.INF) -> void:
	var s := Polygon2D.new()
	var r := randf_range(1.2, 2.0)
	var pts := PackedVector2Array()
	for k in 14:
		pts.append(Vector2.from_angle(TAU * k / 14.0) * r)
	s.polygon = pts
	s.color = [Color(0.6, 0.5, 0.3), Color(0.52, 0.43, 0.27), Color(0.68, 0.58, 0.36)].pick_random()
	s.color.a = randf_range(0.28, 0.42)
	s.position = p.round()
	s.z_index = 2
	main.mundo.add_child(s)
	var meta := hasta if hasta != Vector2.INF else s.position + Vector2(randf_range(-9, 9), -randf_range(4, 9))
	var dur := randf_range(0.5, 0.8)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position", meta.round(), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "scale", Vector2.ONE * randf_range(1.6, 2.2), dur)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)

# Peso del cuerpo cuadro por cuadro, en pixeles enteros (sin estirar ni girar el sprite de Gemini):
# al caminar se hunde al apoyar la bota y sube al pasar la pierna; al cargar se agacha y tiembla,
# al escupir da un culatazo hacia atrás; al recibir daño se sacude hacia atrás; al morir tiembla y se rinde.
func _alto_lin() -> float:
	if not is_instance_valid(sprite):
		return 0.0
	var f := sprite.frame
	match sprite.animation:
		"mover":
			if vel.length() < 6.0:
				return 0.0
			if f == 0 or f == 6:
				return 1.0
			if f == 3 or f == 9:
				return -1.0
			return 0.0
		"ataque":
			if f >= 2 and f <= 9:
				esfuerzo = float(randi_range(-1, 1)) * (1.0 if f >= 6 else 0.5)
				return 1.0
			if f >= 11 and f <= 13:
				esfuerzo = -_lado_lin() * (3.0 - float(f - 11))
				return -1.0 if f == 11 else 0.0
			return 0.0
		"dano":
			if f <= 3:
				esfuerzo = lado_golpe_lin * (3.0 - float(f)) + float(randi_range(-1, 1))
				return -1.0 if f <= 1 else 0.0
			return 0.0
		"pulir":
			if f >= 4 and f <= 12:
				esfuerzo = float(randi_range(-1, 1))
			if f >= 4 and f <= 6:
				return 1.0   # las rodillas se le doblan
			return 0.0
	return 0.0

# ---- Brillito: cristal de cuarzo rosa que flota girando; dispara sus púas; muere partiéndose ----
# bri5_dest: 0-5 púa girando, 6-9 estela, 10-16 impacto, 17-21 destello.  bri5_fx: 0-26 astillas rosas
const CENTRO_BRI := Vector2(0, -22)
var disparo_bri := false
var tanda_bri := 0
var orbita_bri := 0.0
var giro_bri_t := 2.5

func _preparar_brillito() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_mat_bri")
	var tm := Timer.new()
	tm.wait_time = 0.08
	tm.autostart = true
	tm.timeout.connect(_ambiente_bri)
	add_child(tm)
	sprite.frame_changed.connect(_cuadro_bri)
	sprite.animation_changed.connect(func():
		if sprite.animation == "ataque":
			disparo_bri = false)
	var luz := PointLight2D.new()
	luz.name = "LuzBri"
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.55
	luz.color = Color(1.0, 0.55, 0.75)
	luz.energy = 0.25
	luz.position = CENTRO_BRI
	add_child(luz)

func _mat_bri() -> void:
	if mat:
		mat.set_shader_parameter("realce", 1.1)
		mat.set_shader_parameter("volumen", 0.2)
		mat.set_shader_parameter("brillo_ojos", 0.0)
		mat.set_shader_parameter("color_contorno", Vector3(1.0, 0.45, 0.7))

func _centro_bri() -> Vector2:
	return position + Vector2(0, sprite.position.y) + CENTRO_BRI

# IA: flota a media distancia rodeando a Diana; alterna ráfaga de 3 púas apuntadas y corona de 8.
func _ia_bri(hacia: Vector2, dir: Vector2) -> Vector2:
	if anim_t > 0.0 and sprite.animation == "ataque":
		return Vector2.ZERO
	var d := hacia.length()
	if cd_ataque <= 0.0 and d < 240.0:
		cd_ataque = randf_range(2.6, 3.4)
		especial("ataque")
		return Vector2.ZERO
	if d < 90.0:
		return -dir
	if d < 170.0:
		return Vector2(-dir.y, dir.x) * (1.0 if personalidad > 1.0 else -1.0) * 0.8
	return dir

# Altura de vuelo en pixeles enteros: flota subiendo y bajando; al morir cae al piso.
func _alto_bri() -> float:
	if not is_instance_valid(sprite):
		return -14.0
	sprite.speed_scale = 1.0   # el giro va siempre parejo (no se frena ni se traba al detenerse)
	# la cara del ataque y del daño está dibujada mirando a la izquierda: se voltea para quedar frente a Diana;
	# al flotar no se voltea (si no, el giro cambiaría de sentido)
	if sprite.animation in ["ataque", "dano"] and is_instance_valid(objetivo):
		sprite.flip_h = objetivo.position.x > position.x
	elif sprite.animation == "mover":
		sprite.flip_h = false
	if sprite.animation == "pulir":
		var f := sprite.frame
		if f <= 13:
			return -14.0
		if f == 14:
			return -9.0
		if f == 15:
			return -4.0
		return 0.0
	if sprite.animation == "ataque" and sprite.frame >= 3 and sprite.frame <= 9:
		esfuerzo = float(randi_range(-1, 1))
	if sprite.animation == "dano" and sprite.frame <= 2:
		esfuerzo = float(randi_range(-2, 2))
	return roundf(-14.0 + sin(t * 3.0 * personalidad) * 3.0)

func _cuadro_bri() -> void:
	if not is_instance_valid(sprite):
		return
	var f := sprite.frame
	var c := _centro_bri()
	match sprite.animation:
		"gira":
			if f % 2 == 0:
				_mota_bri(c + Vector2(randf_range(-18, 18), randf_range(-14, 14)), Vector2.INF)
				_dest_eng(c + Vector2.from_angle(randf() * TAU) * 18.0, 17, 5, 22.0, 0.3, false, 4)
		"mover":
			if randf() < 0.18:
				_dest_eng(c + Vector2.from_angle(randf() * TAU) * randf_range(16, 20), 17, 5, 20.0, 0.3, false, 4)   # punta de púa que guiña
			if f % 2 == 0:
				_dest_eng(c + Vector2(randf_range(-16, 16), randf_range(-14, 14)), 17, 5, 18.0, 0.35, false, 4)
		"ataque":
			if f >= 2 and f <= 9:
				for i in 3:
					_mota_bri(c + Vector2.from_angle(randf() * TAU) * randf_range(24, 34), c)   # junta energía
				_eco_bri(Color(1.0, 0.35, 0.6, 0.3))
				main.sacudir(0.2 + f * 0.06)
				if f % 4 == 0:
					_dest_eng(c + Vector2.from_angle(randf() * TAU) * 20.0, 17, 5, 20.0, 0.3, false, 4)
			if f == 5:
				main.sacudir(0.8)
				if mat:
					mat.set_shader_parameter("destello", 0.25)
					create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 0.25, 0.0, 0.12)
			if f == 10 and not disparo_bri:
				disparo_bri = true
				_disparar_bri()
			if f == 14:
				for i in 8:   # le vuelven a brotar las púas
					_dest_eng(c + Vector2.from_angle(TAU * i / 8.0) * 16.0, 17, 5, 22.0, 0.3, false, 4)
		"dano":
			if f == 1:
				_dest_eng(c, 10, 7, 20.0, 0.35, randf() < 0.5, 4)
		"pulir":
			# ya muerto no se recalcula la altura: el cuerpo baja él solo hasta el piso
			# y los restos quedan justo sobre su sombra (antes se quedaban flotando arriba)
			if f <= 13:
				sprite.position.y = minf(sprite.position.y, -14.0) if f == 0 else sprite.position.y
			elif f == 14:
				sprite.position.y = -9.0
			elif f == 15:
				sprite.position.y = -4.0
			else:
				sprite.position.y = 4.0
			if f >= 16:
				z_index = -1
			match f:
				3, 6:
					main.sacudir(1.0)
					_astillas_bri(c, 4, 0.8)
					_dest_eng(c + Vector2(randf_range(-8, 8), -10), 17, 5, 18.0, 0.4, false, 4)
				8:
					_astillas_bri(c, 5, 1.0)
					for i in 6:
						_chispa_bri(c + Vector2(0, randf_range(-14, 14)), Vector2([-1.0, 1.0].pick_random() * randf_range(30, 80), randf_range(-60, 10)))
				10:
					# se parte: congela un instante, destello blanco, estallido de cristal
					sprite.pause()
					get_tree().create_timer(0.09).timeout.connect(func():
						if is_instance_valid(sprite):
							sprite.play())
					if mat:
						mat.set_shader_parameter("destello", 1.0)
						create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 1.0, 0.0, 0.3)
					main.sacudir(4.0)
					Juego.sonido("golpe", false, -6.0)
					_luz_bri(c, 1.2, 2.2, 0.5)
					for k in 3:
						_dest_eng(c + Vector2(randf_range(-14, 14), randf_range(-10, 10)), 10, 7, 14.0, 0.5, randf() < 0.5, 4)
					_astillas_bri(c, 10, 1.4)
					for i in 14:
						_chispa_bri(c, Vector2.from_angle(randf() * TAU) * randf_range(40, 110))
					for i in 10:
						_mota_bri(c + Vector2(randf_range(-20, 20), randf_range(-20, 20)), Vector2.INF)
				16:
					# los pedazos pegan en el piso
					main.sacudir(2.5)
					_luz_bri(position, 0.8, 1.2, 0.35)
					_dest_eng(position + Vector2(0, -4), 10, 7, 16.0, 0.45, false, 3)
					for i in 8:
						_humo_bri(position + Vector2(randf_range(-26, 26), randf_range(-4, 1)))
					_astillas_bri(position + Vector2(0, -4), 6, 0.8)

# Dispara púas que vuelan girando: una tanda apuntada (3 en abanico) y la siguiente en corona (8).
func _disparar_bri() -> void:
	var c := _centro_bri()
	Juego.sonido("disparo_enemigo", true, -6.0)
	_luz_bri(c, 0.7, 1.4, 0.3)
	main.sacudir(1.2)
	var al_objetivo: Vector2 = (objetivo.position + Vector2(0, -10) - c).normalized()
	var dirs: Array = []
	if tanda_bri % 2 == 0:
		for k in [-1, 0, 1]:
			dirs.append(al_objetivo.rotated(k * 0.22))
	else:
		for k in 8:
			dirs.append(Vector2.from_angle(TAU * k / 8.0))
	tanda_bri += 1
	for i in 16:
		var a := TAU * i / 16.0
		_mota_bri(c + Vector2.from_angle(a) * 6.0, c + Vector2.from_angle(a) * Vector2(34, 22))
	for i in 10:
		_chispa_bri(c, Vector2.from_angle(randf() * TAU) * randf_range(60, 120))
	if mat:
		mat.set_shader_parameter("destello", 0.4)
		create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 0.4, 0.0, 0.15)
	if dirs.size() == 3:   # la ráfaga apuntada se repite enseguida: más presión sobre Diana
		get_tree().create_timer(0.28).timeout.connect(func():
			if is_instance_valid(self) and vivo and is_instance_valid(objetivo):
				var c2 := _centro_bri()
				var ao: Vector2 = (objetivo.position + Vector2(0, -10) - c2).normalized()
				for k in [-0.3, 0.0, 0.3]:
					_pua_bri(c2 + ao.rotated(k) * 14.0, ao.rotated(k)))
	for d in dirs:
		_pua_bri(c + d * 14.0, d)
		_dest_eng(c + d * 16.0, 17, 5, 22.0, 0.45, false, 4)
		for i in 3:
			_chispa_bri(c + d * 14.0, d * randf_range(40, 90) + Vector2(randf_range(-20, 20), randf_range(-20, 20)))

func _pua_bri(p: Vector2, d: Vector2) -> void:
	var cuadros: Array = []
	for i in 6:
		cuadros.append(sprite.sprite_frames.get_frame_texture("dest", i))
	var s := Sprite2D.new()
	s.texture = cuadros[0]
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * 0.5
	s.rotation = snappedf(d.angle(), PI / 4.0)
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.3 / s.scale.x
	luz.color = Color(1.0, 0.55, 0.75)
	luz.energy = 0.4
	s.add_child(luz)
	var sombra := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 8:
		pts.append((Vector2.from_angle(TAU * k / 8.0) * Vector2(3, 1.2)).round())
	sombra.polygon = pts
	sombra.color = Color(0, 0, 0, 0.3)
	sombra.z_index = -1
	main.mundo.add_child(sombra)
	var principal = main
	var obj = objetivo
	var alto_aire: float = position.y - p.y
	var dist := 0.0
	var paso := [0]
	var vel_p := 170.0
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		if not is_instance_valid(s):
			return
		var nueva := p + d * vel_p * k * 1.6
		var piso := Vector2(nueva.x, nueva.y + alto_aire)
		paso[0] += 1
		s.texture = cuadros[paso[0] / 2 % 6]
		luz.energy = 0.35 + 0.15 * sin(paso[0] * 0.8)
		if not principal.permitido(piso) or (is_instance_valid(obj) and obj.position.distance_to(piso) < 12.0):
			if is_instance_valid(obj) and obj.position.distance_to(piso) < 12.0:
				obj.herir(1, d)
			if is_instance_valid(self):
				_choque_pua_bri(s.position, piso)
			sombra.queue_free()
			s.queue_free()
			return
		s.position = nueva.round()
		sombra.position = piso.round()
		if paso[0] % 3 == 0 and is_instance_valid(self):
			_dest_eng(s.position - d * 6.0, 6, 4, 18.0, 0.4, d.x < 0.0, 2)
		if paso[0] % 2 == 1:
			var e := Sprite2D.new()   # eco rosa de la púa que se queda atrás
			e.texture = s.texture
			e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			e.scale = s.scale
			e.rotation = s.rotation
			e.position = s.position
			e.modulate = Color(1.0, 0.55, 0.8, 0.45)
			e.z_index = 2
			s.get_parent().add_child(e)
			var te := e.create_tween()
			te.tween_property(e, "modulate:a", 0.0, 0.16)
			te.tween_callback(e.queue_free)
		if paso[0] % 5 == 0 and is_instance_valid(self):
			_dest_eng(s.position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 17, 5, 24.0, 0.25, false, 4)
		if paso[0] % 2 == 0 and is_instance_valid(self):
			_chispa_bri(s.position, -d * 20.0 + Vector2(randf_range(-10, 10), randf_range(-10, 10))), 0.0, 1.0, 1.6)
	tw.tween_callback(func():
		if is_instance_valid(s):
			if is_instance_valid(self):
				_choque_pua_bri(s.position, s.position + Vector2(0, alto_aire))
			s.queue_free()
		if is_instance_valid(sombra):
			sombra.queue_free())

func _choque_pua_bri(p: Vector2, piso: Vector2) -> void:
	_dest_eng(p, 10, 7, 18.0, 0.5, randf() < 0.5, 4)
	_dest_eng(p + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 17, 5, 22.0, 0.4, false, 4)
	for i in 6:
		_mota_bri(p + Vector2.from_angle(TAU * i / 6.0) * 3.0, p + Vector2.from_angle(TAU * i / 6.0) * 14.0)
	_luz_bri(p, 0.5, 1.2, 0.25)
	_astillas_bri(p, 3, 0.6)
	for i in 5:
		_chispa_bri(p, Vector2.from_angle(randf() * TAU) * randf_range(30, 70))
	for i in 2:
		_humo_bri(piso + Vector2(randf_range(-4, 4), 0))
	var cl := Sprite2D.new()   # astilla clavada en el piso
	cl.texture = sprite.sprite_frames.get_frame_texture("fx", randi_range(0, 26))
	cl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cl.scale = Vector2.ONE * 0.4
	cl.position = piso.round()
	cl.z_index = 0
	main.mundo.add_child(cl)
	var tc := cl.create_tween()
	tc.tween_interval(0.8)
	tc.tween_property(cl, "modulate:a", 0.0, 0.5)
	tc.tween_callback(cl.queue_free)

func _astillas_bri(p: Vector2, n: int, fuerza: float) -> void:
	for i in n:
		_pz_vag(p + Vector2(randf_range(-6, 6), randf_range(-6, 6)), randi_range(0, 26), Vector2(randf_range(-80, 80), randf_range(-110, -40)) * fuerza, 0.35, 0.55)

func _golpe_brillito(desde: Vector2, critico: bool) -> void:
	var c := _centro_bri() + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	var lejos := signf(position.x - desde.x) if absf(position.x - desde.x) > 1.0 else 1.0
	_dest_eng(c, 10, 7, 20.0, 0.45 if critico else 0.35, lejos < 0.0, 4)
	_luz_bri(c, 0.5, 1.3, 0.25)
	if mat:
		mat.set_shader_parameter("destello", 0.7)
		create_tween().tween_method(func(v): if mat: mat.set_shader_parameter("destello", v), 0.7, 0.0, 0.18)
	_astillas_bri(c, 4 if critico else 2, 0.8)
	for i in (8 if critico else 5):
		_chispa_bri(c, Vector2(lejos * randf_range(20, 80), randf_range(-80, 20)))
	main.sacudir(1.2 if critico else 0.6)

# Vida propia: destellos rosas en las púas, motas que caen, luz que respira (más fuerte al cargar).
func _ambiente_bri() -> void:
	if not vivo or not is_instance_valid(sprite):
		return
	var an := sprite.animation
	var c := _centro_bri()
	if mat and an != "dano":
		var k := 0.0
		if an == "ataque" and sprite.frame <= 10:
			k = 0.45 + 0.3 * sin(t * 24.0)
		mat.set_shader_parameter("contorno", k)
	var luz := get_node_or_null("LuzBri") as PointLight2D
	if luz:
		luz.position = Vector2(0, sprite.position.y) + CENTRO_BRI
		var meta_l := 0.22 + 0.06 * sin(t * 3.0)
		if an == "ataque" and sprite.frame <= 10:
			meta_l = 0.32 + 0.1 * sin(t * 24.0)
		luz.energy = lerpf(luz.energy, meta_l, 0.4)
	if randf() < 0.5:
		_mota_bri(c + Vector2(randf_range(-14, 14), randf_range(-8, 14)), Vector2.INF)
	if vel.length() > 15.0 and an == "mover" and randf() < 0.6:
		_eco_bri(Color(1.0, 0.5, 0.75, 0.35))
	orbita_bri += 0.5
	for k in 3:   # tres chispas que orbitan alrededor del cristal
		var a := orbita_bri + TAU * k / 3.0
		_chispa_fija_bri(c + Vector2(cos(a) * 24.0, sin(a) * 10.0))
	if randf() < 0.06:
		_luz_bri(c + Vector2(randf_range(-12, 12), randf_range(-12, 12)), 0.25, 0.6, 0.25)

func _luz_bri(p: Vector2, escala: float, energia: float, dur: float) -> void:
	var l := PointLight2D.new()
	l.texture = Fx.textura_luz()
	l.texture_scale = escala
	l.color = Color(1.0, 0.6, 0.8)
	l.energy = energia * 0.7
	l.position = p.round()
	main.mundo.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, dur).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)

# Chispa rosa: punto redondo que sale disparado, cae y se enfría a malva.
func _chispa_bri(p: Vector2, v: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.45, 0.8))
	s.color = [Color(1.0, 0.8, 0.9), Color(1.0, 0.6, 0.8), Color(0.9, 0.5, 0.7)].pick_random()
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var dur := randf_range(0.3, 0.5)
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		var tt := k * dur
		s.position = Vector2(roundf(p.x + v.x * tt), roundf(p.y + v.y * tt + 160.0 * tt * tt))
		s.color = s.color.lerp(Color(0.5, 0.25, 0.4), k * 0.06)
		s.modulate.a = 1.0 - k * k, 0.0, 1.0, dur)
	tw.tween_callback(s.queue_free)

# Mota rosa que cae flotando y parpadea; si se da 'hacia', viaja hacia ese punto (junta energía).
func _mota_bri(p: Vector2, hacia: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(randf_range(0.4, 0.7))
	s.position = p.round()
	s.z_index = 3
	main.mundo.add_child(s)
	var dur := randf_range(0.6, 1.0)
	var fase := randf() * TAU
	var meta := hacia if hacia != Vector2.INF else p + Vector2(randf_range(-4, 4), randf_range(10, 18))
	var tw := s.create_tween()
	tw.tween_method(func(k: float):
		s.position = (p.lerp(meta, k) + Vector2(sin(fase + k * 8.0) * 1.5, 0)).round()
		var col := Color(1.0, 0.85, 0.92).lerp(Color(0.85, 0.45, 0.65), k)
		col.a = (1.0 - k * k) * (0.5 + 0.5 * absf(sin(k * 24.0 + fase)))
		s.color = col, 0.0, 1.0, dur)
	tw.tween_callback(s.queue_free)

# Polvo rosa-malva redondo y tenue que se extiende y se deshace.
func _humo_bri(p: Vector2) -> void:
	var s := Polygon2D.new()
	var r := randf_range(1.2, 2.0)
	var pts := PackedVector2Array()
	for k in 14:
		pts.append(Vector2.from_angle(TAU * k / 14.0) * r)
	s.polygon = pts
	s.color = [Color(0.75, 0.55, 0.65), Color(0.6, 0.45, 0.55)].pick_random()
	s.color.a = randf_range(0.28, 0.4)
	s.position = p.round()
	s.z_index = 2
	main.mundo.add_child(s)
	var dur := randf_range(0.5, 0.8)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "position", (s.position + Vector2(randf_range(-10, 10), -randf_range(3, 8))).round(), dur)
	tw.tween_property(s, "scale", Vector2.ONE * randf_range(1.6, 2.2), dur)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)

# Muerte: los pedazos se quedan, guiñan y sueltan motas, y se apagan a saltos.
func _deshacer_brillito() -> void:
	z_index = -1
	var tw := create_tween()
	tw.tween_interval(1.2)
	for paso in 8:
		tw.tween_callback(func():
			esfuerzo = float(randi_range(-1, 1))
			for i in 2:
				_mota_bri(position + Vector2(randf_range(-24, 24), -randf_range(2, 10)), Vector2.INF)
			if paso % 2 == 0:
				var pl := position + Vector2(randf_range(-22, 22), -randf_range(2, 10))
				_dest_eng(pl, 17, 5, 18.0, 0.3, false, 3)
				_luz_bri(pl, 0.3, 0.7, 0.3)
			if paso % 3 == 0:
				_humo_bri(position + Vector2(randf_range(-20, 20), 0)))
		tw.tween_property(sprite, "modulate:a", 1.0 - (paso + 1) / 8.0, 0.0)
		tw.tween_interval(0.12)
	tw.tween_callback(func():
		for i in 6:
			_humo_bri(position + Vector2(randf_range(-20, 20), 0))
		for i in 6:
			_mota_bri(position + Vector2(randf_range(-20, 20), -randf_range(1, 6)), Vector2.INF))
	tw.tween_interval(0.5)
	tw.tween_callback(queue_free)

# Copia del cuadro actual que se queda atrás y se apaga (estela de cristal).
func _eco_bri(col: Color) -> void:
	var e := Sprite2D.new()
	e.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	e.centered = sprite.centered
	e.offset = sprite.offset
	e.flip_h = sprite.flip_h
	e.scale = sprite.scale
	e.global_position = sprite.global_position.round()
	e.modulate = col
	e.z_index = z_index - 1
	main.mundo.add_child(e)
	var tw := e.create_tween()
	tw.tween_property(e, "modulate:a", 0.0, 0.22)
	tw.tween_callback(e.queue_free)

# Punto de luz rosa que dura un instante (las chispas que orbitan se dibujan con esto).
func _chispa_fija_bri(p: Vector2) -> void:
	var s := Polygon2D.new()
	s.polygon = _gota_pts_vag(0.6)
	s.color = Color(0.95, 0.7, 0.85, 0.6)
	s.position = p.round()
	s.z_index = 4 if sin(orbita_bri) > 0.0 else 0
	main.mundo.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.12)
	tw.tween_callback(s.queue_free)


# Segunda fase de los jefes de la mina y el taller: ruge, tiembla la pantalla, se tiñe de rojo,
# se pone furioso (más rápido) y llama refuerzos.
func _entrar_furia() -> void:
	furia = true
	main.sacudir(9.0)
	main.mensaje("¡%s se enfurece!" % main.NIVEL_DATOS[main.nivel].jefe_nombre, 2.0)
	Juego.sonido("oleada", false)
	Fx.estallido(main.mundo, position + Vector2(0, -alto * 0.5), Color(1.0, 0.35, 0.2))
	Fx.chispas(main.mundo, position + Vector2(0, -alto * 0.5), Color(1.0, 0.5, 0.2), 24)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.6, 0.6, 0.5), 0.15)
	tw.tween_property(sprite, "modulate", Color(1.15, 0.85, 0.8), 0.5)
	var refuerzo := "murcielago" if tipo == "golem" else "engrane"
	for i in 3:
		var a := TAU * i / 3.0
		main.aparecer_ya(refuerzo, position + Vector2(cos(a), sin(a)) * 70.0)
