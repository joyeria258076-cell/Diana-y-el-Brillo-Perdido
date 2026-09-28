extends CanvasLayer
## Interfaz de la partida: corazones, barra de brillo y contador de destellos.
## Por ahora muestra valores de ejemplo; cuando exista el jugador con vida y brillo,
## estos metodos se llamaran desde ahi.

const BRILLO_MAXIMO: int = 180
const ANCHO_BARRA: float = 278.0

@onready var corazones: HBoxContainer = $Panel/Corazones
@onready var barra_brillo: ColorRect = $Panel/BrilloRelleno
@onready var texto_brillo: Label = $Panel/BrilloTexto
@onready var texto_destellos: Label = $Panel/DestellosTexto


## Enciende o apaga corazones segun la vida que quede.
func mostrar_vida(corazones_llenos: int) -> void:
	if not is_node_ready():
		return
	for i in corazones.get_child_count():
		var corazon: TextureRect = corazones.get_child(i)
		corazon.modulate = Color.WHITE if i < corazones_llenos else Color(0.35, 0.33, 0.33)


## Ajusta el ancho de la barra de brillo, que es la "municion" de los objetos.
func mostrar_brillo(actual: int) -> void:
	if not is_node_ready():
		return
	var proporcion := clampf(float(actual) / BRILLO_MAXIMO, 0.0, 1.0)
	barra_brillo.size.x = ANCHO_BARRA * proporcion
	texto_brillo.text = "BRILLO  %d/%d" % [actual, BRILLO_MAXIMO]


func mostrar_destellos(cantidad: int) -> void:
	if not is_node_ready():
		return
	texto_destellos.text = "%03d" % cantidad
