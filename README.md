# Hit-the-Monkey: FPGA-Based Arcade Game

## 📌 Project Overview
Hit-the-Monkey is an interactive, hardware-level arcade game implemented in VHDL for FPGA development platforms. This project serves as a comprehensive demonstration of digital logic design, combining sequential state machines, precision timing, hardware-level Pulse Width Modulation (PWM), and multiplexed display control into a unified, real-time system.

The core premise of the game involves a "wandering" light that sweeps continuously across an array of LEDs. The player's objective is to trigger an action button at the exact moment the light aligns with specific target zones, which are dynamically configured by the user via onboard toggle switches. 

## 🧠 Theoretical Background & Core Concepts

### 1. Finite State Machine (FSM) Architecture
The central game logic is governed by a synchronous Finite State Machine. The FSM manages the oscillation of the active LED, tracking its spatial coordinates and directional vector. When the active LED reaches the boundary of the hardware array, the FSM transitions to an edge-handling state, reversing the directional vector to create a continuous ping-pong effect. The FSM also handles asynchronous user interactions, transitioning into evaluation states to determine hit accuracy, update score registers, and scale the game's difficulty dynamically.

### 2. Hardware Timers and Clock Division
FPGA development boards typically operate on high-frequency system clocks (e.g., 100 MHz), which are far too fast for human interaction or mechanical components. This project implements multiple custom clock dividers to generate distinct, slower timing domains:
* **Logic Tick:** Dictates the movement speed of the LED. This timer is dynamically adjustable, decreasing its threshold period to accelerate the game after every sequence of successful hits.
* **PWM Carrier Frequency:** A high-speed counter specifically calibrated to manage the dimming effects of the LEDs without visible flickering.
* **Display Refresh Rate:** A mid-tier frequency designed to cycle through the 7-segment anodes, exploiting the human eye's persistence of vision.

### 3. Pulse Width Modulation (PWM) and Luminance Decay
To enhance the visual experience, the wandering LED leaves a "light tail" mimicking motion blur or phosphor persistence. Instead of simple binary ON/OFF states, the system retains a positional history of the LED in trailing registers. A hardware PWM controller varies the duty cycle of these trailing positions. By progressively lowering the duty cycle of the older positions, the LEDs appear dimmer to the human eye, creating a smooth, fading tail effect.

### 4. Input Edge Detection
Mechanical buttons suffer from bouncing and continuous signal assertion if held down. To prevent game exploits (e.g., holding the action button to guarantee a hit), the system implements an edge detection circuit. By comparing the current state of the button with its state in the previous clock cycle, the logic isolates only the strictly rising edge of the signal, generating a single, one-clock-cycle pulse per physical press.

### 5. Multiplexed BCD Display Control
The scoring system utilizes a Binary-Coded Decimal (BCD) counting mechanism. Because the FPGA shares a single data bus for all digits on the 7-segment display, the driver continuously multiplexes the display. It rapidly activates one anode at a time while simultaneously decoding the corresponding BCD score into a 7-bit cathode map, creating the illusion of a solid, multi-digit display.

## 🎮 Gameplay Mechanics
* **Target Configuration:** Players use the physical toggle switches to designate "hit zones". Multiple zones can be active simultaneously to vary the strategic difficulty.
* **Precision Timing:** A hit is only registered if the action button is pressed exactly when the main LED (or its fading tail) occupies an active hit zone.
* **Progressive Difficulty:** The system continuously monitors the total valid hits. Upon reaching specific score intervals (every 5 points), the FSM triggers a speed-up state, tightening the logic tick timer and forcing the LED to travel faster.
* **Score Tracking:** The current score is mapped dynamically to the 4-digit multiplexed display, supporting a continuous progression loop.

## 📂 System Architecture Overview
The RTL (Register-Transfer Level) design is compartmentalized into the following functional blocks:
* **Input Conditioning Block:** Synchronizes external inputs and detects signal edges.
* **Timing Generator:** Distributes tailored clock enables to various subsystems.

## 👨‍💻 Author
This application was developed by Bob Vlad Ștefan (Faculty of Electronics, Telecommunications and Information Technology - ETTI, Year II, Series B, Group 2126).
* **FSM & Game Logic Core:** Evaluates coordinates, validates hits, and calculates game speed.
* **PWM Visual Engine:** Translates positional history into duty-cycle modulated light outputs.
* **Display Driver:** Decodes numerical data and drives the multiplexed hardware display.
