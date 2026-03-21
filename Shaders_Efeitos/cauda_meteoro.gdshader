shader_type canvas_item;

// --- Controles Fáceis ---
uniform vec4 color_start : source_color = vec4(1.0, 0.3, 0.0, 1.0); // Laranja forte (perto do planeta)
uniform vec4 color_end : source_color = vec4(0.2, 0.0, 0.0, 0.0); // Fumaça escura sumindo
uniform float speed = 5.0; // Rapidez do fogo
uniform vec2 pixels = vec2(60.0, 15.0); // Controla os quadradinhos da pixel art

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    // 1. Quadriculando o UV para estilo Pixel Art
    vec2 uv = floor(UV * pixels) / pixels;
    
    // 2. Distância do meio (Y=0.5). Vai de 0 no centro até 1 nas bordas
    float dist_y = abs(uv.y - 0.5) * 2.0;
    
    // 3. Afina a cauda conforme vai para a direita (UV.x vai de 0 a 1)
    float thickness = 1.0 - uv.x;
    
    // 4. Gera o ruído animado (vento apagando o fogo)
    float noise = random(uv + vec2(TIME * speed, 0.0));
    
    // A MÁGICA QUE EVITA O "V" BIZARRO:
    // O (0.4 + noise * 0.6) garante que o fogo nunca suma completamente no centro,
    // ele só corrói as beiradas, mantendo o formato de cauda sólida.
    float fire_shape = step(dist_y, thickness * (0.4 + noise * 0.6));
    
    // 5. Mistura a cor forte do começo com a cor escura do final
    vec4 final_color = mix(color_start, color_end, uv.x);
    
    COLOR = final_color;
    
    // Corta o formato e desbota suavemente o Alpha no finalzinho da cauda
    COLOR.a *= fire_shape * (1.0 - uv.x);
}