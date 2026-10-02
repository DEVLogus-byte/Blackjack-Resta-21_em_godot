class_name Card

var house : String
var num : int
var title : String
var mesa : Label

func _init(num, house):
	self.num = num
	self.house = house

	# CORRIGIDO: antes o Ás (1) caía no "if num < 11" e virava "1 de ..."
	if self.num == 1:
		self.title = 'Ás'
	elif self.num <= 10:
		self.title = str(self.num)
	elif self.num == 11:
		self.title = 'Valete'
	elif self.num == 12:
		self.title = 'Rainha'
	else:
		self.title = 'Rei'

	self.title += " de " + self.house

func get_value() -> int:
	if self.num == 1:
		return 11 # Ás vale 11; o Player reduz para 1 quando necessário
	elif self.num > 10:
		return 10
	return self.num
