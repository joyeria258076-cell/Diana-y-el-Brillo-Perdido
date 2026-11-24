# Espina de esencia que brota del piso cuando el guardia golpea con el mazo.
# Se queda clavada (hiere a Diana si la toca) hasta que la rompen a disparos o golpes.
extends Node2D

const MAXIMO := 40   # tope para que no broten más (las que hay no se quitan solas)

var main
var objetivo
var vida := 2
var esc := 1.0
var variante := -1   # -1: animada (brota y late); 0..4: forma alta fija; 10..12: espina corta (a medio brotar)
var lista := false   # ya terminó de brotar (antes no hiere)
var _cd := 0.0
var spr: Node2D
var luz: PointLight2D

static func cuantas(arbol: SceneTree) -> int:
	return arbol.get_nodes_in_group("espinas").size()

func _ready() -> void:
	add_to_group("espinas")
	var brillo := CanvasItemMaterial.new()
	brillo.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	if variante < 0:
		var sf := SpriteFrames.new()
		sf.add_animation("brota")
		sf.set_animation_loop("brota", false)
		sf.set_animation_speed("brota", 16.0)
		for i in int(Fx.meta("fx_esp_brota").n):
			sf.add_frame("brota", Fx.cuadro("fx_esp_brota", i))
		sf.set_animation_speed("default", 6.0)
		for i in int(Fx.meta("fx_esp_quieta").n):
			sf.add_frame("default", Fx.cuadro("fx_esp_quieta", i))
		var a := AnimatedSprite2D.new()
		a.sprite_frames = sf
		a.play("brota")
		a.animation_finished.connect(func(): a.play("default"))
		spr = a
		var h: float = Fx.meta("fx_esp_brota").h
		a.offset = Vector2(0, -h * 0.5 + 3.0)
	else:
		var s := Sprite2D.new()
		var hoja := "fx_esp_var" if variante < 10 else "fx_esp_brota"
		s.texture = Fx.cuadro(hoja, variante if variante < 10 else variante - 8)
		var h: float = Fx.meta(hoja).h
		s.offset = Vector2(0, -h * 0.5 + 3.0)
		spr = s
		# brota estirándose desde el piso
		s.scale = Vector2(0.6, 0.0)
		var t := s.create_tween()
		t.tween_property(s, "scale", Vector2(0.6, 0.72), 0.1).set_ease(Tween.EASE_OUT)
		t.tween_property(s, "scale", Vector2(0.6, 0.6), 0.08)
	spr.material = brillo
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if variante < 0:
		spr.scale = Vector2.ONE * 0.6   # escala fija: nítidas (la variedad sale de las formas)
	if randf() < 0.5:
		spr.set("flip_h", true)
	add_child(spr)
	# luz morada propia que late
	luz = PointLight2D.new()
	luz.texture = Fx.textura_luz()
	luz.texture_scale = 0.32 * esc
	luz.color = Color(0.6, 0.3, 1.0)
	luz.energy = 0.0
	luz.position = Vector2(0, -18.0 * esc)
	add_child(luz)
	var tl := luz.create_tween()
	tl.tween_property(luz, "energy", 1.6, 0.1)
	tl.tween_property(luz, "energy", 0.7, 0.3)
	tl.tween_callback(func():
		var lat := luz.create_tween().set_loops()
		lat.tween_property(luz, "energy", 1.0, randf_range(0.7, 1.1)).set_trans(Tween.TRANS_SINE)
		lat.tween_property(luz, "energy", 0.55, randf_range(0.7, 1.1)).set_trans(Tween.TRANS_SINE))
	# motas de esencia que suben alrededor
	var mo := CPUParticles2D.new()
	mo.amount = 5
	mo.lifetime = 1.3
	mo.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mo.emission_rect_extents = Vector2(6.0 * esc, 14.0 * esc)
	mo.position = Vector2(0, -16.0 * esc)
	mo.direction = Vector2(0, -1)
	mo.spread = 25.0
	mo.gravity = Vector2(0, -10)
	mo.initial_velocity_min = 3.0
	mo.initial_velocity_max = 8.0
	mo.scale_amount_min = 1.0
	mo.scale_amount_max = 2.0
	var gm := Gradient.new()
	gm.set_color(0, Color(0.9, 0.7, 1.0, 0.0))
	gm.add_point(0.25, Color(0.85, 0.6, 1.0, 0.9))
	gm.set_color(gm.get_point_count() - 1, Color(0.5, 0.25, 0.9, 0.0))
	mo.color_ramp = gm
	mo.material = brillo
	add_child(mo)
	# al brotar: grieta, piedritas, chispas moradas y un destello
	Fx.chispas(main.mundo, position + Vector2(0, -4), Color(0.75, 0.45, 1.0), 4)
	Fx.polvo(main.mundo, position)
	get_tree().create_timer(0.25).timeout.connect(func(): lista = true)

func _process(delta: float) -> void:
	_cd -= delta
	if lista and _cd <= 0.0 and is_instance_valid(objetivo):
		var d: Vector2 = objetivo.position - position
		if absf(d.x) < 11.0 and absf(d.y) < 8.0:
			_cd = 0.8
			objetivo.herir(1, d.normalized())

