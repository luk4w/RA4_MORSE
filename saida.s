    .syntax unified

    .data
    STACK_RES: .space 8000      @ Pilha para guardar os 1000 ultimos resultados
    STACK_RES_TOP:              @ Topo da pilha
    LIT_ONE_POW: .double 1.0    @ Constante 1 para o acumulador da potenciacao
    LIT_1: .double 4280287232.000000
    LIT_0: .double 1.0

    .text
    .global _start
_start:

    @ Inicializa o Stack Pointer alinhado em 8 bytes para VFP
    LDR SP, =0x3FFFFFF8

    @ Inicializa o RESult stackpointer
    LDR R10, =STACK_RES_TOP

    @ Percorre a AST em pos-ordem (equivale a avaliacao RPN)
    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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
