# Mirilla que sigue al mouse dentro del juego. Usa las 20 miras de joyería
# (assets/objetos/miras.png); el estilo se elige en Opciones (Juego.mirilla).
# Brilla cambiando de tono, suelta chispitas al moverse, estalla al disparar
# y se pone roja al pasar sobre un enemigo.
extends Node2D

const TOTAL := 20
const ROJO := Color(1.0, 0.35, 0.38)

var main
var t := 0.0
var golpe := 0.0      # 1 al disparar, baja a 0
var sobre := 0.0      # 0..1 mientras apunta a un enemigo
var _ultimo_disp := 99.0
var _antes := Vector2.ZERO
var luz_arma := Color(1.0, 0.9, 0.6)   # luz propia del arma que se usa (limpiador azul, aros dorado...)
var particulas: Array = []   # [pos, vel, vida, vida_max, color, tam]

static func nombre(i: int) -> String:
	return "Estilo %d" % (i + 1)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # en pausa se oculta y vuelve la flecha del mouse

func _process(delta: float) -> void:
	t += delta
	var pausa := get_tree().paused
	visible = not pausa
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausa else Input.MOUSE_MODE_HIDDEN
	position = get_viewport().get_mouse_position().round()
	var col := _color()
	var p = main.player if main else null
	if p:
		var id: String = p.arma()
		if Armas.DATOS.has(id):
			luz_arma = Armas.DATOS[id].color
		var d: float = p.mano.disparo_t
		if d < _ultimo_disp:
			golpe = 1.0
			# Estallido de chispas al disparar.
			for i in 10:
				var a := TAU * i / 10.0 + randf() * 0.3
				_chispa(Vector2.RIGHT.rotated(a) * 8.0, Vector2.RIGHT.rotated(a) * randf_range(50.0, 90.0), luz_arma.lightened(0.2), 0.35, 2.0)
		_ultimo_disp = d
		var raton: Vector2 = p.get_global_mouse_position()
		var en := false
		for e in main.enemigos():
			if raton.distance_to(e.position + Vector2(0, -e.alto * 0.5)) < e.radio + 6.0:
				en = true
				break
		sobre = move_toward(sobre, 1.0 if en else 0.0, delta * 8.0)
	golpe = move_toward(golpe, 0.0, delta * 5.0)
	# Al moverse deja una estela de chispitas que caen.
	var mov := position - _antes
	if mov.length() > 3.0 and randf() < 0.7:
		_chispa(Vector2(randf_range(-6, 6), randf_range(-6, 6)) - mov * 0.3, Vector2(randf_range(-10, 10), randf_range(5, 25)), col, randf_range(0.3, 0.5), 1.0 + float(randi() % 2))
	_antes = position
	# Destellitos que brotan alrededor de vez en cuando.
	if randf() < delta * 3.0:
		var a2 := randf() * TAU
		_chispa(Vector2.RIGHT.rotated(a2) * 16.0, Vector2.RIGHT.rotated(a2) * 12.0, col.lightened(0.4), 0.5, 2.0)
	for q in particulas:
		q[0] += q[1] * delta
		q[1] *= 0.92
		q[2] -= delta
	particulas = particulas.filter(func(q): return q[2] > 0.0)
	queue_redraw()

func _chispa(pos: Vector2, vel: Vector2, col: Color, vida: float, tam: float) -> void:
	if particulas.size() < 80:
		particulas.append([pos, vel, vida, vida, col, tam])

# Tono que va y viene entre dorado y rosa; rojo sobre un enemigo.
func _color() -> Color:
	var base := Color(1.0, 0.9, 0.7).lerp(Color(1.0, 0.75, 0.85), 0.5 + 0.5 * sin(t * 1.7))
	return base.lerp(ROJO, sobre)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _draw() -> void:
	var col := _color()
	var late := 0.5 + 0.5 * sin(t * 4.0)
	# Resplandor suave detrás.
	draw_circle(Vector2.ZERO, 17.0 + late * 2.0, Color(col, 0.05 + late * 0.03))
	if golpe > 0.0:
		draw_circle(Vector2.ZERO, 14.0 + golpe * 8.0, Color(luz_arma, golpe * 0.22))   # resplandor del arma al disparar
	# Partículas detrás y delante.
	for q in particulas:
		var a: float = q[2] / q[3]
		var s: float = q[5]
		draw_rect(Rect2((q[0] as Vector2).round() - Vector2(s, s) / 2.0, Vector2(s, s)), Color(q[4], a))
	# La mira: se abre al disparar y se cierra un poco sobre un enemigo.
	var esc := 1.0 + golpe * 0.3 - sobre * 0.1
	var tex := Fx.cuadro("miras", Juego.mirilla % TOTAL)
	var tam := tex.get_size() * esc
	var modul := Color(1, 1, 1).lerp(col, 0.35 + sobre * 0.65)
	modul = modul.lightened(late * 0.12).lerp(luz_arma.lightened(0.3), golpe * 0.6)
	draw_texture_rect(tex, Rect2((-tam / 2.0).round(), tam), false, modul)
	# Destello en cruz al disparar.
	if golpe > 0.2:
		var g := golpe * 7.0
		draw_rect(Rect2(Vector2(-0.5, -g), Vector2(1, g * 2.0)), Color(luz_arma.lightened(0.5), golpe))
		draw_rect(Rect2(Vector2(-g, -0.5), Vector2(g * 2.0, 1)), Color(luz_arma.lightened(0.5), golpe))
