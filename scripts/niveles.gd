extends Node
## Los nueve cuartos del juego y como se conectan.
##
## Cada cuarto se describe aqui y no en una escena aparte: asi agregar o
## reacomodar niveles es tocar una sola lista, y el cuarto se arma solo al
## entrar. El fondo es la imagen completa del lugar; lo unico que hace falta
## declarar es por donde se puede caminar y que hay adentro.
##
##   fondo     imagen del cuarto
##   orillas   cuanto muro hay de cada lado (izq, arriba, der, abajo)
##   entrada   donde aparece Diana, en proporcion del cuarto (0 a 1)
##   enemigos  lista de [tipo, x, y], tambien en proporcion
##   gente     personajes con los que se puede hablar
##   jefe      si el cuarto tiene jefe, cual
##   siguiente que cuarto sigue cuando este queda limpio

const CUARTOS: Array[Dictionary] = [
	{
		"clave": "joyeria",
		"nombre": "Joyería Diana Laura",
		"fondo": "res://sprites/escenarios/joyeria.png",
		"orillas": [110, 150, 110, 120],
		"entrada": [0.5, 0.75],
		"enemigos": [],
		"gente": [
			["don_aurelio", 0.30, 0.55,
			"Toma, Diana. Esta lupa era de mi padre.\nCon ella se le ve el alma a una pieza."],
			["dona_chela", 0.70, 0.55,
			"Mi nieta cumple quince el sábado.\nNo me vayas a fallar con el anillo, mija."],
			["quilate", 0.5, 0.42,
			"¡Vi todo! El de la capucha se llevó las piezas\npor la puerta de atrás."],
		],
		"jefe": "",
		"siguiente": "calle",
		"aviso": "Habla con Don Aurelio y sal por la puerta",
	},
	{
		"clave": "calle",
		"nombre": "Calle de la Exposición",
		"fondo": "res://sprites/escenarios/calle.png",
		"orillas": [120, 170, 120, 130],
		"entrada": [0.5, 0.78],
		"enemigos": [
			["escarabajo", 0.28, 0.42],
			["escarabajo", 0.72, 0.42],
		],
		"gente": [],
		"jefe": "",
		"siguiente": "bodega",
		"aviso": "La niebla ya llegó aquí",
	},
	{
		"clave": "bodega",
		"nombre": "Bodega del Proveedor",
		"fondo": "res://sprites/escenarios/bodega.png",
		"orillas": [110, 120, 110, 110],
		"entrada": [0.5, 0.80],
		"enemigos": [
			["escarabajo", 0.22, 0.40],
			["escarabajo", 0.78, 0.40],
			["polilla", 0.40, 0.28],
			["polilla", 0.62, 0.30],
			["escarabajo", 0.50, 0.62],
		],
		"gente": [],
		"jefe": "",
		"siguiente": "pasillo_horizontal",
		"aviso": "",
	},
	{
		"clave": "pasillo_horizontal",
		"nombre": "Pasillo de Carga",
		"fondo": "res://sprites/escenarios/pasillo_horizontal.png",
		"orillas": [100, 120, 100, 110],
		"entrada": [0.12, 0.55],
		"enemigos": [
			["polilla", 0.40, 0.45],
			["escarabajo", 0.60, 0.55],
			["polilla", 0.80, 0.45],
		],
		"gente": [],
		"jefe": "",
		"siguiente": "sala_jefe",
		"aviso": "",
	},
	{
		"clave": "sala_jefe",
		"nombre": "Patio de Carga",
		"fondo": "res://sprites/escenarios/sala_jefe.png",
		"orillas": [120, 140, 120, 120],
		"entrada": [0.5, 0.82],
		"enemigos": [],
		"gente": [],
		"jefe": "vendedor_de_humo",
		"siguiente": "mina_hielo",
		"aviso": "El Vendedor de Humo trae puesto el Anillo Alborada",
	},
	{
		"clave": "mina_hielo",
		"nombre": "Mina de Cuarzo",
		"fondo": "res://sprites/escenarios/mina_hielo.png",
		"orillas": [110, 130, 110, 110],
		"entrada": [0.5, 0.80],
		"enemigos": [
			["escarabajo", 0.25, 0.40],
			["escarabajo", 0.75, 0.40],
			["golem_de_carbon", 0.50, 0.35],
		],
		"gente": [],
		"jefe": "",
		"siguiente": "pasillo_vertical",
		"aviso": "",
	},
	{
		"clave": "pasillo_vertical",
		"nombre": "Galería del Río",
		"fondo": "res://sprites/escenarios/pasillo_vertical.png",
		"orillas": [90, 120, 90, 110],
		"entrada": [0.5, 0.85],
		"enemigos": [
			["polilla", 0.35, 0.40],
			["polilla", 0.65, 0.55],
		],
		"gente": [],
		"jefe": "",
		"siguiente": "mina_abismo",
		"aviso": "",
	},
	{
		"clave": "mina_abismo",
		"nombre": "Salón de los Cristales",
		"fondo": "res://sprites/escenarios/mina_abismo.png",
		"orillas": [120, 140, 120, 120],
		"entrada": [0.5, 0.82],
		"enemigos": [],
		"gente": [],
		"jefe": "carbonel",
		"siguiente": "taller",
		"aviso": "Carbonel guarda el Collar Luna de Plata",
	},
	{
		"clave": "taller",
		"nombre": "Taller de Imitaciones",
		"fondo": "res://sprites/escenarios/taller.png",
		"orillas": [120, 140, 120, 120],
		"entrada": [0.5, 0.82],
		"enemigos": [
			["escarabajo", 0.25, 0.35],
			["escarabajo", 0.75, 0.35],
		],
		"gente": [],
		"jefe": "baron_oxido",
		"siguiente": "",
		"aviso": "El Barón Óxido tiene la Esclava del Sol",
	},
]

