class_name Deck

const HOUSES := ["Copas", "Espadas", "Ouros", "Paus"]

# Baralho de 52 cartas já embaralhado.
# Se o seu jogo já tem uma função que cria o baralho, pode usar a sua:
# o importante é que seja um Array de Card.
static func build() -> Array:
	var cards := []
	for h in HOUSES:
		for n in range(1, 14):
			cards.append(Card.new(n, h))
	cards.shuffle()
	return cards
