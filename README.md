# 16-bit 8086 Assembly Real-Time Memory Game

A low-level 16-bit real-time memory card game developed in **8086 Assembly** for the **Intel 8086 Microprocessor** architecture. The project demonstrates direct memory manipulation, non-blocking real-time hardware interrupt handling, and custom BIOS/DOS display rendering.

## Technical Specifications
* **Architecture:** x86 16-bit Real Mode
* **Language / Assembler:** 8086 Assembly (MASM/TASM / Emu8086 compatible)
* **Memory Model:** `.MODEL SMALL` (Separated Code and Data Segments)
* **Display Mode:** DOS Mode `03h` (80x25 Color Text Interface via BIOS `INT 10H`)

## Key Low-Level Architecture & Features

### 1. Non-Blocking Real-Time Timer & Keyboard Polling (`KARAKTER_OKU`)
To achieve real-time clock tracking without blocking user inputs:
* **Keyboard Polling:** `INT 16H / AH=01H` continuously checks the keyboard buffer non-blockingly
* **Hardware System Time Reading:** Reads real-time seconds via `INT 21H / AH=2CH` into the `DH` register
* **Partial UI Cursor Updates:** Prevents screen flickering by positioning the cursor directly over the timer via `INT 10H / AH=02H` and updating only the timer coordinates in real time

### 2. BIOS Video Attribute Byte & Color Management (`PRINT_STR_RENKLI`)
Utilizes BIOS Video Services (`INT 10H / AH=09H`) to write ASCII characters with dynamic color attribute bytes directly to video memory
* **`79H` (Light Blue):** Hidden/faced-down cards
* **`0AH` (Green):** Successfully matched cards
* **`0CH` (Red):** Critical time warnings (< 10 seconds remaining) and penalty alerts

### 3. Hexadecimal ASCII to Array Index Conversion (`INDEKSE_CEVIR`)
Converts user input ASCII hex characters (`0-9`, `A-F`, `a-f`) to `0-15` array indices via mathematical register offsets (`SUB AL, 48`, `SUB AL, 55`, `SUB AL, 87`) for efficient register addressing

## Images
<img width="746" height="355" alt="Ekran görüntüsü 2026-11-05 161659" src="https://github.com/user-attachments/assets/50417b65-f8f0-4e1e-b86c-8cf40affa821" />
<img width="757" height="247" alt="Ekran görüntüsü 2026-11-05 161634" src="https://github.com/user-attachments/assets/dac7865b-bd6d-4eda-905e-4df88e06ce4d" />
<img width="755" height="355" alt="Ekran görüntüsü 2026-11-05 161545" src="https://github.com/user-attachments/assets/a2e8ddb9-83cb-4a4f-ac5f-ec7c0f78e9b7" />
<img width="752" height="313" alt="Ekran görüntüsü 2026-11-05 161529" src="https://github.com/user-attachments/assets/07f8b864-68d3-412c-83f9-cb67e5ac33c1" />
<img width="752" height="258" alt="Ekran görüntüsü 2026-11-05 161414" src="https://github.com/user-attachments/assets/1e83aa9a-f52d-4453-921e-2cc5d03b5150" />
<img width="742" height="308" alt="Ekran görüntüsü 2026-11-05 161316" src="https://github.com/user-attachments/assets/27709ffa-24e4-49ee-8e09-0f6070b319c3" />

## Documentation
For full academic implementation details and flow diagrams, read the [Project Report](Project_Report.pdf).

## How to Run
1. Open `memory_game.asm` inside **Emu8086** (or DOSBox).
2. Click **Compile & Emulate**.
3. Press **Run** to launch the interactive terminal game loop.
