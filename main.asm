hblnk = 0xe008
vblnk = 0xe002

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

BLOB_AREA_WIDTH = 32
BLOB_AREA_HEIGHT = SCREEN_HEIGHT

BLOB_MAX = 32

FRAME_COUNT = 520
ROTOZOOM_FRAMES = 560

SCROLL_SPEED=4
ANIM_SPEED=6
PLAYER_BASE_X=18
PLAYER_BASE_Y=17

org #1200

macro wait_vbl
    ; wait for vblank    
    ld hl, vblnk
    ld a, 0x7f
@wait0:
    cp (hl)
    jp nc, @wait0
@wait1:
    cp (hl)
    jp c, @wait1
endm

main:
    di
    im 1

start:
    ld hl,0x0000
    ld (scroll_x), hl

    ld a,SCROLL_SPEED
    ld (scroll_counter),a

    ld a,PLAYER_BASE_X
    ld (player_x),a
    
    ld a,PLAYER_BASE_Y
    ld (player_y),a

    ld a,ANIM_SPEED
    ld (player_counter),a

    xor a
    ld (player_anim),a
    ld (player_state),a
    ld (player_jump),a
    ld (score),a
    ld (score+1),a
    ld (score+2),a
    ld (score+3),a

    ld hl,10+40*4
    ld (player_addr),hl

    ld ix, title
    ld iy, 0xd800 + 40*25 - 40 + 10
    call gfx_fill
    ld iy, 0xd000 + 40*25 - 40 + 10
    call gfx_fill

wait_key:
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key

    wait_vbl

    ld ix, playfield
    ld iy, 0xd800 + 40*25 - 40 + 10
    call gfx_fill
    ld iy, 0xd000 + 40*25 - 40 + 10
    call gfx_fill

loop:
    ld bc, 1
    call inc_score
    call show_score

    wait_vbl
    
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, @no_jump
        ld a,1
        ld (player_state),a
@no_jump

    ld hl, scroll_counter
    dec (hl)
    jp nz,@skip_scroll_update
        ld (hl), SCROLL_SPEED

        ld hl,(scroll_x)
        inc hl
        ld a,l
        and 0xff
        ld l,a
        ld a,h
        and 0x03
        ld h,a
        ld (scroll_x),hl
@skip_scroll_update:
    
    call erase_player
    call draw_field

    ld hl, player_counter
    dec (hl)
    jp nz,@skip_anim_update
        ld (hl), ANIM_SPEED

        ld a,(player_anim)
        inc a
        and #3
        ld (player_anim),a
@skip_anim_update:

    ld a,(player_state)
    cp 0
    jp nz,@jumping
        ld a,PLAYER_BASE_Y
        jp @draw
@jumping:
    ld hl,player_jump
    ld a,(hl)
    inc (hl)
    cp 34
    jp nz,@no_reset
        xor a
        ld (player_state),a
        ld (hl),a
        ld a, PLAYER_BASE_Y
        ld (player_y), a
        jp @draw
@no_reset:
    ld c,a
    ld b,0
    ld hl,jump_curve
    add hl,bc
    ld b,(hl)
    ld a,(player_y)
    add a,b
    ld (player_y),a
@draw:
    ld d,a
    ld e,PLAYER_BASE_X
    call draw_player

    ld a,17
    cp d
    jp z, loop

PRESS_SPACE_OFFSET = 10*SCREEN_WIDTH + SCREEN_WIDTH/2 - 6
    ld hl, press_space
    ld de, 0xd000+PRESS_SPACE_OFFSET
    ld bc, 12
    ldir

    ld hl, 0xd800+PRESS_SPACE_OFFSET
    ld (hl), 0x71
    ld de, 0xd801+PRESS_SPACE_OFFSET
    ld bc, 11
    ldir

    ld b,10
l0:
    wait_vbl
    dec b
    jp nz, l0

wait_key_2:
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key_2

    ld b,10
l1:
    wait_vbl
    dec b
    jp nz, l1

    jp start


; Fill screen with gfx
gfx_fill:
    ld a, 25
.l0:
    ld l, 4
.l1:
    ld (@gfx_fill.save), sp
    di
    
    ld sp, ix
    ld bc, 10
    add ix, bc
    
    pop bc  
    pop de
    exx
    pop hl
    pop bc
    pop de
    
    ld sp, iy
    push de
    push bc
    push hl
    exx
    push de
    push bc

    ld bc,  10
    add iy, bc

@gfx_fill.save equ $+1
    ld sp, 0x0000
    ei
    
    dec l
    jp nz, .l1

    ld bc, -80
    add iy, bc
    
    dec a
    jp nz, .l0

    ret

draw_field:

    ld (@save_sp),sp

    ld hl,(scroll_x)
    ld de,field
    add hl,de
   
repeat 4, i
    ld sp, hl 
    pop de
    pop bc
    exx
    pop hl
    pop de
    pop bc

    ld sp, 0xd800+16*40+(i*10)
    push bc
    push de
    push hl
    exx
    push bc
    push de

    ld bc,10
    add hl,bc
rend

repeat 4, j
repeat 4, i
    ld sp, 0xd800+16*40+(i-1)*10 
    pop de
    pop bc
    exx
    pop hl
    pop de
    pop bc

    ld sp, 0xd800+16*40+(i*10)+(j*40)
    push bc
    push de
    push hl
    exx
    push bc
    push de
