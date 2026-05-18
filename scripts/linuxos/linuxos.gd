extends AnimatedSprite2D

signal response_ready(text: String)

func _ready() -> void:
	play("idle")

func set_emotion(_emotion: String) -> void:
	pass  # ใช้ทีหลังตอนมี sprite จริง

func respond(message: String) -> void:
	var msg := message.strip_edges().to_lower()
	var reply: String

	if "สวัสดี" in message or "hello" in msg or "hi" in msg:
		reply = "...สวัสดี"
	elif "ทำอะไร" in message or "อยู่ไหน" in message:
		reply = "นั่งดู log อยู่"
	elif "ชื่อ" in message or "who are you" in msg:
		reply = "LinuxOS"
	elif "กินข้าว" in message or "หิว" in message:
		reply = "...ฉันไม่กินข้าว"
	else:
		reply = "..."

	emit_signal("response_ready", reply)
