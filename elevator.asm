.data
floors:         .word 5
current_floor:  .word 0
requests:       .word 0, 0, 0, 0, 0

start:          .asciiz "===ELEVETOR SIMULATOR STARTING===\nStarting on Floor 0" 
welcome:        .asciiz "=== Welcome! Elevator doors are open. ===\n"
arrived:        .asciiz ">>> Arrived at floor: "
moving:         .asciiz "\nMoving... Now at floor: "
dest_msg:       .asciiz ">>> Destination request reached at floor: "
door_open:      .asciiz ">>> Doors opening...\n"
same_floor_msg: .asciiz "\nYou are still on floor: "
newline:        .asciiz "\n"
emergency_msg:  .asciiz "\n!!! EMERGENCY STOP ACTIVATED !!!\n"
reset_msg:      .asciiz "\n--- Elevator Reset. Resuming operation. ---\n"
alarm_msg:      .asciiz "\n*** ALARM ACTIVATED! ***\n"
alarm_clear_msg:.asciiz "\n--- Alarm cleared. ---\n"
bye_msg:        .asciiz "\n--- Bye! Thank you for using the Elevator! ---\n"
 
# User manual message to remind users of controls
user_manual_msg: .asciiz "\nControls: [0-4]=request floor | E=emergency | R=reset | A=alarm | C=clear alarm | X=exit program\n"
 
emergency:      .word 0
alarm:          .word 0
exit:           .word 0

.text
.globl main

main:
   # Start simulator
   li $v0, 4
   la $a0, start
   syscall

   la $a0, user_manual_msg
   syscall

   jal move_elevator

   li $v0, 4
   la $a0, bye_msg
   syscall
   li $v0, 10
   syscall

move_elevator:
   addi $sp, $sp, -4
   sw $ra, 0($sp)
   
   # Set state: 0 = idle, 1 = moving up, -1 = moving down
   li $s0, 0      # direction
   li $s1, -1     # destination (-1 means none)
    
   # Main elevator loop
   elevator_loop:
      
      # Exit handler
      lw $t0, exit
      bnez $t0, Exit
      
      # Alarm handler
      lw $t0, alarm
      beqz $t0, skip_alarm
      li $v0, 4
      la $a0, alarm_msg
      syscall
      wait_for_alarm_clear:
         jal check_mmio_input
         move $a1, $v1
         jal process_user_input
         lw $t0, alarm
         bnez $t0, wait_for_alarm_clear
       
      # Emmergency handler
      skip_alarm:
         lw $t0, emergency
         beqz $t0, skip_emergency
         li $v0, 4
         la $a0, emergency_msg
         syscall
      wait_for_reset:
         jal check_mmio_input
         move $a1, $v1
         jal process_user_input
         lw $t0, emergency
         bnez $t0, wait_for_reset
         li $v0, 4
         la $a0, reset_msg
         syscall
         j elevator_loop
         
      skip_emergency:
       
         # MMIO keyboard check and input processing
         jal check_mmio_input
         move $a1, $v1
         jal process_user_input

         # If idle, select a new destination if any requests
         beqz $s0, select_destination

         # If moving, check if current floor is a stop
         lw $t5, current_floor
         la $t6, requests
         sll $t7, $t5, 2
         add $t6, $t6, $t7
         lw $t8, 0($t6)
         beqz $t8, continue_moving

         # If it is a stop: Print welcome, user manual, and destination message at door opening >>>
         li $v0, 4
         la $a0, arrived
         syscall
         li $v0, 1
         move $a0, $t5
         syscall
         li $v0, 4
         la $a0, newline
         syscall

         li $v0, 4
         la $a0, door_open
         syscall
         
         li $v0, 4
         la $a0, welcome
         syscall

         li $v0, 4
         la $a0, user_manual_msg
         syscall

         # Clear request for this floor
         sw $zero, 0($t6)

         # Simulate door open delay
         li $a1, 3000
         jal delay

         # If at destination, go idle and re-evaluate requests
         beq $t5, $s1, arrived_at_destination 

         # Otherwise, keep moving in same direction
         j continue_moving

      arrived_at_destination:
         li $s0, 0      # idle
         li $s1, -1     # no destination
         j elevator_loop
       
      select_destination:
         # Find the next pending request (lowest-numbered)
         jal find_next_request
         li $t0, -1
         beq $v0, $t0, elevator_loop   # No requests, stay idle

         # Set destination and direction
         lw $t1, current_floor
         move $s1, $v0                 # s1 = destination
         blt $t1, $v0, set_up
         bgt $t1, $v0, set_down
         
         # Already at destination, open doors
         j arrived_at_destination
         
         set_up:
            li $s0, 1
            j continue_moving
         set_down:
            li $s0, -1
            j continue_moving
       
      continue_moving:
         # Move one floor in current direction
         lw $t1, current_floor
         beq $s0, 1, move_up
         beq $s0, -1, move_down
         j elevator_loop
       
         move_up:
            addi $t1, $t1, 1
            sw $t1, current_floor
            j after_move
          
         move_down:
            addi $t1, $t1, -1
            sw $t1, current_floor
            j after_move
          
         after_move:
            # Print moving through floor message
            li $v0, 4
            la $a0, moving
            syscall
            li $v0, 1
            move $a0, $t1
            syscall
            li $v0, 4
            la $a0, newline
            syscall

            # Simulate travel delay
            li $a1, 25000
            jal delay

            j elevator_loop
   
   Exit:
      lw $ra, 0($sp)
      jr $ra

# --- MMIO Keyboard Input (digits 0-4, E, R, A, C, X) ---
# $v1 = updated last_key
check_mmio_input:
   li $t8, 0xFFFF0000      # MMIO keyboard status
   lw $t9, 0($t8)
   andi $t9, $t9, 1        #check if a key is pressed, 0-> no key pressed and 1-> key pressed
   beqz $t9, mmio_input_end

   li $t8, 0xFFFF0004      # MMIO keyboard data
   lw $t9, 0($t8)          # ASCII value

   # Clear keyboard buffer by writing 0 to status register
   li $t8, 0xFFFF0000 
   sw $zero, 0($t8)

   mmio_input_store:
      # Store current key as last_key
      move $v1, $t9
      jr $ra
    
   mmio_input_end:
      # If no key, set last_key to -1
      li $v1, -1
      jr $ra

# --- Processing inputs from MMIO ---
process_user_input:
   # Check if there is no mmio input
   li $t0, -1
   beq $a1, $t0, done_input
   
   # Emergency Stop: 'E' (69), Reset: 'R' (82), Alarm: 'A' (65), Clear Alarm: 'C' (67)
   li $t0, 69
   beq $a1, $t0, set_emergency
   li $t0, 82
   beq $a1, $t0, clear_emergency
   li $t0, 65
   beq $a1, $t0, set_alarm
   li $t0, 67
   beq $a1, $t0, clear_alarm
   li $t0, 88
   beq $a1, $t0, set_exit
   
   # If emergency or alarm command is activated, no floor request is processed.
   li $t0, 1
   lw $t1, emergency
   lw $t2, alarm
   beq $t1, $t0, done_input
   beq $t2, $t0, done_input

   # Accept only '0' to '4'
   li $t0, 48              # ASCII '0'
   li $t1, 52              # ASCII '4'
   blt $a1, $t0, done_input
   bgt $a1, $t1, done_input

   sub $t2, $a1, $t0       # digit = ASCII - '0' to find floor number
   
   # Check if request is the current floor
   lw $t1, current_floor
   beq $t2, $t1, same_floor

   # Set requests[digit] = 1
   la $t3, requests
   sll $t4, $t2, 2
   add $t3, $t3, $t4
   li $t5, 1
   sw $t5, 0($t3)
   j done_input
 
   set_emergency:
      li $t0, 1
      sw $t0, emergency
      j done_input
    
   clear_emergency:
      sw $zero, emergency
      j done_input
    
   set_alarm:
      li $t0, 1
      sw $t0, alarm
      j done_input
    
   clear_alarm:
      sw $zero, alarm
      li $v0, 4
      la $a0, alarm_clear_msg
      syscall
      j done_input

   set_exit:
      li $t0, 1
      sw $t0, exit
      j done_input
         
   same_floor:
      li $v0, 4
      la $a0, same_floor_msg
      syscall
      
      li $v0, 1
      lw $a0, current_floor
      syscall
      
      li $v0, 4
      la $a0, newline
      syscall

   done_input:
      jr $ra

# --- Find Next Requested Floor (lowest index) ---
find_next_request:
   la $t1, requests
   li $t2, 0            # floor index
   lw $t3, floors      # number of floors
   find_req_loop:
      beq $t2, $t3, find_req_none
      sll $t4, $t2, 2
      add $t5, $t1, $t4
      lw $t6, 0($t5)
      bnez $t6, find_req_found
      addiu $t2, $t2, 1
      j find_req_loop
   find_req_found:
      move $v0, $t2
      jr $ra
   find_req_none:
      li $v0, -1
      jr $ra

delay:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	move $s0, $a1
	delay_loop: jal check_mmio_input
                    move $a1, $v1
                    jal process_user_input
                    addi $s0, $s0, -1
                    bgt $s0, $zero, delay_loop
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra
					
