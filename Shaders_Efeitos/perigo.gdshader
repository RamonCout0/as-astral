// perigo.gdshader
// Brilho/energia para os cubos de ataque. Usa a cor do ColorRect (COLOR) — cada
// ataque pulsa na SUA cor — e preserva o alpha do telegrafo (piscar).
shader_type canvas_item;

uniform float pulse_speed = 5.0;
uniform float glow = 0.6;
uniform float band_speed = 2.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			   mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec4 base = COLOR;
	vec2 uv = UV;
	float t = TIME;

	// Bandas de energia correndo na diagonal.
	float band = 0.5 + 0.5 * sin((uv.x + uv.y) * 12.0 - t * band_speed * 6.0);

	// Ruído animado sutil pra dar textura.
	float n = noise(uv * 6.0 + t * 1.5);

	// Pulso geral.
	float p = 0.5 + 0.5 * sin(t * pulse_speed);

	// Contorno aceso.
	vec2 d = abs(uv - 0.5) * 2.0;
	float rim = smoothstep(0.74, 1.0, max(d.x, d.y));

	vec3 col = base.rgb;
	col *= 0.7 + glow * p + 0.25 * band + 0.15 * n;
	col += base.rgb * rim * 1.3;          // borda da própria cor, acesa
	col += vec3(1.0) * rim * 0.18;        // leve branco no contorno

	COLOR = vec4(col, base.a);
}
