// nucleo.gdshader
// Núcleo letal do Vórtice — coluna de energia turbulenta com brilho central.
shader_type canvas_item;
render_mode blend_add;

uniform float speed = 2.0;
uniform vec4 col_a    : source_color = vec4(0.80, 0.10, 1.00, 1.0); // energia
uniform vec4 col_b    : source_color = vec4(0.30, 0.00, 0.55, 1.0); // sombra
uniform vec4 col_core : source_color = vec4(1.00, 0.80, 1.00, 1.0); // núcleo

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
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	// Fluxo subindo + turbulência (energia sendo sugada).
	float flow  = fbm(vec2(uv.x * 4.0, uv.y * 5.0 - t * 1.6));
	float swirl = sin(uv.y * 18.0 - t * 5.0 + uv.x * 8.0 + flow * 4.0);
	swirl = 0.5 + 0.5 * swirl;

	// Eixo central mais brilhante.
	float cx = pow(clamp(1.0 - abs(uv.x - 0.5) * 2.0, 0.0, 1.0), 1.2);

	vec3 col = mix(col_b.rgb, col_a.rgb, swirl);
	col = mix(col, col_core.rgb, cx * cx * 0.85);
	col *= 0.7 + 0.6 * flow;
	col *= 0.9 + 0.15 * sin(t * 4.0);          // pulso

	float alpha = clamp(cx * 0.7 + 0.45, 0.0, 1.0) * 0.95;
	COLOR = vec4(col, alpha);
}
