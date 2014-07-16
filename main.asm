	org 0000h
	ajmp start
	org 0003h
	ajmp jint0
	org 000bh
	ajmp t0int
	org 0013h
	ajmp jint1
	
	org 0030h
start:
	mov sp, #60h
	setb ea
	setb ex0
	setb ex1
	setb px1
	setb it0
	setb it1
	clr psw.3
	clr psw.4	;using section zero work register
	mov a, #00h
modsele:	
	lcall rdkb
	mov r0, a
	xrl a, #0eeh
	jz modA
	mov a, r0
	xrl a, #0deh
	jz modB
	sjmp modsele

modA:
	nop
	lcall rdkb
	lcall kv2num
	lcall dispnum
	sjmp modA		;wait for interrupt

modB:
	nop
	lcall rdkb
	lcall kv2num
	lcall displed
	sjmp modB
	
jint0:
	lcall dispErrS
	setb HC595_RST
	lcall dely
	lcall dispErrS
	setb HC595_RST
	lcall dely
	lcall dispErrS
	setb HC595_RST
	reti

jint1:
	mov p0, #11111110b
	mov r6, #50
	mov r5, #80
	lcall startT0
	reti

t0int:
	dec r6
	cjne r6, #00h, pass
	mov r6, #50
	dec r5
	cjne r5, #00h, shftled
	sjmp killT0
shftled:
	mov a, p0
	rl a
	mov p0, a
pass:
	lcall startT0
	sjmp dn
killT0:
	clr tr0
dn:
	nop
	reti


startT0:
	mov tmod, #00010001b
	mov th0, #0efh
	mov tl0, #0b0h
	setb et0
	setb ea
	setb tr0
	reti
	
	
dispnum:
	nop			;display number in register on digital led
	mov dptr, #1000h
	movc a, @a+dptr
	lcall sb595
	setb p0.0
	clr p0.1
	clr p0.2
	clr p0.3
	reti
	
displed:
	nop			;display led x, x is stored in register A
	push 00h
	mov r0, a
	mov a, #11111110b
ledlp:
	rl a
	djnz r0, ledlp
	mov p0, a
	pop 00h
	reti
	
dispErrS:			;display err on digital led for about 1 second
	push 00h
	push 01h
	push 02h
	mov r0, #00fh
dspelp0:
	mov r1, #00fh
dspelp1:
	mov r2, #03h
dspelp2:
	lcall dispErr
	djnz r2, dspelp2
	djnz r1, dspelp1
	djnz r0, dspelp0
	pop 02h
	pop 01h
	pop 00h
	reti
	
dispErr:
	mov a, #10011110b
	lcall sb595
	setb p0.0
	clr p0.1
	clr p0.2
	clr p0.3
	mov a, #11101110b
	lcall sb595
	clr p0.0
	setb p0.1
	clr p0.2
	clr p0.3
	mov a, #11101110b
	lcall sb595
	clr p0.0
	clr p0.1
	setb p0.2
	clr p0.3
	mov a, #00000010b
	lcall sb595
	clr p0.0
	clr p0.1
	clr p0.2
	setb p0.3
	reti

HC595_SCK equ P0.4;
HC595_RCK equ P0.5;
HC595_RST equ P0.6;
HC595_DAT equ P0.7;
sb595:				;send byte to hc595 chip
	nop				;send a byte stored in register A
	push 00h
	clr HC595_RST
	mov r0, #08h	;send 1 byte 8 bits
sd:
	rrc a
	mov HC595_DAT, c
	clr HC595_SCK
	mov r7, #01h
	lcall dlyus
	setb HC595_SCK
	mov r7, #01h
	lcall dlyus
	djnz r0, sd
	
	clr HC595_RCK
	mov r7, #01h
	lcall dlyus
	setb HC595_RCK
	pop 00h
	reti

rdkb:				;wait for key press, and store key value in register A.
	nop
	push 00h
k00:				;line scan
	mov p2, #0fh
	mov a, p2
	anl a, #0fh
	cjne a, #0fh, k01
	ajmp k00
k01:
	lcall delys		;redo line scan to ensure key press
	mov p2, #0fh
	mov a, p2
	anl a, #0fh
	cjne a, #0fh, k02
	ajmp k00
k02:
	mov r0, a		;store line scan data
	mov p2, #0f0h	;row scan
	mov a, p2
	anl a, #0f0h
	cjne a, #0f0h, k03
	ajmp k02
k03:
	lcall delys		;delay and rescan row to ensure
	mov p2, #0f0h
	mov a, p2
	anl a, #0f0h
	cjne a, #0f0h, k04
	ajmp k02
k04:
	orl a, r0		;yield key value in register A
	pop 00h
	reti
	
kv2num:				;key value to number 00h~0ffh
	nop				;key value stores in register A, return value store in register A
	cjne a, #0eeh, k0
	ajmp v0
k0:	cjne a, #0deh, k1
	ajmp v1
k1:	cjne a, #0beh, k2
	ajmp v2
k2:	cjne a, #07eh, k3
	ajmp v3
k3:	cjne a, #0edh, k4
	ajmp v4
k4:	cjne a, #0ddh, k5
	ajmp v5
k5:	cjne a, #0bdh, k6
	ajmp v6
k6:	cjne a, #07dh, k7
	ajmp v7
k7:	cjne a, #0ebh, k8
	ajmp v8
k8:	cjne a, #0dbh, k9
	ajmp v9
k9:	cjne a, #0bbh, ka
	ajmp va
ka:	cjne a, #07bh, kb
	ajmp vb
kb:	cjne a, #0e7h, kc
	ajmp vc
kc:	cjne a, #0d7h, kd
	ajmp vd
kd:	cjne a, #0b7h, ke
	ajmp ve
ke:	cjne a, #077h, errkv ;no corresponding number for this key value 
	ajmp vf
v0: mov a, #00h
	sjmp done
v1: mov a, #01h
	sjmp done
v2: mov a, #02h
	sjmp done
v3: mov a, #03h
	sjmp done
v4: mov a, #04h
	sjmp done
v5: mov a, #05h
	sjmp done
v6: mov a, #06h
	sjmp done
v7: mov a, #07h
	sjmp done
v8: mov a, #08h
	sjmp done
v9: mov a, #09h
	sjmp done
va: mov a, #0ah
	sjmp done
vb: mov a, #0bh
	sjmp done
vc: mov a, #0ch
	sjmp done
vd: mov a, #0dh
	sjmp done
ve: mov a, #0eh
	sjmp done
vf: mov a, #0fh
	sjmp done
errkv:
	mov a, #0ffh
done:
	reti
	
	
dely:
	push 00h
	push 01h
	push 02h
	mov r0, #0ffh
dlp0:
	mov r1, #0ffh
dlp1:
	mov r2, #03h
dlp2:
	djnz r2, dlp2
	djnz r1, dlp1
	djnz r0, dlp0
	pop 02h
	pop 01h
	pop 00h
	reti

delys:
	push 00h
	push 01h	
	mov r0, #0ffh
dslp0:
	mov r1, #66h
dslp1:
	djnz r1, dslp1
	djnz r0, dslp0
	pop 01h
	pop 00h
	reti
	
dlyus:		;delay for x us, x stores in r7
dlyuslp:
	djnz r7, dlyuslp
	reti

org 1000h
db 0fch,060h,0dah,0f2h,066h,0b6h,0beh,0e0h,0feh,0f6h,11101110b,00111110b,10011100b,01111010b,10011110b,10001110b 
	
end