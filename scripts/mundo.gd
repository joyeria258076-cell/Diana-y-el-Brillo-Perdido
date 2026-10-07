extends Node2D
## Arma cada cuarto y lleva el avance de la partida.
##
## No hay una escena por nivel: el cuarto se construye al entrar, a partir
## de la ficha que esta en niveles.gd. Eso hace que agregar un nivel sea
## escribir unas lineas de datos en vez de montar una escena entera.
##
## El recorrido es el de siempre en este tipo de juegos: entras, limpias el
## cuarto, se abre la puerta y pasas al siguiente.

const Niveles := preload("res://scripts/niveles.gd")
const Efectos := preload("res://scripts/efectos.gd")
const JUGADOR := preload("res://escenas/jugador.tscn")
const ENEMIGO := preload("res://escenas/enemigo.tscn")
const JEFE := preload("res://escenas/jefe.tscn")
const PUERTA := preload("res://escenas/puerta.tscn")
const GENTE := preload("res://escenas/persona.tscn")

var cuarto: Dictionary = {}
var limites: Rect2 = Rect2()
var piezas: Array[String] = []

var _por_limpiar: int = 0
var _puerta: Node2D = null
var _jugador: CharacterBody2D = null

@onready var fondo: Sprite2D = $Fondo
@onready var contenido: Node2D = $Contenido
@onready var hud: CanvasLayer = $Hud
@onready var velo: ColorRect = $Transicion/Velo


func _ready() -> void:
	_jugador = JUGADOR.instantiate()
	add_child(_jugador)
	_conectar_hud()
	entrar("joyeria")
	_desvanecer(false)


func _conectar_hud() -> void:
	_jugador.vida_cambiada.connect(hud.mostrar_vida)
	_jugador.brillo_cambiado.connect(hud.mostrar_brillo)
	_jugador.destellos_cambiados.connect(hud.mostrar_destellos)
	_jugador.murio.connect(_al_morir)


## Construye el cuarto completo: fondo, limites, enemigos, gente y puerta.
func entrar(clave: String) -> void:
	for hijo in contenido.get_children():
		hijo.queue_free()
	_puerta = null

	cuarto = Niveles.cuarto(clave)
	fondo.texture = load(cuarto["fondo"])
	var tamano: Vector2 = fondo.texture.get_size()
	fondo.position = tamano / 2.0

	# La zona caminable es el cuarto menos sus muros.
	var orillas: Array = cuarto["orillas"]
	limites = Rect2(
		Vector2(orillas[0], orillas[1]),
		Vector2(tamano.x - orillas[0] - orillas[2],
			tamano.y - orillas[1] - orillas[3]))

	var entrada: Array = cuarto["entrada"]
	_jugador.global_position = Vector2(tamano.x * entrada[0], tamano.y * entrada[1])
	_jugador.limites = limites
	_acomodar_camara(tamano)

	_por_limpiar = 0
	_poner_enemigos(tamano)
	_poner_jefe(tamano)
	_poner_gente(tamano)

	hud.mostrar_nivel("%d. %s" % [Niveles.numero_de(clave), cuarto["nombre"]])
	hud.mostrar_jefe(false)
	if cuarto["jefe"] != "":
		var ficha: Dictionary = Niveles.JEFES[cuarto["jefe"]]
		hud.nombrar_jefe(ficha["nombre"])
		hud.mostrar_jefe(true)

	if cuarto["aviso"] != "":
		hud.avisar(cuarto["aviso"])
	_revisar_si_quedo_limpio()


## La camara no se sale del cuarto: se le ponen los bordes del fondo.
func _acomodar_camara(tamano: Vector2) -> void:
	var camara: Camera2D = _jugador.get_node("Camara")
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = int(tamano.x)
	camara.limit_bottom = int(tamano.y)
	camara.reset_smoothing()


