// Integrantes do grupo (ordem alfabetica):
// Lucas Franco de Mello - luk4w
// Nome do grupo no Canvas: RA3 2

#include "armv7_generator.hpp"
#include <sstream>
#include <map>
#include <string>

// Converter um literal logico para a constante double  TRUE 1.0 e FALSE 0.0
// Usado tanto na coleta da secao .data quanto na emissao
static std::string valorBoolLiteral(const ASTNode *node)
{
    return (node->operando == "TRUE") ? "1.0" : "0.0";
}

// Formata literais numericos (incluindo hexadecimais como 0xFF200000)
// para formato float decimal padrão exigido pelo .double do GNU assembler.
static std::string formatarDouble(const std::string &s)
{
    if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X'))
    {
        try {
            unsigned long long val = std::stoull(s, nullptr, 16);
            return std::to_string(static_cast<double>(val));
        } catch (...) {
            return s;
        }
    }
    if (s.find('.') == std::string::npos && s.find('e') == std::string::npos && s.find('E') == std::string::npos)
    {
        return s + ".0";
    }
    return s;
}

// Como a AST foi projetada com opcodes ARMv7 VFP embutidos nos nós (VADD.F64, VLDR.F64)
// facilita a vida, ou seja
// primeiro emite o codigo dos filhos (deixando operandos na pilha FPU)
// em seguida o nó corrente emite sua propria instrucao

// A pre analise percorre a AST coletando literais numericos e variaveis
// isso sera usado para gerar a secao .data do Assembly
static void coletarLiteraisVariaveis(
    ASTNode *node,
    std::map<std::string, std::string> &literais,
    std::map<std::string, std::string> &variaveis,
    int &contagemLiterais)
{
    if (!node)
        return;

    switch (node->tipo)
    {
    case ASTNodeType::NUMERO_LITERAL:
        if (literais.find(node->operando) == literais.end())
            literais[node->operando] = "LIT_" + std::to_string(contagemLiterais++);
        break;
    case ASTNodeType::BOOL_LITERAL:
    {
        // Literais logicos viram constantes double na secao .data.
        std::string v = valorBoolLiteral(node);
        if (literais.find(v) == literais.end())
            literais[v] = "LIT_" + std::to_string(contagemLiterais++);
        break;
    }
    case ASTNodeType::MEMORIA_LOAD:
    case ASTNodeType::MEMORIA_STORE:
        if (variaveis.find(node->operando) == variaveis.end())
            variaveis[node->operando] = "VAR_" + node->operando;
        break;
    default:
        break;
    }

    for (ASTNode *filho : node->filhos)
        coletarLiteraisVariaveis(filho, literais, variaveis, contagemLiterais);
}

// Decide se um no deixa um valor na pilha FPU apos sua emissao
// Usado para determinar se a expressao de topo deve ser gravada no historico
// de resultados (RES) ao final.
static bool produzValor(ASTNodeType tipo)
{
    switch (tipo)
    {
    case ASTNodeType::NUMERO_LITERAL:
    case ASTNodeType::BOOL_LITERAL:
    case ASTNodeType::MEMORIA_LOAD:
    case ASTNodeType::MEMORIA_RES:
    case ASTNodeType::INSTRUCAO_VFP:
    case ASTNodeType::INSTRUCAO_BITWISE:
    case ASTNodeType::INSTRUCAO_BITWISE_NOT:
        return true;
    default:
        return false;
    }
}

static std::string mapearBranchInverso(std::string op)
{
    if (op == "==")
        return "BNE"; // Salta se não for igual
    if (op == "!=")
        return "BEQ"; // Salta se for igual
    if (op == "<")
        return "BGE"; // Salta se maior ou igual
    if (op == "<=")
        return "BGT"; // Salta se maior que
    if (op == ">")
        return "BLE"; // Salta se menor ou igual
    if (op == ">=")
        return "BLT"; // Salta se menor que
    return "B";       // Fallback de segurança
}

// Declaracao adiantada
// emitirNo e emitirCondicaoSalto se chamam mutuamente
// um comando de controle emite a condicao, que por sua vez pode ser qualquer no
static void emitirNo(
    ASTNode *node,
    std::stringstream &ss,
    const std::map<std::string, std::string> &literais,
    const std::map<std::string, std::string> &variaveis,
    int &contadorLabel);

