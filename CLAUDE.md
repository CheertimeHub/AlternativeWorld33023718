# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AlternativeWorld** เป็น Godot 4 indie game ที่เป็น cozy digital space มี NPC ชื่อ "LUX" ที่ตอบสนองด้วย AI ผ่าน Groq API เป้าหมาย MVP คือห้องเดียว (linux_room) ที่มี player เดิน WASD และ NPC ที่คุยได้

## Running the Project

```
# เปิดใน Godot Editor
godot --path . --debug

# หรือ export เป็น binary แล้วรัน
godot --path . --headless --export-debug "Windows Desktop" AlternativeWorld.exe
```

Engine: **Godot 4.6** (GL Compatibility renderer), viewport 960×540

## Architecture

### Core Systems

**Config Singleton** ([scripts/config.gd](scripts/config.gd)) — Autoload global singleton ที่เก็บ Groq API key, model name (`llama-3.3-70b-versatile`), และ endpoint

**Player** ([scripts/player/player.gd](scripts/player/player.gd)) — CharacterBody2D, WASD movement (80/160 px/s walk/run), sine-wave leg animation สำหรับ idle bob และ walking

**LUX NPC** ([scripts/linuxos/linuxos.gd](scripts/linuxos/linuxos.gd)) — CharacterBody2D ที่มี state machine 3 states:
- `SITTING` → default state ตอนเริ่ม
- `IDLE` → หยุดนิ่งหลัง wander
- `WANDER` → เดินสุ่มใน bounded area

ตรวจจับ player ในระยะ 80px แล้ว HTTP request ไป Groq API เพื่อรับ dialog ที่ personality-driven

**Dialog Box** ([scripts/ui/dialog_box.gd](scripts/ui/dialog_box.gd)) — RPG dialog system แบบ queue-based มี 4 ตัวเลือก predefined สำหรับ player, รับ AI response แล้วแสดงทีละตัวอักษร

**Room Scene** ([scripts/world/linux_room.gd](scripts/world/linux_room.gd)) — Node2D ที่เชื่อม player, NPC, และ dialog box ด้วย Godot signals

### Signal Flow

```
Player (E key press) → linux_room.gd → dialog_box.gd (show dialog)
LUX detects player proximity → HTTP request to Groq → dialog_box.gd (show response)
dialog_box.gd (option selected) → linux_room.gd → linuxos.gd (process choice)
```

### Key Godot Input

- `interact` action = KEY_E (กด E เพื่อคุยกับ LUX)
- Movement: WASD / arrow keys
- Run: Shift

## Project Vision (PROJECT_VISION.md)

Digital space ที่เชื่อม Discord bots, characters, และ players เข้าด้วยกัน — "digital loneliness that's not lonely"

Future tech: Discord.js → WebSocket → Godot, Godot MultiplayerAPI สำหรับ multiplayer

## Important Notes

- API key อยู่ใน `scripts/config.gd` — **อย่า commit** ถ้า key ยังเป็น plaintext
- Font assets ใน `assets/fonts/Noto_Sans_Mono/` มีขนาด ~16 MB เป็น theme หลักของ project
- Scene หลักตอนนี้คือ `scenes/world/linux_room/linux_room.tscn` (uid: `uid://linuxroom`)
