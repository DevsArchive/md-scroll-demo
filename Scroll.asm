; -------------------------------------------------------------------------
; MD Scrolling Demo
; By Devon 2022
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Refresh screen
; -------------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to tilemap
; -------------------------------------------------------------------------

RefreshScreen:
	move.w	cameraY.w,d0			; Get camera position
	andi.w	#$FFF0,d0
	move.w	d0,prevCamY.w
	move.w	cameraX.w,d0
	andi.w	#$FFF0,d0
	move.w	d0,prevCamX.w
	subi.w	#16,d0
	
	moveq	#(ROWTILECNT/2)-1,d7		; Number of columns
	
.Draw:
	movem.l	d0/a0,-(sp)			; Draw column
	bsr.w	DrawColumn2
	bsr.w	FlushColumn
	movem.l	(sp)+,d0/a0
	
	addi.w	#16,d0				; Next column
	dbf	d7,.Draw			; Loop until columns are drawn
	rts

; -------------------------------------------------------------------------
; Draw column from tilemap
; -------------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to tilemap
; -------------------------------------------------------------------------

DrawColumn:
	move.w	cameraX.w,d0			; Update "previous" camera X position
	andi.w	#$FFF0,d0
	move.w	prevCamX.w,d1
	move.w	d0,prevCamX.w

	cmp.w	d1,d0				; Has the camera shifted a 16px block horizontally?
	beq.s	.End				; If not, branch
	bgt.s	.DrawRight			; If it shifted right, branch

.DrawLeft:
	subi.w	#16,d0				; Draw left of the camera
	bra.s	DrawColumn2

.DrawRight:
	addi.w	#320,d0				; Draw right of the camera
	bra.s	DrawColumn2

.End:
	rts

; -------------------------------------------------------------------------

DrawColumn2:
	move.w	cameraY.w,d1			; Draw from the top of the camera
	andi.w	#$FFF0,d1
	subi.w	#16,d1

	move.w	d1,d2				; Construct VDP command from camera position
	andi.w	#$F0,d2				; (y & $F0) * 16
	lsl.w	#4,d2
	move.w	d0,d3				; (x & $1F0) / 4
	andi.w	#$1F0,d3
	lsr.w	#2,d3
	add.w	d3,d2				; Combine
	addi.w	#$4000,d2			; Add base VRAM write command for plane A ($40000003)
	swap	d2
	move.w	#3,d2
	move.l	d2,colVDPCmd.w
	
	move.w	d1,d2				; Get number of tiles in first section before wrapping
	andi.w	#$F0,d2				; $10 - ((y & $F0) / 16)
	lsr.w	#4,d2
	subi.w	#$10,d2
	neg.w	d2
	cmpi.w	#COLTILECNT/2,d2		; Are there too many?
	bcs.s	.NotTooMany			; If not, branch
	move.w	#COLTILECNT/2,d2		; If so, cap it
	
.NotTooMany:
	move.w	d2,colSect1Cnt.w
	
	andi.w	#$3F0,d0			; Add X offset to tilemap address
	lsr.w	#2,d0				; (x & $3F0) / 4
	adda.w	d0,a0
	
	andi.w	#$3F0,d1			; Get Y offset in tilemap
	lsl.w	#5,d1				; (y & $3F0) * $20
	
	lea	colBuffer.w,a1			; Tile column buffer (left)
	lea	COLTILECNT*2(a1),a2		; Tile column buffer (right)

	moveq	#COLTILECNT-1,d2		; Tiles per column

.DrawLoop:
	move.w	(a0,d1.w),(a1)			; Get tile IDs
	move.w	2(a0,d1.w),(a2)
	addq.w	#1,(a1)+			; Add base tile ID of tilemap tiles in VRAM
	addq.w	#1,(a2)+
	addi.w	#$100,d1			; Add tilemap stride to Y offset to go next tilemap row
	andi.w	#$7F00,d1			; Wrap Y around
	dbf	d2,.DrawLoop			; Loop until column data is retrieved

