# Diana: se mueve con WASD/flechas, apunta con el mouse y usa su arma.
# Q cambia de objeto, F recoge objetos, abre cofres o aparta; Shift o clic derecho
# esquiva con un impulso corto (se vuelve "Impulso de luz" al vencer al Vendedor de Humo).
extends Node2D

const VELOCIDAD := 140.0
const ACELERACION := 1100.0
const FRENADO := 1300.0
const IMPULSO_VEL := 340.0
const IMPULSO_DURA := 0.13
const RECARGA_IMPULSO := 0.8
const CARGAS_ESPRINT := 2      # esquives guardados como máximo
const RECUPERA_ESPRINT := 3.5  # segundos para recuperar uno

var aura_puesta := false   # el contorno de curar/energía está encendido
var main
# Vida en medios corazones: 6 = 3 corazones. Cada golpe quita medio corazón.
var vida := 6
var vida_max := 6
var energia := 100.0
var energia_max := 100.0
var sprite: AnimatedSprite2D
var recarga := 0.0
var invulnerable := 0.0
var mirando := Vector2.RIGHT
var paso := 0.0
var polvo_t := 0.0

# Inventario de dos armas; "actual" es el índice de la que trae en la mano.
var armas: Array = []  # empieza sin objeto: lo escoge en el mostrador del inicio
var actual := 0
var mano: Node2D
var _q := false
var _f := false
var vel := Vector2.ZERO
var impulso_t := 0.0       # tiempo que le queda al impulso
var impulso_cd := 0.0      # recarga del esquive
var impulso_dir := Vector2.RIGHT
var fantasma_t := 0.0
var aplastar := Vector2.ONE  # estirar/aplastar al arrancar, frenar o recibir golpe
var respira := 0.0
var polvo_giro := 0.0
var andaba := false
var cargas := float(CARGAS_ESPRINT)
var impulso_luz := false     # mejora del esquive (Anillo Alborada)
var sin_usar := 0.0
var _shift := false
var fiesta_t := 0.0          # dura la animación de festejar
var accion := ""             # animación de un solo uso: disparar, barrer, dano o esquivar
var accion_t := 0.0
var accion_dur := 0.0
var pendiente := ""          # animación de tomar/curar/energía pedida caminando: sale al detenerse
var pendiente_t := 0.0
var pide_mover := false     # hay tecla de movimiento presionada
var otro_tiro := false       # disparo pedido a media animación: se reproduce al terminar el retroceso
var tiro_corriendo := 0.0   # tras disparar corriendo, usa la caminata de combate

func _ready() -> void:
	sprite = Anim.sprite({
		"caminar": ["diana_walk", 9, true],
		"caminar_disp": ["diana_walk_disp", 11, true],
		"reposo": ["diana_idle", 3, true],
		"reposo_disp": ["diana_idle_disp", 3, true],
		"parpadeo": ["diana_parpadeo", 10, false],
		"relajar": ["diana_relajar", 8, false],
		"derrota": ["diana_ko", 8, false],
		"festejar": ["diana_fest", 10, false],
		"disparar": ["diana_disp", 12, false],
		"barrer": ["diana_barr", 16, false],
		"dano": ["diana_dano", 14, false],
		"tomar": ["diana_tomar", 12, false],
		"curar": ["diana_curar", 8, false],
		"energia": ["diana_energia", 8, false],
		"esquivar": ["diana_esq", 16, false],
	}, "reposo")
	sprite.scale = Vector2(0.25, 0.25)  # desde el inicio (en pausa/diálogo no corre el ajuste por cuadro)
	add_child(sprite)
	sprite.frame_changed.connect(_brillo_lupa)
	Fx.sombra(self, 26.0)
	mano = Mano.new()
	mano.position = Vector2(0, -20)
	mano.visible = false  # empieza sin objeto
	add_child(mano)
	var luz := PointLight2D.new()
	luz.texture = Fx.textura_luz()
	# Luz tenue y cálida alrededor (como un brillo de su broche), no un reflector.
	luz.texture_scale = 1.6
	luz.energy = 0.7
	luz.color = Color(1.0, 0.86, 0.7)
	luz.position = Vector2(0, -16)
	add_child(luz)
	# Diana se integra a la escena: más oscura hacia los pies y con un contorno de luz fría
	# del lado de arriba, como si la alumbrara el cuarto y no un recorte pegado.
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 aura = vec4(0.4, 0.7, 1.0, 0.0);   // contorno de energía (alfa = fuerza)
uniform float banda = -1.0;                      // franja de luz que sube (0 pies, 1 cabeza)
uniform float cuadros = 1.0;                     // cuadros de la tira actual
uniform float meneo = 0.0;                       // desplazamiento del cabello, en pixeles del dibujo
bool es_pelo(vec4 p) { return p.a > 0.5 && dot(p.rgb, vec3(0.33)) < 0.3 && p.b >= p.r - 0.02; }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Puntas del cabello de la espalda: se mecen pixel a pixel (mas abajo, mas se mueven).
	float lx = fract(UV.x * cuadros);
	if (meneo != 0.0 && lx < 0.42 && UV.y > 0.45 && UV.y < 0.97) {
		float k = (UV.y - 0.45) / 0.52;
		float dx = floor(meneo * k + 0.5) * TEXTURE_PIXEL_SIZE.x * 4.0;
		vec4 d = texture(TEXTURE, UV - vec2(dx, 0.0));
		if (c.a < 0.5 || es_pelo(c)) {
			c = es_pelo(d) ? d : (c.a < 0.5 ? c : vec4(0.0));
		}
	}
	float y = clamp((UV.y - region.y) / region.w, 0.0, 1.0);
	c.rgb *= mix(1.0, 0.95, smoothstep(0.6, 1.0, y));
	// Atmósfera sombría: colores más apagados, un poco más oscura y fría, sombras hondas.
	float lu = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, vec3(lu), 0.18);
	vec2 px = TEXTURE_PIXEL_SIZE * 4.0;
	float arriba = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	if (c.a > 0.5 && arriba < 0.5) { c.rgb += vec3(0.07, 0.09, 0.13); }
	if (c.a > 0.5 && aura.a > 0.0) {
		// Orilla de la silueta: se enciende con la energía (recortada a su forma).
		float o = min(min(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
			min(texture(TEXTURE, UV + vec2(0.0, px.y)).a, arriba));
		if (o < 0.5) { c.rgb = mix(c.rgb, aura.rgb * 1.3, aura.a); }
		// Franja que la recorre por dentro, de los pies a la cabeza.
		float d = abs((1.0 - y) - banda);
		c.rgb += aura.rgb * aura.a * 0.6 * (1.0 - smoothstep(0.0, 0.09, d));
	}
	COLOR = c;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	sprite.material = mat
	impulso_luz = Juego.has_meta("impulso_luz")

func arma() -> String:
	return armas[actual] if armas.size() > 0 else ""

# Modo captura (prueba): F8 lo activa; al esquivar se congela en el cuadro del impulso. F9 sigue.
var foto := false
var _f8 := false
var _f9 := false
var _congelado := false
var _foto_hecha := false   # una sola congelada por esquive

var aviso_f: Label
var aviso_t := 0.0

func _process(delta: float) -> void:
	# "F" flotando sobre Diana cuando hay algo que recoger o usar cerca.
	aviso_t -= delta
	if aviso_t <= 0.0 and main != null:
		aviso_t = 0.1
		if aviso_f == null:
			aviso_f = Label.new()
			aviso_f.text = "F"
			aviso_f.add_theme_font_size_override("font_size", 10)
			aviso_f.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
			aviso_f.add_theme_color_override("font_outline_color", Color.BLACK)
			aviso_f.add_theme_constant_override("outline_size", 3)
			aviso_f.position = Vector2(-3, -62)
			aviso_f.z_index = 40
			add_child(aviso_f)
		var hay: bool = _cercano() != null or (main.room_id == "apartado" and main.MOSTRADOR.grow(52).has_point(position))
		aviso_f.visible = hay and not main.fin
	if aviso_f != null and aviso_f.visible:
		aviso_f.position.y = -62 + roundf(sin(Time.get_ticks_msec() / 160.0))
	var f8 := Input.is_physical_key_pressed(KEY_F8)
	if f8 and not _f8:
		foto = not foto
		main.mensaje("Modo captura: " + ("activado (esquiva para congelar, F9 sigue)" if foto else "desactivado"), 2.5)
	_f8 = f8
	var f9 := Input.is_physical_key_pressed(KEY_F9)
	if f9 and not _f9 and _congelado:
		_congelado = false
		Engine.time_scale = 1.0
	_f9 = f9
	if sprite.animation != "esquivar" or sprite.frame < 3:
		_foto_hecha = false
	if foto and not _congelado and not _foto_hecha and accion == "esquivar" and accion_t > 0.0 and sprite.animation == "esquivar" and sprite.frame == 3:
		_congelado = true
		_foto_hecha = true
		Engine.time_scale = 0.0

func _physics_process(delta: float) -> void:
	if main.fin:
		mano.visible = false
		return
	var dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
			- float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))
			- float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		mirando = dir
	pide_mover = dir != Vector2.ZERO
	_esquive(dir, delta)
	if impulso_t > 0.0:
		vel = impulso_dir * IMPULSO_VEL
	elif dir != Vector2.ZERO:
		# Polvito al dar media vuelta de golpe.
		if vel.dot(dir) < -40.0 and polvo_giro <= 0.0:
			polvo_giro = 0.25
			for i in 3:
				Fx.polvo(main.mundo, position + Vector2(randf_range(-6, 6), 0))
		vel = vel.move_toward(dir * VELOCIDAD, ACELERACION * delta)
	else:
		vel = vel.move_toward(Vector2.ZERO, FRENADO * delta)
	var en_agua: bool = main.junto_a_tina(position, 0.0)
	position = main.mover(position, vel * delta * (0.55 if en_agua else 1.0), 8.0)  # huella de los pies: 16 px de ancho
	if en_agua and vel.length() > 20.0 and randf() < 0.15:
		Fx.burbujas(main.mundo, position + Vector2(randf_range(-6, 6), -2), 1, 1.0)
	var rapidez := vel.length() / VELOCIDAD
	var anda := rapidez > 0.15 or pide_mover   # con la tecla presionada ya cuenta como caminar (sin disparo quieta a medio arranque)
	# Se estira al arrancar y se aplasta al frenar.
	if anda != andaba:
		aplastar = Vector2(0.88, 1.12) if anda else Vector2(1.12, 0.9)
		# Al frenar levanta polvo de los dos lados.
		if not anda:
			for i in 3:
				Fx.polvo(main.mundo, position + Vector2(randf_range(-8, 8), 0))
	andaba = anda
	aplastar = aplastar.lerp(Vector2.ONE, 1.0 - exp(-12.0 * delta))
	fiesta_t = maxf(fiesta_t - delta, 0.0)
	# La tira de festejar es más alta (brazos arriba): se ajusta el origen para que los pies no se muevan.
	accion_t = maxf(accion_t - delta, 0.0)
	var en_guardia := tiro_corriendo > 0.0
	tiro_corriendo = maxf(tiro_corriendo - delta, 0.0)
	pendiente_t -= delta
	if pendiente != "" and (pendiente_t <= 0.0 or (not anda and accion_t <= 0.0)):
		if pendiente_t > 0.0:
			_accion(pendiente, 1.0 if pendiente == "curar" else -1.0)
		pendiente = ""
	# Al relajarse estando quieta: la mirada se suaviza en un paso intermedio antes de la normal.
	if en_guardia and tiro_corriendo <= 0.0 and not anda and accion_t <= 0.0 and sprite.animation == "reposo_disp":
		_accion("relajar", 0.18)
	if otro_tiro and not anda and (accion != "disparar" or accion_t <= 0.0 or sprite.frame >= 4):
		_tiro_quieta()
	elif otro_tiro and anda:
		otro_tiro = false
	# Curarse o tomar algo no la detiene: si camina, la animación cede a la caminata (los efectos siguen).
	if accion_t > 0.0 and accion in ["curar", "tomar", "energia", "disparar"] and anda:
		accion_t = 0.0
		sprite.self_modulate = Color.WHITE
	var clave := "diana_fest" if fiesta_t > 0.0 else "diana_idle"
	if accion_t > 0.0:
		clave = {"disparar": "diana_disp", "barrer": "diana_barr", "dano": "diana_dano", "esquivar": "diana_esq", "tomar": "diana_tomar", "curar": "diana_curar", "energia": "diana_energia", "parpadeo": "diana_parpadeo", "relajar": "diana_relajar"}[accion]
	elif fiesta_t <= 0.0 and tiro_corriendo > 0.0:
		clave = "diana_walk_disp" if anda else "diana_idle_disp"
	# La suela queda en el origen (algunas tiras traen polvo debajo de los pies).
	var info: Dictionary = Anim.data.chars[clave]
	sprite.offset.y = info.h / 2.0 - info.get("pie", info.h)
	if accion_t > 0.0:
		sprite.play(accion)
		sprite.speed_scale = 1.0
		sprite.position.y = 0.0
		# Movimiento suave entre cuadros (en pixeles enteros) para que no se vea seco.
		var k := 1.0 - accion_t / maxf(accion_dur, 0.01)
		if accion == "dano":
			# Empujón hacia atrás que regresa con suavidad.
			var atras := 1.0 if sprite.flip_h else -1.0
			sprite.position.x = roundf(atras * 4.0 * pow(1.0 - k, 2.0))
			sprite.position.y = roundf(-2.0 * sin(minf(k * 2.0, 1.0) * PI))
		elif accion == "curar":
			# Flota un poco; la luz menta entra por su orilla y la recorre de pies a cabeza.
			sprite.position.y = roundf(-2.0 * sin(k * PI))
			sprite.self_modulate = Color.WHITE.lerp(Color(0.9, 1.08, 0.97), sin(k * PI) * 0.5)
			var mc: ShaderMaterial = sprite.material
			mc.set_shader_parameter("aura", Color(0.5, 0.95, 0.72, clampf(sin(k * PI) * 1.2, 0.0, 0.8) * (0.75 + 0.25 * sin(k * 30.0))) if k > 0.08 else Color(1, 1, 1, 1.0 - k * 6.0))
			mc.set_shader_parameter("banda", clampf((k - 0.2) / 0.65, -1.0, 1.2))
		elif accion == "energia":
			# La energía entra: contorno azul que palpita y una franja que la recorre de pies a cabeza.
			sprite.position.y = roundf(-2.0 * sin(k * PI))
			var mt: ShaderMaterial = sprite.material
			mt.set_shader_parameter("aura", Color(0.45, 0.72, 1.0, clampf(sin(k * PI) * 1.2, 0.0, 0.85) * (0.75 + 0.25 * sin(k * 40.0))) if k > 0.1 else Color(1, 1, 1, 1.0 - k * 5.0))
			mt.set_shader_parameter("banda", clampf((k - 0.25) / 0.6, -1.0, 1.2))
		elif accion == "tomar":
			sprite.position.y = roundf(-2.0 * sin(minf(k * 1.6, 1.0) * PI))
	else:
		sprite.position.x = 0.0
	# Si curar/energía terminó o se canceló (por caminar u otra acción), el contorno y la franja se apagan.
	if aura_puesta and not (accion_t > 0.0 and accion in ["curar", "energia"]):
		aura_puesta = false
		sprite.self_modulate = Color.WHITE
		var mq := sprite.material as ShaderMaterial
		mq.set_shader_parameter("aura", Color(0, 0, 0, 0))
		mq.set_shader_parameter("banda", -1.0)
	elif accion_t > 0.0 and accion in ["curar", "energia"]:
		aura_puesta = true
	if accion_t > 0.0:
		pass
	elif fiesta_t > 0.0:
		sprite.play("festejar")
		sprite.speed_scale = 1.0
		sprite.position.y = 0.0
	elif anda:
		# Disparando mientras corre: caminata con cara de combate, en el mismo paso.
		var nombre := "caminar_disp" if tiro_corriendo > 0.0 else "caminar"
		if sprite.animation != nombre:
			var cuadro := sprite.frame
			var avance := sprite.frame_progress
			sprite.play(nombre)
			sprite.set_frame_and_progress(cuadro, avance)
		sprite.speed_scale = clampf(rapidez, 0.35, 1.0)
		# Rebote suave al caminar y polvito en los pies.
		paso += delta * 12.0 * clampf(rapidez, 0.3, 1.2)
		sprite.position.y = 0.0   # el rebote ya viene en los cuadros de la caminata
		polvo_t -= delta
		if polvo_t <= 0.0:
			polvo_t = 0.18
			Fx.polvo(main.mundo, position)
	elif tiro_corriendo > 0.0:
		# Quieta en combate: se queda en guardia (último cuadro del disparo, cara seria) en vez de volver al reposo.
		# Quieta en combate: el mismo reposo (con su brisa) pero con la mirada de combate.
		sprite.play("reposo_disp")
		sprite.speed_scale = 1.0
		sprite.position.y = 0.0
	else:
		sprite.play("reposo")
		sprite.speed_scale = 1.0
		sprite.position.y = move_toward(sprite.position.y, 0.0, 20.0 * delta)
	# Inclinación leve hacia donde camina y respiración en reposo.
	# Sin girar ni estirar el sprite: el pixel art se embarra. El movimiento lo dan las animaciones.
	# Meneo del cabello: rebota con los pasos al caminar y se mece lento en reposo.
	var mat_d: ShaderMaterial = sprite.material
	var anim_act: String = sprite.animation
	var n_cuadros: int = sprite.sprite_frames.get_frame_count(anim_act)
	mat_d.set_shader_parameter("cuadros", float(n_cuadros))
	mat_d.set_shader_parameter("meneo", 0.0)   # el cabello se mueve con los sprites (Gemini), no por código
	sprite.rotation = 0.0
	sprite.scale = Vector2(0.25, 0.25)  # tiras de Diana al doble de detalle
	sprite.position.y = roundf(sprite.position.y)
	polvo_giro -= delta
	# El aplastado/estirado se vuelve hundirse o levantarse en pixeles enteros (offset va al doble).
	respira += delta
	var hundir := roundf(clampf((1.0 - aplastar.y) * 12.0, -3.0, 3.0))
	var aire := 1.0 if (not andaba and accion_t <= 0.0 and fmod(respira, 1.6) < 0.8) else 0.0
	# Ya no se aplasta ni "respira" por código: el movimiento lo dan los cuadros de cada animación.
	if hundir != 0.0 and aire < 0.0:
		sprite.offset.y += hundir * 4.0

	# Diana siempre mira hacia el mouse, camine hacia donde camine.
	var apunta := get_global_mouse_position() - (global_position + Vector2(0, -20))
	# Al recibir un golpe mira hacia quien la golpeó (así la reacción siempre va hacia atrás).
	if not (accion == "dano" and accion_t > 0.0):
		sprite.flip_h = apunta.x < 0.0
	if accion_t > 0.0 and accion == "esquivar" and absf(impulso_dir.x) > 0.1:
		sprite.flip_h = impulso_dir.x < 0.0  # en el esquive mira hacia donde sale disparada
	# El objeto gira suave hacia el mouse en vez de saltar de ángulo.
	mano.angulo = lerp_angle(mano.angulo, apunta.angle(), 1.0 - exp(-22.0 * delta))
	mano.arma = arma()
	# En disparar y barrer el objeto ya viene dibujado en la animación.
	mano.flotante = arma() != "" and Fx.meta_o_nada("arma_%s_anim" % arma())
	mano.visible = arma() != "" and fiesta_t <= 0.0 and (mano.flotante or not (accion_t > 0.0 and accion in ["disparar", "barrer"])) and not (accion_t > 0.0 and accion in ["tomar", "curar", "energia"])
	# Los aros lanzados ya no están con Diana hasta que regresan.
	if arma() == "aros" and mano.flotante:
		for c in main.mundo.get_children():
			if c.get("tipo") == "aros" and c.has_method("_choca"):
				mano.visible = false
				break
	if mano.flotante:
		# Flota a un lado de Diana, del lado hacia donde apunta, y la sigue con retraso.
		mano.base = Vector2(signf(apunta.x if absf(apunta.x) > 1.0 else 1.0) * 21.0, -14.0 + (sin(paso * 2.0) * 1.0 if andaba else 0.0))
	else:
		mano.base = Vector2(0, -20 + (sin(paso * 2.0) * 1.5 if andaba else 0.0))
	mano.queue_redraw()

	recarga -= delta
	# El brillo baja al usar el objeto y solo se recarga después de un rato sin usarlo.
	sin_usar += delta
	if sin_usar > 1.2:
		energia = minf(energia + 7.0 * delta, energia_max)

	var datos: Dictionary = Armas.DATOS.get(arma(), {})
	var disparo := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_physical_key_pressed(KEY_SPACE)
	if datos.is_empty():
		disparo = false
	if disparo and recarga <= 0.0 and energia >= datos.costo:
		recarga = datos.cadencia
		if not main.PRUEBAS:   # en modo de pruebas el brillo no se acaba
			energia -= datos.costo
		sin_usar = 0.0
		_atacar(apunta.normalized(), datos)
	if disparo and tiro_corriendo > 0.0:
		tiro_corriendo = maxf(tiro_corriendo, 0.4)   # mientras siga disparando, la cara de combate no se quita
	if disparo and recarga <= 0.0 and energia < datos.costo:
		main.sin_brillo_t = 0.4  # la barra parpadea: no alcanza el brillo

	# Teclas que se usan una vez por pulsación.
	var q := Input.is_physical_key_pressed(KEY_Q)
	if q and not _q and armas.size() > 1:
		actual = (actual + 1) % armas.size()
		Juego.sonido("mover", false)
		main.cambio_t = 1.2
	_q = q
	var f := Input.is_physical_key_pressed(KEY_F)
	if f and not _f:
		_usar_cercano()
	_f = f

	if impulso_t > 0.0:
		sprite.modulate.a = 1.0
	elif invulnerable > 0.0:
		invulnerable -= delta
		# Parpadeo completo (aparece/desaparece): la transparencia a medias embarraba el sprite.
		# No parpadea durante la reacción al golpe (los primeros 0.4 s), para que se vea.
		sprite.modulate.a = 1.0 if invulnerable > 0.6 else (0.0 if int(invulnerable * 10) % 2 == 0 else 1.0)
	else:
		sprite.modulate.a = 1.0

