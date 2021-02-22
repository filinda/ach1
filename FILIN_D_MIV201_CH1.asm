.include "m8def.inc"
.def temp = r16
.def temp2 = r18
.def sys = r17
.equ FOSC = 7372800
.equ timbegin0 = 0xff - 66
.equ timbegin2 = 0xff - 130

.dseg

.cseg

.org $000
rjmp Reset

.org $004
rjmp   TIM2_OVF       	// Timer2 Overflow Handler

.org $009
rjmp   TIM0_OVF       	// Timer0 Overflow Handler


PingChar:  .db	"Ping", 0x0a, 0x0d, $00
PongChar:  .db	"Pong", 0x0a, 0x0d, $00


Reset:

//stack init
ldi temp, high(RAMEND)
out sph, temp
ldi temp, low(RAMEND)
out spl, temp
//-------------------

//timer0 setting
ldi temp, 0b00000011
out TCCR0, temp					;prescaler
ldi temp, 0b01000101
out TIMSK, temp
ldi temp, 0b00000001
out TOIE0, temp					;interupt enable
ldi temp, timbegin0
out TCNT0, temp
//-------------------

//timer2 setting
ldi temp, 0b00000100
out TCCR2, temp					;prescaler
ldi temp, 0b01000101
out TIMSK, temp
ldi temp, 0b00000001
out TOIE2, temp					;interupt enable
ldi temp, timbegin2
out TCNT2, temp
//-------------------


//uart init
.equ	baud	= 115200			; baudrate
.equ	bps	= (FOSC/16/baud) - 1; baud prescale

ldi	r16, HIGH(bps)				; load baud prescale
ldi	r17, LOW(bps)	

out	UBRRH,r16					; load baud prescale
out	UBRRL,r17					; to UBRR

ldi	temp,(1<<RXEN)|(1<<TXEN)	; enable transmitter
out	UCSRB,temp							; and receiver

ldi r16, (1<<URSEL)|(1<<USBS)|(3<<UCSZ0)
out UCSRC, r16

//-------------------

sei
Proga:
rjmp Proga



TIM0_OVF:				// Timer1 Overflow Handler
ldi r26, timbegin0
out TCNT0, r26
ldi ZH, HIGH(2*PingChar)
ldi ZL, LOW(2*PingChar)
rjmp Ping
Vix:
reti 

Ping:
	lpm	r19,Z+				; load character from pmem
	cpi	r19,$00				; check if null
	breq	Ping_end			; branch if null
	Ping_wait:				; Wait for empty transmit buffer
		sbis	UCSRA,UDRE
		rjmp Ping_wait
	out	UDR,r19				; transmit character
rjmp Ping
Ping_end:
rjmp Vix

TIM2_OVF:				// Timer2 Overflow Handler
ldi r27, timbegin2
out TCNT2, r27
ldi ZH, HIGH(2*PongChar)
ldi ZL, LOW(2*PongChar)
rjmp Pong
Vix2:
reti 

Pong:
	lpm	r20,Z+				; load character from pmem
	cpi	r20,$00				; check if null
	breq	Pong_end			; branch if null
	Pong_wait:				; Wait for empty transmit buffer
		sbis	UCSRA,UDRE
		rjmp Pong_wait
	out	UDR,r20				; transmit character
rjmp Pong
Pong_end:
rjmp Vix2

