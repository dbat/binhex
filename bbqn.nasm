;PAGE 255, 255
;
; Copyright 2003-2007,
; Adrian H, Ray AF and Raisa NF of PT Softindo, Jakarta
; email: aa _at_ softindo.net
; All right reserved
;
; Version: 0.0.027
; Created: 2003.01.01
; Updated: 2008.02.07
;
; Changelog:
;
; ---------
; Synopsys:
;   Conversion library hex2bin and bin2hex, base64encode/decode
;
;   For all function, source and destination buffer can reside
;   on the same address (overwriting itself), this very useful
;   to conserve memory (such as on embedded system).
;
;   Please read on the respective procedures to see what they do
;
;
;.386
;.model flat, stdcall
;option casemap: none
;
;LOCALS @@
;
;segment FLAT use32; //.data
segment _TEXT use32; //.data
align 16
; *************************************************************************
  id resd 10h
;segment ends

;segment _DATA use32; //.data
  hexLo db "0123456789abcdef"
  hexUp db "0123456789ABCDEF"

  base2tab db "00","01","02","03"
     db "10","11","12","13"
     db "20","21","22","23"
     db "30","31","32","33"

  base4tab db "0000","0001","0010","0011"
     db "0100","0101","0110","0111"
     db "1000","1001","1010","1011"
     db "1100","1101","1110","1111"

  bincheck times 30h db 0; //resb 30h; //db 30h dup(0)
    db 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0
    db 0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0
    times 90h db 0; //resb 90h; //db 90h dup(0) ; a necessary bloat to avoid cmp

align 16
  dq06 times 10h db 06h; // db 10h dup(06h)
  dq07 times 10h db 07h; // db 10h dup(07h)
  dq09 times 10h db 09h; // db 10h dup(09h)
  dq0a times 10h db 0ah; // db 10h dup(0ah)
  dq20 times 10h db 20h; // db 10h dup(20h)
  dq30 times 10h db 30h; // db 10h dup(30h)
  dq_bmask times 8h dw 0ffh; // dw 8h dup(00ffh)
  dq_fmask times 10h db 0fh; // db 10h dup(0fh)

;segment end
;segment CODE use32; //.code
; *************************************************************************
align 4
global __bin2hex
__bin2hex:; //proc source:DWORD, dest:DWORD, count:DWORD, uppercase: BYTE
push ebp
mov ebp,esp
; translate data to its hexadecimal representation
; dest must have enough capacity twice of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    mov ecx, [ebp+10h]; //count
    movzx ebx, byte [ebp+14h]; //uppercase
    lea esi, [esi+ecx-1]                  ; end of source (tail)
    lea edi, [edi+ecx*2-2]                ; end of dest (tail)

    test ebx,ebx              ; uppercase?
    setne bl                  ; if yes
    shl ebx, 4                ; shift lookup to the next paragraph
    ;movzx ebx,bl              ; just in case

    xor eax,eax
    lea ebx, [ebx + hexLo]

  @@Loop:
    sub ecx, 1                          ; at the end of data?
    jl @@Done                            ; out

  @@Begin:
    movzx edx, byte [esi]           ; get byte
    mov al, byte [esi]              ; get byte copy
    shr dl, 4                           ; get hi nibble -> become lo byte / swapped
    and al, 0fh                         ; get lo nibble -> become hi byte / swapped
    mov dl, byte [ebx+edx]
    mov dh, byte [ebx+eax]
    sub esi, 1
    mov [edi], dx                       ; put translated str
    sub edi, 2
    jmp @@Loop                           ;

  @@Done:
    pop edi
    pop esi
    pop ebx
pop ebp
ret 10h
;endp;//__bin2hex endp

; *************************************************************************
align 4
global __hex2bin
__hex2bin:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
; store hexadecimal string to binary, valid char '0'..'9','a'..'f'
; 2 chars become 1 byte. invalid characters simply interpreted as '0'
; count should be an even number, the last odd/orphaned char will
; be stored as high nibble in the last byte. you get it don't you?
; source and dest can be the same but should not overlap
; (if overlapped, SOURCE must be equal or in higher address than dest)

    push ebx
    push esi
    push edi

    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    mov ecx, [ebp+10h]; //count

    mov ebx, bincheck;//lea ebx, [bincheck]

    xor eax,eax
    xor edx,edx

    push ecx
    shr ecx,1
    jz @@done

  @@Loope:
    mov dl, byte [esi]
    mov al, byte [esi+1]
    mov dl, byte [ebx+edx]
    mov al, byte [ebx+eax]
    shl edx, 4
    add esi, 2
    add edx, eax
    mov byte [edi], dl
    add edi, 1
    sub ecx,1
    jg @@Loope

  @@done:
    pop ecx 
    and ecx,1
    jz @@done2
    mov dl, byte [esi]
    mov dl, byte [ebx+edx]
    shl edx, 4
    mov byte [edi], dl

  @@done2:
    pop edi
    pop esi
    pop ebx
