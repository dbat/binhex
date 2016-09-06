PAGE 255, 255
;
; Copyright 2003-2007,
; Adrian H, Ray AF and Raisa NF of PT Softindo, Jakarta
; email: aa _at_ softindo.net
; All right reserved
;

.486
.model flat, stdcall
option casemap: none

.data
; *************************************************************************
  hexLo db "0123456789abcdef"
  hexUp db "0123456789ABCDEF"

  bintab db 30h dup(0)
    db 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0
    db 0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,10,11,12,13,14,15,0,0,0,0,0,0,0,0,0
    db 90h dup(0) ; a necessary bloat

.code
; *************************************************************************
align 4
public __bin2hex
__bin2hex proc source:DWORD, dest:DWORD, count:DWORD, uppercase: DWORD
; translate data to its hexadecimal representation
; dest must have enough capacity twice of count
; source and dest can be the same but should not overlap
; (if overlapped, DEST must be equal or in higher address than source)
    push ebx
    push esi
    push edi

    mov esi, source
    mov edi, dest
    mov ecx, count
    mov eax, uppercase
    lea esi, [esi+ecx-1]                  ; end of source (tail)
    lea edi, [edi+ecx*2-2]                ; end of source (tail)

    test eax,eax              ; uppercase?
    setne al                  ; if yes
    shl eax, 4                ; shift lookup to the next paragraph
    movzx eax,al              ; just in case

    xor ebx,ebx
    lea eax, [eax + hexLo]

  @Loop:
    sub ecx, 1                          ; at the end of data?
    jl @Done                            ; out

  @Begin:
    movzx edx, byte ptr [esi]           ; get byte
    mov bl, byte ptr [esi]              ; get byte copy
    shr dl, 4                           ; get hi nibble -> become lo byte / swapped
    and bl, 0fh                         ; get lo nibble -> become hi byte / swapped
    mov dl, byte ptr [eax+edx]
    mov dh, byte ptr [eax+ebx]
    sub esi, 1
    mov [edi], dx                       ; put translated str
    sub edi, 2
    jmp @Loop                           ;

  @Done:
    pop edi
    pop esi
    pop ebx
    ret

__bin2hex endp

; *************************************************************************
align 4
public __hex2bin
__hex2bin proc source:DWORD, dest:DWORD, count:DWORD
; store hexadecimal string to binary, valid char '0'..'9','a'..'f'
; 2 chars become 1 byte. invalid characters simply interpreted as '0'
; count should be an even number, the last odd/orphaned char will
; be stored as high nibble in the last byte. you get it don't you?
; source and dest can be the same but should not overlap
; (if overlapped, SOURCE must be equal or in higher address than dest)

    push ebx
    push esi
    push edi

    mov esi, source
    mov edi, dest
    mov ecx, count

    lea ebx, bintab

    xor eax,eax
    xor edx,edx

  @Loope:
    sub ecx,2
    jl @done
    mov dl, byte ptr [esi]
    mov al, byte ptr [esi+1]
    mov dl, byte ptr [ebx+edx]
    mov al, byte ptr [ebx+eax]
    shl edx, 4
    add esi, 2
    add edx, eax
    mov byte ptr [edi], dl
    add edi, 1
    jmp @Loope

  @done:
    not ecx
    jcxz @done2
    mov dl, byte ptr [esi]
    mov dl, byte ptr [ebx+edx]
    shl edx, 4
    mov byte ptr [edi], dl

  @done2:
    pop edi
    pop esi
    pop ebx
    ret

__hex2bin endp

end
