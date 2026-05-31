// Integrantes do grupo (ordem alfabetica):
// Lucas Franco de Mello - luk4w
// Nome do grupo no Canvas: RA3 2

#pragma once
#include <vector>
#include <string>
#include <map>
#include <stack>
#include "ast.hpp"
#include "tokens.hpp"

// parsear(_tokens_, tabela_ll1) -> Estrutura de derivacao
// A derivacao contem a sequencia de producoes aplicadas e alimenta gerarArvore()
Derivacao parsear(const std::vector<TokenData> &tokens, const std::map<std::string, std::map<std::string, std::vector<std::string>>> &tabela_ll1);

// gerarArvore(derivacao) -> Arvore sintatica em formato estruturado
// Recebe a estrutura de derivacao produzida por parsear() e retorna a raiz da AST
ASTNode *gerarArvore(const Derivacao &derivacao);