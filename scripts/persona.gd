extends Area2D
## Personaje con el que se puede hablar: Don Aurelio, Doña Chela y Quilate.
##
## No hay que apretar nada. Al acercarse aparece el globo de dialogo y al
## alejarse desaparece; a esta escala es mas comodo que tener que presionar
## una tecla frente a cada quien.

const Efectos := preload("res://scripts/efectos.gd")

var dialogo: String = ""

@onready var sprite: Sprite2D = $Sprite
@onready var sombra: Sprite2D = $Sombra
@onready var globo: Panel = $Globo
@onready var texto: Label = $Globo/Texto

var _flota: float = 0.0


func preparar(ruta_sprite: String, lo_que_dice: String) -> void:
	dialogo = lo_que_dice
	var textura: Texture2D = load(ruta_sprite)
	$Sprite.texture = textura
	$Sprite.offset.y = -textura.get_height() * 0.5
	$Sombra.scale = Vector2(textura.get_width() / 58.0, 0.5)
	$Globo/Texto.text = lo_que_dice
	$Globo.position.y = -textura.get_height() - 46.0


func _ready() -> void:
	globo.modulate.a = 0.0
	body_entered.connect(_al_acercarse)
	body_exited.connect(_al_alejarse)


func _process(delta: float) -> void:
	# Respiracion: sube y baja apenas. Un personaje totalmente quieto se
	# ve como un adorno, no como alguien.
	_flota += delta * 1.6
	sprite.position.y = sin(_flota) * 1.6


func _al_acercarse(cuerpo: Node) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	globo.visible = true
	var animacion := create_tween()
	animacion.tween_property(globo, "modulate:a", 1.0, 0.18)
	Efectos.humo(get_parent(), global_position, Color(1, 1, 0.85, 0.35), 24.0)


func _al_alejarse(cuerpo: Node) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	var animacion := create_tween()
	animacion.tween_property(globo, "modulate:a", 0.0, 0.18)
