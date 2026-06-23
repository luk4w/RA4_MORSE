    .syntax unified

    .data
    STACK_RES: .space 8000      @ Pilha para guardar os 1000 ultimos resultados
    STACK_RES_TOP:              @ Topo da pilha
    LIT_ONE_POW: .double 1.0    @ Constante 1 para o acumulador da potenciacao
    LIT_3: .double 0.0
    LIT_1: .double 4280287232.000000
    LIT_0: .double 1.0
    LIT_6: .double 300.0
    LIT_4: .double 450.0
    LIT_2: .double 600.0
    LIT_5: .double 900.0

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

    @ Comando WRITE
    VPOP.F64 {D1}           @ POP endereco (Double)
    VPOP.F64 {D0}           @ POP valor (Double)
    VCVT.U32.F64 S2, D1     @ Converte endereco para inteiro (unsigned)
    VCVT.S32.F64 S3, D0     @ Converte valor para inteiro
    VMOV R1, S2             @ R1 = endereco
    VMOV R0, S3             @ R0 = valor
    STR R0, [R1]            @ Escreve valor na memoria/periferico

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_0:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_0  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_2:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_2  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 900
    LDR R0, =LIT_5
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
delay_loop_3:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_3  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_4:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_4  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 900
    LDR R0, =LIT_5
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
delay_loop_5:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_5  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_6:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_6  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_7:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_7  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_8:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_8  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_9:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_9  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_10:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_10  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_11:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_11  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_12:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_12  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 900
    LDR R0, =LIT_5
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
delay_loop_13:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_13  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_14:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_14  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_15:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_15  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_16:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_16  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_17:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_17  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_18:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_18  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_19:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_19  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 300
    LDR R0, =LIT_6
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
delay_loop_20:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_20  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 900
    LDR R0, =LIT_5
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
delay_loop_21:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_21  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_22:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_22  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_23:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_23  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_24:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_24  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 450
    LDR R0, =LIT_4
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
delay_loop_25:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_25  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 1
    LDR R0, =LIT_0
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Empilha Constante: 600
    LDR R0, =LIT_2
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
delay_loop_26:
    LDR R1, [R4]            @ Le o Interrupt Status Register
    TST R1, #1              @ Verifica bit de estouro (bit 0)
    BEQ delay_loop_26  @ Continua esperando se 0
    MOV R1, #1
    STR R1, [R4]            @ Reseta flag de interrupcao
    MOV R1, #0
    ADD R5, R3, #8          @ R5 = Control Register
    STR R1, [R5]            @ Desliga o timer

    @ Empilha Constante: 0
    LDR R0, =LIT_3
    VLDR.F64 D0, [R0]
    VPUSH.F64 {D0}

    @ Empilha Constante: 0xFF200000
    LDR R0, =LIT_1
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

    @ Fim do programa
_fim_programa:
    B _fim_programa         @ Halt