# Esquive: impulso corto, invulnerable mientras dura, con estelas rosas.
func _esquive(dir: Vector2, delta: float) -> void:
	impulso_cd = maxf(impulso_cd - delta, 0.0)
	cargas = minf(cargas + delta / RECUPERA_ESPRINT, CARGAS_ESPRINT)
	queue_redraw()
	var boton := (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) 		and DisplayServer.window_is_focused()
	var pide := boton and not _shift
	_shift = boton
	if pide and impulso_cd <= 0.0 and impulso_t <= 0.0 and cargas >= 1.0:
		impulso_dir = dir if dir != Vector2.ZERO else mirando
		impulso_t = IMPULSO_DURA * (1.7 if impulso_luz else 1.0)
		impulso_cd = RECARGA_IMPULSO
		# Gasta una carga; al quedarse sin ninguna, Diana se cansa (la pantalla suda).
		cargas -= 1.0
		if cargas < 1.0:
			main.cansar()
		if tiro_corriendo <= 0.0:   # en combate sigue la caminata con cara de combate (las cejas no desaparecen)
			_accion("esquivar")  # la secuencia completa (8 cuadros) aunque el impulso dure menos
		aplastar = Vector2(1.2, 0.85)
		Juego.sonido("impulso", true, -2.0)
		for i in 5:
			Fx.polvo(main.mundo, position + Vector2(randf_range(-10, 10), randf_range(-2, 2)))
	if impulso_t > 0.0:
		impulso_t -= delta
		fantasma_t -= delta
		if fantasma_t <= 0.0:
			fantasma_t = 0.03
			pass  # la animación de esquive ya trae su estela; las copias encimadas se veían como franja

func _fantasma() -> void:
	var g := Sprite2D.new()
	g.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	g.flip_h = sprite.flip_h
	g.scale = sprite.scale
	g.offset = sprite.offset
	g.position = position + sprite.position
	g.modulate = Color(1.0, 0.9, 0.55, 0.7) if impulso_luz else Color(1.0, 0.55, 0.8, 0.6)
	g.z_index = -1
	main.mundo.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)

# Gotitas blancas que brincan desde los lados de la cabeza (sorpresa/esfuerzo):
# salen, suben en arco, caen y se desvanecen. Pixel nítido.
func _gotas() -> void:
	var lado := -1.0 if sprite.flip_h else 1.0
	for i in 2:
		var g := Polygon2D.new()
		g.polygon = PackedVector2Array([Vector2(0, -2), Vector2(1, 0), Vector2(1, 1), Vector2(0, 2), Vector2(-1, 1), Vector2(-1, 0)])
		g.color = Color(1, 1, 1, 0.0)
		g.z_index = 3
		var sx := (-1.0 if i == 0 else 1.0)
		var ini := Vector2(lado * 2.0 + sx * 9.0, -33.0)
		g.position = ini
		add_child(g)
		var dx := sx * randf_range(5.0, 7.0)
		var tw := g.create_tween().set_parallel(true)
		tw.tween_property(g, "color:a", 0.95, 0.06)
		tw.tween_method(func(k: float): g.position = (ini + Vector2(dx * k, -9.0 * sin(k * PI * 0.8) + 6.0 * k * k)).round(), 0.0, 1.0, 0.5).set_delay(i * 0.05)
		tw.tween_property(g, "color:a", 0.0, 0.18).set_delay(0.37 + i * 0.05)
		tw.chain().tween_callback(g.queue_free)

