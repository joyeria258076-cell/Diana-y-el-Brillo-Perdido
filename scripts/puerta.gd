extends Area2D
## La salida al siguiente cuarto. Aparece cuando ya no queda nada oxidado.
##
## Se dibuja con codigo y no con un sprite: es un portal de luz que late,
## con dos flechas que suben. A esta escala se lee mejor que una puerta
## dibujada, y ademas deja claro que es algo a lo que hay que entrar.

signal cruzada(destino: String)

const Efectos := preload("res://scripts/efectos.gd")
const LUZ := preload("res://sprites/interfaz/luz.png")

var destino: String = ""
var _usada: bool = false


func _ready() -> void:
	body_entered.connect(_al_entrar)
	_armar_portal()
	_latir()


func _armar_portal() -> void:
	var halo := Sprite2D.new()
	halo.texture = LUZ
	halo.modulate = Color(1.0, 0.92, 0.6, 0.85)
	halo.scale = Vector2(1.5, 1.1)
	halo.name = "Halo"
	add_child(halo)

	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.color = Color(1.0, 0.88, 0.55)
	luz.energy = 1.3
	luz.texture_scale = 1.6
	add_child(luz)

	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = Vector2(70, 48)
	forma.shape = caja
	add_child(forma)

	# Dos flechas que suben: dicen "por aqui" sin escribirlo.
	for i in 2:
		var flecha := Label.new()
		flecha.text = "▲"
		flecha.position = Vector2(-9, 4 + i * 14)
		flecha.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 0.9))
		flecha.add_theme_font_size_override("font_size", 16)
		add_child(flecha)
		var sube := flecha.create_tween().set_loops()
		sube.tween_interval(i * 0.25)
		sube.tween_property(flecha, "position:y", flecha.position.y - 16, 0.7)
		sube.parallel().tween_property(flecha, "modulate:a", 0.0, 0.7)
		sube.tween_property(flecha, "position:y", flecha.position.y, 0.0)
		sube.parallel().tween_property(flecha, "modulate:a", 0.9, 0.0)


func _latir() -> void:
	var halo := get_node("Halo")
	var animacion := create_tween().set_loops()
	animacion.tween_property(halo, "scale", Vector2(1.75, 1.3), 0.8) \
		.set_trans(Tween.TRANS_SINE)
	animacion.tween_property(halo, "scale", Vector2(1.5, 1.1), 0.8) \
		.set_trans(Tween.TRANS_SINE)


func _al_entrar(cuerpo: Node) -> void:
	if _usada or not cuerpo.is_in_group("jugador"):
		return
	_usada = true
	Efectos.humo(get_parent(), global_position, Color(1, 0.95, 0.7, 0.9), 70.0)
	cruzada.emit(destino)
