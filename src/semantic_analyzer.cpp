// Integrantes do grupo (ordem alfabetica):
// Lucas Franco de Mello - luk4w
// Nome do grupo no Canvas: RA3 2

#include "semantic_analyzer.hpp"
#include "cli_controller.hpp"
#include "fsm_scanner.hpp"
#include <stdexcept>
#include <fstream>
#include <iomanip>

std::vector<std::string> removerComentarios(const std::vector<std::string> &linhas, std::vector<ErroAnalise> &erros)
{
    std::vector<std::string> resultado(linhas.size());
    bool dentro = false;
    int linha_abertura = -1;

    for (size_t i = 0; i < linhas.size(); ++i)
    {
        const std::string &linha = linhas[i];
        std::string &saida = resultado[i];
        saida.reserve(linha.size());
        int numero_linha = (int)(i + 1);

        size_t pos = 0;
        while (pos < linha.size())
        {
            if (!dentro) // nao ta dentro do comentario
            {
                // detectar a abertura de comentario *{
                if (pos + 1 < linha.size() && linha[pos] == '*' && linha[pos + 1] == '{')
                {
                    dentro = true;
                    linha_abertura = numero_linha;
                    saida += "  "; // preservar a largura para manter posicoes de erro
                    pos += 2;
                }
                // detecta fechamento sem abertura correspondente }*
                else if (pos + 1 < linha.size() && linha[pos] == '}' && linha[pos + 1] == '*')
                {
                    erros.push_back(ErroAnalise{numero_linha, "LEXICO",
                                                "fechamento de comentario '}*' sem abertura '*{' correspondente"});
                    saida += "  ";
                    pos += 2;
                }
                else
                {
                    saida += linha[pos];
                    pos++;
                }
            }
            else // dentro do comentario
            {
                // detectar fechamento }*
                if (pos + 1 < linha.size() && linha[pos] == '}' && linha[pos + 1] == '*')
                {
                    dentro = false;
                    linha_abertura = -1;
                    saida += "  ";
                    pos += 2;
                }
                else
                {
                    saida += ' '; // substitui conteúdo do comentario por espaços
                    pos++;
                }
            }
        }
    }

    if (dentro)
    {
        // erro de comentario mal formado sem fechar
        erros.push_back(ErroAnalise{linha_abertura, "LEXICO",
                                    "comentario '*{' aberto na linha " + std::to_string(linha_abertura) +
                                        " nao foi fechado com '}*'"});
    }

    return resultado;
}

std::vector<std::string> prepararEntradaSemantica(const std::string &arquivo, std::vector<ErroAnalise> &erros)
{
    std::vector<std::string> linhas;
    lerArquivo(arquivo, linhas); // lança exceção se o arquivo nao existir ou estiver vazio

    // Remove comentarios *{ }* antes de tokenizar
    std::vector<std::string> linhas_limpas = removerComentarios(linhas, erros);

    // Tokeniza cada linha limpa, acumulando erros léxicos sem interromper
    std::vector<std::string> tokens;
    for (size_t i = 0; i < linhas_limpas.size(); ++i)
    {
        size_t marca = tokens.size();
        try
        {
            parseExpressao(linhas_limpas[i], tokens, (int)(i + 1));
        }
        catch (const std::exception &e)
        {
            tokens.resize(marca); // descarta tokens parciais da linha com erro
            std::string msg = e.what();
            while (!msg.empty() && (msg.back() == '\n' || msg.back() == '\r'))
                msg.pop_back();
            erros.push_back(ErroAnalise{(int)(i + 1), "LEXICO", msg});
        }
    }

    return tokens;
}

void construirTabelaSimbolos(ASTNode *raiz, TabelaSimbolos &tabela, std::vector<ErroAnalise> &erros)
{
    if (!raiz)
        return;

    // Se for um STORE (V MEM)
    if (raiz->tipo == ASTNodeType::MEMORIA_STORE)
    {
        std::string nome = raiz->operando;
        if (tabela.find(nome) == tabela.end())
        {
            // Primeira vez que o comp viu a variavel define
            tabela[nome] = {nome, TipoDado::DESCONHECIDO, raiz->linha, {}, true};
        }
        else
        {
            // reatribuicao -> uso/escrita
            tabela[nome].inicializada = true;
            tabela[nome].linhasUso.push_back(raiz->linha);
        }
    }
    // Se for um LOAD (MEM)
    else if (raiz->tipo == ASTNodeType::MEMORIA_LOAD)
    {
        std::string nome = raiz->operando;
        // rerificar se é uma palavra reservada
        if (nome != "TRUE" && nome != "FALSE")
        {
            if (tabela.find(nome) == tabela.end() || !tabela[nome].inicializada)
            {
                // nao devem entrar na tabela como variaveis
                erros.push_back(ErroAnalise{raiz->linha, "SEMANTICO",
                                            "Variavel '" + nome + "' usada sem ser definida previamente com (V " + nome + ")"});
                // Registra mesmo com erro para evitar erros duplicados
                if (tabela.find(nome) == tabela.end())
                    tabela[nome] = {nome, TipoDado::DESCONHECIDO, -1, {raiz->linha}, false};
            }
            else
            {
                tabela[nome].linhasUso.push_back(raiz->linha);
            }
        }
    }

    // recursao nos filhos para garantir que toda a arvore seja processada
    for (ASTNode *filho : raiz->filhos)
    {
        construirTabelaSimbolos(filho, tabela, erros);
    }
}

void exportarTabelaSimbolos(const TabelaSimbolos &tabela, const std::string &arquivo)
{
    std::ofstream out(arquivo);
    if (!out.is_open())
        return;

    out << "# Tabela de Símbolos\n\n";
    out << "| Variável | Tipo | Linha Definição | Linhas de Uso |\n";
    out << "|----------|------|-----------------|---------------|\n";

    for (const auto &[nome, sim] : tabela)
    {
        std::string tipoStr;
        switch (sim.tipo)
        {
        case TipoDado::INT: tipoStr = "INT"; break;
        case TipoDado::REAL: tipoStr = "REAL"; break;
        case TipoDado::BOOL: tipoStr = "BOOL"; break;
        default: tipoStr = "DESCONHECIDO"; break;
        }

        std::string linhasUso;
        for (size_t i = 0; i < sim.linhasUso.size(); ++i)
        {
            linhasUso += std::to_string(sim.linhasUso[i]);
            if (i < sim.linhasUso.size() - 1)
                linhasUso += ", ";
        }

        out << "| " << nome << " | " << tipoStr << " | "
            << (sim.linhaDefinicao != -1 ? std::to_string(sim.linhaDefinicao) : "N/A")
            << " | " << (linhasUso.empty() ? "-" : linhasUso) << " |\n";
    }

    out.close();
}
