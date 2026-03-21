shader_type canvas_item;

// Controles fáceis no Inspetor
uniform int layers = 3; // Quantidade de camadas para dar profundidade
uniform float density = 80.0; // Quantidade de neve (aumente para mais bolinhas)
uniform vec2 wind_direction = vec2(-1.5, 0.5); // X negativo = vai para a esquerda
uniform float speed = 1.5; // Velocidade geral da tempestade
uniform float wave_amplitude = 0.5; // Força do sobe e desce
uniform float wave_frequency = 2.0; // Rapidez das ondas
uniform float particle_size = 0.08; // Tamanho das bolinhas
uniform vec4 snow_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);

// Função para gerar valores aleatórios
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    float snow = 0.0;
    
    // Cria múltiplas camadas de neve (uma ao fundo lenta, outra na frente rápida)
    for (int i = 1; i <= layers; i++) {
        float layer_scale = float(i);
        
        // Ajusta o tamanho do grid para a camada atual
        vec2 layer_uv = uv * density / layer_scale;
        
        // Aplica o vento e a velocidade
        layer_uv += TIME * wind_direction * speed * layer_scale;
        
        // Aplica o efeito de ONDA (sobe e desce na vertical)
        layer_uv.y += sin(layer_uv.x * wave_frequency + TIME) * wave_amplitude;
        
        // Divide a tela em milhares de quadradinhos (grid)
        vec2 grid_id = floor(layer_uv);
        vec2 grid_pos = fract(layer_uv) - 0.5; 
        
        // Define uma posição aleatória para a bolinha dentro desse quadradinho
        vec2 random_offset = vec2(random(grid_id), random(grid_id + 150.0)) - 0.5;
        
        // Calcula a distância para formar um círculo perfeito (bolinha)
        float dist = length(grid_pos - random_offset);
        
        // Desenha a bolinha de forma nítida (estilo pixel art)
        float circle = step(dist, particle_size); 
        
        // Faz algumas bolinhas brilharem mais que outras aleatoriamente
        circle *= random(grid_id + 50.0);
        
        snow += circle;
    }

    // Aplica a cor final
    COLOR = snow_color;
    COLOR.a = min(snow, 1.0) * snow_color.a;
}