# Disparo estando quieta: siempre se ve; si ya estaba en guardia arranca sin pasar por el reposo.
func _tiro_quieta() -> void:
	otro_tiro = false
	_accion("disparar")
	sprite.play("disparar")
	if tiro_corriendo > 0.0:
		sprite.frame = 1

func _atacar(hacia: Vector2, datos: Dictionary) -> void:
	var punta := position + Vector2(0, -20) + hacia * 22.0
	if mano.flotante:
		punta = position + mano.position + mano.punta_local() + hacia * 4.0
	mano.golpe(datos.tipo)
	# Al entrar en combate (no venía disparando), saltan gotitas de sudor junto a las cejas.
	_gotas()
	tiro_corriendo = maxf(0.7, datos.cadencia + 0.2)   # una vuelta de la caminata de combate por disparo; la cara de combate se queda un rato: sin parpadeos entre disparos
	if arma() == "pano" and not mano.flotante:
		_accion("barrer")
	elif not pide_mover and vel.length() < VELOCIDAD * 0.15:
		if accion == "disparar" and accion_t > 0.0 and sprite.frame < 4:
			otro_tiro = true   # va a la mitad del retroceso: el siguiente arranca en cuanto regrese
		else:
			_tiro_quieta()
	Fx.chispas(main.mundo, punta, datos.color, 3)
	# Destello propio del arma en la punta (la lupa lo saca en su animación de disparo).
	var fd := "fx_%s_destello" % arma()
	var fsal := "fx_%s_salida" % arma()
	if arma() in ["aros", "limpiador"] and Fx.meta_o_nada(fsal):
		# Estrella dorada con anillos de luz al soltar los aros.
		var es := 0.25 if arma() == "limpiador" else 0.5   # el del limpiador viene más grande
		var sx := Fx.animar(main.mundo, punta, fsal, 16.0, Color(1, 1, 1, 0.85), es)
		if arma() == "limpiador":
			sx.rotation = hacia.angle()   # los anillos salen hacia donde apunta
	elif Fx.meta_o_nada(fsal) and arma() != "lupa":   # la lupa ya no usa el círculo de salida
		# Luz que brota del cristal: el círculo queda sobre el cristal y el rayo apunta al tiro.
		var sl := Fx.animar(main.mundo, punta - hacia * 4.0, fsal, 18.0, Color(1, 1, 1, 0.7), 0.35)
		sl.rotation = hacia.angle()
		sl.offset.x = Fx.meta(fsal).ox
	elif Fx.meta_o_nada(fd):
		var fs := Fx.animar(main.mundo, punta, fd, 18.0, Color(1, 1, 1, 0.7), 0.5)
		if arma() == "espejo":
			# El óvalo nace en el cristal y los rayos salen hacia donde apunta.
			fs.rotation = hacia.angle()
			fs.offset.x = Fx.meta(fd).w * 0.32
	# Salida del disparo con fuerza: luz del color del arma, anillo pequeño y chispas.
	if mano.flotante and datos.tipo != "corte":
		Fx.estallido(main.mundo, punta, Color(datos.color, 0.6))
		Fx.chispas(main.mundo, punta, datos.color, 4)
		var ls := PointLight2D.new()
		ls.texture = Fx.textura_luz()
		ls.texture_scale = 0.35
		ls.energy = 0.9
		ls.color = datos.color
		ls.position = punta
		main.mundo.add_child(ls)
		var tl2 := ls.create_tween()
		tl2.tween_property(ls, "energy", 0.0, 0.18)
		tl2.tween_callback(ls.queue_free)
	if datos.tipo == "corte":
		_cortar(hacia, datos)
		return
	match datos.tipo:
		"latigo":
			if not mano.flotante:
				_latigo(hacia, datos)
				return
			# Collar nuevo: lanza un abanico de perlas (sigue abajo como disparo).
		"onda":
			# Pistola ultrasónica: dispara una onda sónica que viaja y estalla en agua.
			main.sacudir(1.5, hacia)
		"aros":
			# No se vuelven a lanzar hasta que regresan los dos.
			for c in main.mundo.get_children():
				if c.get("tipo") == "aros" and c.has_method("_choca"):
					energia += datos.costo
					return
	Juego.sonido("disparo_" + datos.tipo, true, -5.0)
	var angulos := [0.0]
	if datos.tipo == "abanico":
		angulos = [-0.4, -0.2, 0.0, 0.2, 0.4]
	elif datos.tipo == "aros":
		angulos = [0.0, 0.0]   # paralelos: salen juntos, sin abrirse
	elif datos.tipo == "latigo":
		angulos = [-0.36, -0.18, 0.0, 0.18, 0.36]
		# Lanzamiento con peso: luz rosa, chispas y una sacudida leve.
		var lz := PointLight2D.new()
		lz.texture = Fx.textura_luz()
		lz.texture_scale = 0.5
		lz.energy = 0.6
		lz.color = Color(1.0, 0.5, 0.75)
		lz.position = punta
		main.mundo.add_child(lz)
		var tz := lz.create_tween()
		tz.tween_property(lz, "energy", 0.0, 0.3)
		tz.tween_callback(lz.queue_free)
		Fx.chispas(main.mundo, punta, Color(1.0, 0.6, 0.85), 5)
		Fx.chispas(main.mundo, punta, Color(1.0, 0.85, 0.45), 3)
		main.sacudir(1.2, hacia)
	var lado_aro := -1.0
	for a in angulos:
		lado_aro = -lado_aro
		var s = preload("res://scripts/shot.gd").new()
		s.main = main
		s.tipo = "perla" if datos.tipo == "latigo" else ("sonica" if datos.tipo == "onda" else datos.tipo)
		s.dano = datos.dano
		s.direccion = hacia.rotated(a)
		s.position = punta
		if datos.tipo == "aros":
			# uno junto al otro, paralelos
			s.position += hacia.orthogonal() * 6.0 * lado_aro
		main.agregar(s)

# Collar como látigo: pule en línea a buena distancia y jala los destellos.
func _latigo(hacia: Vector2, datos: Dictionary) -> void:
	Juego.sonido("disparo_latigo", true, -3.0)
	var desde := position + Vector2(0, -20)
	var largo := 140.0
	Fx.latigo(main.mundo, desde, hacia, largo)
	for e in main.enemigos():
		var p: Vector2 = e.position + Vector2(0, -e.alto * 0.5)
		var t := clampf((p - desde).dot(hacia), 0.0, largo)
		if (desde + hacia * t).distance_to(p) < e.radio + 8.0:
			var critico := randf() < 0.15
			e.danar(datos.dano * (2 if critico else 1), hacia, critico)
			impacto_arma(e.position + Vector2(0, -e.alto * 0.5))
	for c in main.mundo.get_children():
		if c.get("tipo") in ["destello", "corazon", "pocion"] and c.position.distance_to(position) < 220.0:
			c.atraer = true

# Limpiador ultrasónico: onda circular que pule todo alrededor de Diana.
func _onda(datos: Dictionary, hacia := Vector2.RIGHT, punta := Vector2.ZERO) -> void:
	# Pistola ultrasónica: ondas en arco hacia donde apunta (cono de ~110 px).
	Juego.sonido("impulso", true, -4.0)
	main.sacudir(2.5, hacia)
	if punta == Vector2.ZERO:
		punta = position + Vector2(0, -20)
	if Fx.meta_o_nada("fx_limpiador_tiro"):
		var m := Fx.meta("fx_limpiador_tiro")
		var esc := 220.0 / float(m.w)
		var s := Fx.animar(main.mundo, punta, "fx_limpiador_tiro", 14.0, Color(1, 1, 1, 0.72), esc)
		s.rotation = hacia.angle()
		s.offset.x = float(m.w) * 0.5
	else:
		Fx.onda_agua(main.mundo, position)
	for e in main.enemigos():
		var d: Vector2 = e.position + Vector2(0, -e.alto * 0.5) - punta
		if d.length() < 115.0 and absf(hacia.angle_to(d)) < 0.6:
			e.danar(datos.dano, d.normalized(), false)
			impacto_arma(e.position + Vector2(0, -e.alto * 0.5))
	for r in main.rompibles():
		var d2: Vector2 = r.position - punta
		if d2.length() < 100.0 and absf(hacia.angle_to(d2)) < 0.6:
			r.golpear(2)

