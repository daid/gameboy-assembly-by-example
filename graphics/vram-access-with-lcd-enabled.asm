; Enable this to check STAT for busy before writting to the background map.
;  This allows proper writting to VRAM, but at a cpu cycle overhead
ENABLE_STAT_CHECK = 0

; Enable gameboy color double speed mode and notice that you can execute more instructions in the time where you can write to vram.
ENABLE_GBC = 0

; Amount of bytes to write to VRAM. When the STAT check is enabled, this writes this many bytes to VRAM before checking STAT again.
WRITE_BURST_SIZE = 4

INCLUDE "hardware.inc"


SECTION "entry", ROM0[$100]
  jp start

IF ENABLE_GBC
SECTION "gbc", ROM0[$143]
  db CART_COMPATIBLE_DMG_GBC
ENDC

SECTION "main", ROM0[$150]
start:
IF ENABLE_GBC
  call setDoubleSpeed
ENDC

  call disableLCD
  call loadHexDigits
  call loadPalette
  call enableLCD

  ; Write 0-255 to both tilemaps. Do this correctly, or incorrectly depending on the settings at the top.
  xor  a
  ld   hl, _SCRN0
writeBackgroundTilemapLoop:
IF ENABLE_STAT_CHECK
  ld   b, a
.loop:
  ld   a, [rSTAT]
  and  STATF_BUSY
  jr   nz, .loop
  ; After this check you have 16 guaranteed machine cycles to access VRAM
  ld   a, b      ; 1 machine cycle
ENDC
REPT WRITE_BURST_SIZE
  ld   [hl+], a  ; 2 machine cycles
  inc  a         ; 1 machine cycle
ENDR
  bit  3, h
  jp   nz, writeBackgroundTilemapLoop

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
  ld   a, %11010100
  ld   [rBGP], a
IF ENABLE_GBC
  ld   a, $80
  ld   [rBCPS], a
  ld   hl, gbcPalette
REPT 8
  ld   a, [hl+]
  ld   [rBCPD], a
ENDR
ENDC
  ret
  
gbcPalette:
  dw $ffff, $eeee, $4444, $0000
  
loadHexDigits:
  ld   de, _VRAM + 16
  ld   c, 1

loop:
  ld   a, c
  swap a
  and  $0f
  ld   l, a
  ld   h, 0
  add  hl, hl
  add  hl, hl
  add  hl, hl
  push de
  ld   de, hexDigitFont4x8_1bbp
  add  hl, de
  pop  de

  push de
REPT 8
  ld   a, [hl+]
  swap a
  inc  de
  ld   [de], a
  inc  de
ENDR
  pop  de

  ld   a, c
  and  $0f
  ld   l, a
  ld   h, 0
  add  hl, hl
  add  hl, hl
  add  hl, hl
  push de
  ld   de, hexDigitFont4x8_1bbp
  add  hl, de
  pop  de

  inc de
  inc de
  inc hl
REPT 7
  ld   a, %01111111
  ld   [de], a
  inc  de
  ld   a, [de]
  or   [hl]
  inc  hl
  ld   [de], a
  inc  de
ENDR

  inc  c
  jp   nz, loop
  ret

enableLCD:
  ld   a, LCDCF_BGON | LCDCF_BG8000 | LCDCF_ON
  ldh  [rLCDC], a
  ret

setDoubleSpeed:
  ;-----------------------------------
  ld   a, [rKEY1]
  add  a, a  ; if bit 7 is set, this will cause the carry flag to be set.
  ret  c
  
  ld   a, P1F_GET_NONE ; disable joypad input
  ld   [rP1], a
  xor  a  ; set a to zero to disable interrupts
  ld   [rIE], a
  inc  a  ; set a to 1 to switch speeds
  ld   [rKEY1], a
  stop
  ret


hexDigitFont4x8_1bbp:
  db %000
  db %010
  db %101
  db %101
  db %101
  db %101
  db %101
  db %010

  db %000
  db %010
  db %110
  db %010
  db %010
  db %010
  db %010
  db %111

  db %000
  db %010
  db %101
  db %001
  db %010
  db %010
  db %100
  db %111

  db %000
  db %010
  db %101
  db %001
  db %010
  db %001
  db %101
  db %010

  db %000
  db %001
  db %101
  db %101
  db %111
  db %001
  db %001
  db %001

  db %000
  db %111
  db %100
  db %110
  db %001
  db %001
  db %101
  db %010

  db %000
  db %010
  db %101
  db %100
  db %110
  db %101
  db %101
  db %010

  db %000
  db %111
  db %001
  db %001
  db %010
  db %010
  db %100
  db %100

  db %000
  db %010
  db %101
  db %101
  db %010
  db %101
  db %101
  db %010

  db %000
  db %010
  db %101
  db %101
  db %011
  db %001
  db %101
  db %010

  db %000
  db %010
  db %101
  db %101
  db %111
  db %101
  db %101
  db %101

  db %000
  db %010
  db %101
  db %101
  db %110
  db %101
  db %101
  db %110

  db %000
  db %010
  db %101
  db %100
  db %100
  db %100
  db %101
  db %010

  db %000
  db %110
  db %101
  db %101
  db %101
  db %101
  db %101
  db %110

  db %000
  db %111
  db %100
  db %100
  db %110
  db %100
  db %100
  db %111

  db %000
  db %111
  db %100
  db %100
  db %110
  db %100
  db %100
  db %100
