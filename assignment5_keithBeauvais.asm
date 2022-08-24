;	Assignment #5
; 	Author: Keith Beauvais
; 	Section: 1001
; 	Date Last Modified: 10/09/2021
; 	Program Description: This program will explore the use of fuctions and syscall



section .data

    SYSTEM_EXIT equ 60
	SUCCESS equ 0
	SYSTEM_READ equ 0 
	STANDARD_IN equ 0
	SYSTEM_WRITE equ 1
	STANDARD_OUT equ 1
   
;   Constant Characters:

    NULL equ 0
	LINEFEED equ 10
    BUFFER_SIZE equ 100
    MAX_NUM equ 2147483647
    MIN_NUM equ -2147483647

;   Labels:
    promptUserString db "Input Interger Numbers or Quit :", NULL
    quitString db "Quit",NULL
    validNumber db "Valid Numeric Value", LINEFEED, NULL
    newLine db LINEFEED, NULL
    errorMin db "Number below minimum: −2,147,483,648",LINEFEED, NULL
    errorMax db "Number above maximum: 2,147,483,647", LINEFEED,NULL
    nonValidNum db "Unexpected character found", LINEFEED,NULL
    errorLong db "Input Too Long, Try a smaller value", LINEFEED, NULL
    noValueEntered db "Please Enter a Value",LINEFEED, NULL

section .bss

    stringBuffer resb 100
    convertedInt resq 1

section .text
;--------------------------
; Argument 1: Address to a null terminated string
global stringLength
stringLength:

    push rbx
    push rdi

    mov rcx, 0
    stringLoop:

		mov bl, byte[rdi] 
		cmp bl, NULL 
		je endStringLoop 

		inc rcx 
		inc rdi 
		jmp stringLoop

    endStringLoop:
    mov rax, rcx ; returns the length of the string

    pop rdi
    pop rbx

ret
;--------------------------
; Argument 1: Address to a null terminated string
global printString
printString:
    push rbx
    push r12

    mov r12, rdi

    call stringLength
    

    mov rdx, rax
    mov rax, SYSTEM_WRITE
    mov rdi, STANDARD_OUT
    mov rsi, r12

    syscall

    pop r12
    pop rbx
ret
;--------------------------
; Argument 1: Address to a string prompt to output 
; Argument 2: Address to a string buffer
; Argument 3: Maximum input size (32 bit unsigned int)
global promptUser
promptUser:
    ; Preserved Registers
    push rbx
    push r12

    mov rbx, rsi
    mov r12, rdx

    call printString

    mov rcx, 0 ; counter 
    inputLoop:
        
        mov rax, SYSTEM_READ
        mov rdi, STANDARD_IN
        lea rsi, [rbx + rcx]
        mov rdx, 1
        push rcx
        syscall
        pop rcx
        

        cmp byte[rbx+rcx], LINEFEED ; compares the input to Linefeed
        je acceptedInput

        inc rcx

        cmp rcx, r12 ; compares the max buffer to counter if equal or great then clear buffer
        jge clearBuffer

        jmp inputLoop

    clearBuffer:
        mov rax, SYSTEM_READ
        mov rdi, STANDARD_OUT
        mov rsi, rbx
        mov rdx, 1
        syscall
        cmp byte[rbx], LINEFEED
        jne clearBuffer

        mov rax, -1

        jmp finished


    acceptedInput:
        mov rax, rcx

        inc rax
        mov byte[rbx + rcx], NULL

    finished:

    pop r12
    pop rbx

ret 
;--------------------------
; Argument 1: Address to null terminated string
; Argument 2: Address to null terminated string
global compareStrings
compareStrings:
    
    mov dl, byte[rdi]
    cmp dl, byte[rsi]
    je compareNULL ; same char see if NULL

    cmp dl, byte[rsi]
    jb charLess

    mov rax, 1
    ret 

charLess:
    mov rax, -1 ; rdi is less than rsi 
    ret

compareNULL:
    cmp dl, NULL
    jne increaseChar ; not NULL but equal char, move to next char if not equal to NULL
    mov rax, 0 ; char is a NULL and returns 0 
    ret

increaseChar:
    inc rdi
    inc rsi
    jmp compareStrings
;--------------------------
; Argument 1: Address to a null terminated string
; Argument 2: Address to a 32 bit location to store the converted value
; Check for the following:
;   Number below minimum: −2,147,483,648
;   Number above maximum: 2,147,483,647
;   Unexpected character found including internal spaces at least 1 numeric digit
global convertStringToInt
convertStringToInt:
    push rbx ; counter 
    push r12 ; 
    push r13 ; flag for positive or negative
    push r14


    mov rbx, 0 ; counter 

	mov r13, 1 ; sets sign to automatically be 1 unless it has a '-'
	mov cl, byte[rdi] ; seeing what the first character is from rdx 
    cmp cl, ' ' ; compares to a space to handle spaces
    je spaceLoop 
	cmp cl, '-' ; comparing the first character to minus
	jne carryOn ; if it is not a minus then it is a plus and it sets r13 to 1 
	mov r13, -1 ; reset sign to -1 if '-'
	inc rbx ; increment past the '-'
    jmp conversionLoop

    spaceLoop:
    inc rbx
    mov r12b, byte[rdi+rbx] ; moves the character in the index (signaled by rbx counter)
	cmp r12b, ' ' ; keeps reading in spaces
    je spaceLoop
    cmp r12b, '-'
    jne conversionLoop
    mov r13, -1 ; reset sign to -1 if '-'
	inc rbx ; increment past the '-'
    jmp conversionLoop

	carryOn:
		mov eax, 0 ; setting the sum to 0 eax is sum register
		cmp cl, '+' ; compare to see if the first character is '+' if not then jump to conversion loop because it is either '-' and rcx has be incremented or the first char is a number 
		jne conversionLoop
		inc rbx ; increase rcx counter 

	conversionLoop:

		mov r12b, byte[rdi+rbx] ; moves the character in the index (signaled by rbx counter)
		cmp r12b, NULL ; compares the character to NULL if NULL come out of loop 
		je doneConversionLoop
        cmp r12b, 48
        jl checkUnexpectedChar
        cmp r12b, 57
        jg checkUnexpectedChar
		sub r12b, '0' ; subtracting the first char wiht '0' 
		mov r10b, 10 ; moving 10 into 10 register
		movzx r14, r12b ; expanding r12b to r14 to do conversion 
		mul r10 ; multiplying rax (sum) by 10
		add rax, r14 ; adding r14 with rax 
		inc rbx ; increase the index counter
		jmp conversionLoop

    checkUnexpectedChar:
       
        mov rdi, nonValidNum
        call printString
    
        mov rax, -1 
        pop rbx ; counter 
        pop r12 ; 
        pop r13 ; flag for positive or negative
        pop r14
        ret
    tooLarge:
        
        mov rdi, errorMax
        call printString

        mov rax, -1 
        pop rbx ; counter 
        pop r12 ; 
        pop r13 ; flag for positive or negative
        pop r14
        ret
    tooSmall:
     
        mov rdi, errorMin
        call printString

        mov rax, -1 
        pop rbx ; counter 
        pop r12 ; 
        pop r13 ; flag for positive or negative
        pop r14
        ret
    enterAValue:
      
        mov rdi, noValueEntered
        call printString

        mov rax, -1 
        pop rbx ; counter 
        pop r12 ; 
        pop r13 ; flag for positive or negative
        pop r14
        ret
	doneConversionLoop:

    mul r13 ; multiply with new sign

    cmp rax, MAX_NUM
    jg tooLarge
    
    cmp rax, MIN_NUM
    jl tooSmall

    cmp rax, 0
    je enterAValue

    cmp rax, -1
    je enterAValue

    cmp rax, 1
    je enterAValue

    mov rax, 1 

    pop rbx ; counter 
    pop r12 ; 
    pop r13 ; flag for positive or negative
    pop r14
ret 
;--------------------------
; int main(){

;}
global _start
_start:
    
    promptUserLoop: 

        mov rdi, promptUserString ; Argument 1: Address to a string prompt to output 
        mov rsi, stringBuffer ; Argument 2: Address to a string buffer
        mov rdx, 100    ; Argument 3: Maximum input size (32 bit unsigned int)
        call promptUser

        cmp rax, -1
        je errorTooLong
        
        mov rdi, quitString  ; checking to see it quit was used 
        mov rsi, stringBuffer
        call compareStrings
        cmp rax, 0 
        je endProgram

        mov rdi, stringBuffer
        mov rsi, convertedInt
        call convertStringToInt

        cmp rax, 1 
        jne promptUserLoop

        mov rdi, validNumber
        call printString
        
        jmp promptUserLoop


    errorTooLong:
       
        mov rdi, errorLong
        call printString

        jmp promptUserLoop


endProgram:
    mov rax, SYSTEM_EXIT
    mov rdi, SUCCESS
    syscall