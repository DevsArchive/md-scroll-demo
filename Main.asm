; -------------------------------------------------------------------------
; MD Scrolling Demo
; By Devon 2022
; -------------------------------------------------------------------------

	opt	l.				; Local labels use "."
	
; -------------------------------------------------------------------------

	include	"Variables.asm"

; -------------------------------------------------------------------------
; Very basic vector table
; -------------------------------------------------------------------------

	dc.l	$00000000			; Stack pointer
	dc.l	Start				; Entry point
	dcb.l	$1C, Start			; Error exceptions
	dc.l	VInterrupt			; V-BLANK interrupt
	dcb.l	$21, Start			; Other exceptions

; -------------------------------------------------------------------------
; ROM header
; -------------------------------------------------------------------------

	dc.b	"SEGA MEGA DRIVE "
	dc.b	"DEVON   2022.SEP"
	dc.b	"MD SCROLLING DEMO BY DEVON                      "
	dc.b	"MD SCROLLING DEMO BY DEVON                      "
	dc.b	"GM XXXXXXXX-00"
	dc.w	0
	dc.b	"J               "
	dc.l	$000000, $3FFFFF
	dc.l	$FF0000, $FFFFFF
	dc.b	"            "
	dc.b	"            "
	dc.b	"                                        "
	dc.b	"JUE             "

; -------------------------------------------------------------------------
; Program
; -------------------------------------------------------------------------

Start:
	move	#$2700,sr			; Disable interrupts
	movea.l	$0.w,sp				; Reset stack pointer

	move.b	$A10001,d0			; Check if this is a TMSS system
	andi.b	#$F,d0
	beq.s	.NoTMSS				; If not, branch
	move.l	#"SEGA",$A14000			; Satisfy TMSS

.NoTMSS:
	lea	$C00004,a0			; VDP control port
	lea	-4(a0),a1			; VDP data port

.WaitDMA:
	move.w	(a0),d0				; Reset VDP and wait for any DMAs to finish
	btst	#1,d0
	bne.s	.WaitDMA
	
	lea	$FF0000,a2			; Clear RAM
	move.w	#$10000/4-1,d0
	
.ClearRAM:
	clr.l	(a2)+
	dbf	d0,.ClearRAM

	move.w	#$8000|(%00000100),(a0)		; Disable H-INT and unlatch H/V counter
	move.w	#$8100|(%00110100),(a0)		; Disable display, enable V-INT and DMA, and set 224px vertical resolution
	move.w	#$8200|($C000/$400),(a0)	; Set plane A address in VRAM to $C000
	move.w	#$8300|($D000/$400),(a0)	; Set window plane address in VRAM to $D000
	move.w	#$8400|($E000/$2000),(a0)	; Set plane B address in VRAM to $E000
	move.w	#$8500|($F800/$200),(a0)	; Set sprite table address in VRAM to $F800
	move.w	#$8700,(a0)			; Set background color to line 0 color 0
	move.w	#$8ADF,(a0)			; Set H-INT counter to $DF
	move.w	#$8B00|(%00000000),(a0)		; Scroll horizontally and vertically by screen
	move.w	#$8C00|(%10000001),(a0)		; Set 320px horizontal resolution and disable shadow/highlight mode
	move.w	#$8D00|($FC00/$400),(a0)	; Set horizontal scroll table address in VRAM to $FC00
	move.w	#$8F01,(a0)			; Set auto-increment to 1 (for VRAM fill after this)
	move.w	#$9000|(%00000001),(a0)		; Set plane size to 64x32 tiles
	move.w	#$9100,(a0)			; Set window plane horizontal position to 0
	move.w	#$9200,(a0)			; Set window plane vertical position to 0

	move.l	#$93FF94FF,(a0)			; Fill VRAM with 0
	move.w	#$9780,(a0)
	move.l	#$40000080,(a0)
	move.w	#(0)<<8,(a1)

.WaitVRAMClear:
	move.w	(a0),d0				; Wait for VRAM to clear
	btst	#1,d0
	bne.s	.WaitVRAMClear

	move.w	#$8F02,(a0)			; Set auto-increment to 2
	
	move.l	#$C0000000,(a0)			; Clear CSRAM
	move.w	#$80/4-1,d0
	
.ClearCRAM:
	move.l	#0,(a1)
	dbf	d0,.ClearCRAM
	
	move.l	#$40000010,(a0)			; Clear VSRAM
	move.w	#$50/4-1,d0
	
.ClearVSRAM:
	move.l	#0,(a1)
	dbf	d0,.ClearVSRAM
	
	move.w	#$100,$A11200			; Set Z80 reset off
	move.w	#$100,$A11100			; Stop the Z80

.WaitZ80:
	btst	#0,$A11100
	bne.s	.WaitZ80
	
	moveq	#$40,d0				; Set up I/O control ports
	move.b	d0,$A10009
	move.b	d0,$A1000B
	move.b	d0,$A1000D
	
	lea	$A00000,a2			; Set up Z80 program
	move.b	#$F3,(a2)+			; DI
	move.b	#$C3,(a2)+			; JP $0000
	move.b	#$00,(a2)+
	move.b	#$00,(a2)+
	
	move.w	#0,$A11200			; Set Z80 reset on
	ror.l	#8,d0				; Delay for a bit
	move.w	#$100,$A11200			; Set Z80 reset off
	move.w	#0,$A11100			; Start	the Z80
	
	move.b	#$9F,$11(a1)			; Silence PSG
	move.b	#$BF,$11(a1)
	move.b	#$DF,$11(a1)
	move.b	#$FF,$11(a1)

