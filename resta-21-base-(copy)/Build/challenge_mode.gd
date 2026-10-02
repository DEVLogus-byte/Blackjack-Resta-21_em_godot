class_name ChallengeMode
extends Node
## Modo Desafio / Sobrevivência.
## Regras: o jogador tem vidas. Cada crupiê exige X rodadas vencidas.
## Perder rodada = -1 vida. Derrotar crupiê = +1 vida (até o máximo).
## Passou do último crupiê: recomeça a lista mais difícil (+1 rodada por volta).

enum State { IDLE, PLAYER_TURN, DEALER_TURN, ROUND_END, RUN_OVER }
enum Result { PLAYER_WIN, DEALER_WIN, PUSH }

signal run_started
signal stage_started(ai: DealerAI, stage_number: int)
signal round_started
signal card_dealt(target: Player, card: Card)
signal player_turn_started
signal dealer_turn_started
signal dealer_revealed
signal round_ended(result: Result)
signal lives_changed(lives: int)
signal stage_cleared(ai: DealerAI)
signal campaign_completed(loop_count: int)
signal run_ended(victory: bool, stages_cleared: int)

@export var max_lives := 3
@export var dealer_delay := 0.8      # pausa entre ações do crupiê (segundos)
@export var round_end_delay := 1.5   # pausa após o fim da rodada
@export var auto_play := false       # true = a IA de jogador (PlayerBot) joga por você
@export var endless_after_campaign := true

var player := Player.new("Você")
var dealer := Player.new("Crupiê")
var deck: Array = []
var roster: Array[DealerAI] = []
var current_ai: DealerAI
var state: State = State.IDLE

var lives := 0
var stage_index := 0
var loop_count := 0
var round_wins := 0
var stages_cleared := 0

# ---------- API para a UI ----------

func start_run() -> void:
	lives = max_lives
	stage_index = 0
	loop_count = 0
	stages_cleared = 0
	roster = DealerRoster.build_campaign()
	run_started.emit()
	lives_changed.emit(lives)
	_start_stage()

func player_hit() -> void:
	if state != State.PLAYER_TURN:
		return
	player.take_card(deck)
	card_dealt.emit(player, player.hand[-1])
	if player.is_bust():
		_resolve_round()
	elif player.score == 21:
		player_stand()

func player_stand() -> void:
	if state != State.PLAYER_TURN:
		return
	_dealer_turn()

func rounds_needed() -> int:
	return current_ai.rounds_to_win + loop_count

# ---------- Fluxo interno ----------

func _start_stage() -> void:
	current_ai = roster[stage_index]
	round_wins = 0
	stage_started.emit(current_ai, stages_cleared + 1)
	start_round()

func start_round() -> void:
	deck = Deck.build()
	player.reset()
	dealer.reset()
	round_started.emit()
	for i in 2:
		player.take_card(deck)
		card_dealt.emit(player, player.hand[-1])
		dealer.take_card(deck)
		card_dealt.emit(dealer, dealer.hand[-1])
	if player.is_blackjack() or dealer.is_blackjack():
		_resolve_round()
		return
	_player_turn()

func _player_turn() -> void:
	state = State.PLAYER_TURN
	player_turn_started.emit()
	if auto_play:
		_run_player_bot()

func _run_player_bot() -> void:
	while state == State.PLAYER_TURN:
		await get_tree().create_timer(dealer_delay).timeout
		if state != State.PLAYER_TURN:
			return
		if PlayerBot.should_hit(player, dealer.hand[0]):
			player_hit()
		else:
			player_stand()
			return

func _dealer_turn() -> void:
	state = State.DEALER_TURN
	dealer_turn_started.emit()
	dealer_revealed.emit()
	while true:
		await get_tree().create_timer(dealer_delay).timeout
		if not current_ai.decide(dealer, player, deck):
			break
		dealer.take_card(deck)
		card_dealt.emit(dealer, dealer.hand[-1])
	_resolve_round()

func _resolve_round() -> void:
	state = State.ROUND_END
	dealer_revealed.emit()
	var result := evaluate_round(player, dealer, current_ai.tie_goes_to_dealer)
	if result == Result.PLAYER_WIN:
		round_wins += 1
	elif result == Result.DEALER_WIN:
		lives -= 1
		lives_changed.emit(lives)
	round_ended.emit(result)

	await get_tree().create_timer(round_end_delay).timeout

	if lives <= 0:
		state = State.RUN_OVER
		run_ended.emit(false, stages_cleared)
	elif round_wins >= rounds_needed():
		_clear_stage()
	else:
		start_round()

func _clear_stage() -> void:
	stages_cleared += 1
	stage_cleared.emit(current_ai)
	lives = mini(lives + 1, max_lives)
	lives_changed.emit(lives)
	stage_index += 1
	if stage_index >= roster.size():
		if not endless_after_campaign:
			state = State.RUN_OVER
			run_ended.emit(true, stages_cleared)
			return
		loop_count += 1
		stage_index = 0
		campaign_completed.emit(loop_count)
	_start_stage()

# ---------- Regras e ferramentas ----------

static func evaluate_round(p: Player, d: Player, tie_to_dealer: bool) -> Result:
	if p.score > 21:
		return Result.DEALER_WIN
	if d.score > 21:
		return Result.PLAYER_WIN
	if p.is_blackjack() and not d.is_blackjack():
		return Result.PLAYER_WIN
	if d.is_blackjack() and not p.is_blackjack():
		return Result.DEALER_WIN
	if p.score > d.score:
		return Result.PLAYER_WIN
	if p.score < d.score:
		return Result.DEALER_WIN
	return Result.DEALER_WIN if tie_to_dealer else Result.PUSH

## Simula N rodadas do PlayerBot contra um crupiê e devolve a % de vitórias do jogador.
## Use para balancear: ajuste rounds_to_win / risk_limit conforme o resultado.
static func simulate_win_rate(ai: DealerAI, rounds := 10000) -> float:
	var wins := 0
	for i in rounds:
		var d := Deck.build()
		var p := Player.new("bot")
		var c := Player.new("crupie")
		p.take_card(d)
		c.take_card(d)
		p.take_card(d)
		c.take_card(d)
		while not p.is_bust() and p.score < 21 and PlayerBot.should_hit(p, c.hand[0]):
			p.take_card(d)
		if not p.is_bust() and not p.is_blackjack():
			while ai.decide(c, p, d):
				c.take_card(d)
		if evaluate_round(p, c, ai.tie_goes_to_dealer) == Result.PLAYER_WIN:
			wins += 1
	return float(wins) / rounds