// Emite a condicao de um IFELSE/WHILE e salta pro labelFalso quando ela e falsa
// dois casos
// relacional (INSTRUCAO_CMP) o proprio no faz VCMP + VMRS e a gente usa o branch inverso do operador
// booleana qualquer (variavel, literal TRUE/FALSE) o no deixa 1.0/0.0 na pilha, testa com zero e salta se for 0
static void emitirCondicaoSalto(
    ASTNode *cond,
    const std::string &labelFalso,
    std::stringstream &ss,
    const std::map<std::string, std::string> &literais,
    const std::map<std::string, std::string> &variaveis,
    int &contadorLabel)
{
    if (cond && cond->tipo == ASTNodeType::INSTRUCAO_CMP)
    {
        // relacional, o emitirNo(cond) ja gera o VCMP + VMRS
        emitirNo(cond, ss, literais, variaveis, contadorLabel);
        ss << "    " << mapearBranchInverso(cond->opcode)
           << " " << labelFalso << "        @ Salta se a condicao for FALSA\n";
    }
    else
    {
        // booleana nao-relacional (variavel, literal)
        // o no empilha 1.0 (true) ou 0.0 (false) e a gente testa contra zero
        emitirNo(cond, ss, literais, variaveis, contadorLabel);
        ss << "    @ Condicao booleana nao-relacional: testa se e FALSA (== 0.0)\n";
        ss << "    VPOP.F64 {D0}           @ Desempilha o valor logico\n";
        ss << "    VCMP.F64 D0, #0.0       @ Compara com zero (false)\n";
        ss << "    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador\n";
        ss << "    BEQ " << labelFalso << "        @ Salta se a condicao for FALSA (== 0)\n";
    }
}

