shader_type canvas_item;

// --- Configurações Místicas ---
uniform vec4 aura_color : source_color = vec4(0.4, 0.0, 0.8, 1.0); // Roxo etéreo padrão
uniform float aura_size : hint_range(0.0, 1.0) = 0.35; // Tamanho do espaço limpo no centro
uniform float edge_softness : hint_range(0.0, 1.0) = 0.5; // Quão esfumaçada/suave é a transição
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0; // Velocidade da "respiração" da aura
uniform float wave_intensity : hint_range(0.0, 0.2) = 0.03; // Força das ondas ao redor da visão

void fragment() {
    // 1. Centraliza as coordenadas (move o ponto 0,0 para o meio da tela)
    vec2 centered_uv = UV - 0.5;
    
    // Ajusta a proporção para que a aura não fique ovalada em telas wide
    // (opcional, remova a linha abaixo se quiser que a aura acompanhe o formato da tela)
    // centered_uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    
    // 2. Calcula o ângulo para criar as distorções em círculo
    float angle = atan(centered_uv.y, centered_uv.x);
    
    // 3. Cria uma distorção orgânica (como fumaça mágica ou energia)
    // Multiplicamos o ângulo por 8.0 para ter 8 "pontas" de onda ao redor da tela
    float wave = sin(angle * 8.0 + TIME * 1.5) * wave_intensity;
    
    // 4. Calcula a distância do pixel atual até o centro, somada à onda
    float dist = length(centered_uv) + wave;
    
    // 5. Faz a aura pulsar ("respirar") levemente com o tempo
    float current_size = aura_size + (sin(TIME * pulse_speed) * 0.02);
    
    // 6. Calcula a máscara esfumaçada (smoothstep cria o degradê)
    // Pixels mais próximos que current_size ficam com alpha 0.0
    // Pixels mais distantes ficam com alpha 1.0
    float aura_mask = smoothstep(current_size, current_size + edge_softness, dist);
    
    // 7. Aplica a cor escolhida e usa a máscara para definir onde é transparente
    COLOR = aura_color;
    COLOR.a = aura_mask * aura_color.a;
}