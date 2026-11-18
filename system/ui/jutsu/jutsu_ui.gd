extends Control
class_name JutsuUi
## Jutsu HUD (bottom-left) + jutsu wheel. World gives it the current player.


var player: Player:
    set(v):
        player = v
        $JutsuHud.player = v
        $JutsuWheel.player = v