## Como se comporta cada enemigo. El oxido hace las veces de vida: cuando
## llega a cero el enemigo no muere, queda limpio y se retira.
const ENEMIGOS: Dictionary = {
	"escarabajo": {
		"sprite": "res://sprites/personajes/escarabajo.png",
		"oxido": 3, "velocidad": 52.0, "alerta": 260.0, "dano": 1,
		"empuje": 90.0, "nombre": "Escarabajo Oxidado",
	},
	"polilla": {
		"sprite": "res://sprites/personajes/polilla.png",
		"oxido": 2, "velocidad": 70.0, "alerta": 320.0, "dano": 1,
		"empuje": 60.0, "vuela": true, "zigzag": true,
		"nombre": "Polilla de Hollín",
	},
	"golem_de_carbon": {
		"sprite": "res://sprites/personajes/golem_de_carbon.png",
		"oxido": 8, "velocidad": 34.0, "alerta": 300.0, "dano": 2,
		"empuje": 40.0, "nombre": "Gólem de Carbón",
	},
}

## Los jefes. Cada uno pelea distinto, como dice el libreto.
const JEFES: Dictionary = {
	"vendedor_de_humo": {
		"sprite": "res://sprites/personajes/vendedor_de_humo.png",
		"oxido": 26, "velocidad": 46.0, "dano": 1,
		"nombre": "Vendedor de Humo",
		"patron": "parpadeo",
		"pieza": "Anillo Alborada",
		"recompensa": "Impulso de luz: ahora esquivas con Espacio",
	},
	"carbonel": {
		"sprite": "res://sprites/personajes/carbonel.png",
		"oxido": 30, "velocidad": 62.0, "dano": 1,
		"nombre": "Carbonel",
		"patron": "escondite",
		"pieza": "Collar Luna de Plata",
		"recompensa": "Aura de luz: ves más lejos en la oscuridad",
	},
	"baron_oxido": {
		"sprite": "res://sprites/personajes/baron_oxido.png",
		"oxido": 40, "velocidad": 40.0, "dano": 2,
		"nombre": "Barón Óxido",
		"patron": "copias",
		"pieza": "Esclava del Sol",
		"recompensa": "¡Recuperaste las tres piezas!",
	},
}


## Devuelve el cuarto que lleva esa clave.
static func cuarto(clave: String) -> Dictionary:
	for c in CUARTOS:
		if c["clave"] == clave:
			return c
	return CUARTOS[0]


## En que numero de la lista va ese cuarto, para mostrar el avance.
static func numero_de(clave: String) -> int:
	for i in CUARTOS.size():
		if CUARTOS[i]["clave"] == clave:
			return i + 1
	return 1
