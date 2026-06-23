    .syntax unified

    .data
    STACK_RES: .space 8000      @ Pilha para guardar os 1000 ultimos resultados
    STACK_RES_TOP:              @ Topo da pilha
    LIT_ONE_POW: .double 1.0    @ Constante 1 para o acumulador da potenciacao
    LIT_12: .double 0.0
    LIT_18: .double 4280287232.000000
    LIT_16: .double 1.0
    LIT_11: .double 1.0
    LIT_13: .double 100.0
    LIT_6: .double 2.0
    LIT_8: .double 2.0
    LIT_2: .double 20.0
    LIT_14: .double 200.0
    LIT_17: .double 3.0
    LIT_7: .double 3.5
    LIT_5: .double 4.0
    LIT_1: .double 5.0
    LIT_10: .double 50.0
    LIT_3: .double 6.0
    LIT_15: .double 60.0
    LIT_4: .double 7.0
    LIT_0: .double 8.0
    LIT_9: .double 9.0
    VAR_ATIVO: .double 0.0
    VAR_CONTADOR: .double 0.0
    VAR_FINAL: .double 0.0
    VAR_TAXA: .double 0.0

    .text
    .global _start
_start:

    @ Inicializa o Stack Pointer alinhado em 8 bytes para VFP
    LDR SP, =0x3FFFFFF8

    @ Inicializa o RESult stackpointer
    LDR R10, =STACK_RES_TOP

    @ Percorre a AST em pos-ordem (equivale a avaliacao RPN)
    @ Empilha Constante: 8
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 5
    LDR R0, =LIT_1
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Soma
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VADD.F64 D2, D0, D1     @ A + B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 20
    LDR R0, =LIT_2
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 6
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Subtracao
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VSUB.F64 D2, D0, D1     @ A - B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 7
    LDR R0, =LIT_4
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 4
    LDR R0, =LIT_5
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Multiplicacao
    VPOP.F64 {D1}           @ POP B
    VPOP.F64 {D0}           @ POP A
    VMUL.F64 D2, D0, D1     @ D2 = A * B
    VPUSH.F64 {D2}          @ PUSH

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 6
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 2
    LDR R0, =LIT_6
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Subtracao
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VSUB.F64 D2, D0, D1     @ A - B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 20
    LDR R0, =LIT_2
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 6
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Divisao Inteira (/)
    VPOP.F64 {D1}           @ POP B
    VPOP.F64 {D0}           @ POP A
    VDIV.F64 D2, D0, D1     @ D2 = A / B
    VCVT.S32.F64 S4, D2     @ Trunca o resultado para inteiro
    VCVT.F64.S32 D2, S4     @ Converte de volta para Double (sem decimais)
    VPUSH.F64 {D2}          @ PUSH

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 20
    LDR R0, =LIT_2
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 6
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Modulo (%)
    VPOP.F64 {D1}           @ POP B
    VPOP.F64 {D0}           @ POP A
    VDIV.F64 D2, D0, D1     @ D2 = A / B
    VCVT.S32.F64 S4, D2     @ S4 = parte inteira de (A/B)
    VCVT.F64.S32 D3, S4     @ D3 = parte inteira em Double
    VMUL.F64 D4, D1, D3     @ D4 = B * parte_inteira(A/B)
    VSUB.F64 D5, D0, D4     @ D5 = A - D4 (sobra o resto)
    VPUSH.F64 {D5}          @ PUSH Resto

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 2
    LDR R0, =LIT_6
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 5
    LDR R0, =LIT_1
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Potenciacao (^)
    VPOP.F64 {D1}           @ POP B (Expoente)
    VPOP.F64 {D0}           @ POP A (Base)
    VCVT.S32.F64 S2, D1     @ Converte expoente para inteiro (S2)
    VMOV R4, S2             @ Move expoente para R4 (Contador de Hardware)
    LDR R5, =LIT_ONE_POW    @ Carrega ponteiro do 1.0
    VLDR.F64 D2, [R5]       @ D2 = 1.0 (Acumulador neutro)
