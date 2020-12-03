INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

EntryPoint:
    di
    jp Start

REPT $150 - $104
    db 0
ENDR


SECONDS EQU $c000
MINUTES EQU $c001
HOURS EQU $c002
DRAW_HOURS EQU $9906
DRAW_MINUTES EQU $9909
DRAW_SECONDS EQU $990c


SECTION "VBlank", ROM0[$0040]
    call UpdateScreen
    reti

SECTION "Timer", ROM0[$0050]
    call Timer
    reti

SECTION "Main", ROM0
Start:
.setup
di

xor a
ld [rLCDC], a

ld hl, $9000
ld de, FontTiles
ld bc, FontTilesEnd - FontTiles

.memcpy
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .memcpy

ld hl, $9800
ld bc, 32 * 32
.clean_screen
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .clean_screen


.setupTimer
    ld a, %00000100
    ld [rIE], a

    ld a, %0000100
    ld [rTAC], a

    ld a, %00000101
    ld [$FFFF], a

    call Refresh
    call ScreenInit
    ei

.lockup
    ld a, $10
    ld [rP1], a
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    cpl

    and %00000001

    call nz, Refresh

    halt
    jr .lockup


Refresh:
    xor a
    ld b, a
    ld c, a
    ld hl, SECONDS
    ld [hli], a                 ;; seconds
    ld [hli], a                 ;; minutes
    ld [hl], a                 ;; hours
    ret

ScreenInit:
    ;; palette
    ld a, %10110100
    ld [rBGP],  a

    ;; screen pos
    ld a, 0
    ld [rSCX], a

    ;; set tiles to 00:00:00
    ld hl, DRAW_HOURS
    ld a, $01
    ld [hli], a
    ld [hli], a
    ld a, $0b
    ld [hli], a
    ld a, $01
    ld [hli], a
    ld [hli], a
    ld a, $0b
    ld [hli], a
    ld a, $01
    ld [hli], a
    ld [hli], a

    ld a, %10000001
    ld [rLCDC], a
    ret

UpdateHMS:
    ld c, [hl]
    ld a, c

    sra a
    sra a
    sra a
    sra a

    add a, $1
    ld h, d
    ld l, e
    ld [hli], a
    ld a, c
    and %00001111
    add a, $1
    ld [hli], a
    ret

UpdateScreen:
    ld hl, SECONDS
    ld de, DRAW_SECONDS
    call UpdateHMS

    ld hl, MINUTES
    ld de, DRAW_MINUTES
    call UpdateHMS

    ld hl, HOURS
    ld de, DRAW_HOURS
    call UpdateHMS

    ret

Timer:
    ld a, b
    inc a
    cp a, $10
    jr z, .seconds
    ld b, a
    ret

.seconds
    ld b, $00
    ld hl, SECONDS
    ld a, [hl]
    inc a
    daa
    cp $60
    jr z, .minutes
    ld [hl], a
    ret

.minutes
    ld [hl], $00
    ld hl, MINUTES
    ld a, [hl]
    inc a
    daa
    cp $60
    jr z, .hours
    ld [hl], a
    ret

.hours
    ld [hl], $00
    ld hl, HOURS
    ld a, [hl]
    inc a
    daa
    cp $99
    jr z, .refresh
    ld [hl], a
    ret

.refresh
    ld [hl], $00

    ret


SECTION "Font", ROM0
FontTiles:
INCBIN "numbers.chr"
FontTilesEnd:
