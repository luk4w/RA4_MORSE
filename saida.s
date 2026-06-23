    .syntax unified

    .data
    STACK_RES: .space 8000      @ Pilha para guardar os 1000 ultimos resultados
    STACK_RES_TOP:              @ Topo da pilha
    LIT_ONE_POW: .double 1.0    @ Constante 1 para o acumulador da potenciacao
    LIT_0: .double 0.0
    LIT_2: .double 4280287232.000000
    LIT_1: .double 1.0
    LIT_4: .double 1023.0
    LIT_3: .double 500.0
    VAR_ESTADO: .double 0.0

    .text
    .global _start
_start:

    @ Inicializa o Stack Pointer alinhado em 8 bytes para VFP
    LDR SP, =0x3FFFFFF8

    @ Inicializa o RESult stackpointer
    LDR R10, =STACK_RES_TOP

    @ Percorre a AST em pos-ordem (equivale a avaliacao RPN)
    @ Empilha Constante: 0
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Grava resultado na variavel ESTADO
    VPOP.F64 {D0}
    LDR R0, =VAR_ESTADO
    VSTR.F64 D0, [R0]

while_start_0:
    @ Empilha Literal Logico: TRUE (1.0)
    LDR R0, =LIT_1
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Condicao booleana nao-relacional: testa se e FALSA (== 0.0)
    VPOP.F64 {D0}           @ Desempilha o valor logico
    VCMP.F64 D0, #0.0       @ Compara com zero (false)
    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador
    BEQ while_end_0        @ Salta se a condicao for FALSA (== 0)
    @ LOAD: Le a variavel ESTADO da memoria e empilha
    LDR R0, =VAR_ESTADO
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_2
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comando WRITE
    VPOP.F64 {D1}           @ POP endereco (Double)
    VPOP.F64 {D0}           @ POP valor (Double)
    VCVT.U32.F64 S2, D1     @ Converte endereco para inteiro (unsigned)
    VCVT.S32.F64 S3, D0     @ Converte valor para inteiro
    VMOV R1, S2             @ R1 = endereco
    VMOV R0, S3             @ R0 = valor
    STR R0, [R1]            @ Escreve valor na memoria/periferico

    @ Empilha Constante: 500
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comando DELAY (Private Timer)
    VPOP.F64 {D0}           @ POP tempo em ms
    VCVT.S32.F64 S2, D0     @ Converte ms para inteiro
    VMOV R0, S2             @ R0 = ms
    LDR R1, =200000         @ Frequencia base (200 MHz / 1000)
    MUL R2, R0, R1          @ R2 = total de ciclos do timer
    LDR R3, =0xFFFEC600     @ Endereco do A9 Private Timer
    STR R2, [R3]            @ Define o valor de LOAD do timer
    MOV R1, #1
    ADD R4, R3, #8          @ R4 = Control Register
    STR R1, [R4]            @ Inicia o timer
    ADD R4, R3, #12         @ R4 = Interrupt Status Register
delay_loop_1:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_1  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ LOAD: Le a variavel ESTADO da memoria e empilha
    LDR R0, =VAR_ESTADO
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Comparacao FPU
    VPOP.F64 {D1}           @ Operando B
    VPOP.F64 {D0}           @ Operando A
    VCMP.F64 D0, D1         @ Compara A com B
    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador

    BNE else_label_2        @ Salta se a condicao for FALSA
    @ Empilha Constante: 1023
    LDR R0, =LIT_4
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    B end_if_2
else_label_2:
    @ Empilha Constante: 0
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

end_if_2:

    @ Grava resultado na variavel ESTADO
    VPOP.F64 {D0}
    LDR R0, =VAR_ESTADO
    VSTR.F64 D0, [R0]

    B while_start_0
while_end_0:

    @ Fim do programa
_fim_programa:
    B _fim_programa         @ Halt