pow_loop_0:
    CMP R4, #0              @ Verifica se o contador e <= 0
    BLE pow_end_0   @ Quebra o laco se o expoente esgotar
    VMUL.F64 D2, D2, D0     @ Acumula: D2 = D2 * Base
    SUB R4, R4, #1          @ Decrementa contador
    B pow_loop_0    @ Retorna pro laco
pow_end_0:
    VPUSH.F64 {D2}          @ PUSH resultado

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 3.5
    LDR R0, =LIT_7
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 2.0
    LDR R0, =LIT_8
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Soma
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VADD.F64 D2, D0, D1     @ A + B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 9.0
    LDR R0, =LIT_9
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 2.0
    LDR R0, =LIT_8
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Divisao Real (|)
    VPOP.F64 {D1}           @ POP B
    VPOP.F64 {D0}           @ POP A
    VDIV.F64 D2, D0, D1     @ D2 = A / B
    VPUSH.F64 {D2}          @ PUSH

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ Empilha Constante: 50
    LDR R0, =LIT_10
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Grava resultado na variavel CONTADOR
    VPOP.F64 {D0}
    LDR R0, =VAR_CONTADOR
    VSTR.F64 D0, [R0]

    @ Empilha Constante: 3.5
    LDR R0, =LIT_7
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Grava resultado na variavel TAXA
    VPOP.F64 {D0}
    LDR R0, =VAR_TAXA
    VSTR.F64 D0, [R0]

    @ Empilha Literal Logico: TRUE (1.0)
    LDR R0, =LIT_11
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Grava resultado na variavel ATIVO
    VPOP.F64 {D0}
    LDR R0, =VAR_ATIVO
    VSTR.F64 D0, [R0]

    @ LOAD: Le a variavel CONTADOR da memoria e empilha
    LDR R0, =VAR_CONTADOR
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 2
    LDR R0, =LIT_6
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Operador RES: Busca historico na memoria
    VPOP.F64 {D0}           @ Pega o N da pilha
    VCVT.S32.F64 S0, D0     @ Converte N de Double para Inteiro
    VMOV R1, S0             @ MOV N pro R1
    LSL R1, R1, #3          @ Multiplica N por 8 bytes (descobrir o offset)
    ADD R2, R10, R1         @ Soma o offset com o R10 para achar o endereco antigo
    VLDR.F64 D1, [R2]       @ Le o historico da RAM
    VPUSH.F64 {D1}          @ PUSH pilha

    @ Soma
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VADD.F64 D2, D0, D1     @ A + B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ LOAD: Le a variavel TAXA da memoria e empilha
    LDR R0, =VAR_TAXA
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 2.0
    LDR R0, =LIT_8
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Multiplicacao
    VPOP.F64 {D1}           @ POP B
    VPOP.F64 {D0}           @ POP A
    VMUL.F64 D2, D0, D1     @ D2 = A * B
    VPUSH.F64 {D2}          @ PUSH

    @ salva o resultado no historico de memoria
    VPOP.F64 {D0}           @ POP resultado final da FPU
    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico
    VSTR.F64 D0, [R10]      @ Grava na RAM

    @ LOAD: Le a variavel ATIVO da memoria e empilha
    LDR R0, =VAR_ATIVO
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Literal Logico: FALSE (0.0)
    LDR R0, =LIT_12
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comparacao FPU
    VPOP.F64 {D1}           @ Operando B
    VPOP.F64 {D0}           @ Operando A
    VCMP.F64 D0, D1         @ Compara A com B
    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador

    @ LOAD: Le a variavel CONTADOR da memoria e empilha
    LDR R0, =VAR_CONTADOR
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 50
    LDR R0, =LIT_10
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comparacao FPU
    VPOP.F64 {D1}           @ Operando B
    VPOP.F64 {D0}           @ Operando A
    VCMP.F64 D0, D1         @ Compara A com B
    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador

    BLT else_label_1        @ Salta se a condicao for FALSA
    @ Empilha Constante: 100
    LDR R0, =LIT_13
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    B end_if_1
else_label_1:
    @ Empilha Constante: 200
    LDR R0, =LIT_14
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

