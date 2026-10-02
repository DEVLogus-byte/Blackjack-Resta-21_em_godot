class_name DealerRoster
extends RefCounted
## Lista dos crupiês do modo desafio, do mais fácil ao chefe.

class Iniciante extends DealerAI:
	func _init():
		dealer_name = "Iniciante Nervoso"
		description = "Para no 16 e às vezes erra a decisão."
		rounds_to_win = 2
		mistake_chance = 0.08
	func _should_hit(dealer: Player, player: Player, deck: Array) -> bool:
		return dealer.score < 16

class Classico extends DealerAI:
	func _init():
		dealer_name = "Crupiê Clássico"
		description = "Regra de cassino: pede até 16, para no 17."
		rounds_to_win = 3
	func _should_hit(dealer: Player, player: Player, deck: Array) -> bool:
		return dealer.score < 17

class Trapaceiro extends DealerAI:
	func _init():
		dealer_name = "Trapaceiro"
		description = "Para no 17, mas empates são vitória da casa."
		rounds_to_win = 3
		tie_goes_to_dealer = true
	func _should_hit(dealer: Player, player: Player, deck: Array) -> bool:
		return dealer.score < 17

class Contador extends DealerAI:
	var risk_limit := 0.62 # pede carta enquanto o risco de estourar for menor que isso
	func _init():
		dealer_name = "Contador de Cartas"
		description = "Calcula o risco de estourar com base nas cartas restantes."
		rounds_to_win = 3
	func _should_hit(dealer: Player, player: Player, deck: Array) -> bool:
		if dealer.score <= 11:
			return true
		if dealer.score >= 19:
			return false
		return bust_probability(dealer.hand, deck) < risk_limit

class Vidente extends DealerAI:
	func _init():
		dealer_name = "Vidente"
		description = "Enxerga as 2 próximas cartas do baralho."
		rounds_to_win = 4
	func _should_hit(dealer: Player, player: Player, deck: Array) -> bool:
		var next1 := Player.calc_score(dealer.hand + [deck[0]])
		var next2 := 99
		if deck.size() > 1:
			next2 = Player.calc_score(dealer.hand + [deck[0], deck[1]])
		# Abaixo de 17: pede, a não ser que a próxima carta estoure.
		if dealer.score < 17:
			return next1 <= 21
		# 17 ou mais: só arrisca se está perdendo e a visão garante melhora.
		if dealer.score < player.score and next1 <= 21:
			var best := next1
			if next2 <= 21:
				best = maxi(next1, next2)
			return best > dealer.score
		return false

class Mestre extends Vidente:
	func _init():
		super()
		dealer_name = "Mestre da Casa"
		description = "Vê 2 cartas e ganha todos os empates. Chefe final."
		rounds_to_win = 4
		tie_goes_to_dealer = true

static func build_campaign() -> Array[DealerAI]:
	var list: Array[DealerAI] = [
		Iniciante.new(),
		Classico.new(),
		Trapaceiro.new(),
		Contador.new(),
		Vidente.new(),
		Mestre.new(),
	]
	return list
