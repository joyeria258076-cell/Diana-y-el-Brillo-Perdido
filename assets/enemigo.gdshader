// Enemigos: contorno blanco al recibir daño, destello blanco y ojos que brillan en la penumbra.
shader_type canvas_item;

uniform float contorno = 0.0;      // 0 = sin contorno, 1 = contorno
uniform vec3 color_contorno = vec3(1.0);   // blanco por defecto; el gólem lo lleva morado
uniform float destello = 0.0;      // mezcla hacia blanco
uniform vec3 color_ojos = vec3(1.0, 0.85, 0.35);
uniform float brillo_ojos = 0.0;   // cuánto brillan los pixeles del color de los ojos
uniform float volumen = 0.0;       // luz arriba / sombra abajo para que no se vean planos
uniform float reflejo = 0.0; 
uniform float ondula = 0.0;      // gelatina: las filas se mecen en pixeles enteros (gota)
uniform vec3 color_vena = vec3(0.18, 0.22, 0.04);
uniform float vena = 0.0;        // brillo ácido que recorre el cuerpo de arriba abajo (gota)
uniform float realce = 1.0;      // aclara la penumbra sin quemar los claros a blanco     // brillo en las orillas de arriba (luz que pega desde arriba)

void fragment() {
	vec2 uv = UV;
	if (ondula > 0.0) {
		float fila = floor(UV.y / TEXTURE_PIXEL_SIZE.y / 6.0);
		float d = floor(sin(fila * 0.9 + TIME * 5.0) * ondula + 0.5) * 3.0;
		uv.x += d * TEXTURE_PIXEL_SIZE.x * (1.0 - smoothstep(0.75, 0.95, UV.y));
	}
	vec4 c = texture(TEXTURE, uv);
	if (c.a < 0.5) {
		if (contorno > 0.0) {
			vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
			float a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
				+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
			if (a > 0.5) {
				c = vec4(color_contorno, contorno);
			}
		}
	} else {
		if (brillo_ojos > 0.0 && distance(c.rgb, color_ojos) < 0.24) {
			c.rgb = c.rgb * (1.0 + brillo_ojos) + color_ojos * 0.25 * brillo_ojos;
		}
		// Volumen: la tira es una sola fila, así que UV.y va de arriba (0) a abajo (1).
		c.rgb *= mix(1.0 + volumen * 0.5, 1.0 - volumen, smoothstep(0.15, 1.0, UV.y));
		// Reflejo: pixel con hueco transparente arriba de él = orilla iluminada.
		vec2 px2 = TEXTURE_PIXEL_SIZE * 2.0;
		float arriba = texture(TEXTURE, UV - vec2(0.0, px2.y)).a;
		float arriba2 = texture(TEXTURE, UV - vec2(0.0, px2.y * 2.0)).a;
		if (arriba < 0.5 || arriba2 < 0.5) {
			float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
			if (lum > 0.12) {
				c.rgb += vec3(1.0, 0.92, 0.8) * reflejo * (arriba < 0.5 ? 1.0 : 0.5);
			}
		}
		if (vena > 0.0) {
			float banda = fract(TIME * 0.45);
			float fy = floor(UV.y * 40.0) / 40.0;
			float lum2 = dot(c.rgb, vec3(0.3, 0.59, 0.11));
			if (abs(fy - banda) < 0.03 && lum2 > 0.15) {
				c.rgb += color_vena * vena;
			}
		}
		c.rgb = vec3(1.0) - pow(vec3(1.0) - c.rgb, vec3(realce));   // curva suave: los oscuros suben, los claros no llegan a blanco
		c.rgb = mix(c.rgb, vec3(1.0), destello);
	}
	COLOR = c * COLOR;
}