# Golpe del paño: daña todo lo que esté en un arco frente a Diana.
func _cortar(hacia: Vector2, datos: Dictionary) -> void:
	Juego.sonido("golpe", true)
	var centro := position + Vector2(0, -16)
	if mano.flotante and Fx.meta_o_nada("fx_pano_barrido"):
		# Tajo de tela mágica frente a Diana: la panza del arco mira hacia donde apunta.
		var b := Fx.animar(main.mundo, (centro + hacia * 34.0).round(), "fx_pano_barrido", 13.0, Color(1, 1, 1, 0.9), 1.0)
		b.rotation = hacia.angle() + PI
		b.flip_v = hacia.x < 0.0
		b.z_index = 5   # por delante del piso, pero sin tapar la cara de Diana
		# Golpe con peso: luz rosa breve, pétalos a lo largo del arco y una sacudida leve.
		var foco := (centro + hacia * 34.0).round()
		var l := PointLight2D.new()
		l.texture = Fx.textura_luz()
		l.texture_scale = 0.6
		l.energy = 0.35
		l.color = Color(1.0, 0.35, 0.65)
		l.position = foco
		main.mundo.add_child(l)
		var tl := l.create_tween()
		tl.tween_property(l, "energy", 0.0, 0.35)
		tl.tween_callback(l.queue_free)
		for k in 5:
			var a := hacia.angle() + PI + (k - 2) * 0.45
			var p := foco + Vector2.from_angle(a + PI) * 16.0
			Fx.chispas(main.mundo, p, Color(1.0, 0.45, 0.7) if k % 2 == 0 else Color(1.0, 0.85, 0.45), 2)
		main.sacudir(1.5, hacia)
	elif not mano.flotante:
		Fx.corte(main.mundo, centro, hacia.angle(), datos.color)
	for e in main.enemigos():
		var d: Vector2 = e.position + Vector2(0, -e.alto * 0.5) - centro
		if d.length() < 44.0 and absf(hacia.angle_to(d)) < 1.2:
			var critico := randf() < 0.15
			e.danar(datos.dano * (2 if critico else 1), hacia, critico)
			impacto_arma(e.position + Vector2(0, -e.alto * 0.5))
	for r in main.rompibles():
		if (r.position - position).length() < 40.0:
			r.golpear(2)

func _cercano():
	var mejor = null
	var dist := 46.0
	for c in main.mundo.get_children():
		if c.has_method("usar") and c.tipo in ["arma", "cofre"]:
			var d: float = c.position.distance_to(position)
			if d < dist:
				dist = d
				mejor = c
	return mejor

func _usar_cercano() -> void:
	var mejor = _cercano()
	if mejor:
		mejor.usar()
	else:
		main.usar_mostrador()

# Recoge un arma del piso; si ya trae dos, suelta la que tiene en la mano.
func tomar_arma(p) -> void:
	var nueva: String = p.arma
	if nueva in armas:
		actual = armas.find(nueva)
		return
	if armas.is_empty() and main.room_id == "inicio":
		for c in main.mundo.get_children():
			if c != p and c.get("tipo") == "arma":
				Fx.chispas(main.mundo, c.position + Vector2(0, -10), Color(1.0, 0.9, 0.6), 6)
				c.queue_free()
	if armas.size() < 2:
		armas.append(nueva)
		actual = armas.size() - 1
		p.queue_free()
	else:
		var vieja: String = armas[actual]
		armas[actual] = nueva
		p.arma = vieja
	Juego.sonido("recoger", false)
	main.cambio_t = 1.5
	alegria()

# Saltito de alegría (lo llaman los objetos al recogerse).
func alegria(tinte := Color(0, 0, 0, 0)) -> void:
	# Ya no festeja: toma el objeto con un haz de luz (del color del arma si trae una).
	if accion_t > 0.0 and accion in ["curar", "dano"]:
		return
	# Varios objetos seguidos: una sola animación; si ya pasó, la siguiente vuelve a salir.
	var nombre := "energia" if tinte.a > 0.0 else "tomar"
	if accion == nombre and accion_t > 0.0:
		return
	if pide_mover and pendiente != "curar":
		pendiente = nombre; pendiente_t = 1.0
	elif not pide_mover:
		_accion(nombre)
	# Haz de luz blanco teñido del color del arma (dorado si no trae ninguna).
	var col: Color = Armas.DATOS[arma()].color if arma() != "" else Color(1.0, 0.82, 0.45)
	if tinte.a > 0.0:
		col = tinte
	# Poción de energía: efecto propio de absorción azul (si ya existe la hoja).
	if tinte.a > 0.0:
		Particulas.energia(self, tinte)
		return
	var m: Dictionary = Fx.meta("fx_diana_tomar")
	Fx.animar_suave(self, Vector2(0, 4.0 - m.h / 8.0), "fx_diana_tomar", 11.0, col.lightened(0.25), 0.5)   # a la escala de Diana

# Reproduce una animación de un solo uso; dura lo que sus cuadros (o lo indicado).
# Disparo: en el cuadro 5 (se inclina hacia adelante) la lupa del collar suelta un destello dorado.
func _brillo_lupa() -> void:
	if accion != "disparar" or sprite.animation != "disparar" or sprite.frame != 2:
		return
	var lado := -1.0 if sprite.flip_h else 1.0
	var lupa := global_position + Vector2(lado * 4.0, -22.0)
	if mano.flotante:
		return  # el destello ya sale de la punta de la lupa flotante
	Fx.chispas(main.mundo, lupa, Color(1.0, 0.85, 0.35), 8)

func _accion(nombre: String, dura := -1.0) -> void:
	accion = nombre
	sprite.frame = 0
	sprite.play(nombre)
	sprite.frame = 0
	var f := sprite.sprite_frames
	accion_t = dura if dura > 0.0 else f.get_frame_count(nombre) / f.get_animation_speed(nombre)
	accion_dur = accion_t

var corazon_roto := -1   # índice del corazón que acaba de perder (el HUD lo sacude)

func herir(n: int, desde := Vector2.ZERO) -> void:
	if OS.get_cmdline_user_args().has("--inmune"):   # prueba: no recibe daño
		return
	if invulnerable > 0.0 or impulso_t > 0.0 or main.fin:
		return
	invulnerable = Juego.dif().invul
	n *= int(Juego.dif().dano)   # dificultad: medio corazón o corazón entero por golpe
	main.herido_sala = true
	corazon_roto = int((vida - 1) / 2)
	vida = max(vida - n, 0)
	main.sacudir(6.0, desde)
	main.pausa_impacto(0.08)
	# Empujón hacia atrás y destello rojo que se apaga.
	if desde != Vector2.ZERO:
		vel = desde.normalized() * 320.0
		if absf(desde.x) > 0.01:
			sprite.flip_h = desde.x > 0.0   # empujada a la derecha = el golpe vino de la izquierda
	sprite.self_modulate = Color(2.0, 0.55, 0.55)
	var tw := create_tween()
	tw.tween_property(sprite, "self_modulate", Color.WHITE, 0.25)
	main.dano_t = 0.5
	Juego.sonido("dano", false)
	Fx.chispas(main.mundo, position + Vector2(0, -24), Color(1.0, 0.5, 0.6), 10)
	aplastar = Vector2(1.2, 0.84)
	_accion("dano")
	Fx.animar(self, Vector2(0, -20), "fx_diana_golpe", 20.0)
	if vida == 0:
		accion_t = 0.0
		sprite.modulate.a = 1.0
		sprite.offset.y = -Anim.data.chars.diana_ko.h / 2.0
		sprite.play("derrota")
		main.game_over()

var cura_ms := 0   # cuándo se curó (el HUD hace saltar los corazones)
func curar(n: int) -> void:
	vida = min(vida + n, vida_max)
	cura_ms = Time.get_ticks_msec()
	# Varios corazones seguidos: una sola animación (no se reinicia mientras sigue curándose).
	if vida > 0 and not main.fin and not (accion == "curar" and accion_t > 0.0):
		if pide_mover:
			pendiente = "curar"; pendiente_t = 1.0
		else:
			_accion("curar", 1.0)
		# Círculo de runas a sus pies (detrás de ella).
		var m: Dictionary = Fx.meta("fx_diana_curar")
		var c := Fx.animar_suave(self, Vector2(0, 6.0 - m.h / 4.0), "fx_diana_curar", 14.0, Color.WHITE, 1.0, 0.4)
		c.z_index = -1
		Particulas.energia(self, Color(0.45, 0.88, 0.68), "menta")

