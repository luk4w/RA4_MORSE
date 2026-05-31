// Integrantes do grupo (ordem alfabetica):
// Lucas Franco de Mello - luk4w
// Nome do grupo no Canvas: RA3 2

#pragma once
#include <string>
#include <vector>
#include "tokens.hpp"

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
