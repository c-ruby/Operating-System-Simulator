# OS Simulator (Assembly)

**Course:** CMSC 3100 — Assembly Language 
**Contributors:** Allan Cunningham, Evan Thompson, Caleb Ruby  


---

## Overview
This project is a **basic operating system simulator** written in **x86 Assembly** using the **Irvine32** library.  
It simulates a minimal command-line OS environment capable of accepting and processing commands such as loading, running, holding, and killing simulated "jobs."

The simulator is designed to strengthen understanding of **low-level system operations**, **process control**, and **assembly-level I/O**.

---

## Features
- Command parsing for OS-like inputs:
  - `LOAD`
  - `RUN`
  - `HOLD`
  - `KILL`
  - `SHOW`
  - `STEP`
  - `CHANGE`
  - `HELP`
  - `QUIT`
- Maintains a simulated **job queue** in memory
- Stores metadata for each job:
  - Job name  
  - Priority  
  - Status (available, running, hold)  
  - Run time  
  - Load time  
- Uses **buffers** to manage user input and parse commands
- Built with **Irvine32.inc** for console interaction and I/O utilities

---

## Learning Objectives
- Understand **process simulation** and scheduling concepts
- Practice **string and buffer manipulation** in Assembly
- Apply **modular programming** concepts in Assembly (procedures and data segments)
- Strengthen skills in **register management**, **memory addressing**, and **control flow**

---

## Example Commands
```
LOAD JOB1 3 25
RUN JOB1
SHOW
STEP 5
HOLD JOB1
KILL JOB1
QUIT
```

---

## How to Build & Run
### Requirements
- MASM assembler (Microsoft Macro Assembler)
- Irvine32 library installed and configured  
  (typically in `C:\Irvine` or `C:\Irvine\Irvine32.inc`)

### Compile and Link
```
ml /c /coff os_sim.asm
link /subsystem:console os_sim.obj Irvine32.lib
```

### Run
```
os_sim.exe
```

---

## Potential Improvements
- Implement actual process scheduling logic
- Add persistent job storage
- Improve error handling for invalid commands
- Implement time simulation for `STEP` command

---

## Notes
This was an educational project focused on **learning assembly-level programming and system concepts**, not production OS behavior.