; -------------------------------------------------------------------------

	move.l	#$C0000000,(a0)			; Load palette
	lea	Palette(pc),a2
	moveq	#PaletteLen/4-1,d0

.LoadPal:
	move.l	(a2)+,(a1)
	dbf	d0,.LoadPal

	move.w	#$9700|((Tiles>>17)&$7F),(a0)	; Load tiles
	move.l	#$96009500|((Tiles<<7)&$FF0000)|((Tiles>>1)&$FF),(a0)
	move.l	#$94009300|((TilesLen<<7)&$FF0000)|((TilesLen>>1)&$FF),(a0)
	move.w	#$4020,(a0)			; Due to hardware bug, VDP command must be split
	move.w	#$0080,-(sp)			; with the lower word being read from RAM
	move.w	(sp)+,(a0)

	clr.w	cameraX.w			; Reset camera
	clr.w	cameraY.w

	lea	Tilemap,a0			; Refresh screen
	bsr.w	RefreshScreen
	
	move.w	#$8100|(%01110100),$C00004	; Enable display

; -------------------------------------------------------------------------

MainLoop:
	bsr.w	VSync				; VSync
	
	btst	#0,ctrlHold.w			; Is up being held?
	beq.s	.CheckDown			; If not, branch
	subq.w	#2,cameraY.w			; Move camera up
	
.CheckDown:
	btst	#1,ctrlHold.w			; Is down being held?
	beq.s	.CheckLeft			; If not, branch
	addq.w	#2,cameraY.w			; Move camera down
	
.CheckLeft:
	btst	#2,ctrlHold.w			; Is up being held?
	beq.s	.CheckRight			; If not, branch
	subq.w	#2,cameraX.w			; Move camera left
	
.CheckRight:
	btst	#3,ctrlHold.w			; Is down being held?
	beq.s	.Draw				; If not, branch
	addq.w	#2,cameraX.w			; Move camera right
	
.Draw:
	lea	Tilemap,a0			; Draw column
	bsr.w	DrawColumn
	lea	Tilemap,a0			; Draw row
	bsr.w	DrawRow

	bra.s	MainLoop			; Loop

; -------------------------------------------------------------------------
; V-BLANK interrupt
; -------------------------------------------------------------------------

VInterrupt:
	movem.l	d0-a6,-(sp)			; Save registers
	
	move.w	#$100,$A11100			; Stop the Z80

.WaitZ80:
	btst	#0,$A11100
	bne.s	.WaitZ80
	
	bsr.w	ReadController			; Read controller
	
	move.l	#$7C000003,$C00004		; Set horizontal scroll offset
	move.w	cameraX.w,d0
	neg.w	d0
	move.w	d0,$C00000
	
	move.l	#$40000010,$C00004		; Set vertical scroll offset
	move.w	cameraY.w,$C00000

	bsr.w	FlushColumn			; Flush column
	bsr.w	FlushRow			; Flush row
	
	move.w	#0,$A11100			; Start	the Z80

	addq.w	#1,frameCount.w			; Increment frame count
	movem.l	(sp)+,d0-a6			; Restore registers
	rte

; -------------------------------------------------------------------------
; Read controller
; -------------------------------------------------------------------------

ReadController:
	lea	ctrlData.w,a0			; Controller data buffer
	lea	$A10003,a1			; Controller port 1

	move.b	#0,(a1)				; TH = 0
	tst.w	(a0)				; Delay
	move.b	(a1),d0				; Read start and A buttons
	lsl.b	#2,d0
	andi.b	#$C0,d0
	
	move.b	#$40,(a1)			; TH = 1
	tst.w	(a0)				; Delay
	move.b	(a1),d1				; Read B, C, and D-pad buttons
	andi.b	#$3F,d1

	or.b	d1,d0				; Combine button data
	not.b	d0				; Flip bits
	move.b	d0,d1				; Make copy

	move.b	(a0),d2				; Mask out tapped buttons
	eor.b	d2,d0
	move.b	d1,(a0)+			; Store pressed buttons
	and.b	d1,d0				; store tapped buttons
	move.b	d0,(a0)+
	rts

; -------------------------------------------------------------------------
; VSync
; -------------------------------------------------------------------------

VSync:
	move	#$2000,sr			; Enable interrupts
	move.w	frameCount.w,d0			; Get current frame count

.Wait:
	cmp.w	frameCount.w,d0			; Has it changed yet?
	beq.s	.Wait				; If not, wait
	rts
	
; -------------------------------------------------------------------------

	include	"Scroll.asm"

; -------------------------------------------------------------------------
; Data
; -------------------------------------------------------------------------

PaletteLen	EQU	PaletteEnd-Palette
Palette:
	incbin	"Data/Palette.bin"
PaletteEnd:
	even

TilesLen	EQU	TilesEnd-Tiles
Tiles:
	incbin	"Data/Art.bin"
TilesEnd:
	even

Tilemap:
	incbin	"Data/Map.bin"
	even

; -------------------------------------------------------------------------
