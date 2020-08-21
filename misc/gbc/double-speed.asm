INCLUDE "hardware.inc"

SECTION "entry", ROM0[$100]
  jp start

SECTION "gbc", ROM0[$143]
  db CART_COMPATIBLE_DMG_GBC

SECTION "main", ROM0[$150]
start:
  ;-----------------------------------
  ld   a, [rKEY1]
  add  a, a  ; if bit 7 is set, this will cause the carry flag to be set.
  jr   c, .noSpeedSwitch
  
  ld   a, P1F_GET_NONE ; disable joypad input
  ld   [rP1], a
  xor  a  ; set a to zero to disable interrupts
  ld   [rIE], a
  inc  a  ; set a to 1 to switch speeds
  ld   [rKEY1], a
  stop
  
.noSpeedSwitch
  ;----------------------------------
  ; Below is just code to show the result of the switching to doublespeed.


  ; measure how many instructions we can execute during a lcd line.
  ; Depending on doublespeed or not de will be $10 or $21
  ld hl, rLY
  ld de, 0
  xor a
waitForLine0:
  cp [hl]
  jr nz, waitForLine0
  inc a
waitForLine1:
  cp [hl]
  jr nz, waitForLine1
  inc a
waitForLine2:
  inc de
  cp [hl]
  jr nz, waitForLine2
  
  ; check de to see the difference between normal an doublespeed.
  halt
