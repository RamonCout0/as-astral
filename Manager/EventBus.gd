extends Node

# Sinais do Jogador
signal player_max_health_set(max_health)
signal player_health_updated(current_health)
signal player_counter_pressed()  

# Sinais do Chefe
signal boss_max_health_set(max_health, health_per_segment)
signal boss_health_updated(current_health)
signal boss_staggered() # Sinal para o sistema de Stagger
