shader_type canvas_item;

// --- Controles no Inspetor ---
// Cores principais (use tons de verde/ciano e roxo/azul com alpha baixo)
uniform vec4 color_top : source_color = vec4(0.0, 1.0, 0.7, 0.3);
uniform vec4 color_mid : source_color = vec4(0.2, 0.8, 1.0, 0.5);
uniform vec4 color_bottom : source_color = vec4(0.4, 0.1, 1.0, 0.2);

// Velocidade da animação (movimento geral)
uniform float speed = 0.4;

// Complexidade e detalhes das ondas
uniform float wave_frequency = 4.0;
uniform float wave_complexity = 3.0; // Quantas camadas de ondas somar

// Suavidade do desbotamento (0.0 a 1.0)
uniform float vertical_smoothness = 0.4;
uniform float horizontal_edge_fade = 0.2; // Largura do fade nas laterais

void fragment() {
    vec2 uv = UV;
    float time = TIME * speed;
    
    // 1. Geração de Ondas Compostas (Mais complexas e orgânicas)
    float waves = 0.0;
    float f = wave_frequency;
    float a = 0.1; // Amplitude base
    
    for (float i = 1.0; i < wave_complexity + 1.0; i++) {
        // Cria ondas baseadas em seno, com frequências e velocidades diferentes
        waves += sin(uv.x * f + time * (1.0 + i * 0.2)) * a;
        f *= 1.8; // Aumenta a frequência para o próximo detalhe
        a *= 0.6; // Diminui a amplitude para o próximo detalhe
    }
    
    // 2. Cálculo da Intensidade Vertical (Suavizando as bordas de cima e baixo)
    // Centraliza a aurora verticalmente e aplica a suavidade
    float base_y = 0.5 + waves; // A onda desloca o centro vertical
    float v_intensity = smoothstep(vertical_smoothness, 0.0, abs(uv.y - base_y));
    
    // 3. Cálculo do Desbotamento Horizontal (O "começo e fim transparentes")
    // Cria um fade nas bordas esquerda (0.0) e direita (1.0)
    float h_fade = smoothstep(0.0, horizontal_edge_fade, uv.x) * smoothstep(1.0, 1.0 - horizontal_edge_fade, uv.x);
    
    // 4. Mistura de Cores Baseada na Posição Vertical
    // Cria um gradiente suave entre as três cores definidas
    vec4 final_color = mix(color_bottom, color_mid, smoothstep(0.3, 0.6, uv.y));
    final_color = mix(final_color, color_top, smoothstep(0.6, 0.9, uv.y));
    
    // 5. Aplicação do Resultado Final
    COLOR = final_color;
    // Combina a transparência base da cor com a intensidade vertical e o fade horizontal
    COLOR.a *= v_intensity * h_fade;
}