func _poner_enemigos(tamano: Vector2) -> void:
	for datos in cuarto["enemigos"]:
		var ficha: Dictionary = Niveles.ENEMIGOS[datos[0]]
		var e := ENEMIGO.instantiate()
		contenido.add_child(e)
		e.preparar(ficha)
		e.global_position = Vector2(tamano.x * datos[1], tamano.y * datos[2])
		e.limites = limites
		e.pulido.connect(_al_pulir)
		_por_limpiar += 1


func _poner_jefe(tamano: Vector2) -> void:
	if cuarto["jefe"] == "":
		return
	var ficha: Dictionary = Niveles.JEFES[cuarto["jefe"]]
	var j := JEFE.instantiate()
	contenido.add_child(j)
	j.preparar(ficha)
	j.global_position = Vector2(tamano.x * 0.5, tamano.y * 0.32)
	j.limites = limites
	j.pulido.connect(_al_pulir_jefe.bind(ficha))
	j.oxido_cambiado.connect(hud.mostrar_oxido_jefe)
	_por_limpiar += 1


func _poner_gente(tamano: Vector2) -> void:
	for datos in cuarto["gente"]:
		var p := GENTE.instantiate()
		contenido.add_child(p)
		p.preparar("res://sprites/personajes/%s.png" % datos[0], datos[3])
		p.global_position = Vector2(tamano.x * datos[1], tamano.y * datos[2])


func _al_pulir(_quien) -> void:
	_por_limpiar -= 1
	_revisar_si_quedo_limpio()


func _al_pulir_jefe(_quien, ficha: Dictionary) -> void:
	_por_limpiar -= 1
	piezas.append(ficha["pieza"])
	hud.mostrar_jefe(false)
	hud.avisar("Recuperaste el %s\n%s" % [ficha["pieza"], ficha["recompensa"]])

	# La primera pieza desbloquea el impulso de esquive, como dice el libreto.
	if ficha["pieza"] == "Anillo Alborada":
		_jugador.tiene_impulso = true
	_jugador.curar(2)
	_revisar_si_quedo_limpio()


func _revisar_si_quedo_limpio() -> void:
	if _por_limpiar > 0:
		hud.mostrar_pendientes(_por_limpiar)
		return
	hud.mostrar_pendientes(0)
	if cuarto["siguiente"] == "":
		hud.avisar("Las joyas recuperaron su brillo.\n¡Terminaste el juego!")
		return
	if _puerta == null:
		_abrir_puerta()


## La puerta aparece arriba del cuarto cuando ya no queda nada oxidado.
func _abrir_puerta() -> void:
	var tamano: Vector2 = fondo.texture.get_size()
	_puerta = PUERTA.instantiate()
	contenido.add_child(_puerta)
	_puerta.global_position = Vector2(tamano.x * 0.5, limites.position.y + 16.0)
	_puerta.destino = cuarto["siguiente"]
	_puerta.cruzada.connect(_cambiar_de_cuarto)
	hud.avisar("¡Cuarto limpio! La salida se abrió")


func _cambiar_de_cuarto(destino: String) -> void:
	await _desvanecer(true)
	entrar(destino)
	await _desvanecer(false)


## Fundido a negro entre cuartos. Sin el, el cambio se siente como un salto.
func _desvanecer(a_negro: bool) -> Signal:
	velo.visible = true
	var animacion := create_tween()
	animacion.tween_property(velo, "color:a", 1.0 if a_negro else 0.0, 0.3)
	if not a_negro:
		animacion.tween_callback(func(): velo.visible = false)
	return animacion.finished


func _al_morir() -> void:
	hud.avisar("Te quedaste sin brillo.\nVuelves al inicio del cuarto")
	await get_tree().create_timer(1.2).timeout
	_jugador.vida = _jugador.vida_maxima
	_jugador.vida_cambiada.emit(_jugador.vida, _jugador.vida_maxima)
	entrar(cuarto["clave"])


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		if evento.keycode == KEY_ESCAPE:
			get_tree().paused = not get_tree().paused
			hud.mostrar_pausa(get_tree().paused)