pop ebp
ret 12
;endp;//__hex2bin endp

; *************************************************************************
align 4
global __bin2base2
__bin2base2:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
; translate data to its binary digit representation
; dest must have enough capacity 8 x of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    mov ecx, [ebp+10h]; //count
    mov ebx, base2tab;//lea ebx, [base2tab]
    lea esi, [esi+ecx-1]                  ; end of source (tail)
    lea edi, [edi+ecx*8-8]                ; end of dest (tail)

  @@Loop:
    sub ecx, 1                          ; at the end of data?
    jl @@Done                            ; out

  @@Begin:
    movzx edx, byte [esi]           ; get byte
    movzx eax, byte [esi]           ; get byte copy
    shr dl, 4                           ; get hi nibble
    and al, 0fh                         ; get lo nibble
    mov edx, [ebx*4+edx]
    mov eax, [ebx*4+eax]
    sub esi, 1
    mov [edi], edx                       ; put translated str
    mov [edi+4], eax                       ; put translated str
    sub edi, 8
    jmp @@Loop                           ;

  @@Done:
    pop edi
    pop esi
    pop ebx
pop ebp
ret 12
;endp;//__bin2base2 endp

; *************************************************************************
align 4
global __bin2base4
__bin2base4:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
; translate data to its binary digit representation
; no checking, dest must have enough capacity 4 x of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    mov ecx, [ebp+10h]; //count
    mov ebx, base4tab;//lea ebx, [base4tab]
    lea esi, [esi+ecx-1]                  ; end of source (tail)
    lea edi, [edi+ecx*4-4]                ; end of dest (tail)

  @@Loop:
    sub ecx, 1                          ; at the end of data?
    jl @@Done                            ; out

  @@Begin:
    movzx edx, byte [esi]           ; get byte
    movzx eax, byte [esi]           ; get byte copy
    shr dl, 4                           ; get hi nibble
    and al, 0fh                         ; get lo nibble
    mov dx, word [ebx*2+edx]
    mov ax, word [ebx*2+eax]
    sub esi, 1
    mov [edi], dx                       ; put translated str
    mov [edi+2], ax                     ; put translated str
    sub edi, 4
    jmp @@Loop                           ;

  @@Done:
    pop edi
    pop esi
    pop ebx
pop ebp
ret 12
;endp;//__bin2base4 endp
;segment end
;segment DATA use32; //.data
align 4
; *************************************************************************
  base64encode_table db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
     ; with a necessary bloat to allow hi 2 bits resulted in the same char
     ; If you want to be even faster, use these ugly catch-all,
     ;db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
     ;db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
     ;db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    ;
    ;	"A" 0x41 = 0	"Q" 9x51 = 16	"g" 0x67 = 32	"w" 0x77 = 48
    ;	"B" 0x42 = 1	"R" 9x52 = 17	"h" 0x68 = 33	"x" 0x78 = 49
    ;	"C" 0x43 = 2	"S" 9x53 = 18	"i" 0x69 = 34	"y" 0x79 = 50
    ;	"D" 0x44 = 3	"T" 9x54 = 19	"j" 0x6a = 35	"z" 0x7a = 51
    ;	"E" 0x45 = 4	"U" 9x55 = 20	"k" 0x6b = 36	"0" 0x30 = 52
    ;	"F" 0x46 = 5	"V" 9x56 = 21	"l" 0x6c = 37	"1" 0x31 = 53
    ;	"G" 0x47 = 6	"W" 9x57 = 22	"m" 0x6d = 38	"2" 0x32 = 54
    ;	"H" 0x48 = 7	"X" 9x58 = 23	"n" 0x6e = 39	"3" 0x33 = 55
    ;	"I" 0x49 = 8	"Y" 9x59 = 24	"o" 0x6f = 40	"4" 0x34 = 56
    ;	"J" 0x4a = 9	"Z" 9x5a = 25	"p" 0x70 = 41	"5" 0x35 = 57
    ;	"K" 0x4b = 10	"a" 9x61 = 26	"q" 0x71 = 42	"6" 0x36 = 58
    ;	"L" 0x4c = 11	"b" 9x62 = 27	"r" 0x72 = 43	"7" 0x37 = 59
    ;	"M" 0x4d = 12	"c" 9x63 = 28	"s" 0x73 = 44	"8" 0x38 = 60
    ;	"N" 0x4e = 13	"d" 9x64 = 29	"t" 0x74 = 45	"9" 0x39 = 61
    ;	"O" 0x4f = 14	"e" 9x65 = 30	"u" 0x75 = 46	"+" 0x2b = 62
    ;	"P" 0x50 = 15	"f" 9x66 = 31	"v" 0x76 = 47	"/" 0x2f = 63
    ;
    ;   note that the blocks are:
    ;     0x2b, 0x2f	"+" and "/"	= [61, 62]
    ;     0x30 - 0x39	"0" - "9"	= [52..61]
    ;     0x41 - 0x5a	"A" - "Z"	= [0..25]
    ;         0x41 - 0x4f  "A" - "O"	=    [0..14]
    ;         0x50 - 0x5a  "P" - "Z"	=    [15..25]
    ;     0x61 - 0x7a	"a" - "z"	= [26..51]
    ;         0x61 - 0x6f  "a" - "o"	=    [16..40]
    ;         0x50 - 0x5a  "p" - "z"	=    [41..51]

;  base64decode_table db 2bh dup(0)
;    db 62,00,00,00,63					; 0x2b-0x2f
;    db 52,53,54,55,56,57,58,59,60,61,00,00,00,00,00,00	; 0x30-0x3f
;    db 00,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14	; 0x40-0x4f
;    db 15,16,17,18,19,20,21,22,23,24,25,00,00,00,00,00	; 0x50-0x5f
;    db 00,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40	; 0x60-0x6f
;    db 41,42,43,44,45,46,47,48,49,50,51,00,00,00,00,00	; 0x70-0x7f
;    db 80h dup(0) ; a necessary bloat to avoid cmp

  base64cmp_table times 2bh db 0; //db 2bh dup(0)
  ; the only difference is that index:"A" has value=64 not 0
  ; consequently the value must be cleaned after taken by: AND 63.
    db 62,00,00,00,63					; 0x2b-0x2f
    db 52,53,54,55,56,57,58,59,60,61,00,00,00,00,00,00	; 0x30-0x3f
    db 00,64,01,02,03,04,05,06,07,08,09,10,11,12,13,14	; 0x40-0x4f
    db 15,16,17,18,19,20,21,22,23,24,25,00,00,00,00,00	; 0x50-0x5f
    db 00,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40	; 0x60-0x6f
    db 41,42,43,44,45,46,47,48,49,50,51,00,00,00,00,00	; 0x70-0x7f
    times 80h db 0; //db 80h dup(0) ; a necessary bloat to avoid cmp
;segment end
;segment CODE use32; //.code
; *************************************************************************
align 4
global __base64encode
 __base64encode:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
; translate data to its base64 digit representation RFC3548
; returns EAX: bytes encoded = (count + 2) / 3 * 4, always divisible by 4
;
; This function using backward direction scan
;
; count MUST be divisible by 3 for incomplete translation/conversion
; (ie. not a complete source, more data expected to come)
;
; no check, dest must have enough capacity 4/3 x of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)

    mov ecx, [ebp+10h]; //count
    test ecx,ecx
    jz @@ZeroCount
    jmp @@Start
    @@ZeroCount:
    xor eax,eax
    ret

  @@Start:
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    mov eax, ecx
    mov ecx, 3

    xor edx, edx
    div ecx

    ; calculate result count
    ; xor ecx,ecx
    test edx,edx
    setnz cl
    add ecx,eax
    shl ecx,2                           ; dest count = 4 x eax
    push ecx				; put result in stack

    mov ebx, base64encode_table;//lea ebx, [base64encode_table]
    lea esi, [esi+eax*2-3]		; end of source (tail)
    lea edi, [edi+eax*4-4]		; end of dest (tail)
    add esi,eax				; src count = 3 x eax

    push ebp ; using ebp, any disturbance will throw a very nasty error!
    mov ebp, eax
    xor eax,eax
    test edx,edx
    jz @@Loop;				; rem:0 => divisible by 3

  @@Fixtail:
    ; caution ----------------------------------------------------------
    ; watch out for referenced mem. when source and dest are equal!
    ; do not write to the block mem before calculation is really done
    ;-------------------------------------------------------------------
    movzx eax, byte [esi+3]
    shr al, 2
    mov ecx,"===="

    mov cl, byte [ebx+eax]
    mov al, byte [esi+3]			; refetch

    and al, 3		; only 2 bits needed
    shl al, 4		; (hi portion of ch#2)

    cmp dl,1
    mov dl, byte [esi+3+1]
    mov ch, byte [ebx+eax]
    ; caution ----------------------------------------------------------
    ;-- mov ch, byte esi+3+1]	; if src/dest equal, these two lines -
    ;-- mov [edi+4+1], cl		;  might refer to the same address
    ;-------------------------------------------------------------------
    mov dh, dl				; copy
    mov [edi+4], ecx                    ; write, at last
    jz @@Loop;				; done for rem:1

  @@Fixtail2:
    ;mov [edi+4+2], dx                    ; write, at last

    and dh, 15	; only 4 bits needed for hi part of Ch#3
    shr dl, 4	; lo part of Ch#2
    shl dh, 2	; hi part of Ch#3
    or al, dl	; al had hi part of Ch#2
    movzx edx, dh
    mov al, byte [ebx+eax]
    mov dl, byte [ebx+edx]

    mov [edi+4+1], al			; write 1 byte = 2 b64
    mov [edi+4+2], dl			; write 1 byte = 2 b64
    jmp @@Loop

  @@Loop:
    sub ebp,1                      ; at the end of data?
    jl @@Done                       ; out

  @@Begin1: ; 3 bytes round ; OK but weird
    ; fetch wth big-endian scheme, but must be stored as little-endian
    ;= mov edx,[esi]		; might get stalled -unaligned4
    ;= bswap edx		; edx: big endian string (3bytes)
    ;= shr edx,8		; 00:[esi]:[esi+1]:[esi+2]
    mov dh, byte [esi]
    mov dl, byte [esi+1]
    movzx eax, byte [esi+2]		; get 3rd-byte
    shl edx,8
    mov dl,al
    and al,63
    shr edx,6                           ; arithmatic ops use big-endian value
    mov ch, byte [ebx+eax]          ; storing use little-endian scheme
    mov al,dl				; fetch
    and al,63
    shr edx,6
    mov cl, byte [ebx+eax]
    mov al,dl				; fetch 3rd b64
    shr edx,6
    and al,63
    and dl,63
    mov ah, byte [ebx+eax]
    mov al, byte [ebx+edx]
    sub esi,3
    mov [edi], ax
    mov [edi+2], cx
    sub edi,4
    jmp @@Loop                           ;

  @@Done:
    pop ebp
    pop eax		; result count should be divisible by 4
    pop edi
    pop esi
    pop ebx
