extends CanvasLayer
## La interfaz de la partida: corazones, barra de brillo, destellos, nombre
## del cuarto, barra del jefe y los avisos.
##
## Los corazones se crean por codigo a partir de la vida maxima, asi que si
## algun dia Diana aguanta mas golpes no hay que tocar la escena.

const CORAZON := preload("res://sprites/interfaz/corazon.png")
const ANCHO_BARRA: float = 278.0
const ANCHO_JEFE: float = 320.0

@onready var corazones: HBoxContainer = $Panel/Corazones
@onready var relleno: ColorRect = $Panel/BrilloRelleno
@onready var texto_brillo: Label = $Panel/BrilloTexto
@onready var texto_destellos: Label = $Panel/DestellosTexto
@onready var texto_nivel: Label = $NivelTexto
@onready var texto_aviso: Label = $Aviso
@onready var pendientes: Label = $Pendientes
@onready var caja_jefe: Panel = $Jefe
@onready var barra_jefe: ColorRect = $Jefe/Relleno
@onready var nombre_jefe: Label = $Jefe/Nombre
@onready var cartel_pausa: Label = $Pausa


func _ready() -> void:
	caja_jefe.visible = false
	cartel_pausa.visible = false
	texto_aviso.modulate.a = 0.0


func mostrar_vida(actual: int, maxima: int) -> void:
	# Se crean los corazones que falten; los sobrantes se quitan.
	while corazones.get_child_count() < maxima:
		var c := TextureRect.new()
		c.texture = CORAZON
		c.custom_minimum_size = Vector2(22, 22)
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		corazones.add_child(c)
	while corazones.get_child_count() > maxima:
		var sobra := corazones.get_child(corazones.get_child_count() - 1)
		corazones.remove_child(sobra)
		sobra.queue_free()

	for i in corazones.get_child_count():
		var corazon := corazones.get_child(i) as TextureRect
		corazon.modulate = Color.WHITE if i < actual else Color(0.3, 0.28, 0.3)


func mostrar_brillo(actual: int, maximo: int) -> void:
	var parte := clampf(float(actual) / float(maxi(maximo, 1)), 0.0, 1.0)
	relleno.size.x = ANCHO_BARRA * parte
	texto_brillo.text = "BRILLO  %d/%d" % [actual, maximo]


func mostrar_destellos(cantidad: int) -> void:
	texto_destellos.text = "%03d" % cantidad


func mostrar_nivel(texto: String) -> void:
	texto_nivel.text = texto


func mostrar_pendientes(cuantos: int) -> void:
	pendientes.text = "" if cuantos <= 0 else "Faltan %d por pulir" % cuantos


## Aviso que aparece, se queda un momento y se va solo.
func avisar(texto: String) -> void:
	texto_aviso.text = texto
	var animacion := create_tween()
	animacion.tween_property(texto_aviso, "modulate:a", 1.0, 0.25)
	animacion.tween_interval(2.6)
	animacion.tween_property(texto_aviso, "modulate:a", 0.0, 0.5)


func mostrar_jefe(visible_ahora: bool) -> void:
	caja_jefe.visible = visible_ahora


func nombrar_jefe(texto: String) -> void:
	nombre_jefe.text = texto


func mostrar_oxido_jefe(actual: int, total: int) -> void:
	var parte := clampf(float(actual) / float(maxi(total, 1)), 0.0, 1.0)
	var animacion := create_tween()
	animacion.tween_property(barra_jefe, "size:x", ANCHO_JEFE * parte, 0.18)
	# La barra se pone roja cuando al jefe le queda poco: avisa la fase final.
	barra_jefe.color = Color(0.85, 0.32, 0.3) if parte <= 0.34 \
		else Color(0.78, 0.55, 0.28)


func mostrar_pausa(en_pausa: bool) -> void:
	cartel_pausa.visible = en_pausa