# Al vencer al jefe: festeja una vez y vuelve al reposo (el juego ya está en pausa de fin).
func festejar() -> void:
	accion_t = 0.0
	sprite.modulate.a = 1.0
	sprite.position = Vector2.ZERO
	var f: Dictionary = Anim.data.chars.diana_fest
	sprite.offset.y = f.h / 2.0 - f.get("pie", f.h)
	sprite.speed_scale = 1.0
	sprite.play("festejar")
	await sprite.animation_finished
	var r: Dictionary = Anim.data.chars.diana_idle
	sprite.offset.y = r.h / 2.0 - r.get("pie", r.h)
	sprite.play("reposo")

# Reaparece en el Apartado con la vida llena.
func revivir() -> void:
	vida = vida_max
	energia = energia_max
	invulnerable = 1.5
	sprite.offset.y = -Anim.data.chars.diana_idle.h / 2.0
	sprite.play("reposo")
	mano.visible = true


# Arma en la mano: gira hacia el mouse y se voltea para no quedar de cabeza.
# Cargas de esquive: dos rombos bajo los pies (solo se ven cuando falta alguno).
func _draw() -> void:
	if cargas >= CARGAS_ESPRINT:
		return
	for i in CARGAS_ESPRINT:
		var c := Vector2((i - 0.5) * 8.0, 6.0)
		var lleno := clampf(cargas - i, 0.0, 1.0)
		var r := PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0), c + Vector2(0, 3), c + Vector2(-3, 0)])
		draw_colored_polygon(r, Color(0.1, 0.06, 0.1, 0.8))
		if lleno >= 1.0:
			draw_colored_polygon(r, Color(1.0, 0.6, 0.85))
		elif lleno > 0.0:
			var h := 3.0 * lleno
			draw_rect(Rect2(c + Vector2(-1, 3 - h * 2.0), Vector2(2, h * 2.0)), Color(1.0, 0.6, 0.85, 0.6))

# Destello del arma sobre el enemigo golpeado (cada arma con el suyo), de ~20 px.
func impacto_arma(pos: Vector2, id := "") -> void:
	if id == "":
		id = arma()
	var clave := "fx_espejo_impacto" if id == "espejo" else "fx_%s_destello" % id
	var expl := "fx_%s_explosion" % id
	if Fx.meta_o_nada(expl):
		# Explosión propia del arma (de Gemini), más grande.
		var me := Fx.meta(expl)
		Fx.animar(main.mundo, pos, expl, 16.0, Color(1, 1, 1, 0.8), 56.0 / maxf(float(me.w), float(me.h)))
	elif Fx.meta_o_nada(clave):
		var m := Fx.meta(clave)
		Fx.animar(main.mundo, pos, clave, 20.0, Color(1, 1, 1, 0.55), 40.0 / maxf(float(m.w), float(m.h)))
	# Golpe de luz, onda expansiva y chispas del color del arma.
	var col: Color = Armas.DATOS[id].color if Armas.DATOS.has(id) else Color(1, 0.9, 0.6)
	Fx.estallido(main.mundo, pos, Color(col, 0.7))
	Fx.chispas(main.mundo, pos, col, 4)
	var l := PointLight2D.new()
	l.texture = Fx.textura_luz()
	l.texture_scale = 0.4
	l.energy = 0.8
	l.color = col
	l.position = pos
	main.mundo.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, 0.25)
	tw.tween_callback(l.queue_free)