pop ebp
ret 12
;endp;//__base64encode endp

; *************************************************************************
align 4
;global __base64decode_STRICT
__base64decode_STRICT:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
; Translate base64 data to binary,
; ANY invalid characters Base64, will be translated as "A" or 0
;
; returns EAX: bytes decoded = (count / 4 * 3) (+0/+1/+2 bytes)
; returned size might be +1 or +2 bytes, depends on circumtances
;
; This function using forward direction scan of source and dest
;
; The only valid padding is "=" or "==" at the very last 4 chars block,
; otherwise it will be silently translated as 0 (equal with "A" in base64)
; for instance, "====" decoded as  "AA==", "==A=" decoded as "AAA=",
; "===9" will be decoded as "AAA9" since all of "=" are malformed.
;
; If count is not divisible by 4, then char "=" is assumed as padding,
; ;- no literal padding allowed anymore, any other occurences of "="
; ;- will be silently translated as 0 ("A")
;
; Any invalid/unknown base64 characters will be simply translated as 0 as well
;
; Normally, padding only affect result size: -0, -1 or -2, unless on
; malformed input base64, i.e.: count is not divisible by 4, AND source
; has additional (trailing) data which can be unintentionally processed
; (because decoding is always performed in 4 bytes block) - fixed. no extra data read anymore
;
; count SHOULD be divisible by 4 for incomplete translation/conversion
; (ie. not a complete source, more data expected to come).
;
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
;
; dest must have enough space for 1 or 2 bytes extra padding translation as 0
; ie. dest size must be: (count + 3) / 4 * 3
    mov ecx,[ebp+10h] ;//[count]
    test ecx,ecx
    jz @@ZeroCount
    jmp @@Start

    @@ZeroCount:
    xor eax,eax
    ret

 @@Start:
    push ebx
    push esi
    push edi

    mov esi, [ebp+8]; //source
    mov eax, ecx
    mov edi, [ebp+12]; //dest

    shr eax,2			; div 4
    mov ebx, base64cmp_table;//lea ebx, [base64cmp_table]
    lea eax, [eax*2 + eax]	; count / 4 * 3
    push eax

    movzx eax, word [esi+ecx-2]
    push eax		; last 2 bytes (could be overwritten if source=dest and count < 9)
                    ; only used for checking if count is divisible by 4

  @@Loop:
    sub ecx,4
    jb @@LastCheck

    movzx edx, byte [esi]
    movzx eax, byte [esi+1]
    ;- and dl, 7fh
    ;- and al, 7fh
    mov dl, byte [ebx+edx]
    mov al, byte [ebx+eax]
    and dl,63
    and al,63
    shl edx, 6
    or edx, eax
    mov al, byte [esi+2]
    ;- and al, 7fh
    shl edx, 6
    mov al, byte [ebx+eax]
    and al,63
    or edx, eax
    mov al, byte [esi+3]
    shl edx, 6
    mov al, byte [ebx+eax]
    and al,63
    add esi, 4
    or eax, edx
    shr edx, 16
    mov byte [edi], dl
    mov byte [edi+1], ah
    mov byte [edi+2], al
    add edi,3

    jmp @@Loop

  @@LastCheck:
    pop edx		;// 2 chars at the end
    add ecx,4
    jnz @@LastCheckMod;// size is not divisible by 4

  @@LastCheckZero:
    mov eax,[esp]
    cmp dl, "="
    jz @@dec2
    cmp dh, "="
    jz @@dec1
    jmp @@Done
    @@dec2: dec eax
    @@dec1: dec eax
    mov [esp], eax
    @@dec0: jmp @@Done

  @@LastCheckMod:
    ;// size is not divisible by 4
    ;// 1 byte source => 1 byte dest
    ;// 2 byte source => 2 byte dest
    ;// 3 byte source => 2 byte dest
    inc dword [esp]
    movzx eax, byte [esi]
    movzx edx, byte [esi+1]
    ;// and al,7fh
    ;// and dl,7fh
    mov al, byte [ebx+eax]
    mov dl, byte [ebx+edx]
    and al,63
    and dl,63
    shl eax,2
    mov byte [edi], al
    shl eax,4
    dec ecx
    jz @@Done
    or eax,edx
    inc dword [esp]
    shl eax,4
    mov dl, byte [esi+2]
    mov byte [edi], ah
    mov byte [edi+1], al
    ;- and dl,7fh
    dec ecx
    jz @@Done
    mov dl, byte [ebx+edx]
    and dl,63
    shr edx,2
    or eax,edx
    mov byte [edi+1], al
    jmp @@Done

  @@Done:
    pop eax
    pop edi
    pop esi
    pop ebx
