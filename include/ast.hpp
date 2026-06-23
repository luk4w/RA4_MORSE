// Integrantes do grupo (ordem alfabetica):
// Lucas Franco de Mello - luk4w
// Nome do grupo no Canvas: RA3 2

#pragma once
#include <string>
#include <vector>

// Categorias para o gerador saber COMO navegar nos filhos
enum class ASTNodeType
{
    PROGRAMA,
    SEQUENCIA,
    INSTRUCAO_VFP,  // "VADD.F64" ou "VMUL.F64"
    MEMORIA_LOAD,   // "VLDR.F64", operando = "X"
    MEMORIA_STORE,  // "VSTR.F64", operando = "X"
    MEMORIA_RES,    // Historico de resultados (RES)
    NUMERO_LITERAL, // Folha da arvore, operando = "10.0"
    BOOL_LITERAL,   // Literal TRUE ou FALSE
    COMANDO_WHILE,
    COMANDO_IFELSE,
    INSTRUCAO_CMP,
    INSTRUCAO_BITWISE,     // binario inteiro: AND, OR, XOR, << (LSL), >> (LSR)
    INSTRUCAO_BITWISE_NOT, // unario inteiro: NOT (MVN)
    COMANDO_WRITE,         // (valor endereco WRITE) - escreve em registrador (void)
    COMANDO_DELAY          // (ms DELAY) - espera via A9 Private Timer (void)
};

enum class TipoDado
{
    DESCONHECIDO,
    INT,
    REAL,
    BOOL
};

struct ASTNode
{
    ASTNodeType tipo;
    TipoDado tipoDado = TipoDado::DESCONHECIDO;
    std::string opcode;   // "VADD.F64", "VDIV.F64"
    std::string operando; // "10.0", "VAR_X"
    int linha;            // Linha do código fonte

    std::vector<ASTNode *> filhos;

    // Construtor para facilitar a criacao de nos
    ASTNode(ASTNodeType t, int lin, std::string opc = "", std::string opnd = "") : tipo(t), linha(lin), opcode(opc), operando(opnd) {}

    // Destrutor para evitar memory leaks
    ~ASTNode()
    {
        for (ASTNode *filho : filhos)
        {
            delete filho;
        }
    }
};

// Alimenta a funcao gerarArvore()
struct ProducaoAplicada
{
    std::string nao_terminal; // Nao-terminal expandido // "operacao"
    std::vector<std::string> producao; // Regra aplicada // ["OPERADOR"]
};

struct Derivacao
{
    // Sequencia de producoes aplicadas durante o parsing LL(1)
    // Representa a "estrutura de derivacao"
    std::vector<ProducaoAplicada> producoes;

    // AST pre-construida atraves das acoes semanticas em RPN
    // Sera extraida por gerarArvore() conforme a secao 7.4
    ASTNode *raiz = nullptr;
};