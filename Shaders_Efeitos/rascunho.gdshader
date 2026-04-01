shader_type canvas_item;

// --- Configurações do Grafite Denso (Estilo Carvão) ---
uniform vec4 pencil_color : source_color = vec4(0.2, 0.2, 0.2, 1.0); // Cor do grafite escuro
uniform float sketch_intensity : hint_range(0.0, 10.0) = 4.0; // Quão escuros/densos são os rabiscos
uniform float stroke_density : hint_range(50.0, 1000.0) = 400.0; // Quantidade massiva de linhas
uniform float stroke_chaos : hint_range(0.0, 5.0) = 2.0; // Quão bagunçadas e orgânicas são as linhas

// --- Configurações da Borda (Vinheta) ---
uniform float border_size : hint_range(0.0, 1.0) = 0.3; // Tamanho da área limpa no centro
uniform float border_softness : hint_range(0.0, 1.0) = 0.6; // Suavidade da transição para o rascunho

// Função geradora de números pseudo-aleatórios simples
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Cria hachurado procedural bagunçado massivo sobrepondo 4 ângulos diferentes
float get_sketch_lines(vec2 uv, float time) {
    float lines = 0.0;
    
    // Matrizes de rotação para inclinar as linhas em ângulos bagunçados
    mat2 rot_45 = mat2(vec2(0.707, -0.707), vec2(0.707, 0.707));
    mat2 rot_115 = mat2(vec2(-0.423, -0.906), vec2(0.906, -0.423));
    mat2 rot_negative_30 = mat2(vec2(0.866, 0.5), vec2(-0.5, 0.866));

    // Função interna para criar uma camada de linhas bagunçadas
    // Isso imita a mão tremendo e a bagunça da sua referência.
    for (float i = 0.0; i < 4.0; i++) {
        mat2 current_rot;
        if (i == 0.0) current_rot = mat2(vec2(1.0, 0.0), vec2(0.0, 1.0)); // Horizontais
        if (i == 1.0) current_rot = rot_45;
        if (i == 2.0) current_rot = rot_115;
        if (i == 3.0) current_rot = rot_negative_30;

        vec2 rot_uv = current_rot * uv;
        vec2 uv_lines = rot_uv * stroke_density * (1.0 + i * 0.1);

        // Bagunça as linhas: o segredo está em balançar a coordenada X e Y
        // antes de calcular o pecado, criando curvas e tremidos orgânicos.
        float noise_x = random(vec2(floor(uv_lines.y * 0.5), i + time * 0.02)) * stroke_chaos;
        float noise_y = random(vec2(floor(uv_lines.x * 0.5), i * 1.5 + time * 0.02)) * stroke_chaos;
        
        // Sobrepõe o hachurado, invertendo e somando para densidade
        lines += abs(sin(uv_lines.y + noise_x + noise_y));
    }

    // Normaliza e inverte o resultado (linhas escuras no fundo claro)
    float final_lines = 1.0 - (lines / 4.0);
    
    // Aplica a intensidade (densidade) do rabisco
    return pow(final_lines, sketch_intensity);
}

void fragment() {
    // 1. Centraliza as coordenadas (0,0 no meio da tela)
    vec2 centered_uv = UV - 0.5;
    
    // 2. Calcula a distância do pixel até o centro
    float dist = length(centered_uv);
    
    // 3. Cria a máscara da borda (Vignette)
    // Se dist < border_size, alpha é 0 (centro limpo)
    float border_mask = smoothstep(border_size, border_size + border_softness, dist);
    
    // 4. Gera a textura procedural de rascunho de carvão massivo
    // Passamos o TIME para que o rascunho "viva" e mude levemente (como carvão no papel).
    float sketch_tex = get_sketch_lines(UV, TIME);
    
    // 5. Aplica a cor definida
    COLOR = pencil_color;
    
    // 6. Mistura tudo:
    // Começa transparente. A alpha aumenta massivamente nas bordas (border_mask)
    // E dentro da borda, a alpha é controlada pelo rascunho densamente procedural (sketch_tex).
    // Invertemos sketch_tex no alpha (1.0 - tex) para que as linhas pretas
    // sejam opacas e o espaço entre elas transparente, mostrando o jogo atrás.
    COLOR.a = border_mask * pencil_color.a * (1.0 - sketch_tex);
}