end_if_1:

while_start_2:
    @ LOAD: Le a variavel CONTADOR da memoria e empilha
    LDR R0, =VAR_CONTADOR
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 60
    LDR R0, =LIT_15
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comparacao FPU
    VPOP.F64 {D1}           @ Operando B
    VPOP.F64 {D0}           @ Operando A
    VCMP.F64 D0, D1         @ Compara A com B
    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador

    BGE while_end_2        @ Salta se a condicao for FALSA
    @ LOAD: Le a variavel CONTADOR da memoria e empilha
    LDR R0, =VAR_CONTADOR
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 1
    LDR R0, =LIT_16
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Soma
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VADD.F64 D2, D0, D1     @ A + B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ Grava resultado na variavel CONTADOR
    VPOP.F64 {D0}
    LDR R0, =VAR_CONTADOR
    VSTR.F64 D0, [R0]

    B while_start_2
while_end_2:

    @ Empilha Literal Logico: TRUE (1.0)
    LDR R0, =LIT_11
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Literal Logico: FALSE (0.0)
    LDR R0, =LIT_12
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comparacao FPU
    VPOP.F64 {D1}           @ Operando B
    VPOP.F64 {D0}           @ Operando A
    VCMP.F64 D0, D1         @ Compara A com B
    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador

    @ Empilha Constante: 8
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 2
    LDR R0, =LIT_6
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Multiplicacao
    VPOP.F64 {D1}           @ POP B
    VPOP.F64 {D0}           @ POP A
    VMUL.F64 D2, D0, D1     @ D2 = A * B
    VPUSH.F64 {D2}          @ PUSH

    @ Empilha Constante: 3
    LDR R0, =LIT_17
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 1
    LDR R0, =LIT_16
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Soma
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VADD.F64 D2, D0, D1     @ A + B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ Subtracao
    VPOP.F64 {D1}           @ POP operando B
    VPOP.F64 {D0}           @ POP operando A
    VSUB.F64 D2, D0, D1     @ A - B
    VPUSH.F64 {D2}          @ PUSH pilha

    @ Empilha Constante: 2
    LDR R0, =LIT_6
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Potenciacao (^)
    VPOP.F64 {D1}           @ POP B (Expoente)
    VPOP.F64 {D0}           @ POP A (Base)
    VCVT.S32.F64 S2, D1     @ Converte expoente para inteiro (S2)
    VMOV R4, S2             @ Move expoente para R4 (Contador de Hardware)
    LDR R5, =LIT_ONE_POW    @ Carrega ponteiro do 1.0
    VLDR.F64 D2, [R5]       @ D2 = 1.0 (Acumulador neutro)
pow_loop_3:
    CMP R4, #0              @ Verifica se o contador e <= 0
    BLE pow_end_3   @ Quebra o laco se o expoente esgotar
    VMUL.F64 D2, D2, D0     @ Acumula: D2 = D2 * Base
    SUB R4, R4, #1          @ Decrementa contador
    B pow_loop_3    @ Retorna pro laco
pow_end_3:
    VPUSH.F64 {D2}          @ PUSH resultado

    @ Grava resultado na variavel FINAL
    VPOP.F64 {D0}
    LDR R0, =VAR_FINAL
    VSTR.F64 D0, [R0]

    @ LOAD: Le a variavel FINAL da memoria e empilha
    LDR R0, =VAR_FINAL
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_18
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comando WRITE (efeito colateral)
    VPOP.F64 {D1}           @ POP endereco (Double)
    VPOP.F64 {D0}           @ POP valor (Double)
    VCVT.U32.F64 S2, D1     @ Converte endereco para inteiro (unsigned)
    VCVT.S32.F64 S3, D0     @ Converte valor para inteiro
    VMOV R1, S2             @ R1 = endereco
    VMOV R0, S3             @ R0 = valor
    STR R0, [R1]            @ Escreve valor na memoria/periferico

    @ Fim do programa
_fim_programa:
    B _fim_programa         @ Halt