rend
rend

@save_sp equ $+1
    ld sp,0x0000

    ret

erase_player:
    ld hl,(player_addr)
    push hl 
    xor a
    ld bc,40-4
repeat 4, j
repeat 4, i
    ld (hl),a
    inc hl
rend
    add hl,bc
rend

    pop hl
    ld de, 0x0800
    add hl, de
    ld a, 0x11
repeat 4, j
repeat 4, i
    ld (hl),a
    inc hl
rend
    add hl,bc
rend
    ret

; e : x
; d : y
draw_player:
    push de

    ld a,(player_anim)
    add a,a
    add a,a
    add a,a
    add a,a
    ld e,a
    ld d,0
    ld ix,player
    add ix,de

    pop de
    ld a,d
    ; compute address
    add a,a
    ld l,a
    ld h,hi(y_offset)
    ld c,(hl)
    inc hl
    ld b,(hl)

    ld l,e
    ld h,0xd0
    add hl,bc

    ld (player_addr),hl
    push bc

    ; out (char)
    ld bc, 40-4
repeat 4, j
repeat 4, i
    ld a,(ix+(i-1)+((j-1)*4))
    
    ld (hl),a
    inc hl
rend
    add hl, bc
rend
    
    pop bc
    
    ld l,e
    ld h,0xd8
    add hl,bc

    ld d,0
    ; out (col)
    ld bc, 40-4
repeat 4, j
repeat 4, i
    ld a,(hl)
    or d
    ld d, a

    ld a,(player_col+(i-1)+((j-1)*4))
    ld (hl),a
    inc hl
rend
    add hl, bc
rend

    ret

inc_score:
    ld hl,(score)
    ld a,l
    add c
    daa
    ld l,a
    ld a,h
    adc b
    daa
    ld h,a
    ld (score),hl
    ret nc
    ld hl,(score+2)
    ld a,l
    add 1
    daa
    ld l,a
    ld a,h
    adc 0
    daa
    ld h,a
    ld (score+2),hl
    ret

show_score:
    exx
    ld hl, 0xd000+7
    exx
    ld hl,(score+2)
    call show_bcd 
    ld hl,(score)
    call show_bcd 
    ret

print_char:
    exx
    ld (hl),a
    inc hl
    exx
    ret

show_bcd:
    ld a,h
    call @bcd
    ld a,l
@bcd:
    ld h,a
    rra
    rra
    rra
    rra
    and 0x0f
    add 0x20
    call print_char
    ld a,h
    and 0x0f
    add 0x20
    call print_char
    ret

field:
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17
    defb 17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17
    defb 17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17
    defb 17,17,68,68,17,17,17,17,17,17,68,68,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,68,68,17,17
    defb 17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17
    defb 17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17
    defb 17,68,68,17,17,17,17,68,17,17,17,17,17,68,68,17,17,17,17,17,68,17,17,17,17,17,68,17,17,17,17,17
    defb 68,68,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,68,68,17
    defb 17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,68,68,17,17,17,17,17,17,17,17,17,17,17,17
    defb 17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
player:
    ; chars
    defb 0x4b,0x84,0x84,0x4c
    defb 0x6f,0x3a,0x3a,0x6e
    defb 0x70,0x43,0x43,0x70
    defb 0x00,0x56,0x42,0x00

    ; chars
    defb 0x4b,0x83,0x84,0x4c
    defb 0x6f,0x3a,0x3a,0x6e
    defb 0xa8,0x43,0x43,0xa9
    defb 0x00,0x42,0x42,0x00

    ; chars
    defb 0x4b,0x82,0x83,0x4c
    defb 0x6f,0x3a,0x3a,0x6e
    defb 0x76,0x43,0x43,0x77
    defb 0x00,0x56,0x42,0x00

    ; chars
    defb 0x4b,0x83,0x82,0x4c
    defb 0x6f,0x3a,0x3a,0x6e
    defb 0xdd,0x43,0x43,0xd9
    defb 0x00,0x56,0x56,0x00

player_col:
    ; cols
    defb 0x61,0xf1,0xf1,0x61
    defb 0x61,0x71,0x71,0x61
    defb 0x61,0x71,0x71,0x61
    defb 0x11,0x61,0x61,0x11
    
align 256
y_offset:
i = 0
while i < 25
    defw i*40
    i = i+1
wend

jump_curve:
    defb -3,-2,-2,-1,-1,0,-1,0,-1,0,-1,0,-1,0,0,0,0,0,0,0,0,1,0,1,0,1,0,1,0,1,1,2,2,3

playfield:
    incbin "./data/playfield.bin"
title:
    incbin "./data/title.bin"

press_space:
    defb 0x10,0x12,0x05,0x13,0x13,0x00,0x00,0x13,0x10,0x01,0x03,0x05

score:
    defw 0x0000,0x0000
scroll_x:
    defw 0x0000
scroll_counter:
    defb SCROLL_SPEED
player_x:
    defb PLAYER_BASE_X
player_y:
    defb PLAYER_BASE_Y
player_jump:
    defb 0
player_state:
    defb 0
player_counter:
    defb ANIM_SPEED
player_anim:
    defb 0x00
player_addr:
    defw 10+40*4
; [todo] RAM var at the end
buffer:
