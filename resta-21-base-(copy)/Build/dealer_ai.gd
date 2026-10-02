class_name DealerAI
extends RefCounted
## Base de todo crupiê. Cada crupiê muda UMA regra ou "poder".
## IA não generativa: só regras fixas, probabilidade e um pouco de aleatoriedade.

var dealer_name: String = "Crupiê"
var description: String = ""
var rounds_to_win: int = 3            # rodadas que o jogador precisa vencer para derrotá-lo
var tie_goes_to_dealer: bool = false  # empate favorece a casa?
var mistake_chance: float = 0.0       # chance de inverter a decisão (0.0 a 1.0)

## Retorna true = pedir carta, false = parar.
func decide(dealer: Player, player: Player, deck: Array) -> bool:
	if dealer.score >= 21 or deck.is_empty() or player.is_bust():
		return false
	var hit := _should_hit(dealer, player, deck)
	if mistake_chance > 0.0 and randf() < mistake_chance:
		hit = not hit
	return hit

## Sobrescreva nos crupiês específicos.
func _should_hit(dealer: Player, player: Player, deck: Array) -> bool:
	return dealer.score < 17

## Probabilidade (0..1) da próxima carta do baralho estourar a mão.
static func bust_probability(hand: Array, deck: Array) -> float:
	if deck.is_empty():
		return 0.0
	var busts := 0
	for c in deck:
		if Player.calc_score(hand + [c]) > 21:
			busts += 1
	return float(busts) / deck.size()
