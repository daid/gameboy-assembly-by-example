; Simple example to show how to load initial graphics data into VRAM.
; This is only applicable during initial start of your rom, as it disables the LCD
; to get full access to VRAM. This will make the screen white during this time.

INCLUDE "hardware.inc"

SECTION "graphics", ROM0
graphicTiles:
  ; Graphics data, below contains 3x the same 8x8 graphics tile in different formats.
  ; Prefered way would be to use INCBIN with rgbgfx, which is currently not possible in rgbds-live.
opt g.123
  dw `.111111.
  dw `1......1
  dw `1.3..3.1
  dw `1......1
  dw `1......1
  dw `1.2..2.1
  dw `1..22..1
  dw `.111111.
  
  dw $007e
  dw $0081
  dw $24a5
  dw $0081
  dw $0081
  dw $2481
  dw $1881
  dw $007e
  
  db $7e, $00, $81, $00, $a5, $24, $81, $00, $81, $00, $81, $24, $81, $18, $7e, $00
.end:

SECTION "entry", ROM0[$100]
  jp start

SECTION "main", ROM0[$150]
start:
  call disableLCD
  call loadTiles
  call loadPalette
  call enableLCD

haltLoop:
  halt
  jp   haltLoop
  
disableLCD:
  ; Disable the LCD, needs to happen during VBlank, or else we damage hardware
.waitForVBlank:
  ld   a, [rLY]
  cp   144
  jr   c, .waitForVBlank

  xor  a
  ld   [rLCDC], a ; disable the LCD by writting zero to LCDC
  ret

loadPalette:
  ld   a, %11100100
  ld   [rBGP], a
  ret

; Load the graphics tiles into VRAM
loadTiles:
  ld   hl, graphicTiles
  ld   de, graphicTiles.end - graphicTiles  ; We set de to the amount of bytes to copy.
  ld   bc, _VRAM

.copyTilesLoop:
  ; Copy a byte from ROM to VRAM, and increase both hl, bc to the next location.
  ld   a, [hl+]
  ld   [bc], a
  inc  bc
  ; Decrease the amount of bytes we still need to copy and check if the amount left is zero.
  dec  de
  ld   a, d
  or   e
  jp   nz, .copyTilesLoop
  ret

enableLCD:
  ld   a, LCDCF_BGON | LCDCF_BG8000 | LCDCF_ON
  ldh  [rLCDC], a
  ret