class Mano extends Node2D:
	var angulo := 0.0
	var arma := ""
	var retroceso := 0.0
	var giro := 0.0      # giro extra al usarlo (el paño barre, el collar azota)
	var t := 0.0
	var flotante := false   # armas con tira animada: flotan derechas junto a Diana
	var base := Vector2(0, -20)
	var deriva := Vector2.ZERO   # se queda atrás cuando Diana se mueve y luego la alcanza
	var vel := Vector2.ZERO
	var ultimo := Vector2.INF
	var inclina := 0.0
	var pendulo := 0.0      # ángulo del collar/paño colgando
	var prisa_tela := 0.0   # 0 quieta, ~0.45 caminando, 1 esquivando
	var pendulo_v := 0.0
	var tam := Vector2.ZERO
	var esc_px := 0.25
	var latigo_hecho := false
	# Centro del cristal (de donde sale el disparo), relativo al nodo.
	func punta_local() -> Vector2:
		var lado := -1.0 if absf(angulo) > PI / 2.0 else 1.0
		return Vector2(lado * tam.x * 0.2, -tam.y * 0.2).rotated(inclina)
	var luz: PointLight2D
	var chispa_t := 0.0
	func _ready() -> void:
		# Luz real del color del arma: ilumina el piso y a Diana.
		luz = PointLight2D.new()
		luz.texture = Fx.textura_luz()
		luz.texture_scale = 0.45
		luz.energy = 0.75
		add_child(luz)
	var disparo_t := 99.0   # tiempo desde el último disparo (para la tira arma_<id>_disp)
	func golpe(tipo: String) -> void:
		disparo_t = 0.0
		retroceso = 7.0
		match tipo:
			"corte": giro = 1.6
			"latigo": giro = -1.0
			"onda": retroceso = 0.0; giro = 0.0; scale = Vector2(1.4, 1.4)
			_: giro = 0.35
	func _process(delta: float) -> void:
		t += delta
		disparo_t += delta
		var p: Vector2 = (get_parent() as Node2D).global_position
		if ultimo != Vector2.INF:
			deriva -= p - ultimo
		ultimo = p
		deriva = deriva.limit_length(9.0)
		vel += (-deriva * 150.0 - vel * 15.0) * delta
		deriva += vel * delta
		position = base + (deriva if flotante else Vector2.ZERO)
		var dueña = get_parent()
		if arma == "pano" and flotante:
			if disparo_t < 0.05:
				latigo_hecho = false
			elif not latigo_hecho and disparo_t >= 0.3 and dueña.get("main"):
				latigo_hecho = true
				var d := Vector2.RIGHT.rotated(angulo)
				var punta_l: Vector2 = dueña.position + position + d * 18.0
				Fx.animar(dueña.main.mundo, punta_l, "fx_pano_destello", 18.0, Color(1, 1, 1, 0.85), 30.0 / float(Fx.meta("fx_pano_destello").w))
				Fx.chispas(dueña.main.mundo, punta_l, Color(1.0, 0.55, 0.8), 6)
				Fx.chispas(dueña.main.mundo, punta_l, Color(1.0, 0.85, 0.4), 3)
		var meta_prisa := 0.0
		if dueña.get("impulso_t") != null and dueña.impulso_t > 0.0:
			meta_prisa = 1.0
		elif dueña.get("andaba"):
			meta_prisa = 0.45
		prisa_tela = lerpf(prisa_tela, meta_prisa, 1.0 - exp(-(8.0 if meta_prisa > prisa_tela else 2.5) * delta))
		# Péndulo: lo que cuelga se queda atrás al moverse y se balancea hasta asentarse.
		var mueve_x: float = dueña.get("vel").x if dueña.get("vel") != null else 0.0
		var meneo_solo := sin(t * 1.7) * 0.2 if arma == "collar" else 0.0
		var empuje := meneo_solo + clampf(-vel.x * 0.02 - deriva.x * 0.025 - signf(mueve_x) * prisa_tela * 0.4, -0.6, 0.6)
		pendulo_v += (-(pendulo - empuje) * 26.0 - pendulo_v * 5.0) * delta
		pendulo = clampf(pendulo + pendulo_v * delta, -0.9, 0.9)
		if luz:
			luz.visible = flotante and visible
			if flotante:
				var fz := clampf(1.0 - disparo_t * 3.0, 0.0, 1.0)
				luz.color = Armas.DATOS[arma].color
				luz.energy = 0.4 + 0.1 * sin(t * 3.0) + fz * (1.0 if arma == "collar" else 0.55)
				luz.texture_scale = 0.45 + fz * 0.25
		# Al moverse suelta chispitas de su color.
		chispa_t -= delta
		if flotante and visible and vel.length() > 25.0 and chispa_t <= 0.0:
			chispa_t = 0.09
			var j = get_parent()
			if j.get("main"):
				Fx.chispas(j.main.mundo, j.position + position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Armas.DATOS[arma].color, 1)
		retroceso = move_toward(retroceso, 0.0, 40.0 * delta)
		giro = lerpf(giro, 0.0, 1.0 - exp(-14.0 * delta))
		scale = scale.lerp(Vector2.ONE, 1.0 - exp(-10.0 * delta))
	func _draw() -> void:
		if arma == "":
			return
		if flotante:
			_dibujar_flotante()
			return
		# Se mece suave aunque Diana esté quieta y patea al usarlo.
		var izquierda := absf(angulo) > PI / 2.0
		var lado := -1.0 if izquierda else 1.0
		var meneo := sin(t * 3.0) * 0.12
		var dist := 10.0 - retroceso + sin(t * 2.5) * 2.0
		match arma:
			"pano":  # la tela ondea
				meneo = sin(t * 7.0) * 0.25
			"collar":  # se balancea como péndulo
				meneo = sin(t * 4.0) * 0.35
			"aros":  # giran
				meneo = t * 3.0
		Armas.dibujar_en_mano(self, arma, angulo + (meneo - giro) * lado, dist)
		var punta := Vector2.RIGHT.rotated(angulo) * (dist + 10.0)
		# Destello que recorre el cristal de la lupa y del espejo cada tanto.
		if arma == "espejo" and fmod(t, 1.6) < 0.25:
			var k := fmod(t, 1.6) / 0.25
			var c := Color(1, 1, 1, 1.0 - k)
			var e := 2.0 + k * 4.0
			draw_line(punta + Vector2(-e, 0), punta + Vector2(e, 0), c, 1.5)
			draw_line(punta + Vector2(0, -e), punta + Vector2(0, e), c, 1.5)
		# Burbujas del limpiador.
		if arma == "limpiador":
			for i in 3:
				var f := fmod(t * 0.8 + i * 0.33, 1.0)
				draw_arc(punta + Vector2(sin(t * 5.0 + i) * 3.0, -f * 14.0), 1.6, 0, TAU, 8, Color(0.8, 0.95, 1.0, 1.0 - f), 1.0)

	# Arma derecha (nunca de cabeza): se voltea de lado, se inclina hacia donde apunta,
	# se mece al flotar y patea hacia atrás al disparar.
	func _dibujar_flotante() -> void:
		var anim := "arma_%s_anim" % arma
		var m := Fx.meta(anim)
		var dir := Vector2.RIGHT.rotated(angulo)
		var lado := -1.0 if dir.x < 0.0 else 1.0
		var sube := atan2(dir.y, absf(dir.x))
		# Sigue al mouse hacia arriba y abajo; al disparar la punta se levanta por el retroceso.
		var inclina_meta := (clampf(sube * 0.9, -1.1, 1.1) + sin(t * 2.2) * 0.05 - retroceso / 7.0 * 0.5 - deriva.x * 0.02 * lado) * lado
		inclina = lerpf(inclina, inclina_meta, 0.3)
		var off := -dir * retroceso * 0.8 + Vector2(0, sin(t * 2.6) * 1.6 - retroceso / 7.0 * 2.0)
		off = (off * 2.0).round() / 2.0   # cae en pixeles exactos de pantalla (zoom 2)
		# Escala exacta (1/2, 1/4 u 1/8): cada pixel del dibujo cae en pixeles enteros
		# de pantalla, así se ve nítido como Diana. Se elige la más cercana a ~24 px.
		esc_px = 0.5
		for e in [0.25, 0.125]:
			if absf(float(m.h) * e - 20.0) < absf(float(m.h) * esc_px - 20.0):
				esc_px = e
		if arma == "aros":
			esc_px = 0.375   # los aros a mano un poco más grandes (~29 px)
		tam = Vector2(m.w, m.h) * esc_px
		# Ida y vuelta (1-2-3-4-3-2): el ciclo no salta del último cuadro al primero.
		var nn := int(m.n)
		var ciclo := maxi(1, nn * 2 - 2)
		var vel_anim := 8.0
		if arma in ["pano", "collar"]:
			# La tela ondea según Diana: calmada quieta, más al caminar, rápido al esquivar.
			vel_anim = lerpf(2.5, 11.0, prisa_tela)
		var f := int(t * vel_anim) % ciclo
		if f >= nn:
			f = ciclo - f
		# Al disparar: secuencia propia del arma (el cristal se ilumina y se apaga).
		var disp := "arma_%s_disp" % arma
		var fps_disp := 10.0 if arma == "pano" else (13.0 if arma == "collar" else 20.0)   # latigazos más pausados
		if Fx.meta_o_nada(disp) and disparo_t < Fx.meta(disp).n / fps_disp:
			var md := Fx.meta(disp)
			tam = Vector2(md.w, md.h) * esc_px   # misma escala exacta que la tira normal
			anim = disp
			f = mini(int(disparo_t * fps_disp), int(md.n) - 1)
		# Aura: resplandor del color del arma que palpita detrás, más fuerte al disparar,
		# y tres chispitas que giran alrededor.
		var col: Color = Armas.DATOS[arma].color
		var pulso := 0.5 + 0.5 * sin(t * 3.0)
		var fuerza := clampf(1.0 - disparo_t * 3.0, 0.0, 1.0)
		var r := minf(tam.x, tam.y) * 0.35 + pulso * 1.0 + fuerza * 2.0
		draw_circle(off, r, Color(col, 0.08 + pulso * 0.03 + fuerza * 0.1))
		for i in 3:
			var ang := t * 2.2 + i * TAU / 3.0
			var cp := off + Vector2(cos(ang) * r * 1.15, sin(ang) * r * 0.75).round()
			var br := 0.55 + 0.45 * sin(t * 6.0 + i * 2.0)
			draw_rect(Rect2(cp - Vector2(1, 1), Vector2(2, 2)), Color(col.lightened(0.3), br))
			if br > 0.85:
				draw_rect(Rect2(cp - Vector2(0.5, 2.5), Vector2(1, 5)), Color(col.lightened(0.4), br * 0.6))
				draw_rect(Rect2(cp - Vector2(2.5, 0.5), Vector2(5, 1)), Color(col.lightened(0.4), br * 0.6))
		if arma == "aros" and Fx.meta_o_nada("fx_aros_aura"):
			# Resplandor dorado de dos círculos detrás de los aros, con destellos que van y vienen.
			var ma := Fx.meta("fx_aros_aura")
			var ta := Fx.cuadro("fx_aros_aura", int(t * 5.0) % int(ma.n))
			var ea := 0.5   # ~32 px, rodea los aros (~29 px)
			var sa := Vector2(ma.w, ma.h) * ea
			draw_texture_rect(ta, Rect2(off - sa / 2.0, sa), false, Color(1, 1, 1, 0.45 + pulso * 0.15 + fuerza * 0.3))
		if arma == "pano" and disparo_t < 0.46:
			return   # el paño se vuelve el tajo mientras dura el golpe
		if arma == "collar" and anim != disp and Fx.meta_o_nada("arma_collar_vaiven"):
			# Dibujo según el balanceo: izquierda / derecho / derecha (la física suaviza el paso).
			anim = "arma_collar_vaiven"
			f = 1
			if pendulo > 0.09:
				f = 0
			elif pendulo < -0.09:
				f = 2
		if arma == "collar":
			_brillos_collar(off)
		if arma in ["collar", "pano"]:
			tam = tam.round()
			_dibujar_colgando(Fx.cuadro_retro(anim, f, tam), off, lado)
			if arma == "collar":
				_destellos_perlas(off)
			return
		draw_set_transform(off, inclina, Vector2(lado, 1.0))
		tam = tam.round()
		draw_texture_rect(Fx.cuadro_retro(anim, f, tam), Rect2(-tam / 2.0, tam), false)
		draw_set_transform(Vector2.ZERO)

	# Collar y paño: cuelgan del broche y se doblan por franjas (abajo se mueve más),
	# así el hilo se curva al moverse en vez de ser un dibujo rígido.
	func _dibujar_colgando(at: Texture2D, off: Vector2, lado: float) -> void:
		var franjas := 6
		var reg := Rect2(Vector2.ZERO, at.get_size())
		var arriba := off + Vector2(0, -tam.y / 2.0)
		var giro_p := 0.25 if arma == "collar" else 0.7   # el collar ya trae el vaivén dibujado
		draw_set_transform(arriba, inclina * 0.3 + pendulo * giro_p, Vector2(lado, 1.0))
		var px := Vector2.ZERO
		for i in franjas:
			var k0 := float(i) / franjas
			var k1 := float(i + 1) / franjas
			# Desplazamiento lateral que crece hacia abajo (curva) y una onda suave.
			var curva := pendulo * tam.y * 0.15 * pow(k1, 2.0) * lado
			var onda := sin(t * lerpf(1.6, 9.0, prisa_tela) - k1 * 3.0) * lerpf(0.3, 1.2, prisa_tela) * k1
			var x := roundf(curva + onda)
			var src := Rect2(reg.position.x, reg.position.y + reg.size.y * k0, reg.size.x, reg.size.y * (k1 - k0) + 0.5)
			var dst := Rect2(-tam.x / 2.0 + x * lado, tam.y * k0, tam.x, tam.y * (k1 - k0) + 0.6)
			draw_texture_rect_region(at, dst, src)
		draw_set_transform(Vector2.ZERO)

	# Barrido del paño: el paño recorre un arco frente a Diana y deja una estela de tela
	# (gruesa y fucsia adelante, delgada y transparente en la cola). Regresa su posición.
	func _barrido_pano(dir: Vector2, lado: float) -> Vector2:
		var dura := 0.42
		var k := clampf(disparo_t / dura, 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		var a0 := dir.angle() - 1.1 * lado
		var a1 := dir.angle() + 1.1 * lado
		var ang := lerpf(a0, a1, k)
		# El arco gira alrededor del pecho de Diana, por delante (hacia donde apunta).
		var centro := Vector2(0, -20) - position
		var radio := 30.0
		return centro + Vector2.from_angle(ang) * radio - Vector2(0, tam.y * 0.4)

	# Collar al atacar: resplandor rosa fuerte y anillo de chispitas que se abre.
	func _brillos_collar(off: Vector2) -> void:
		var k := clampf(1.0 - disparo_t / 0.45, 0.0, 1.0)
		if k <= 0.0:
			return
		var c := Color(1.0, 0.55, 0.8)
		draw_circle(off, tam.x * 0.6 * (1.0 + (1.0 - k) * 0.6), Color(c, 0.18 * k))
		var r := tam.y * 0.45 + (1.0 - k) * 10.0
		for i in 8:
			var a := i * TAU / 8.0 + t * 2.0
			var p := (off + Vector2.from_angle(a) * r).round()
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.75, 0.9, k))

	# Destellos en cruz que aparecen sobre las perlas de vez en cuando.
	func _destellos_perlas(off: Vector2) -> void:
		for i in 3:
			var ciclo := fmod(t * 0.9 + i * 0.37, 1.0)
			if ciclo > 0.3:
				continue
			var b := sin(ciclo / 0.3 * PI)
			var semilla: float = floor(t * 0.9 + i * 0.37) * 7.0 + i * 13.0
			var p := off + Vector2(sin(semilla) * tam.x * 0.35, -tam.y * 0.3 + fmod(abs(cos(semilla)) * 10.0, 1.0) * tam.y * 0.7)
			p = p.round()
			var e := 1.0 + b * 2.0
			var col := Color(1.0, 0.92, 0.97, b)
			draw_rect(Rect2(p - Vector2(0.5, e), Vector2(1, e * 2.0)), col)
			draw_rect(Rect2(p - Vector2(e, 0.5), Vector2(e * 2.0, 1)), col)

	# Aros: uno a cada lado de Diana (como sus manos), girando despacio.
	func puntos_aros() -> Array:
		var centro := Vector2(0, -20) - position     # pecho de Diana, visto desde aquí
		var izq := Vector2(centro.x - 16.0, centro.y + 5.0 + sin(t * 2.4) * 1.5)
		var der := Vector2(centro.x + 16.0, centro.y + 5.0 + sin(t * 2.4 + PI) * 1.5)
		return [izq.round(), der.round()]

	func _dibujar_aros_lados(off: Vector2) -> void:
		var m := Fx.meta("fx_aros_giro")
		var brillo := clampf(1.0 - disparo_t * 3.0, 0.0, 1.0)
		var pts := puntos_aros()
		for i in 2:
			var p: Vector2 = pts[i]
			var fr: int = [7, 0, 1, 0][(int(t * 3.0) + i * 2) % 4]
			var at := Fx.cuadro("fx_aros_giro", fr)
			var ta := Vector2(m.w, m.h) * 0.25
			draw_texture_rect(at, Rect2((p - ta / 2.0).round(), ta), false, Color(1, 1, 1).lerp(Color(1.4, 1.2, 0.8), brillo))


