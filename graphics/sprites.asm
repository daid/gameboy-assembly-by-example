; "Minimal" example on how to work with sprites
; Sprites require a lot of working parts, so this is one of the larger examples out there.
; OAM is the memory that contains the sprite information.
;   But we do not want to write to this directly, so we setup a OAM buffer in WRAM
;   And then during VBlank we copy from the buffer to the actual OAM memory.
;   We use a special DMA routine for this, which needs to be in HRAM.

INCLUDE "hardware.inc"

SECTION "OAMData", WRAM0, ALIGN[8]
wOAMBuffer: ; OAM Memory is for 40 sprites with 4 bytes per sprite
  ds 40 * 4
.end:

SECTION "vblankInterrupt", ROM0[$040]
  jp vblankHandler

SECTION "entry", ROM0[$100]
  jp start
  ds $150-@, 0 ; Space for the header

SECTION "vblankHandler", ROM0
vblankHandler:
  ; VBlank interrupt. We only call the OAM DMA routine here.
  ; We need to be careful to preserve the registers that we use, see interrupt example.
  push af
  call hOAMCopyRoutine
  pop  af
  reti

SECTION "main", ROM0
start:
  call disableLCD
  call initOAM
  call loadTiles
  call loadPalette
  call enableLCD

  ; Configure 2 sprites in the OAM memory with different positions and palettes.
  ld   a, 20  ; y position
  ld   [wOAMBuffer + 0], a
  ld   a, 20  ; x position
  ld   [wOAMBuffer + 1], a
  ld   a, 0   ; tile number
  ld   [wOAMBuffer + 2], a
  ld   a, 0   ; sprite attributes
  ld   [wOAMBuffer + 3], a

  ld   a, 24  ; y position
  ld   [wOAMBuffer + 4], a
  ld   a, 24  ; x position
  ld   [wOAMBuffer + 5], a
  ld   a, 0   ; tile number
  ld   [wOAMBuffer + 6], a
  ld   a, OAMF_PAL1 | OAMF_YFLIP
  ld   [wOAMBuffer + 7], a

  ; Start the main loop, first enable the VBlank interrupt, and then just loop forever
  ld   a, IEF_VBLANK
  ld   [rIE], a
  ei
haltLoop:
  halt
  ; Enable the next 2 lines to move one of the sprites.
  ;ld   hl, wOAMBuffer + 1
  ;inc  [hl]
  jp   haltLoop
  
initOAM:
  ; Initialize the OAM shadow buffer, and setup the OAM copy routine in HRAM.
  ld   hl, wOAMBuffer
  ld   c, wOAMBuffer.end - wOAMBuffer
  xor  a
.clearOAMLoop:
  ld   [hl+], a
  dec  c
  jr   nz, .clearOAMLoop

  ld   hl, hOAMCopyRoutine
  ld   de, oamCopyRoutine
  ld   c, hOAMCopyRoutine.end - hOAMCopyRoutine
.copyOAMRoutineLoop:
  ld   a, [de]
  inc  de
  ld   [hl+], a
  dec  c
  jr   nz, .copyOAMRoutineLoop
  ; We directly copy to clear the initial OAM memory, which else contains garbage.
  call hOAMCopyRoutine
  ret

oamCopyRoutine:
LOAD "hram", HRAM
hOAMCopyRoutine:
  ld   a, HIGH(wOAMBuffer)
  ldh  [rDMA], a
  ld   a, $28
.wait:
  dec  a
  jr   nz, .wait
  ret
.end:
ENDL

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
  ld   a, %11100100
  ld   [rOBP0], a
  ld   a, %11011000
  ld   [rOBP1], a
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
  ld   a, LCDCF_BGON | LCDCF_BG8800 | LCDCF_ON | LCDCF_OBJON
  ldh  [rLCDC], a
  ret



SECTION "graphics", ROM0
graphicTiles:
  ; Graphics data
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
.end:
