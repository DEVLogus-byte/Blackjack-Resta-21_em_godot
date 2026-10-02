extends Node
## Exemplo de uso: anexe a um Node qualquer para testar no console.
## Troque os prints pela sua UI (labels, CardView, botões Pedir/Parar).

var challenge := ChallengeMode.new()

func _ready() -> void:
	# 1) Balanceamento rápido (sem UI)
	for ai in DealerRoster.build_campaign():
		var rate := ChallengeMode.simulate_win_rate(ai, 5000)
		print("%s -> jogador vence %.1f%% das rodadas" % [ai.dealer_name, rate * 100.0])

	# 2) Partida automática de teste
	add_child(challenge)
	challenge.auto_play = true
	challenge.dealer_delay = 0.1
	challenge.round_end_delay = 0.2

	challenge.stage_started.connect(func(ai, n): print("== Fase %d: %s (%s)" % [n, ai.dealer_name, ai.description]))
	challenge.card_dealt.connect(func(who, card): print("%s recebeu %s" % [who.player_name, card.title]))
	challenge.round_ended.connect(func(r): print("Resultado: ", ChallengeMode.Result.keys()[r]))
	challenge.lives_changed.connect(func(l): print("Vidas: ", l))
	challenge.run_ended.connect(func(victory, cleared): print("FIM — vitória: %s, fases: %d" % [victory, cleared]))

	challenge.start_run()

	# Com UI real, ligue os botões:
	# $BtnPedir.pressed.connect(challenge.player_hit)
	# $BtnParar.pressed.connect(challenge.player_stand)
