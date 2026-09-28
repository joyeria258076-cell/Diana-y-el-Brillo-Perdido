extends Area2D
## Destello: la moneda del juego. Se recoge al pasarle encima.

@export var valor: int = 1


func _ready() -> void:
	body_entered.connect(_al_tocar)
	_flotar()


## Pequeno vaiven para que se note que es algo que se recoge.
func _flotar() -> void:
	var animacion := create_tween().set_loops()
	animacion.tween_property(self, "position:y", position.y - 3.0, 0.6).set_trans(Tween.TRANS_SINE)
	animacion.tween_property(self, "position:y", position.y, 0.6).set_trans(Tween.TRANS_SINE)


func _al_tocar(cuerpo: Node) -> void:
	if cuerpo.has_method("recoger_destello"):
		cuerpo.recoger_destello(valor)
		queue_free()
