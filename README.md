# MIPS Elevator Simulator -- Professional Documentation

This repository contains a fully implemented elevator simulation written
in **MIPS Assembly**, designed to run on **MIPS 4.5 (mips4.5.jar)** or
any compatible MIPS simulator supporting syscalls and MMIO keyboard
input.\
The implementation demonstrates realistic elevator logic, state-driven
movement, interrupt-style input handling, and robust system controls.

------------------------------------------------------------------------

## Overview

The elevator system manages **five floors (0--4)** and uses a **request
queue**, **direction state**, and **MMIO keyboard input** to simulate
real-world operational behavior.\
It is optimized to handle mid-route floor requests, emergency stops,
alarms, and resets, demonstrating practical embedded-systems logic.

This project highlights:

-   Low-level programming in MIPS
-   Realistic elevator control logic
-   Finite State Machine (FSM) design
-   Device I/O handling using MMIO
-   Robust safety-state handling

------------------------------------------------------------------------

## Features

### Core Functionalities

-   Movement between floors 0 to 4\
-   Automatic selection of next requested floor\
-   Efficient movement (handles intermediate requests during travel)\
-   Door-opening simulation upon arrival

### Safety & System Controls

-   **E** -- Emergency Stop\
-   **R** -- System Reset\
-   **A** -- Activate Alarm\
-   **C** -- Clear Alarm\
-   **X** -- Exit Program

### Input Handling

-   Fully implemented **MMIO keyboard input**\
-   Non-blocking input polling\
-   Supports ASCII detection for digits and commands

### Internal Design

-   Boolean array for request management\
-   `current_floor` tracking\
-   Movement direction encoded as:
    -   `1` = moving up\
    -   `-1` = moving down\
    -   `0` = idle
-   Controlled delays for movement simulation\
-   Clean stack usage for subroutine handling (`delay`,
    `check_mmio_input`, `process_user_input`)

------------------------------------------------------------------------

## File Structure

    elevator.asm     # Main MIPS elevator simulation
    README.md        # Project documentation

------------------------------------------------------------------------

## How to Run

### Requirements

-   **mips4.5.jar**, **MARS**, or **QtSPIM** with MMIO enabled.

### Steps

1.  Open your MIPS emulator.
2.  Load the file:

```{=html}
    elevator.asm
```
3.  Assemble the program.
4.  Run with input from keyboard using the controls below.

------------------------------------------------------------------------

## Controls

  Key    Action
  ------ --------------------------------
  0--4   Request floor
  E      Emergency Stop
  R      Reset elevator after emergency
  A      Activate Alarm
  C      Clear Alarm
  X      Exit Program

------------------------------------------------------------------------

## System Behavior

### Elevator Movement

The elevator: - Moves one floor per cycle\
- Prints status updates using syscalls\
- Responds to new floor requests even while moving\
- Handles door operations upon arrival

### Request Handling

The program searches for the **lowest pending request**, ensuring
deterministic and predictable movement.

### Safety Conditions

-   Emergency: halts all movement until reset\
-   Alarm: freezes operation until cleared\
-   Exit: stops the simulation safely

------------------------------------------------------------------------

## Learning Outcomes

This project demonstrates strong understanding of:

### Embedded & Low-Level Design

-   MMIO communication
-   Polling loops
-   System-state modeling
-   Timing control using software delays

### MIPS Programming Concepts

-   Register conventions
-   Stack frame management
-   Branching logic
-   Subroutine-based architecture

### Computer Architecture Concepts

-   Event-driven behavior
-   Interrupt-like simulation
-   Real-time system constraints

------------------------------------------------------------------------

## Author

**Prince Patel**\
MIPS Assembly System Simulation\
University of New Brunswick

------------------------------------------------------------------------

## License

This project is intended for academic and learning purposes.