pop ebp
ret 12
;endp;//__base64decode_STRICT endp

; *************************************************************************
align 4
global __base64decode
__base64decode:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
; Translate base64 data to binary, silently discard any invalid chars.
; returns EAX: bytes decoded to original binary

 @@Start:
    push ebx
    push esi
    push edi

    mov ecx, [ebp+10h]; //count
    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    push edi		; store original source addr
    mov ebx, base64cmp_table;//lea ebx, [base64cmp_table]

    add ecx, esi
    xor eax, eax

    push ebp
    push 4
    pop ebp

  @@Loop:
    cmp esi, ecx
    jae @@Checkout
    mov al, [esi]
    add esi, 1
    ;- test byte [ebx+eax], -1
    mov al, byte [ebx+eax]
    test al, al
    jz @@Loop
    and al, 63
    shl edx, 6
    or dl, al

    dec ebp
    jnz @@Loop

    mov al, dl
    shr edx, 8
    mov ebp, 4
    mov [edi], dh
    mov [edi+1], dl
    mov [edi+2], al
    add edi, 3
    xor edx,edx
    jmp @@Loop

  @@Checkout:
    mov eax,ebp			; steps to go on 4 bytes block cycle = 4 - (size mod 3)
    test ebp, 3 		;
    pop ebp
    lea ecx,[eax*2+eax] 	; ecx = (eax) * 3
    jz @@Done
    ;- 1 byte src -> invalid
    ;- 2 bytes src -> 1 bytes dst
    ;- 3 bytes src -> 2 bytes dst
    shl ecx,1			; ecx = (eax) * 6
    shl edx,cl			; shl edx (eax*6)
    ;-- mov cl,al
    ;-- mov al,dl
    shr edx,8
    mov [edi], dh
    inc edi
    cmp al, 1 			; check bytes short in 4 bytes cycle.
    ja @@Done                   ; done for less than 3 => 3 = (4-1)
    mov [edi], dl               ; 3 bytes to process
    inc edi

  @@Done:
    ;- already done in @@Checkout: pop ebp
    mov eax, edi
    pop edx
    pop edi
    pop esi
    pop ebx
    sub eax, edx
pop ebp
ret 12
;endp;//__base64decode endp

; *************************************************************************
align 4
global __trimCRLF
__trimCRLF:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
    mov ecx, [ebp+10h]; //count

  @@Start:
    push ebx
    push esi
    push edi
    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest

    add ecx, esi

    push edi

  @@Loop:
    cmp esi,ecx
    jae @@Done

    mov al, [esi]
    add esi, 1

    cmp al, 0ah
    jz @@next
    cmp al, 0dh
    jz @@next

    mov [edi], al
    add edi, 1

  @@next: jmp @@Loop

  @@Done:
    mov eax, edi
    pop ecx
    pop edi
    pop esi
    pop ebx
    sub eax,ecx
pop ebp
ret 12
;endp;//__trimCRLF endp

