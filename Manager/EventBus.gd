extends Node

# Sinais emitidos por outras classes (padrão "signal bus").
# @warning_ignore evita o falso UNUSED_SIGNAL — eles SÃO usados, só que em outros scripts.

# Sinais do Jogador
@warning_ignore("unused_signal")
signal player_max_health_set(max_health)
@warning_ignore("unused_signal")
signal player_health_updated(current_health)
@warning_ignore("unused_signal")
signal player_counter_pressed()

# Sinais do Chefe
@warning_ignore("unused_signal")
signal boss_max_health_set(max_health, health_per_segment)
@warning_ignore("unused_signal")
signal boss_health_updated(current_health)
@warning_ignore("unused_signal")
signal boss_staggered()
@warning_ignore("unused_signal")
signal boss_stagger_updated(current_stagger: float, max_stagger: float)
