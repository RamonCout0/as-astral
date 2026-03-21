shader_type canvas_item;

// --- Configurações no Inspetor ---
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Cor das estrelas
uniform float star_speed = 0.01; // Velocidade que as estrelas "rodam" no fundo
uniform float twinkle_speed = 3.0; // Velocidade do piscar

// Função geradora de números aleatórios
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    // Começa com a transparência zerada (totalmente invisível)
    float final_alpha = 0.0; 
    
    // Cria 3 camadas de estrelas
    for (float i = 1.0; i <= 3.0; i++) {
        vec2 layer_uv = uv * (60.0 + i * 30.0); 
        layer_uv.x += TIME * star_speed * i; 
        
        vec2 grid_id = floor(layer_uv);
        vec2 grid_pos = fract(layer_uv) - 0.5;
        
        float rand = random(grid_id);
        
        if (rand < 0.015 * i) { 
            float twinkle = sin(TIME * twinkle_speed + rand * 100.0) * 0.5 + 0.5;
            float star_size = 0.08 + (random(grid_id + 10.0) * 0.04);
            float star_shape = step(length(grid_pos), star_size);
            
            // Soma a transparência apenas onde a estrela existe
            final_alpha += star_shape * (0.4 + 0.2 * i) * twinkle;
        }
    }
    
    // Aplica a cor escolhida e usa o alpha calculado
    COLOR = star_color;
    COLOR.a = min(final_alpha, 1.0) * star_color.a; 
}