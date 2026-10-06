extends BaseCharacter



func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Idle, true)
	super._ready()
	
