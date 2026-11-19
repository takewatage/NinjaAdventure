extends Resource
class_name ResourceWallet
## The player's money. Resource.changed fires when it changes.
## The World hands the same wallet to the new player after a defeat.


@export var money: int = 0
@export var max_money: int = 9999


func add(amount: int) -> void:
    money = clampi(money + amount, 0, max_money)
    emit_changed()


## Pays if there is enough. Returns false (and changes nothing) otherwise.
func spend(amount: int) -> bool:
    if amount > money:
        return false
    money -= amount
    emit_changed()
    return true
