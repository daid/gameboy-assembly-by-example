INCLUDE "hardware.inc"

SECTION "entry", ROM0[$100]
  jp start

SECTION "gbc", ROM0[$143]
  db CART_COMPATIBLE_DMG_GBC

SECTION "main", ROM0[$150]
start:
  
  ld   a, [rKEY1]
  add  a, a  ; if bit 7 is set, this will cause the carry flag to be set.
  jr   c, .noSpeedSwitch
  
  ld   a, P1F_GET_NONE
  ld   [rP1], a
  xor  a  ; set a to zero
  ld   [rIE], a
  inc  a
  ld   [rKEY1], a
  stop
  
.noSpeedSwitch
  
  halt
