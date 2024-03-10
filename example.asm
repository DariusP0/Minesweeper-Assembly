.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern rand: proc
extern srand: proc
extern time: proc
extern printf: proc
includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640
area_height EQU 480
area DD 0
counter DD 0 ; numara evenimentele de tip timer

cnt DD 4
cnt2 dd 4
impartire dd 25
impartire10 dd 10
i2 dd 2
var_nr dw 0
bomb_x DD 0
bomb_y DD 0
nr_bombe dd 0
y_b dd 0
x_b dd 0
f db "%d" ,13,10, 0
fmt_elmat db "a[%d][%d] = %d", 13, 10, 0
frmt2 db "%d ",13,10,0
mesajBomba db " Ati apasat pe o bomba ",13,10,0
i dd 0
sum dw 0
m dw 0, 0, 0, 0, 0
  dw 0, 0, 0, 0, 0
  dw 0, 0, 0, 0, 0
  dw 0, 0, 0, 0, 0
  dw 0, 0, 0, 0, 0
nr_rand dd 5
line_size dd ?
contorColoana dd 0
contorLinie dd 0
contorLinie2 dd 0
contorColoana2 dd 0
contorAfisare dd 0
contorAfisare2 dd 0
newLine db " ",13,10,0

s db "%d",13,10,0
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x, y, len, color
local bucla_line	
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_line
endm

line_vertical macro x, y, len, color
local bucla_line
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
bucla_line:
	mov dword ptr[eax], color
	add eax, 4 * area_width
	loop bucla_line
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
randomfunc macro x
    push 0
    call time
    add esp,4
    push eax
    call srand
    add esp,4
	mov edx, 0
	
	push eax
    call rand
    add esp,4
	
	div impartire
	mov ebx,edx
	mov x,ebx
endm
; randomfunc2 macro y
	; mov edx, 0
	
	; push eax
	; call rand
	; add esp,4
	
	; div impartire2
	; mov ebx,edx
	; mov eax,60
	; mov edx,0
	; mul ebx
	; mov y,eax
	; add y,20
; endm

draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
afisare_castig:
	
	make_text_macro 'C', area, 260, 370
	make_text_macro 'A', area, 270, 370
	make_text_macro 'S', area, 280, 370
	make_text_macro 'T', area, 290, 370
	make_text_macro 'I', area, 300, 370
	make_text_macro 'G', area, 310, 370
	make_text_macro 'A', area, 320, 370
	make_text_macro 'T', area, 330, 370
	
	; push 0
	; call exit

evt_click:
	mov edi, area
	mov ecx, area_height
	mov ebx, [ebp+arg3]
	and ebx, 7
	inc ebx
	; evt_click_bomb_x macro x,y
	
	; mov edx, [ebp+arg3]
	; mov eax, [ebp+arg4] 
	
	; cmp eax, bomb_x ;; comparam coordonata x(generata random) fata de coordonata x pe care am dat click
	; jne final3 ;;daca nu este egala jump la final, unde incrementam esi

; verificam_y:
	; inc esi ;;daca x = coordonata x de la click comparam coordonata y(generata random) fata de coordonata y pe care am dat click
	; cmp edx, bomb_y
	; jne final3 ;;daca nu este egala jump la final, unde incrementam esi
; final:
	;coloram patratul care contine si coordonatele generate
; final3:
	;coloram(punem cate bombe sunt adiacente cu respectivele)
; endm


;vreau la fiecare click sa determin linia si coloana pe care ma aflu;

;x lower-bound = 0 , x upper bound = 130, dupa ce am mers o colona lower bound <= upper bound
;y lower-bound = 0 , y upper bound = 60, dupa ce am mers rand lower boud <= upper bound

	linie:
	mov contorLinie, 0
	mov contorColoana, 0
	mov edi, 0 ; edi reprezinta pixelii pe linie
	mov esi, 20 ; esi reprezinta pixelii pe coloana
	

	mov eax, [ebp+arg2];x
	
	
	loop_eticheta:
	
		cmp eax, edi
		;eax trebuie sa fie mai mare decat edi
		jb gata
		add edi, 130
		inc contorLinie
		cmp eax, edi
		ja gata		
		
		dec contorLinie
		jmp gata1
	
		gata:
		cmp contorLinie, 3
		jbe loop_eticheta
		
	gata1:
	;afisare (test)
	
	pusha
	mov eax, contorLinie
	mov contorLinie2,eax
	push eax
	push offset frmt2
	call printf
	add esp, 8
	popa

	coloana:
	;mov contorLinie, 0
	mov contorColoana, 0
	mov edi, 0 ; edi reprezinta pixelii pe linie
	mov esi, 20 ; esi reprezinta pixelii pe coloana
	

	mov eax, [ebp+arg3];x
	
	
	loop_eticheta1:
	
		cmp eax, esi
		;eax trebuie sa fie mai mare decat edi
		jb gata2
		add esi, 60
		inc contorColoana
		cmp eax, esi
		ja gata2	
		
		dec contorColoana
		jmp gata3
	
		gata2:
		cmp contorColoana, 5
		jbe loop_eticheta1
		
	gata3:
	
	
	pusha
	push offset newLine
	call printf
	add esp, 4
	popa
	
	pusha
	mov eax, contorColoana
	mov contorColoana2,eax
	push eax
	push offset frmt2
	call printf
	add esp, 8
	popa
	
	pusha
	push offset newLine
	call printf
	add esp, 4
	popa
	
	
	;vreau sa afisez daca dau click pe o bomba ca am dat click pe o bomba
	;matrice[contorLinie][contorColoana] >= 7 inseamna ca trebuie sa printam pe ecran AI DAT CLICK PE O BOMBA
	lea ebx, m
	mov edi, 0
	loop_aflare_linie_in_matrice:
		add ebx,10
		add edi,10
		dec contorColoana2
		cmp contorColoana2,0
	ja loop_aflare_linie_in_matrice
	
	loop_aflare_coloana_in_matrice:
		add ebx, 2
		add edi, 2
		dec contorLinie2
		cmp contorLinie2, 0
		ja loop_aflare_coloana_in_matrice
	
	
	mov dx, [ebx]
	and edx, 0FFh
	; pusha
	; push edx
	; push offset frmt2
	; call printf
	; add esp, 8
	; popa
	pusha 
	push nr_bombe
	push offset frmt2
	call printf
	add esp, 8
	popa
	
	mov ebx, 0 
	mov bx,dx
	cmp bx, 7
	jae bomba_afis
	mov eax,0
	mov edi,130
	mov esi,60
	
	mov eax, contorLinie
	mul edi
	add eax, 50
	mov contorAfisare,eax
	
	mov eax,0
	mov eax, contorColoana
	mul esi
	add eax,50
	mov contorAfisare2,eax
	
	add ebx,'0'
	make_text_macro ebx, area, contorAfisare, contorAfisare2
	
	cmp dx, 7
	jb evt_timer
	bomba_afis:
	pusha
	; push offset newLine
	push offset mesajBomba
	call printf
	add esp, 8
	mov [m+edi], 0
	inc nr_bombe
	
	mov eax,0
	mov edi,130
	mov esi,60
	
	mov eax, contorLinie
	mul edi
	add eax, 50
	mov contorAfisare,eax
	
	mov eax,0
	mov eax, contorColoana
	mul esi
	add eax,50
	mov contorAfisare2,eax
	make_text_macro 'X', area, contorAfisare, contorAfisare2
	popa
	cmp nr_bombe,4
	je afisare_castig
	
	
	; pusha
	; push esi
	; push offset frmt2
	; call printf
	; add esp,8
	; popa

evt_timer:
	;inc counter

	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	; mov ebx, 10
	; mov eax, counter
	; cifra unitatilor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 30, 10
	; cifra zecilor
	make_text_macro 'B',area,440,370
	make_text_macro 'O',area,450,370
	make_text_macro 'M',area,460,370
	make_text_macro 'B',area,470,370
	make_text_macro 'E',area,480,370
	make_text_macro ' ',area,490,370
	mov edx, nr_bombe
	add edx, '0'
	 make_text_macro edx, area, 500, 370
	 make_text_macro 'Z', area, 510, 370
	 make_text_macro '4', area, 520, 370
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 20, 10
	; cifra sutelor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 10, 10
	;scriem un mesaj
	; make_text_macro 'M', area, 110, 100
	; make_text_macro 'R', area, 120, 100
	; make_text_macro 'O', area, 130, 100
	; make_text_macro 'I', area, 140, 100
	; make_text_macro 'E', area, 150, 100
	; make_text_macro 'C', area, 400, 400
	; make_text_macro 'T', area, 170, 100
	
	; make_text_macro 'L', area, 130, 120
	; make_text_macro 'A', area, 140, 120
	
	; make_text_macro 'C', area, 100, 140
	; make_text_macro 'A', area, 110, 140
	; make_text_macro 'S', area, 120, 140
	; make_text_macro 'T', area, 130, 140
	; make_text_macro 'I', area, 140, 140
	; make_text_macro 'G', area, 150, 140
	; make_text_macro 'A', area, 160, 140
	; make_text_macro 'T', area, 170, 140
	; make_text_macro 'E', area, 180, 140
	
	
	mov esi, 20
