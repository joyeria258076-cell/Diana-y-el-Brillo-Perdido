# Aviso de que ahí va a salir un enemigo: un círculo de runas que gira y crece,
# con chispas que suben. Dura lo que tarda en aparecer el enemigo.
extends Node2D

var t := 0.0
var color := Color(0.75, 0.45, 1.0)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var k := minf(t / 0.8, 1.0)
	var r := 6.0 + 20.0 * k
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, r, Color(color, 0.18 * k))
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(color, 0.85), 2.0)
	draw_arc(Vector2.ZERO, r * 0.65, 0, TAU, 24, Color(1, 1, 1, 0.5 * k), 1.0)
	for i in 6:   # runas que giran
		var a := t * 2.5 + TAU * i / 6.0
		var p := Vector2.RIGHT.rotated(a) * r * 0.82
		draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.9, 1, 0.9))
	draw_set_transform(Vector2.ZERO)
	for i in 5:   # chispas que suben
		var f := fmod(t * 1.4 + i * 0.2, 1.0)
		var x := sin(i * 2.3 + t) * r * 0.7
		Ui.estrella(self, Vector2(x, -f * 28.0 * k), 1.2, Color(color.lightened(0.4), 1.0 - f))
