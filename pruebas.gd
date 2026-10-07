extends SceneTree
## Comprobacion rapida de los datos del juego, sin abrir ventana.
## Revisa que cada cuarto tenga su imagen, que los enemigos y jefes que
## menciona existan, y que la cadena de niveles llegue hasta el final.

const Niveles := preload("res://scripts/niveles.gd")


func _initialize() -> void:
	var fallas := 0

	for cuarto in Niveles.CUARTOS:
		var clave: String = cuarto["clave"]
		if not ResourceLoader.exists(cuarto["fondo"]):
			print("FALTA el fondo de ", clave, ": ", cuarto["fondo"])
			fallas += 1

		for e in cuarto["enemigos"]:
			if not Niveles.ENEMIGOS.has(e[0]):
				print("enemigo desconocido en ", clave, ": ", e[0])
				fallas += 1

		if cuarto["jefe"] != "" and not Niveles.JEFES.has(cuarto["jefe"]):
			print("jefe desconocido en ", clave, ": ", cuarto["jefe"])
			fallas += 1

		for g in cuarto["gente"]:
			var ruta := "res://sprites/personajes/%s.png" % g[0]
			if not ResourceLoader.exists(ruta):
				print("falta el sprite de ", g[0])
				fallas += 1

	for nombre in Niveles.ENEMIGOS:
		if not ResourceLoader.exists(Niveles.ENEMIGOS[nombre]["sprite"]):
			print("falta el sprite del enemigo ", nombre)
			fallas += 1
	for nombre in Niveles.JEFES:
		if not ResourceLoader.exists(Niveles.JEFES[nombre]["sprite"]):
			print("falta el sprite del jefe ", nombre)
			fallas += 1

	# El recorrido debe empezar en la joyeria y terminar en el taller.
	var visitados := []
	var actual: String = Niveles.CUARTOS[0]["clave"]
	while actual != "" and not visitados.has(actual):
		visitados.append(actual)
		actual = Niveles.cuarto(actual)["siguiente"]
	print("recorrido: ", " -> ".join(visitados))
	if visitados.size() != Niveles.CUARTOS.size():
		print("ATENCION: hay cuartos sueltos fuera del recorrido")
		fallas += 1

	# Las escenas que arma el mundo deben poder cargarse.
	for escena in ["res://escenas/mundo.tscn", "res://escenas/jugador.tscn",
			"res://escenas/enemigo.tscn", "res://escenas/jefe.tscn",
			"res://escenas/puerta.tscn", "res://escenas/persona.tscn",
			"res://escenas/haz.tscn", "res://escenas/destello.tscn",
			"res://escenas/hud.tscn"]:
		if load(escena) == null:
			print("no carga ", escena)
			fallas += 1

	print("fallas: ", fallas)
	quit()
