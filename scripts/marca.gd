# Aviso en el piso de que ahí va a salir un enemigo.
extends Node2D

var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var r := 6.0 + fmod(t * 18.0, 10.0)
	draw_arc(Vector2.ZERO, r, 0, TAU, 20, Color(0.7, 0.7, 0.75, 0.8), 2.0)
	draw_circle(Vector2.ZERO, 4.0, Color(0.45, 0.45, 0.5, 0.6))
