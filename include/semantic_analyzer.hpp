// Integrantes do grupo (ordem alfabetica):
// Lucas Franco de Mello - luk4w
// Nome do grupo no Canvas: RA3 2

#pragma once
#include <string>
#include <vector>
#include "tokens.hpp"

#include "ast.hpp"
#include <map>

/**
 * @brief Estrutura para representar um simbolo/variavel na tabela de simbolos.
 */
struct Simbolo
{
    std::string nome;
    TipoDado tipo;
    int linhaDefinicao;
    std::vector<int> linhasUso;
    bool inicializada = false;
};

/**
 * @brief Tabela de simbolos para mapear o nome da variavel para os dados
 */
using TabelaSimbolos = std::map<std::string, Simbolo>; // apelido para std::map<std::string, Simbolo>;

/**
 * @brief Remove comentarios *{ ... }* das linhas e preservar as posicoes
 * para nao mudar a numero da linha que acontece o erro
 * comentarios nao fechados geram um ErroAnalise do tipo LEXICO
 * @param linhas as linhas para remover os comentarios
 * @param erros struct para acumular todos os erros
 */
std::vector<std::string> removerComentarios(const std::vector<std::string> &linhas, std::vector<ErroAnalise> &erros);

/**
 * @brief Carrega o arquivo, remove comentarios *{ }* e tokeniza cada linha
 * Erros lexicos sao acumulados em `erros` sem interromper o processamento
 * Retorna os tokens brutos no formato "tipo,linha,valor"
 * @param arquivo caminho do arquivo fonte a ser carregado
 * @param erros struct para acumular todos os erros
 */
std::vector<std::string> prepararEntradaSemantica(const std::string &arquivo, std::vector<ErroAnalise> &erros);

/**
 * @brief Percorre a AST para construir a Tabela de simbolos e validar declaracoes
 * @param raiz Ponteiro para a raiz da AST
 * @param tabela Tabela de simbolos a ser preenchida
 * @param erros Vetor para acumular erros semânticos de declaração/uso
 */
void construirTabelaSimbolos(ASTNode *raiz, TabelaSimbolos &tabela, std::vector<ErroAnalise> &erros);

/**
 * @brief Exporta a tabela de simbolos para um arquivo Markdown
 */
void exportarTabelaSimbolos(const TabelaSimbolos &tabela, const std::string &arquivo);