.End:
	rts

; -------------------------------------------------------------------------
; Draw row from tilemap
; -------------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to tilemap
; -------------------------------------------------------------------------

DrawRow:
	move.w	cameraY.w,d1			; Update "previous" camera Y position
	andi.w	#$FFF0,d1
	move.w	prevCamY.w,d0
	move.w	d1,prevCamY.w

	cmp.w	d0,d1				; Has the camera shifted a 16px block vertically?
	beq.s	.End				; If not, branch
	bgt.s	.DrawBottom			; If it shifted right, branch

.DrawTop:
	subi.w	#16,d1				; Draw above camera
	bra.s	DrawRow2

.DrawBottom:
	addi.w	#224,d1				; Draw below camera
	bra.s	DrawRow2

.End:
	rts

; -------------------------------------------------------------------------

DrawRow2:
	move.w	cameraX.w,d0			; Draw from the left of the camera
	andi.w	#$FFF0,d0
	subi.w	#16,d0

	move.w	d1,d2				; Construct VDP command from camera position
	andi.w	#$F0,d2				; (y & $F0) * 16
	lsl.w	#4,d2
	move.w	d0,d3				; (x & $1F0) / 4
	andi.w	#$1F0,d3
	lsr.w	#2,d3
	add.w	d3,d2				; Combine
	addi.w	#$4000,d2			; Add base VRAM write command for plane A ($40000003)
	swap	d2
	move.w	#3,d2
	move.l	d2,rowVDPCmd.w
	
	move.w	d0,d2				; Get number of tiles in first section before wrapping
	andi.w	#$1F0,d2			; $20 - ((x & $1F0) / 16)
	lsr.w	#4,d2
	subi.w	#$20,d2
	neg.w	d2
	cmpi.w	#ROWTILECNT/2,d2		; Are there too many?
	bcs.s	.NotTooMany			; If not, branch
	move.w	#ROWTILECNT/2,d2		; If so, cap it
	
.NotTooMany:
	move.w	d2,rowSect1Cnt.w
	
	andi.w	#$3F0,d1			; Add Y offset to tilemap address
	lsl.w	#5,d1				; (y & $3F0) * $20
	adda.w	d1,a0
	
	andi.w	#$3F0,d0			; Get X offset in tilemap
	lsr.w	#2,d0				; (x & $3F0) / 4
	
	lea	rowBuffer.w,a1			; Tile row buffer (top)
	lea	ROWTILECNT*2(a1),a2		; Tile row buffer (bottom)
	lea	$100(a0),a3			; Get tilemap address 1 row down

	moveq	#ROWTILECNT-1,d2		; Tiles per row

.DrawLoop:
	move.w	(a0,d0.w),(a1)			; Get tile IDs
	move.w	(a3,d0.w),(a2)
	addq.w	#1,(a1)+			; Add base tile ID of tilemap tiles in VRAM
	addq.w	#1,(a2)+
	addq.w	#2,d0				; Go to next tile
	andi.w	#$FE,d0				; Wrap X around
	dbf	d2,.DrawLoop			; Loop until row data is retrieved

.End:
	rts

; -------------------------------------------------------------------------
; Flush column
; -------------------------------------------------------------------------

FlushColumn:
	lea	$C00004,a0			; VDP control port
	lea	-4(a0),a1			; VDP data port
	lea	colBuffer.w,a2			; Column buffer
	
	move.w	#$8F80,(a0)			; Set auto-increment to plane stride

	move.w	colSect1Cnt.w,d0		; Get number of blocks in first section before wrapping
	clr.w	colSect1Cnt.w			; Reset it
	subq.w	#1,d0				; Decrement for dbf
	bmi.s	.End				; If it's not set, then don't update
	move.w	d0,d1				; Save it for repeated use
	
	move.w	#((COLTILECNT/2)-1)-1,d2	; Get number of blocks in second section after wrapping
	sub.w	d0,d2				; (Also pre-decremented for dbf)
	move.w	d2,d3
	
	move.l	colVDPCmd.w,d4			; Set VRAM write command
	move.l	d4,(a0)
	
