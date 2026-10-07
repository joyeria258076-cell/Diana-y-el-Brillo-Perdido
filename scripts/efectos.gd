extends Node
## Caja de herramientas de efectos visuales.
##
## Todo lo de aqui se crea y se destruye solo: no hay que preparar escenas
## ni acordarse de limpiar. Son los detalles que hacen que el juego se
## sienta vivo aunque los sprites sean los mismos: el golpe que destella,
## la cámara que tiembla, el polvo de los pasos, el humo que suelta un
## enemigo al quedar limpio.

const LUZ := preload("res://sprites/interfaz/luz.png")


## Destello blanco corto sobre un sprite. Es la forma mas barata de avisar
## que algo recibio un impacto.
static func parpadear(sprite: CanvasItem, veces: int = 1) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var animacion := sprite.create_tween()
	for _i in veces:
		animacion.tween_property(sprite, "modulate", Color(3, 3, 3), 0.04)
		animacion.tween_property(sprite, "modulate", Color.WHITE, 0.1)


## Chispas que salen del punto de impacto. La direccion las abre en abanico
## hacia donde venia el golpe.
static func chispas(padre: Node, donde: Vector2, color: Color,
		cantidad: int = 10, direccion: Vector2 = Vector2.ZERO) -> void:
	var p := CPUParticles2D.new()
	p.position = donde
	p.amount = cantidad
	p.lifetime = 0.42
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 0.95
	p.spread = 38.0 if direccion != Vector2.ZERO else 180.0
	p.direction = direccion if direccion != Vector2.ZERO else Vector2.UP
	p.initial_velocity_min = 55.0
	p.initial_velocity_max = 150.0
	p.gravity = Vector2(0, 180)
	p.scale_amount_min = 1.4
	p.scale_amount_max = 2.6
	p.color = color
	padre.add_child(p)
	p.finished.connect(p.queue_free)


## Anillo de humo que se abre y se desvanece. Se usa cuando un enemigo
## queda limpio y cuando el jefe se teletransporta.
static func humo(padre: Node, donde: Vector2, color: Color = Color(0.8, 0.8, 0.85, 0.75),
		tamano: float = 26.0) -> void:
	var aro := Sprite2D.new()
	aro.texture = LUZ
	aro.position = donde
	aro.modulate = color
	aro.scale = Vector2.ONE * 0.2
	padre.add_child(aro)

	var animacion := aro.create_tween()
	animacion.set_parallel(true)
	animacion.tween_property(aro, "scale", Vector2.ONE * (tamano / 40.0), 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(aro, "modulate:a", 0.0, 0.45)
	animacion.chain().tween_callback(aro.queue_free)


## Resplandor corto en un punto: el fogonazo de la lupa al disparar.
static func fogonazo(padre: Node, donde: Vector2, color: Color, fuerza: float = 0.7) -> void:
	var luz := PointLight2D.new()
	luz.texture = LUZ
	luz.position = donde
	luz.color = color
	luz.energy = fuerza
	luz.texture_scale = 0.9
	padre.add_child(luz)

	var animacion := luz.create_tween()
	animacion.tween_property(luz, "energy", 0.0, 0.14)
	animacion.tween_callback(luz.queue_free)


## Polvo bajo los pies al caminar.
static func polvo(padre: Node, donde: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = donde
	p.amount = 4
	p.lifetime = 0.35
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 0.8
	p.spread = 180.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 22.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.85, 0.82, 0.74, 0.5)
	padre.add_child(p)
	p.finished.connect(p.queue_free)


## Numero flotante, para que se vea cuanto oxido le quitaste a un enemigo.
static func numero(padre: Node, donde: Vector2, texto: String, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.position = donde + Vector2(-10, -24)
	etiqueta.z_index = 90
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_font_size_override("font_size", 13)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	etiqueta.add_theme_constant_override("outline_size", 4)
	padre.add_child(etiqueta)

	var animacion := etiqueta.create_tween()
	animacion.set_parallel(true)
	animacion.tween_property(etiqueta, "position:y", etiqueta.position.y - 22, 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion.tween_property(etiqueta, "modulate:a", 0.0, 0.6).set_delay(0.2)
	animacion.chain().tween_callback(etiqueta.queue_free)


## Sacudida de camara. `fuerza` en pixeles y `duracion` en segundos.
static func sacudir(camara: Camera2D, fuerza: float = 4.0, duracion: float = 0.22) -> void:
	if camara == null or not is_instance_valid(camara):
		return
	var azar := RandomNumberGenerator.new()
	azar.randomize()
	var pasos := int(duracion / 0.03)
	var animacion := camara.create_tween()
	for i in pasos:
		# La sacudida se va apagando: si no, se siente como un temblor parejo.
		var resto := fuerza * (1.0 - float(i) / float(maxi(pasos, 1)))
		animacion.tween_property(camara, "offset", Vector2(
			azar.randf_range(-resto, resto),
			azar.randf_range(-resto, resto)), 0.03)
	animacion.tween_property(camara, "offset", Vector2.ZERO, 0.05)


## Estela corta detras de un proyectil.
static func estela(padre: Node, donde: Vector2, color: Color) -> void:
	var punto := Sprite2D.new()
	punto.texture = LUZ
	punto.position = donde
	punto.modulate = color
	punto.scale = Vector2.ONE * 0.12
	punto.z_index = -1
	padre.add_child(punto)

	var animacion := punto.create_tween()
	animacion.set_parallel(true)
	animacion.tween_property(punto, "scale", Vector2.ONE * 0.02, 0.22)
	animacion.tween_property(punto, "modulate:a", 0.0, 0.22)
	animacion.chain().tween_callback(punto.queue_free)