; *************************************************************************
align 4
global __trimCharTable
__trimCharTable:; //proc source:DWORD, dest:DWORD, count:DWORD, CharTable: DWORD
; strip characters that are translated to 0 in char table
; returns EAX: new size
;
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
;
    mov ecx, [ebp+10h]; //count

  @@Start:
    push ebx
    push esi
    push edi
    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest
    mov ebx, [ebp+14h]; //CharTable
    add ecx, esi
    push edi	; original dest address
    xor eax,eax

  @@Loop:
    cmp esi,ecx
    jae @@Checkout

    mov al, [esi]
    add esi, 1
    test byte [ebx+eax], -1
    jz @@next

    mov [edi], al
    add edi, 1

  @@next: jmp @@Loop

  @@Checkout:

  @@Done:
    pop eax
    pop edi
    pop esi
    pop ebx
pop ebp
ret 10h
;endp;//__trimCharTable endp

; *************************************************************************
align 4
global __putDelimiter2
__putDelimiter2:; //proc source:DWORD, dest:DWORD, count:DWORD, blockSize: DWORD, delimiter: WORD
push ebp
mov ebp,esp
; put delimiter (max 2 chars) for every block size,
; if the second char is null, then only the first char is used as delimiter
; returns EAX: new size
;
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)

  @@Start:
    push ebx
    push esi
    push edi
    mov esi, [ebp+8]; //source
    mov edi, [ebp+12]; //dest

    mov eax, [ebp+10h]; //count
    push eax		; original count

    mov ebx, [ebp+14h]; //blockSize

    test eax,eax
    jz @@Done

    and ebx,-2
    jz @@simplecopy

    lea esi, [esi+eax-1]

    mov ecx,eax		; save esi original count
    ;dec eax		; dec:1 to get floor value from div

    xor edx,edx
    div ebx
    mov ebx,ecx		; save esi original count, again?

    ;- lea ecx, [ecx+eax*2]; result/quotient * 2 bytes delimiters
    ;- add ecx,eax
    add ecx,eax		; result/quotient * 1 byte delimiters' count
    test byte [ebp+18h+1], -1
    jz @@setDestEnd
    add ecx,eax		; result/quotient * additional 1 byte delimiters' count

    @@setDestEnd: lea edi, [edi+ecx-1]

    ;push ecx		; end-result size/count
    mov [esp], ecx
    mov ecx,edx		; remainder
    std
    rep movsb

    sub ebx,edx		; dec. esi count by remainder
    ;jbe @@Done		; never will happen

    mov ecx, [ebp+14h]; //blockSize
    movzx edx, [word ebp+18h]; //delimiter (WORD)

    test dh, -1
    jz @@Loop1
    jmp @@Loop2

  @@Loop2:
    sub ebx, ecx
    jb @@Done
    mov [edi-1],dx
    sub edi,2
    rep movsb
    mov ecx, [ebp+14h]; //blockSize
    jmp @@Loop2

  @@Loop1:
    sub ebx, ecx
    jb @@Done
    mov [edi],dl
    sub edi,1
    rep movsb
    mov ecx, [ebp+14h]; //blockSize
    jmp @@Loop1

  @@Loop4:
    sub ebx, ecx
    jb @@Done
    mov [edi-3],edx
    sub edi,4
    rep movsb
    mov ecx, [ebp+14h]; //blockSize
    jmp @@Loop4

    @@simplecopy:
    cmp esi, edi
    jz @@Done
    mov ecx,eax
    shr ecx,2
    cld
    rep movsd
    mov ecx,eax
    and ecx,3
    rep movsb
    ;//jmp @@Done

  @@Done:
    cld		; crap! this shit must be cleared afterwise
		; someone takes for granted that this is already clear
    pop eax
    pop edi
    pop esi
    pop ebx
pop ebp
ret 14h
;endp;//__putDelimiter2 endp

; *************************************************************************
align 4
global __base64trim
__base64trim:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
    push base64cmp_table
    push [dword ebp+10h]; //count
    push [dword ebp+12]; //dest
    push [dword ebp+8]; //source
    ;- mov byte [base64decode_table+"A"], 64	; temporary make it true
    ;- mov byte [base64decode_table+"="], 128	; temporary make it true
    call __trimCharTable
    mov ecx,eax
    and ecx,3
    jz @@done
    sub ecx, 4
    push edi
    neg ecx
    add edi, eax
    push eax
    mov al, "="
    rep stosb
    pop eax
    pop edi
    ;- mov byte [base64decode_table+"A"], 0	; turn back original value
    ;- mov byte [base64decode_table+"="], 0	; temporary make it true
  @@done: ;//ret
pop ebp
ret 12
;endp;//__base64trim endp

; *************************************************************************
align 4
global __base64delim
__base64delim:; //proc source:DWORD, dest:DWORD, count:DWORD
push ebp
mov ebp,esp
    push 0a0dh
    push 64
    push dword [ebp+10h]; //count
    push dword [ebp+12]; //dest
    push dword [ebp+8]; //source
    call __putDelimiter2