.DrawLeft1:
	move.l	(a2)+,(a1)			; Draw column tile
	dbf	d0,.DrawLeft1			; Loop until section is drawn
	
	tst.w	d2				; Is there a section 2 to draw?
	bmi.s	.DrawRight			; If not, branch
	
	move.l	d4,d0				; Set VRAM write command at top of plane
	andi.l	#$F07FFFFF,d0
	move.l	d0,(a0)
	
.DrawLeft2:
	move.l	(a2)+,(a1)			; Draw column tile
	dbf	d2,.DrawLeft2			; Loop until section is drawn

.DrawRight:
	move.l	d4,d0				; Set VRAM write command
	addi.l	#$20000,d4
	move.l	d4,(a0)
	
.DrawRight1:
	move.l	(a2)+,(a1)			; Draw column tile
	dbf	d1,.DrawRight1			; Loop until section is drawn
	
	tst.w	d3				; Is there a section 2 to draw?
	bmi.s	.End				; If not, branch
	
	andi.l	#$F07FFFFF,d4			; Set VRAM write command at top of plane
	move.l	d4,(a0)
	
.DrawRight2:
	move.l	(a2)+,(a1)			; Draw column tile
	dbf	d3,.DrawRight2			; Loop until section is drawn
	
.End:
	move.w	#$8F02,(a0)			; Set auto-increment back to 2
	rts

; -------------------------------------------------------------------------
; Flush row
; -------------------------------------------------------------------------

FlushRow:
	lea	$C00004,a0			; VDP control port
	lea	-4(a0),a1			; VDP data port
	lea	rowBuffer.w,a2			; Row buffer

	move.w	rowSect1Cnt.w,d0		; Get number of blocks in first section before wrapping
	clr.w	rowSect1Cnt.w			; Reset it
	subq.w	#1,d0				; Decrement for dbf
	bmi.s	.End				; If it's not set, then don't update
	move.w	d0,d1				; Save it for repeated use
	
	move.w	#((ROWTILECNT/2)-1)-1,d2	; Get number of blocks in second section after wrapping
	sub.w	d0,d2				; (Also pre-decremented for dbf)
	move.w	d2,d3
	
	move.l	rowVDPCmd.w,d4			; Set VRAM write command
	move.l	d4,(a0)
	
.DrawTop1:
	move.l	(a2)+,(a1)			; Draw row tile
	dbf	d0,.DrawTop1			; Loop until section is drawn
	
	tst.w	d2				; Is there a section 2 to draw?
	bmi.s	.DrawBottom			; If not, branch
	
	move.l	d4,d0				; Set VRAM write command at left side of plane
	andi.l	#$FF80FFFF,d0
	move.l	d0,(a0)
	
.DrawTop2:
	move.l	(a2)+,(a1)			; Draw row tile
	dbf	d2,.DrawTop2			; Loop until section is drawn

.DrawBottom:
	move.l	d4,d0				; Set VRAM write command
	addi.l	#$800000,d4
	move.l	d4,(a0)
	
.DrawBottom1:
	move.l	(a2)+,(a1)			; Draw row tile
	dbf	d1,.DrawBottom1			; Loop until section is drawn
	
	tst.w	d3				; Is there a section 2 to draw?
	bmi.s	.End				; If not, branch
	
	andi.l	#$FF80FFFF,d4			; Set VRAM write command at left side of plane
	move.l	d4,(a0)
	
.DrawBottom2:
	move.l	(a2)+,(a1)			; Draw row tile
	dbf	d3,.DrawBottom2			; Loop until section is drawn
	
.End:
	rts

; -------------------------------------------------------------------------