desenare_linii:
	line_horizontal 0 ,esi, 640, 0 
	add esi, 60
	cmp esi, 361
	jle desenare_linii
	mov esi, 0
desenare_col:
	line_vertical esi, 20, 300, 0
	add esi , 128
	cmp esi, 640
	jl desenare_col
afisare_ecran:

	; y = 0 -> 80
	; x = 0 -> 130
	; apelam make_text_macro si variabila a[i][j]
	; sa fie in centru
	; x= x+130 si y = y+80 dupa
	; mov ecx, nr_rand
	; xor ebx, ebx
	; xor esi, esi
	; lea ebx, m
	; shl eax, 1
	; mov line_size, eax
	; traverse_matrix:
	; push ecx
	; mov ecx, nr_rand
	; xor edi, edi
	; traverse_row:
		; pusha
		; mov dx, [ebx + 2 * edi]
		
		; and dx, 0FFh
		; add dx,'0'
		; make_text_macro dx, area, x_b, y_b
		
		; push edx
		; push edi
		; push esi
		; push offset fmt_elmat
		; call printf
		; add esp, 16
		
	
		; popa
		; inc edi
		; add x_b,130
		; loop traverse_row
	; pop ecx
	; inc esi
	; add ebx, line_size
	; add y_b,80
	; loop traverse_matrix
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
	
draw endp

inserare_matrice proc
	din_nou:
	randomfunc bomb_x
	mov esi, bomb_x
	shl esi, 1
	cmp [m+esi],7
	je din_nou 
	mov [m+esi],7
	add esi,2
	 mov eax,0 
	 mov edx,0
	 mov eax,esi
	;div impartire10
	; cmp edx, 0
	; jb uv0
	; cmp edx,8
	; ja uv0
	
	; add esi,2
	inc [m+esi]
	; cmp esi,2
	; jb uv0
	; cmp esi,14
	; ja uv0
	; inc [m+esi]
	uv0:
	sub esi,4
	mov eax,0 
	mov edx,0
	mov eax,esi
	div impartire10
	inc [m+esi]
	
	sub esi, 10
	; mov eax,0 
	; mov edx,0
	; mov eax,esi
	; div impartire10
	inc [m+esi]
	
	add esi, 2
	; mov eax,0 
	; mov edx,0
	; mov eax,esi
	; div impartire10
	inc [m+esi]
	
	add esi, 2
	; mov eax,0 
	; mov edx,0
	; mov eax,esi
	; div impartire10
	inc [m+esi]
	
	
	add esi,16
	; mov eax,0 
	; mov edx,0
	; mov eax,esi
	; div impartire10
	inc [m+esi]
	
ret
inserare_matrice endp

start:

loopi:
    call inserare_matrice
	; pop bomb_y
	
	;Verificam 4 bombe, daca nu, resetam i si generam un nr random si traversam matricea(din nou) sa punem numarul
	 ; push bomb_x
	 ; push offset s
	 ; call printf
	 ; add esp, 4
	 pop bomb_x
	
	  dec cnt
      cmp cnt,0
	  jne loopi
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; mov ecx, nr_rand
	; xor ebx, ebx
	; xor esi, esi
	; lea ebx, m
	; mov sum, 0
	; mov eax, nr_rand
	
	; shl eax, 1
	; mov line_size, eax
	; traverse_matrix1:
	; push ecx
	; mov ecx, nr_rand
	; xor edi, edi
	; traverse_row1:
		
		; pusha
		; mov dx, [ebx + 2 * edi]
		; and edx, 0FFh
		
		; cmp edx,7
		; jne treci
		; inc edi
		; inc [m+ebx+2*edi]
		; treci:
		; popa
		; inc edi
		; loop traverse_row1
	; pop ecx
	; inc esi
	; add ebx, line_size
	; mov sum, 0
	; loop traverse_matrix1
	;;;;;;;;;;;;
	
	
	
	
	
	
	
	
	
	mov ecx, nr_rand
	xor ebx, ebx
	xor esi, esi
	lea ebx, m
	
	mov eax, nr_rand
	
	shl eax, 1
	mov line_size, eax
	traverse_matrix:
	push ecx
	mov ecx, nr_rand
	xor edi, edi
	traverse_row:
		
		pusha
		mov dx, [ebx + 2 * edi]
		and edx, 0FFh
		
		push ecx
		push edx
		push edi
		push esi
		push offset fmt_elmat
		call printf
		add esp, 16
		pop ecx
	
		popa
		inc edi
		loop traverse_row
	pop ecx
	inc esi
	add ebx, line_size
	loop traverse_matrix
	; push sum
	; push offset f
	; call printf
	; add esp,8
	; alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	

	;terminarea programului
	push 0
	call exit
end start