pop ebp
ret 12
;endp;//__base64delim endp

; *************************************************************************
align 16
global __bin2hex_sse2
__bin2hex_sse2:;// proc source:DWORD, dest:DWORD, count:DWORD, upperCase: BYTE
push ebp
mov ebp,esp
;//procedure bin2hex_SSE(const source: pchar; var dest; const count: integer; const upperCase: boolean); stdcall;
; translate data to its hexadecimal representation
; dest must have enough capacity twice of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
  mov eax,[ebp+8]; //[source];
  mov edx,[ebp+12]; //[dest];
  mov ecx,[ebp+16]; //[count];

    test eax,eax;
    cmovz edx,eax
    test edx,edx;
    jz @@Stop

;//  jmp @@Start
;//
;//align 4
;//  @@hexLo db '0123456789abcdef';
;//  @@hexUp db '0123456789ABCDEF';

  @@Start:
    push esi;
    lea esi,[eax+ecx];
    push edi;
    lea edi,[edx+ecx*2];

  cmp byte [ebp+14h],1; //[upperCase],1;
  push ebx
  sbb ebx,ebx;  // zero if boolean-case > 0; allbitset if boolean-case = 0

  test dl,1
  jnz @@old_bin2hex
  cmp ecx,32;
  jl @@old_bin2hex

  movd xmm2,ebx;         ;// true = 0, false = -`
  movdqu xmm0,oword [dq20]
  punpcklbw xmm2,xmm2;
  punpcklbw xmm2,xmm2;

  movdqu xmm7,oword [dq_fmask] ;//movdqu xmm7,dq_fmask
  movdqu xmm3,oword [dq30] ;//movdqu xmm4,dq30
  movdqu xmm4,oword [dq07] ;//movdqu xmm4,dq07
  movdqu xmm5,oword [dq0a] ;//movdqu xmm4,dq0a
  pand xmm2,xmm0            ;//lowercase mask (inverted)

  test edi,15;
  jz @@tail_done
  @@tail_SSE:
    ;// debug only (movq triggers internal error in delphi7)
    ;// movdqu xmm0,[esi-8]     ;//
    ;// movdqu xmm1,[esi-8]     ;//
    ;//use these 2 instructions instead on release
    movq xmm0,[esi-8]     ;//internal error
    movq xmm1,[esi-8]     ;// copy
    psrlq xmm0,4          ;// shr logical 4; get hi nibble
    punpcklbw xmm0,xmm1   ;// unpack 1-nibble in every byte

    movdqa xmm1,xmm5      ;// 9s
    pand xmm0,xmm7        ;//apply bitmask for niblles

    pcmpgtb xmm1,xmm0     ;//create mask for N <= 9
    pandn xmm1,xmm4       ;//invert mask, build 8s (to be added) for N > 9

    paddusb xmm0,xmm3     ;//add 30s
    paddusb xmm0,xmm1     ;//add 8s for N > 9

    por xmm0,xmm2         ;//apply lowercase
    movdqu [edi-16],xmm0    ;//movdqu [edi-16],xmm0

    mov edx,edi
    and edx,15;
    sub edi,edx

    shr edx,1
    sub ecx,edx;
    sub esi,edx;

  @@tail_done:
    push ecx;
    shr ecx,3;
    jz @@doneSSE2

    @@Loop_SSE2:
      sub ecx,1;
      jl @@doneSSE2

      sub esi,8
      sub edi,16

      ;// debug only (movq triggers internal error in delphi7)
      ;// movdqu xmm0,[esi]     ;//
      ;// movdqu xmm1,[esi]     ;//
      ;//use these 2 instructions instead on release
      movq xmm0,[esi]     ;// internal error. skipit
      movq xmm1,[esi]     ;// copy

      psrlq xmm0,4        ;// shr logical 4; get hi nibble
      punpcklbw xmm0,xmm1 ;// unpack 1-nibble in every byte

      movdqa xmm1,xmm5    ;// 9s
      pand xmm0,xmm7      ;//apply bitmask for niblles

      pcmpgtb xmm1,xmm0   ;//create mask for N <= 9
      pandn xmm1,xmm4     ;//invert mask, build 8s (to be added) for N > 9

      paddusb xmm0,xmm3   ;//add 30s
      paddusb xmm0,xmm1   ;//add 8s for N > 9

      por xmm0,xmm2       ;//apply lowercase
      movdqa [edi],xmm0   ;//movdqu [edi-16],xxmm0

    jmp @@Loop_SSE2

  @@doneSSE2:
    ;//emms
    pop ecx;
    and ecx,7;
    jz @@Done

  @@old_bin2hex:
    sub esi,1
    sub edi,2
    shl ebx,4
    xor edx,edx
    lea ebx,[hexUp+ebx];

  @@Loop_small:
    movzx eax,byte [esi];
    sub esi,1;
    mov dl,al;
    shr al,4;   ;// low nibble
    and dl,0fh;

    mov al,[ebx+eax]
    mov ah,[ebx+edx]
    mov [edi],ax
    sub edi,2;

    sub ecx,1;
    jg @@Loop_small

  @@Done:
    pop ebx;
    pop edi;
    pop esi;
  @@Stop:
  ;//ret
