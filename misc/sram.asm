INCLUDE "hardware.inc"

SECTION "sram", SRAM
; Create a 1 byte variable
sByteVariable::
  ds 1
; Create a 2 byte variable
sWordVariable::
  ds 2

; Create a 16 byte buffer
sBuffer::
  ds 16
.end::


SECTION "entry", ROM0[$100]
  jp start


SECTION "cart_type", ROM0[$147]
  db CART_ROM_MBC5_RAM_BAT
SECTION "cart_sram_size", ROM0[$149]
  db CART_RAM_64K

SECTION "main", ROM0[$150]
start:
  ; Enable SRAM read/write access
  ld   a, CART_RAM_ENABLE
  ld   [$0000], a

  ; Store 100 in wByteVariable
  ld   a, 100
  ld   [sByteVariable], a

  ; Store 1000 in wWordVariable
  ld   a, HIGH(1000)
  ld   [sWordVariable+0], a
  ld   a, LOW(1000)
  ld   [sWordVariable+1], a

  ; Clear wBuffer
  ld   hl, sBuffer
  xor  a
  ld   c, sBuffer.end - sBuffer
clearBufferLoop:
  ld   [hl+], a
  dec  c
  jr   nz, clearBufferLoop
  
  
  ; Read wByteVariable into a
  ld   a, [sByteVariable]
  ld   b, a

  ; Read wWordVariable into de
  ld   hl, sWordVariable
  ld   d, [hl]
  inc  hl
  ld   e, [hl]

  ; Disable SRAM read/write access, this disables writing to it by mistake, as well as some power
  ld   a, CART_RAM_DISABLE
  ld   [$0000], a

  ; Check the sram to see the values written to memory
  ; See a = $64, which is 100 in hex
  ; See de = $03e8, which is 1000 in hex
haltLoop:
  halt
  jr haltLoop
