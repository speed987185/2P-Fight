extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		if body.has_method("is_multiplayer_authority"):
			if body.is_multiplayer_authority():
				body.rpc("die")
		else:
			body.die()