// Walker recursivo pos-ordem: emite o Assembly para o subarvore raiz em no
// Invariante: ao retornar, nos que "produzem valor" deixam 1 double na pilha FPU (via VPUSH.F64)
// Nos de efeito colateral (STORE) consomem e nao deixam residuo
// Comandos de controle (IFELSE/WHILE) serao completados na logica de controle e saltos do programa
static void emitirNo(
    ASTNode *node,
    std::stringstream &ss,
    const std::map<std::string, std::string> &literais,
    const std::map<std::string, std::string> &variaveis,
    int &contadorLabel)
{
    if (!node)
        return;

    switch (node->tipo)
    {
    case ASTNodeType::PROGRAMA:
        // Cada filho e uma expressao/comando de topo.
        for (ASTNode *filho : node->filhos)
        {
            emitirNo(filho, ss, literais, variaveis, contadorLabel);

            // Apos expressoes de topo que produzem valor, salva em RES.
            if (produzValor(filho->tipo))
            {
                ss << "    @ salva o resultado no historico de memoria\n";
                ss << "    VPOP.F64 {D0}           @ POP resultado final da FPU\n";
                ss << "    SUB R10, R10, #8        @ Avanca o ponteiro da pilha de historico\n";
                ss << "    VSTR.F64 D0, [R10]      @ Grava na RAM\n\n";
            }
        }
        break;

    case ASTNodeType::NUMERO_LITERAL:
        // Folha: empilha a constante vinda da secao .data.
        ss << "    @ Empilha Constante: " << node->operando << "\n";
        ss << "    LDR R0, =" << literais.at(node->operando) << "\n";
        ss << "    VLDR.F64 D0, [R0]\n";
        ss << "    VPUSH.F64 {D0}\n\n";
        break;

    case ASTNodeType::BOOL_LITERAL:
    {
        // Folha logica
        // empilha TRUE ou FALSE como constante double
        std::string v = valorBoolLiteral(node);
        ss << "    @ Empilha Literal Logico: " << node->operando << " (" << v << ")\n";
        ss << "    LDR R0, =" << literais.at(v) << "\n";
        ss << "    VLDR.F64 D0, [R0]\n";
        ss << "    VPUSH.F64 {D0}\n\n";
        break;
    }

    case ASTNodeType::MEMORIA_LOAD:
        // Folha: carrega o valor da variavel e empilha.
        // node->opcode = "VLDR.F64" (definido pelo parser).
        ss << "    @ LOAD: Le a variavel " << node->operando << " da memoria e empilha\n";
        ss << "    LDR R0, =" << variaveis.at(node->operando) << "\n";
        ss << "    " << node->opcode << " D0, [R0]\n";
        ss << "    VPUSH.F64 {D0}\n\n";
        break;

    case ASTNodeType::MEMORIA_STORE:
        // Emite o valor a armazenar (filho unico), depois grava na variavel.
        // node->opcode = "VSTR.F64" (definido pelo parser).
        if (!node->filhos.empty())
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
        ss << "    @ Grava resultado na variavel " << node->operando << "\n";
        ss << "    VPOP.F64 {D0}\n";
        ss << "    LDR R0, =" << variaveis.at(node->operando) << "\n";
        ss << "    " << node->opcode << " D0, [R0]\n\n";
        break;

    case ASTNodeType::MEMORIA_RES:
        // Emite o indice N (filho), depois resolve offset no historico.
        if (!node->filhos.empty())
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
        ss << "    @ Operador RES: Busca historico na memoria\n";
        ss << "    VPOP.F64 {D0}           @ Pega o N da pilha\n";
        ss << "    VCVT.S32.F64 S0, D0     @ Converte N de Double para Inteiro\n";
        ss << "    VMOV R1, S0             @ MOV N pro R1\n";
        ss << "    LSL R1, R1, #3          @ Multiplica N por 8 bytes (descobrir o offset)\n";
        ss << "    ADD R2, R10, R1         @ Soma o offset com o R10 para achar o endereco antigo\n";
        ss << "    VLDR.F64 D1, [R2]       @ Le o historico da RAM\n";
        ss << "    VPUSH.F64 {D1}          @ PUSH pilha\n\n";
        break;

    case ASTNodeType::INSTRUCAO_VFP:
        // Pos-ordem: emite os dois operandos primeiro, depois o operador.
        if (node->filhos.size() >= 2)
        {
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
            emitirNo(node->filhos[1], ss, literais, variaveis, contadorLabel);
        }

        // Operadores de instrucao unica: usa diretamente node->opcode.
        if (node->opcode == "VADD.F64")
        {
            ss << "    @ Soma\n";
            ss << "    VPOP.F64 {D1}           @ POP operando B\n";
            ss << "    VPOP.F64 {D0}           @ POP operando A\n";
            ss << "    VADD.F64 D2, D0, D1     @ A + B\n";
            ss << "    VPUSH.F64 {D2}          @ PUSH pilha\n\n";
        }
        else if (node->opcode == "VSUB.F64")
        {
            ss << "    @ Subtracao\n";
            ss << "    VPOP.F64 {D1}           @ POP operando B\n";
            ss << "    VPOP.F64 {D0}           @ POP operando A\n";
            ss << "    VSUB.F64 D2, D0, D1     @ A - B\n";
            ss << "    VPUSH.F64 {D2}          @ PUSH pilha\n\n";
        }
        else if (node->opcode == "VMUL.F64")
        {
            ss << "    @ Multiplicacao\n";
            ss << "    VPOP.F64 {D1}           @ POP B\n";
            ss << "    VPOP.F64 {D0}           @ POP A\n";
            ss << "    VMUL.F64 D2, D0, D1     @ D2 = A * B\n";
            ss << "    VPUSH.F64 {D2}          @ PUSH\n\n";
        }
        else if (node->opcode == "VDIV.F64")
        {
            ss << "    @ Divisao Real (|)\n";
            ss << "    VPOP.F64 {D1}           @ POP B\n";
            ss << "    VPOP.F64 {D0}           @ POP A\n";
            ss << "    VDIV.F64 D2, D0, D1     @ D2 = A / B\n";
            ss << "    VPUSH.F64 {D2}          @ PUSH\n\n";
        }
        // Operadores compostos: sequencias de VFP.
        else if (node->opcode == "DIV_INT")
        {
            ss << "    @ Divisao Inteira (/)\n";
            ss << "    VPOP.F64 {D1}           @ POP B\n";
            ss << "    VPOP.F64 {D0}           @ POP A\n";
            ss << "    VDIV.F64 D2, D0, D1     @ D2 = A / B\n";
            ss << "    VCVT.S32.F64 S4, D2     @ Trunca o resultado para inteiro\n";
            ss << "    VCVT.F64.S32 D2, S4     @ Converte de volta para Double (sem decimais)\n";
            ss << "    VPUSH.F64 {D2}          @ PUSH\n\n";
        }
        else if (node->opcode == "MOD_INT")
        {
            ss << "    @ Modulo (%)\n";
            ss << "    VPOP.F64 {D1}           @ POP B\n";
            ss << "    VPOP.F64 {D0}           @ POP A\n";
            ss << "    VDIV.F64 D2, D0, D1     @ D2 = A / B\n";
            ss << "    VCVT.S32.F64 S4, D2     @ S4 = parte inteira de (A/B)\n";
            ss << "    VCVT.F64.S32 D3, S4     @ D3 = parte inteira em Double\n";
            ss << "    VMUL.F64 D4, D1, D3     @ D4 = B * parte_inteira(A/B)\n";
            ss << "    VSUB.F64 D5, D0, D4     @ D5 = A - D4 (sobra o resto)\n";
            ss << "    VPUSH.F64 {D5}          @ PUSH Resto\n\n";
        }
        else if (node->opcode == "POW")
        {
            int id = contadorLabel++;
            ss << "    @ Potenciacao (^)\n";
            ss << "    VPOP.F64 {D1}           @ POP B (Expoente)\n";
            ss << "    VPOP.F64 {D0}           @ POP A (Base)\n";
            ss << "    VCVT.S32.F64 S2, D1     @ Converte expoente para inteiro (S2)\n";
            ss << "    VMOV R4, S2             @ Move expoente para R4 (Contador de Hardware)\n";
            ss << "    LDR R5, =LIT_ONE_POW    @ Carrega ponteiro do 1.0\n";
            ss << "    VLDR.F64 D2, [R5]       @ D2 = 1.0 (Acumulador neutro)\n";
            ss << "pow_loop_" << id << ":\n";
            ss << "    CMP R4, #0              @ Verifica se o contador e <= 0\n";
            ss << "    BLE pow_end_" << id << "   @ Quebra o laco se o expoente esgotar\n";
            ss << "    VMUL.F64 D2, D2, D0     @ Acumula: D2 = D2 * Base\n";
            ss << "    SUB R4, R4, #1          @ Decrementa contador\n";
            ss << "    B pow_loop_" << id << "    @ Retorna pro laco\n";
            ss << "pow_end_" << id << ":\n";
            ss << "    VPUSH.F64 {D2}          @ PUSH resultado\n\n";
        }
        break;

    case ASTNodeType::INSTRUCAO_CMP:
        // logica de controle e saltos do programa VCMP.F64 + VMRS + execucao condicional dentro de IFELSE/WHILE
        // Na aritmetica funcional apenas preserva os efeitos colaterais dos operandos
        if (node->filhos.size() >= 2)
        {
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
            emitirNo(node->filhos[1], ss, literais, variaveis, contadorLabel);
            ss << "    @ Comparacao FPU\n";
            ss << "    VPOP.F64 {D1}           @ Operando B\n";
            ss << "    VPOP.F64 {D0}           @ Operando A\n";
            ss << "    VCMP.F64 D0, D1         @ Compara A com B\n";
            ss << "    VMRS APSR_nzcv, FPSCR   @ Transfere Flags da FPU para o processador\n\n";
        }
        break;

    case ASTNodeType::COMANDO_IFELSE:
    {
        int id = contadorLabel++;

        // 1. Emite a condicao e salta para o ELSE se ela for FALSA
        //    Trata tanto condicao relacional quanto booleana generica
        emitirCondicaoSalto(node->filhos[0], "else_label_" + std::to_string(id),
                            ss, literais, variaveis, contadorLabel);

        // 2. Bloco THEN
        emitirNo(node->filhos[1], ss, literais, variaveis, contadorLabel);
        ss << "    B end_if_" << id << "\n";

        ss << "else_label_" << id << ":\n";
        if (node->filhos.size() > 2)
            emitirNo(node->filhos[2], ss, literais, variaveis, contadorLabel);

        ss << "end_if_" << id << ":\n\n";
        break;
    }
    case ASTNodeType::COMANDO_WHILE:
    {
        int id = contadorLabel++;

        ss << "while_start_" << id << ":\n";

        // 1. Emite a condicao e salta para o FIM se ela for FALSA
        //    Trata tanto condicao relacional quanto booleana generica
        emitirCondicaoSalto(node->filhos[0], "while_end_" + std::to_string(id),
                            ss, literais, variaveis, contadorLabel);

        // 2. Corpo do laço
        emitirNo(node->filhos[1], ss, literais, variaveis, contadorLabel);

        // 3. Retorno ao início
        ss << "    B while_start_" << id << "\n";
        ss << "while_end_" << id << ":\n\n";
        break;
    }
    case ASTNodeType::INSTRUCAO_BITWISE:
    {
        if (node->filhos.size() >= 2)
        {
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
            emitirNo(node->filhos[1], ss, literais, variaveis, contadorLabel);
        }
        
        ss << "    @ Operacao Bitwise Binaria: " << node->operando << "\n";
        ss << "    VPOP.F64 {D1}           @ POP operando B\n";
        ss << "    VPOP.F64 {D0}           @ POP operando A\n";
        ss << "    VCVT.S32.F64 S2, D0     @ Converte A para inteiro (S2)\n";
        ss << "    VCVT.S32.F64 S3, D1     @ Converte B para inteiro (S3)\n";
        ss << "    VMOV R0, S2             @ R0 = A (inteiro)\n";
        ss << "    VMOV R1, S3             @ R1 = B (inteiro)\n";
        
        // Aplica a operação bitwise no registrador ARM
        if (node->opcode == "AND")
            ss << "    AND R2, R0, R1          @ R2 = R0 AND R1\n";
        else if (node->opcode == "ORR")
            ss << "    ORR R2, R0, R1          @ R2 = R0 OR R1\n";
        else if (node->opcode == "EOR")
            ss << "    EOR R2, R0, R1          @ R2 = R0 XOR R1\n";
        else if (node->opcode == "LSL")
            ss << "    LSL R2, R0, R1          @ R2 = R0 << R1 (Shift Left)\n";
        else if (node->opcode == "LSR")
            ss << "    LSR R2, R0, R1          @ R2 = R0 >> R1 (Shift Right)\n";
            
        ss << "    VMOV S4, R2             @ Move resultado R2 para FPU\n";
        ss << "    VCVT.F64.S32 D2, S4     @ Converte resultado para Double\n";
        ss << "    VPUSH.F64 {D2}          @ PUSH pilha\n\n";
        break;
    }
    case ASTNodeType::INSTRUCAO_BITWISE_NOT:
    {
        if (!node->filhos.empty())
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
            
        ss << "    @ Operacao Bitwise Unaria: NOT\n";
        ss << "    VPOP.F64 {D0}           @ POP operando A\n";
        ss << "    VCVT.S32.F64 S2, D0     @ Converte A para inteiro (S2)\n";
        ss << "    VMOV R0, S2             @ R0 = A (inteiro)\n";
        ss << "    MVN R1, R0              @ R1 = NOT R0\n";
        ss << "    VMOV S4, R1             @ Move resultado R1 para FPU\n";
        ss << "    VCVT.F64.S32 D1, S4     @ Converte resultado para Double\n";
        ss << "    VPUSH.F64 {D1}          @ PUSH pilha\n\n";
        break;
    }
    case ASTNodeType::COMANDO_WRITE:
    {
        if (node->filhos.size() >= 2)
        {
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
            emitirNo(node->filhos[1], ss, literais, variaveis, contadorLabel);
        }
        
        ss << "    @ Comando WRITE\n";
        ss << "    VPOP.F64 {D1}           @ POP endereco (Double)\n";
        ss << "    VPOP.F64 {D0}           @ POP valor (Double)\n";
        ss << "    VCVT.U32.F64 S2, D1     @ Converte endereco para inteiro (unsigned)\n";
        ss << "    VCVT.S32.F64 S3, D0     @ Converte valor para inteiro\n";
        ss << "    VMOV R1, S2             @ R1 = endereco\n";
        ss << "    VMOV R0, S3             @ R0 = valor\n";
        ss << "    STR R0, [R1]            @ Escreve valor na memoria/periferico\n\n";
        break;
    }
    case ASTNodeType::COMANDO_DELAY:
    {
        if (!node->filhos.empty())
            emitirNo(node->filhos[0], ss, literais, variaveis, contadorLabel);
            
        int id = contadorLabel++;
        ss << "    @ Comando DELAY (Private Timer)\n";
        ss << "    VPOP.F64 {D0}           @ POP tempo em ms\n";
        ss << "    VCVT.S32.F64 S2, D0     @ Converte ms para inteiro\n";
        ss << "    VMOV R0, S2             @ R0 = ms\n";
        
        // 1 ms = 200.000 ciclos no A9 Private Timer
        ss << "    LDR R1, =200000         @ Frequencia base (200 MHz / 1000)\n";
        ss << "    MUL R2, R0, R1          @ R2 = total de ciclos do timer\n";
        ss << "    LDR R3, =0xFFFEC600     @ Endereco do A9 Private Timer\n";
        ss << "    STR R2, [R3]            @ Define o valor de LOAD do timer\n";
        
        // Habilita o timer (Control Register bit 0 = 1, sem auto-reload ou interrupcoes)
        // Control register fica no offset 8. Para evitar offset no STR, fazemos ADD R4, R3, #8
        ss << "    MOV R1, #1\n";
        ss << "    ADD R4, R3, #8          @ R4 = Control Register\n";
        ss << "    STR R1, [R4]            @ Inicia o timer\n";
        
        // Loop de espera ativa (Polling)
        // Interrupt Status Register fica no offset 12. Fazemos ADD R4, R3, #12
        ss << "    ADD R4, R3, #12         @ R4 = Interrupt Status Register\n";
        ss << "delay_loop_" << id << ":\n";
        ss << "    LDR R1, [R4]            @ Le o Interrupt Status Register\n";
        ss << "    TST R1, #1              @ Verifica bit de estouro (bit 0)\n";
        ss << "    BEQ delay_loop_" << id << "  @ Continua esperando se 0\n";
        
        // Limpa a flag de estouro (escrevendo 1 no Interrupt Status Register) e desliga o timer
        ss << "    MOV R1, #1\n";
        ss << "    STR R1, [R4]            @ Reseta flag de interrupcao\n";
        ss << "    MOV R1, #0\n";
        ss << "    ADD R5, R3, #8          @ R5 = Control Register\n";
        ss << "    STR R1, [R5]            @ Desliga o timer\n\n";
        break;
    }
    case ASTNodeType::SEQUENCIA:
        // logica de controle de emissao completa com labels proprios (contadorLabel reservado)
        // Na aritmetica funcional apenas emite os filhos para preservar efeitos (STORE/RES)
        for (ASTNode *filho : node->filhos)
            emitirNo(filho, ss, literais, variaveis, contadorLabel);
        break;
    }
}

