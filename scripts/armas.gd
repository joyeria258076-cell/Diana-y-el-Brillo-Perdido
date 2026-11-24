# Objetos del mostrador que usa Diana (libreto, sección 7.2) y su dibujo con los
# sprites de "sprites armas". Diana no usa armas: pule con lo que hay en la joyería.
class_name Armas

# tipo: forma de pulir. costo: brillo por uso (las que cuestan más pegan más fuerte). cadencia: segundos entre usos.
# giro: ángulo del sprite para que la punta quede hacia la derecha al apuntar.
const DATOS := {
	"lupa": {"nombre": "Lupa de Aurelio", "tipo": "destello", "costo": 3, "cadencia": 0.26, "dano": 1,
		"color": Color(1.0, 0.9, 0.55), "giro": 2.36},
	"espejo": {"nombre": "Espejo del aparador", "tipo": "abanico", "costo": 7, "cadencia": 0.5, "dano": 2,
		"color": Color(0.8, 0.95, 1.0), "giro": 2.36},
	"pano": {"nombre": "Paño de pulir", "tipo": "corte", "costo": 0, "cadencia": 0.42, "dano": 3,
		"color": Color(1.0, 0.7, 0.8), "giro": 0.0},
	"collar": {"nombre": "Collar de perlas", "tipo": "latigo", "costo": 7, "cadencia": 0.55, "dano": 2,
		"color": Color(0.97, 0.95, 0.9), "giro": 0.0},
	"limpiador": {"nombre": "Limpiador ultrasónico", "tipo": "onda", "costo": 12, "cadencia": 0.7, "dano": 5,
		"color": Color(0.55, 0.85, 1.0), "giro": 0.0},
	"aros": {"nombre": "Aros de destello", "tipo": "aros", "costo": 5, "cadencia": 0.3, "dano": 2,
		"color": Color(1.0, 0.85, 0.35), "giro": 0.0},
}
# Los que salen en cofres de la Bodega; los demás quedan para la Mina y el Taller.
const BODEGA := ["espejo", "pano", "collar", "limpiador", "aros"]

static func nombre(id: String) -> String:
	return DATOS[id].nombre

# Las texturas se guardan aquí: si se sueltan después de dibujar, Godot pinta un cuadro blanco.
static var _cache := {}

static func textura(id: String) -> Texture2D:
	if not _cache.has(id):
		_cache[id] = load("res://assets/objetos/arma_%s.png" % id)
	return _cache[id]

# Dibujo en el HUD o en el piso: derecho, centrado en (12*s, 0).
static func dibujar(c: CanvasItem, id: String, s := 1.0) -> void:
	# Diseño nuevo (tira animada) si existe; si no, la imagen vieja.
	var anim := "arma_%s_anim" % id
	if Fx.meta_o_nada(anim):
		var m := Fx.meta(anim)
		var f := int(Time.get_ticks_msec() / 160) % int(m.n)
		var k := 22.0 * s / maxf(float(m.h), float(m.w) * 1.1)
		var tm := Vector2(m.w, m.h) * k
		c.draw_texture_rect(Fx.cuadro(anim, f), Rect2(Vector2(12 * s, 0) - tm / 2.0, tm), false)
		return
	var t := textura(id)
	var tam := t.get_size() * 0.5 * s
	c.draw_texture_rect(t, Rect2(Vector2(12 * s, 0) - tam / 2.0, tam), false)

# Dibujo en la mano: gira hacia "angulo" con la punta al frente.
static func dibujar_en_mano(c: CanvasItem, id: String, angulo: float, distancia: float) -> void:
	var t: Texture2D = textura(id)
	var tam := t.get_size() * 0.5 * 0.9
	# Si el arma tiene tira animada (arma_<id>_anim), se dibuja su cuadro actual al mismo tamaño.
	var anim := "arma_%s_anim" % id
	if Fx.meta_o_nada(anim):
		var m := Fx.meta(anim)
		var f := int(Time.get_ticks_msec() / 160) % int(m.n)
		var k := tam.x / float(m.w)
		t = Fx.cuadro(anim, f)
		tam = Vector2(m.w, m.h) * k * 1.25
	var izquierda := absf(angulo) > PI / 2.0
	var giro: float = DATOS[id].giro
	c.draw_set_transform(Vector2.RIGHT.rotated(angulo) * distancia, angulo + (giro if not izquierda else -giro), Vector2(1, -1 if izquierda else 1))
	c.draw_texture_rect(t, Rect2(-tam / 2.0, tam), false)
	c.draw_set_transform(Vector2.ZERO)
