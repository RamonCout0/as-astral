shader_type canvas_item;

// --- Configurações no Inspetor ---
uniform vec4 color_1 : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Cor 1 (ex: Branca)
uniform vec4 color_2 : source_color = vec4(0.6, 0.8, 1.0, 1.0); // Cor 2 (ex: Azulada)
uniform vec4 color_3 : source_color = vec4(1.0, 0.9, 0.5, 1.0); // Cor 3 (ex: Amarelada)

uniform float star_speed = 0.01; // Velocidade que as estrelas "rodam" no fundo
uniform float twinkle_speed = 3.0; // Velocidade do piscar

// Função geradora de números aleatórios
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    vec3 final_rgb = vec3(0.0); // Guarda as cores acumuladas
    float final_alpha = 0.0;    // Guarda a transparência acumulada
    
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
            
            // Cria um número aleatório novo só para decidir a cor da estrela
            float color_rand = random(grid_id + 42.0); 
            vec3 star_color;
            
            // Sorteia entre as 3 cores definidas no Inspetor
            if (color_rand < 0.33) {
                star_color = color_1.rgb;
            } else if (color_rand < 0.66) {
                star_color = color_2.rgb;
            } else {
                star_color = color_3.rgb;
            }
            
            // Calcula a transparência final dessa estrela específica
            float current_alpha = star_shape * (0.4 + 0.2 * i) * twinkle;
            
            // Soma a cor e o alpha no resultado final do pixel
            final_rgb += star_color * current_alpha;
            final_alpha += current_alpha;
        }
    }
    
    // Aplica o resultado na tela
    COLOR = vec4(final_rgb, min(final_alpha, 1.0)); 
}