// recebe a raiz da AST e emite Assembly ARMv7 VFP
void gerarAssembly(ASTNode *arvore, std::string &codigoAssembly)
{
    codigoAssembly.clear();
    if (arvore == nullptr)
        return;

    // Analise estatica -- coleta literais/variaveis para a secao .data.
    std::map<std::string, std::string> literais;
    std::map<std::string, std::string> variaveis;
    int contagemLiterais = 0;
    coletarLiteraisVariaveis(arvore, literais, variaveis, contagemLiterais);

    std::stringstream ss;

    // Diretivas do compilador Assembly
    ss << "    .syntax unified\n\n";

    // Secao .data: reserva de memoria RAM
    ss << "    .data\n";
    ss << "    STACK_RES: .space 8000      @ Pilha para guardar os 1000 ultimos resultados\n";
    ss << "    STACK_RES_TOP:              @ Topo da pilha\n";
    ss << "    LIT_ONE_POW: .double 1.0    @ Constante 1 para o acumulador da potenciacao\n";

    // Literais numericos lidos do arquivo .txt
    for (const auto &p : literais)
        ss << "    " << p.second << ": .double " << formatarDouble(p.first) << "\n";
    // Variaveis inicializadas em 0.0
    for (const auto &p : variaveis)
        ss << "    " << p.second << ": .double 0.0\n";

    // Secao .text: codigo executavel
    ss << "\n    .text";
    ss << "\n    .global _start\n";
    ss << "_start:\n\n";

    ss << "    @ Inicializa o Stack Pointer alinhado em 8 bytes para VFP\n";
    ss << "    LDR SP, =0x3FFFFFF8\n\n";

    ss << "    @ Inicializa o RESult stackpointer\n";
    ss << "    LDR R10, =STACK_RES_TOP\n\n";

    ss << "    @ Percorre a AST em pos-ordem (equivale a avaliacao RPN)\n";

    // Walker recursivo pos-ordem
    int contadorLabel = 0;
    emitirNo(arvore, ss, literais, variaveis, contadorLabel);

    // Sem display automatico: para mostrar algo nos LEDs, use WRITE no RPN.
    // No fim, trava num laco vazio para nao executar lixo de memoria.
    ss << "    @ Fim do programa\n";
    ss << "_fim_programa:\n";
    ss << "    B _fim_programa         @ Halt\n";

    codigoAssembly = ss.str();
}