# Para los disparos de Diana (como los muebles que se rompen).
func toca(p: Vector2) -> bool:
	return absf(p.x - position.x) < 11.0 and p.y < position.y + 5.0 and p.y > position.y - 60.0

func golpear(n := 1) -> void:
	vida -= n
	var pi := position + Vector2(randf_range(-3, 3), -randf_range(10.0, 24.0))
	var imp := Fx.animar(main.mundo, pi, "fx_esp_impacto", 18.0, Color.WHITE, 0.8, randf() < 0.5)
	imp.material = _sin_luz(true)
	_astillas(pi, 3)
	Fx.chispas(main.mundo, pi, Color(0.8, 0.5, 1.0), 4)
	spr.modulate = Color(2.0, 1.6, 2.4)
	create_tween().tween_property(spr, "modulate", Color.WHITE, 0.15)
	if vida <= 0:
		romper()

func romper() -> void:
	if is_queued_for_deletion():
		return
	remove_from_group("espinas")
	# desintegración: se ilumina por dentro, se quiebra en pedazos curvos y se vuelve polvo de luz
	var fx := Fx.animar(main.mundo, position, "fx_esp_desin", 13.0, Color.WHITE, 1.0, spr.get("flip_h") == true)
	fx.offset = Vector2(0, -Fx.meta("fx_esp_desin").h * 0.5 + 3.0)
	fx.material = _sin_luz(false)
	fx.z_index = 3
	_astillas(position + Vector2(0, -16), 6)
	Fx.chispas(main.mundo, position + Vector2(0, -14.0), Color(0.8, 0.5, 1.0), 8)
	# polvo de esencia que sube y motas/destellos que se apagan (lo que el fondo rosa se comió del dibujo)
	var pol := CPUParticles2D.new()
	pol.position = position + Vector2(0, -12)
	pol.one_shot = true
	pol.emitting = true
	pol.amount = 22
	pol.lifetime = 1.2
	pol.explosiveness = 0.6
	pol.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pol.emission_rect_extents = Vector2(6, 14)
	pol.direction = Vector2(0, -1)
	pol.spread = 40.0
	pol.gravity = Vector2(0, -14)
	pol.initial_velocity_min = 6.0
	pol.initial_velocity_max = 22.0
	pol.scale_amount_min = 1.0
	pol.scale_amount_max = 2.5
	var gp := Gradient.new()
	gp.set_color(0, Color(1.0, 0.9, 1.0, 1.0))
	gp.add_point(0.3, Color(0.8, 0.55, 1.0, 0.9))
	gp.set_color(gp.get_point_count() - 1, Color(0.45, 0.2, 0.8, 0.0))
	pol.color_ramp = gp
	pol.material = _sin_luz(true)
	main.mundo.add_child(pol)
	get_tree().create_timer(1.6).timeout.connect(pol.queue_free)
	for k in 3:
		_destello(position + Vector2(randf_range(-10, 10), -randf_range(6, 30)), 0.15 * k)
	Juego.sonido("golpe", true, -12.0)
	var tl := luz.create_tween()
	tl.tween_property(luz, "energy", 2.0, 0.05)
	tl.tween_property(luz, "energy", 0.0, 0.35)
	spr.visible = false
	set_process(false)
	get_tree().create_timer(0.45).timeout.connect(queue_free)


func _sin_luz(sumar: bool) -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	if sumar:
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

# Astillas curvas de espina y chispas moradas que saltan y caen.
func _astillas(p: Vector2, n: int) -> void:
	for i in n:
		var a := Sprite2D.new()
		a.texture = Fx.cuadro("fx_esp_part", [0, 1, 2, 7, 8][randi() % 5])
		a.scale = Vector2.ONE * 0.4
		a.position = p
		a.z_index = 4
		a.material = _sin_luz(false)
		main.mundo.add_child(a)
		var fin := p + Vector2(randf_range(-26, 26), randf_range(6, 18))
		var alt := randf_range(10, 22)
		var dur := randf_range(0.4, 0.6)
		var t := a.create_tween()
		t.tween_method(func(k: float):
			if is_instance_valid(a):
				a.position = p.lerp(fin, k) + Vector2(0, -sin(k * PI) * alt)
				a.rotation = k * randf_range(-5.0, 5.0), 0.0, 1.0, dur)
		t.tween_property(a, "modulate:a", 0.0, 0.4)
		t.tween_callback(a.queue_free)

func _destello(p: Vector2, retraso: float) -> void:
	var d := Sprite2D.new()
	d.texture = Fx.cuadro("fx_esp_part", 5 + randi() % 2)
	d.scale = Vector2.ZERO
	d.position = p
	d.z_index = 5
	d.material = _sin_luz(true)
	main.mundo.add_child(d)
	var t := d.create_tween()
	t.tween_interval(retraso)
	t.tween_property(d, "scale", Vector2.ONE * 0.45, 0.1)
	t.tween_property(d, "scale", Vector2.ZERO, 0.3)
	t.tween_callback(d.queue_free)
