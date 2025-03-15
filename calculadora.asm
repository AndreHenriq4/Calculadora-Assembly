;Alunos: André Henrique dos Santos da Silva e Lucas Ivanov Costa

;nasm -f elf64 calculadora.asm 
;gcc -m64 -no-pie calculadora.o -o calculadora.x

extern printf
extern fopen
extern fprintf
extern fclose
extern atof
%define _exit 60

section .data
    modoAberturaArquivo      : db "a", 0
    nomeArquivo              : db "saida.txt", 0
    ctrlArquivo              : db "%.2lf %c %.2lf = %.2lf", 10, 0
    ctrlArquivoNaoDisponivel : db "%.2lf %c %.2lf = funcionalidade não disponível", 10, 0
    ctrlEntradaInvalida      : db "Operando de entrada inválido = %c", 10, 0
    eqMsg                    : db "Uso: ./calculadora operando1 operador operando2", 10, 0
	
section .bss
    op1       : resd 1
    operacao  : resd 1	
    op2       : resd 1
    resultado : resd 1
    arq       : resq 1

section .text 
    global main
	
main:
    push rbp
    mov rbp, rsp
	
    mov rbx, rsi

    cmp rdi, 4
    jge continua

    mov rdi, eqMsg
    call printf
    jmp erro

continua:
    ;Abre o arquivo
    xor rax, rax
    mov rdi, nomeArquivo
    mov rsi, modoAberturaArquivo
    call fopen
    mov [arq], rax

    ;Converte o primeiro operando para float
    mov rax, [rbx+8]
    mov rdi, rax
    call atof
    cvtsd2ss xmm0, xmm0
    movss [op1], xmm0
	
    ;Obtém o operador
    mov rax, [rbx+16]
    movzx r9, byte [rax]
    mov [operacao], r9b

    ;Converte o segundo operando para float
    mov rax, [rbx+24]
    mov rdi, rax
    call atof
    cvtsd2ss xmm0, xmm0
    movss [op2], xmm0

    movss xmm0, [op1]
    movss xmm1, [op2]

    movzx r9, byte [operacao]

    cmp r9b, 'a'
    je callSoma
	
    cmp r9b, 's'
    je callSub
	 	
    cmp r9b, 'm'
    je callMult
	
    cmp r9b, 'd'
    je callDiv

    call entradaInvalida 
	
_fim:
    mov rdi, qword [arq]
    call fclose
	
    mov rsp, rbp
    pop rbp
	
    mov rax, _exit
    mov rdi, 0
    syscall

erro:
    mov rsp, rbp
    pop rbp
    mov rax, _exit
    mov rdi, 1
    syscall
	
callSoma:
    call soma
    jmp _fim

callSub:
    call sub
    ;Troca valores de xmm1 e xmm0 para escrever, pois é op2 - op1
    movss xmm4, [op1]
    movss xmm5, [op2] 
    movss [op1], xmm5
    movss [op2], xmm4
    call disponivel
    jmp _fim
	
callMult:
    call mult
    jmp _fim
	
callDiv:
    call div
    jmp _fim

soma:
    push rbp
    mov rbp, rsp
	
    mov r9b, "+"
    mov [operacao], r9b
		
    vaddss xmm2, xmm0, xmm1
    call disponivel
	
    mov rsp, rbp
    pop rbp
    ret

sub:
    push rbp
    mov rbp, rsp

    mov r9b, "-"
    mov [operacao], r9b
	
    vsubss xmm2, xmm1, xmm0

    mov rsp, rbp
    pop rbp
    ret

mult:
    push rbp
    mov rbp, rsp
	
    mov r9b, "*"
    mov [operacao], r9b
	
    vmulss xmm2, xmm0, xmm1
    call disponivel
		
    mov rsp, rbp
    pop rbp
    ret
	
div:
    push rbp
    mov rbp, rsp
	
    mov r9b, "/"
    mov [operacao], r9b
	
    ; Verifica se o divisor é zero
    cvtss2si r10, xmm1
    mov r11, 0
    cmp r10, r11
    je divPorZero
	
    vdivss xmm2, xmm0, xmm1
    call disponivel
	
    mov rsp, rbp
    pop rbp
    ret
	
divPorZero:
    call naoDisponivel
    mov rsp, rbp
    pop rbp
    ret
    	
disponivel:
    push rbp
    mov rbp, rsp
	
    movss [resultado], xmm2
    mov rax, 2
    mov rdi, qword [arq]
    mov rsi, ctrlArquivo
    cvtss2sd xmm0, [op1]
    mov rdx, [operacao]
    cvtss2sd xmm1, [op2]
    cvtss2sd xmm2, [resultado]
    call fprintf
	
    mov rsp, rbp
    pop rbp
    ret
		
naoDisponivel:
    push rbp
    mov rbp, rsp
	
    movss [resultado], xmm2
    mov rax, 2
    mov rdi, qword [arq]
    mov rsi, ctrlArquivoNaoDisponivel
    cvtss2sd xmm0, [op1]
    mov rdx, [operacao]
    cvtss2sd xmm1, [op2]
    call fprintf
	
    mov rsp, rbp
    pop rbp
    ret

entradaInvalida:
    push rbp
    mov rbp, rsp
	
    mov rdi, qword [arq]
    mov rax, 2
    mov rsi, ctrlEntradaInvalida
    mov rdx, [operacao]
    call fprintf
	
    mov rsp, rbp
    pop rbp
    ret