# Destello de energía/curación sobre Diana, en dos capas (la de atrás la tapa su cuerpo):
# al tocar el objeto saltan chispas en cruz; luego cometitas giran y entran en su pecho;
# al final titilan chispitas alrededor de su silueta.
class Particulas extends Node2D:
	var clave := "azul"          # "azul" (energía) o "menta" (curación)
	var color := Color(0.35, 0.65, 1.0)
	var motas: Array = []
	var chispas: Array = []
	var titilos: Array = []
	var t := 0.0
	var frente := false
	const PECHO := Vector2(0, -20)
	static func energia(diana: Node2D, c: Color, tipo := "azul") -> void:
		var atras := Particulas.new()
		var adelante := Particulas.new()
		for p in [atras, adelante]:
			p.color = c
			p.clave = tipo
		adelante.frente = true
		atras.z_index = -1
		adelante.z_index = 1
		for i in 16:
			atras.motas.append({"a": randf() * TAU, "r": randf_range(16, 26), "y": randf_range(-38, 2),
				"d": randf_range(0.1, 0.5), "v": randf_range(3.5, 6.0)})
		for i in 10:
			var ang := randf() * TAU
			adelante.chispas.append({"p": PECHO + Vector2(randf_range(-4, 4), randf_range(-6, 6)),
				"v": Vector2(cos(ang), sin(ang) * 0.8) * randf_range(60, 110), "f": randi() % 4})
		for i in 7:
			adelante.titilos.append({"p": Vector2(randf_range(-13, 13), randf_range(-40, -4)), "d": randf_range(0.55, 0.85)})
		adelante.motas = atras.motas
		diana.add_child(atras)
		diana.add_child(adelante)
	func _process(delta: float) -> void:
		t += delta
		for c in chispas:
			c.p += c.v * delta
			c.v *= exp(-5.0 * delta)
		if t > 1.25:
			queue_free()
		queue_redraw()
	func _tex(nombre: String, f: int, p: Vector2, ang := 0.0, alfa := 1.0) -> void:
		var cl := "%s_%s" % [nombre, clave]
		var m := Fx.meta(cl)
		var tam := (Vector2(m.w, m.h) * 0.5 * 0.55).round()   # chispas chicas, a la resolución de Diana
		var at := Fx.cuadro_retro(cl, clampi(f, 0, int(m.n) - 1) if nombre == "chispa" else f % int(m.n), tam)
		draw_set_transform(p.round(), ang)
		draw_texture_rect(at, Rect2(-tam / 2.0, tam), false, Color(1, 1, 1, alfa))
		draw_set_transform(Vector2.ZERO)
	func _draw() -> void:
		# Cometitas que giran y entran en su pecho (cambian de capa al pasar detrás/delante).
		for m in motas:
			var tt: float = t - m.d
			if tt < 0.0:
				continue
			var k := clampf(tt / 0.7, 0.0, 1.0)
			if k >= 1.0:
				continue
			var ang: float = m.a + tt * m.v
			var r: float = m.r * (1.0 - k * k)
			var p := Vector2(cos(ang) * r, lerpf(m.y, PECHO.y, k * k) + sin(ang) * r * 0.25)
			if (sin(ang) < 0.0) == frente:
				continue
			var dir := Vector2(-sin(ang) * r, (PECHO.y - m.y) * 2.0 * k + cos(ang) * r * 0.25)
			_tex("cometa", int(tt * 12.0), p, dir.angle() + PI * 0.75, minf(tt * 6.0, 1.0))
		if not frente:
			return
		# Chispas en cruz que saltan al tocar el objeto.
		if t < 0.45:
			for c in chispas:
				if t < c.get("d", 0.0):
					continue
				_tex("chispa", int(t / 0.45 * 10.0), c.p)   # nace, destella y se apaga una vez
		# Chispitas que titilan alrededor de su silueta al final.
		for ti in titilos:
			var tt2: float = t - ti.d
			if tt2 < 0.0 or tt2 > 0.35:
				continue
			_tex("chispa", int(tt2 / 0.35 * 10.0), ti.p)

