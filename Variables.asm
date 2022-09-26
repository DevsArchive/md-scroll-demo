; -------------------------------------------------------------------------
; MD Scrolling Demo
; By Devon 2022
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Constants
; -------------------------------------------------------------------------

ROWTILECNT	EQU	(320/8)+4
COLTILECNT	EQU	(224/8)+4

; -------------------------------------------------------------------------
; RAM
; -------------------------------------------------------------------------

	rsset	$FFFF8000
frameCount	rs.w	1			; Frame count

ctrlData	rs.b	0			; Controller data
ctrlHold	rs.b	1			; Controller held buttons
ctrlTap		rs.b	1			; Controller tapped buttons

cameraX		rs.w	1			; Camera X position
cameraY		rs.w	1			; Camera Y position

prevCamX	rs.w	1			; Previous camera X position
prevCamY	rs.w	1			; Previous camera Y position

colVDPCmd	rs.l	1			; Column VDP command
colSect1Cnt	rs.w	1			; Column section 1 block count
rowVDPCmd	rs.l	1			; Row VDP command
rowSect1Cnt	rs.w	1			; Row section 1 block count

colBuffer	rs.w	COLTILECNT*2		; Column buffer
rowBuffer	rs.w	ROWTILECNT*2		; Row buffer

; -------------------------------------------------------------------------
