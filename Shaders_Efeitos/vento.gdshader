// vento.gdshader
// Vendaval curvo convergindo pro centro (sucção do Vórtice). Usa ruído pra ficar natural.
shader_type canvas_item;
render_mode blend_add;

uniform float speed = 1.5;
uniform float intensity = 0.7;
uniform vec4 wind_color : source_color = vec4(0.88, 0.94, 1.0, 1.0);

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
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float dir = (uv.x < 0.5) ? 1.0 : -1.0;

	// Distorce o caminho do vento com ruído (curvas suaves).
	float warp = fbm(vec2(uv.x * 3.0, uv.y * 7.0 + t * 0.4));

	// Linhas finas onduladas.
	float lane = uv.y * 26.0 + warp * 2.5;
	float line = smoothstep(0.5, 0.0, abs(fract(lane) - 0.5));

	// Segmentos correndo em direção ao centro.
	float flow = uv.x * 5.0 + t * dir * 0.9 + warp * 1.5;
	float run = smoothstep(0.65, 1.0, fract(flow));

	float streak = line * run;

	// Mais denso e com leve brilho perto do centro (onde está o vórtice).
	float center = pow(clamp(1.0 - abs(uv.x - 0.5) * 2.0, 0.0, 1.0), 1.4);
	float glow = center * center * 0.18;

	float a = (streak * center + glow) * intensity;
	COLOR = vec4(wind_color.rgb, a);
}