pop ebp
ret 10h
;//__bin2hex_sse2 endp

; -------------------------------------------------------------------------
align 16
global __hex2bin_sse2
__hex2bin_sse2:;// proc source: dword, dest: dword, count: dword
push ebp
mov ebp,esp
;//procedure hex2bin_sse2(const source: pchar; var dest; const count: integer);
;//// dest should be aligned 8
; store hexadecimal string to binary, valid char '0'..'9','a'..'f'
; 2 chars become 1 byte. invalid characters simply interpreted as '0'
; count should be an even number, the last odd/orphaned char will
; be stored as high nibble in the last byte. you get it don't you?
; source and dest can be the same but should not overlap
; (if overlapped, SOURCE must be equal or in higher address than dest)

  mov ecx,[ebp+16]; //[count];
  mov edx,[ebp+12]; //[dest];
  mov eax,[ebp+8]; //[source];
  test ecx, ecx
  jle @@Stop
  test eax, eax
  jz @@Stop
  test edx, edx
  jz @@Stop

  @@begin:
  ;// older jwasm recognized both dqword and oword. uasm (newer) only know oword
  movdqu xmm2,oword [dq20];
  ;//movdqu xmm3,dq30;
  movdqu xmm4,oword [dq09]
  movdqu xmm6,oword [dq06]
  movdqu xmm7,oword [dq_bmask];

  @@Loop:
    movdqu xmm1,[eax];
    movdqu xmm3,oword [dq30];

    psubusb xmm1,xmm3     ;// N = N - 30h
    pxor xmm0,xmm0        ;// clear reg1
    pcmpgtb xmm0,xmm1     ;// 0 > N? (get bitmask)
    pandn xmm0,xmm1       ;// apply bitmask (strip negative values)
    ;//movdqa xmm1,xmm0      ;// copy value
    movdqa xmm1,xmm0      ;// save first to another reg
    pcmpgtb xmm0,xmm4     ;// is n > 9

    pandn xmm0,xmm1       ;// apply mask, clear N >= 10
    por xmm1,xmm2         ;// N = N or 20h (convert to lowercase)
    psubusb xmm1,xmm3     ;// N = N - 30h (ceil down)
    pxor xmm5,xmm5        ;// clear reg5
    movdqa xmm3,xmm1      ;// copy xmm1

    pcmpeqb xmm5,xmm1     ;// is N = 0? (to be not-anded)
    pcmpgtb xmm3,xmm6     ;// is N > 6? (to be not-anded)

    ;//paddb xmm1,dq09       ;// N = N + 9 //[internal error]
    paddusb xmm1,xmm4     ;// N = N + 9
    por xmm5,xmm3         ;// combine (N = 0) or (N > 6)
    pandn xmm5,xmm1       ;// apply mask, (N<>0) and (N<=6)
    por xmm0,xmm5         ;// combine result
    movdqa xmm1,xmm0      ;// copy

    psllw xmm0,4          ;// shl 4; hi nibble
    psrlw xmm1,8          ;// shr 8; lo nibble from next byte

    por xmm0,xmm1
    pand xmm0,xmm7;//dq_bmask
    packuswb xmm0,xmm0

    sub ecx,16;
    jl @@check_tail;
      movq [edx],xmm0;
      lea eax,[eax+16];
      lea edx,[edx+8];
    jg @@Loop;
    jz @@done;

  @@tail8:
  @@tail_Loop:
    mov [edx],al;
    shr eax,8;
    add edx,1;
    sub ecx,2;
    jg @@tail_Loop
  jmp @@tail_done

  @@tail16:
    movq [ebp-16],xmm0
    add ecx,16;
    mov eax,[ebp-16];
    cmp ecx,8;
    jl @@tail8;
      mov [edx],eax;
      lea edx,[edx+4];
      lea ecx,[ecx-8];
      mov eax,[ebp-16+4];
    jnz @@tail8
    jmp @@tail_done;

  @@check_tail:
    cmp ecx,-1;
    jl @@tail16;
    movq [edx],xmm0; //jmp @@tail_done

  @@tail_done:
  @@done:
  @@Stop:
  ;//ret
pop ebp
ret 12
;//__hex2bin_sse2 endp;

;segment end
end
