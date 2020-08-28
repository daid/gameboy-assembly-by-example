INCLUDE "hardware.inc"

SECTION "workram", WRAM0
; Create a 1 byte variable
wByteVariable::
  ds 1
; Create a 2 byte variable
wWordVariable::
  ds 2

; Create a 16 byte buffer
wBuffer::
  ds 16
.end::


SECTION "entry", ROM0[$100]
  jp start

SECTION "main", ROM0[$150]
start:
  ; Store 100 in wByteVariable
  ld   a, 100
  ld   [wByteVariable], a

  ; Store 1000 in wWordVariable
  ld   a, HIGH(1000)
  ld   [wWordVariable+0], a
  ld   a, LOW(1000)
  ld   [wWordVariable+1], a

  ; Clear wBuffer
  ld   hl, wBuffer
  xor  a
  ld   c, wBuffer.end - wBuffer
clearBufferLoop:
  ld   [hl+], a
  dec  c
  jr   nz, clearBufferLoop
  
  
  ; Read wByteVariable into a
  ld   a, [wByteVariable]
  ld   b, a

  ; Read wWordVariable into de
  ld   hl, wWordVariable
  ld   d, [hl]
  inc  hl
  ld   e, [hl]

  ; Check the vram to see the values written to memory
  ; See a = $64, which is 100 in hex
  ; See de = $03e8, which is 1000 in hex
haltLoop:
  halt
  jr haltLoop
