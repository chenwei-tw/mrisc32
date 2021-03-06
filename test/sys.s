; =============================================================================
; == System library
; =============================================================================

; -----------------------------------------------------------------------------
; exit(int exit_code)
; -----------------------------------------------------------------------------
_exit:
  ; exit routine: 0xffff0000
  ldi    s9, 0xffff0000
  j      s9


; -----------------------------------------------------------------------------
; putc(int c)
; -----------------------------------------------------------------------------
_putc:
  ; putc routine: 0xffff0004
  ldi    s9, 0xffff0000  ; Upper 19 bits = 0b1111111111111111000
  or     s9, s9, 4       ; Lower 13 bits = 0b                   0000000000100
  j      s9


; -----------------------------------------------------------------------------
; puts(char* s)
; -----------------------------------------------------------------------------
_puts:
  add    sp, sp, -12
  stw    lr, sp, 0
  stw    s16, sp, 4
  stw    s17, sp, 8

  mov    s16, s1
  ldi    s17, 0
.loop:
  ldub   s1, s16, s17
  add    s17, s17, 1
  bz     s1, .eos
  bl     _putc
  b      .loop

.eos:
  ldi    s1, 10
  bl     _putc

  ldw    lr, sp, 0
  ldw    s16, sp, 4
  ldw    s17, sp, 8
  add    sp, sp, 12
  ldi    s1, 1        ; Return a non-negative number
  j      lr


; -----------------------------------------------------------------------------
; printhex(unsigned x)
; -----------------------------------------------------------------------------
_printhex:
  add    sp, sp, -16
  stw    lr, sp, 0
  stw    s16, sp, 4
  stw    s17, sp, 8
  stw    s18, sp, 12

  lea    s16, .hex_chars
  mov    s17, s1
  ldi    s18, 7
.loop:
  lsl    s9, s18, 2   ; s9 = s18 * 4
  lsr    s9, s17, s9  ; s9 = x >> (s18 * 4)
  and    s9, s9, 15   ; s9 = (x >> (s18 * 4)) & 15
  ldb    s1, s16, s9  ; s1 = hex_chars[(x >> (s18 * 4)) & 15]
  add    s18, s18, -1
  bl     _putc
  bge    s18, .loop

  ldw    lr, sp, 0
  ldw    s16, sp, 4
  ldw    s17, sp, 8
  ldw    s18, sp, 12
  add    sp, sp, 16
  j      lr

.hex_chars:
  .ascii "0123456789abcdef"


; -----------------------------------------------------------------------------
; unsigned mul32(unsigned a, unsigned b)
; -----------------------------------------------------------------------------
_mul32:
  ; TODO(m): This is broken!
  and    s4, s2, 1
  ldi    s3, 0
.loop:
  bz     s4, .no_add
  add    s3, s3, s1
.no_add:
  lsr    s2, s2, 1
  and    s4, s2, 1
  bnz    s2, .loop

  or     s1, s3, z    ; s1 = result
  j      lr


; -----------------------------------------------------------------------------
; [s1: unsigned Q, s2: unsigned R] = divu32(s1: unsigned N, s2: unsigned D)
;   Compute N / D and N % D
;
; Reference:
;   https://en.wikipedia.org/wiki/Division_algorithm
; -----------------------------------------------------------------------------
_divu32:
  ldi    s9, 0          ; s9 = Q (quotient)
  ldi    s10, 0         ; s10 = R (remainder)

  ldi    s11, 31        ; s11 = i (bit counter)
.loop:
  lsl    s9, s9, 1      ; Q = Q << 1
  lsl    s10, s10, 1    ; R = R << 1

  lsr    s12, s1, 31
  lsl    s1, s1, 1      ; N = N << 1
  or     s10, s10, s12  ; R(0) = N(31)

  sleu   s12, s2, s10   ; D <= R?
  add    s11, s11, -1   ; --i
  bns    s12, .no_op
  sub    s10, s10, s2   ; R = R - D
  or     s9, s9, 1      ; Q(0) = 1
.no_op:

  bge    s11, .loop

  or     s1, s9, z      ; s1 = Q
  or     s2, s10, z     ; s2 = R
  j      lr

