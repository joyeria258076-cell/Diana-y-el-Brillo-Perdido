# Construye SpriteFrames a partir de las tiras exportadas en assets/chars.
class_name Anim

static var data: Dictionary = {}

static func load_data() -> void:
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data.json"))

static func frames(anims: Dictionary) -> SpriteFrames:
	# anims = { "nombre_animacion": ["clave_tira", fps, loop] }
	load_data()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for name in anims:
		var key: String = anims[name][0]
		var info: Dictionary = data.chars[key]
		var tex: Texture2D = load("res://assets/chars/%s.png" % key) if key != "door" else load("res://assets/door.png")
		sf.add_animation(name)
		sf.set_animation_speed(name, anims[name][1])
		sf.set_animation_loop(name, anims[name][2])
		for i in int(info.n):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * info.w, 0, info.w, info.h)
			sf.add_frame(name, at)
	return sf

# Sprite con el origen en los pies, dibujado a la mitad (las tiras van a 2x).
static func sprite(anims: Dictionary, first: String) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames(anims)
	s.scale = Vector2(0.5, 0.5)
	s.animation = first
	s.play()
	var h: float = data.chars[anims[first][0]].h
	s.offset = Vector2(0, -h / 2.0)
	return s
