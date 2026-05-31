# ANALISADOR SEMÂNTICO

Lucas Franco de Mello - luk4w
Nome do grupo no Canvas: RA3 2

Instituição: Pontifícia Universidade Católica do Paraná (PUCPR)  
Disciplina: Linguagens Formais e Compiladores
Professor: Frank de Alcantara  
Ano: 2026

> Devido a plataforma do github não permitir a criação de repositórios com espaços, o nome do grupo foi alterado para RA3_2, no entanto, o nome real do grupo é RA3 2.

O `ANALISADOR SEMÂNTICO` é a terceira fase do projeto da disciplina de `Linguagens Formais e Compiladores` ministrada pelo professor `Frank de Alcantara` na `Pontifícia Universidade Católica do Paraná`.

## Instruções de Compilação e Execução

A infraestrutura de *build* deste projeto é orquestrada pelo **CMake**, e garante uma compilação modular e reprodutível. Como o desenvolvimento tem como alvo principal o ambiente Windows, as instruções abaixo utilizam a *toolchain* do **MSVC** (Microsoft Visual C++) integrada ao **Visual Studio Code**.

#### Pré-requisitos do Ambiente
Certifique-se de ter os seguintes componentes instalados:
* **Compilador:** Ferramentas de Build do Visual Studio Community 2022 (ou superior) com suporte para desenvolvimento em C++23.
* **Editor:** Visual Studio Code.
* **Extensões (Visual Studio Code):**
  * `C/C++` (Microsoft)
  * `CMake Tools` (Microsoft)

#### Metodo 1: Compilação via Visual Studio Code
A extensão [CMake Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools) automatiza o os comandos de configuração e construção, simplificando o processo. Siga os passos abaixo:

1. Abra a pasta raiz do projeto no Visual Studio Code (`File > Open Folder...`).
2. A extensão identificará o arquivo `CMakeLists.txt` então, através da paleta de comandos `Ctrl+Shift+p`, ou o atalho que você configurou, selecione um **Kit** de compilação, escolha a arquitetura nativa do MSVC (ex: `Visual Studio Community 2022 Release - x86_amd64`).
3. Aguarde o processo de configuração (*Configuring*) terminar. O CMake irá gerar a árvore de diretórios e o *cache* de compilação.
4. Utilize o atalho `Ctrl+Shift+p` para abrir a paleta de comandos, e execute `CMake: Build` para iniciar a compilação do projeto.
5. Se não houver erros, o executável final (`AnalisadorSemantico.exe`) será gerado dentro do diretório `build/Debug/` (ou `build/Release/`), dependendo da configuração selecionada.

### Execução

O programa recebe **um único argumento**: o caminho de um arquivo de teste `.txt` contendo o programa em RPN (uma expressão por linha, entre `(START)` e `(END)`).

A partir do diretório onde está o executável:

```powershell
.\AnalisadorSemantico.exe .\teste.txt
```

Exemplos usando os arquivos de teste fornecidos na pasta `tests/`:

```powershell
# Programa valido (gera ast_saida.json e saida.s)
.\AnalisadorSemantico.exe ..\..\tests\teste1.txt

# Programa com erros (exibe o relatório de erros e NÃO gera assembly)
.\AnalisadorSemantico.exe ..\..\tests\teste_erro_sintatico.txt
```

> Nota: ajustar o caminho relativo (`..\..\tests\`).

**Saídas geradas** (no diretório de execução), quando o programa não contém erros:

| Arquivo | Descrição |
| :--- | :--- |
| `tokens.txt` | Vetor de tokens da última execução (saída do analisador léxico). |
| `ast_saida.json` | Árvore Sintática Abstrata (AST) serializada em JSON. |
| `saida.s` | Código Assembly ARMv7 gerado a partir da AST. |

Se o programa **contém erros**, é exibido um **relatório de erros** (com tipo `LEXICO`/`SINTATICO`/`SEMANTICO` e número da linha) e nenhum código Assembly é gerado — o processo encerra com código de saída `1`.

### Sintaxe das Estruturas de Controle

A linguagem mantém a notação polonesa reversa (RPN) para todas as estruturas. Os operandos sempre precedem a keyword que os opera.

#### Tomada de Decisão — `IFELSE`

Requer **3 operandos** antes da keyword: condição, bloco verdadeiro e bloco falso.

```
( (condição) (bloco_verdadeiro) (bloco_falso) IFELSE )
```

**Exemplo** — se `A > B`, retorna `A + B`, senão retorna `A - B`:
```
( (A B >) (A B +) (A B -) IFELSE )
```

A condição deve ser uma expressão que resulte em valor comparável via operador relacional (`<`, `>`, `==`, `!=`, `<=`, `>=`). Ambos os blocos são obrigatórios.

#### Laço de Repetição — `WHILE`

Requer **2 operandos** antes da keyword: condição e bloco de repetição.

```
( (condição) (bloco_repeticao) WHILE )
```

**Exemplo** — enquanto `CONTADOR < 10`, soma `1` ao contador e armazena:
```
( ((CONTADOR) 10 <) (((CONTADOR) 1 +) CONTADOR) WHILE )
```

O laço avalia a condição antes de cada iteração. Quando a condição resulta em falso, a execução continua na linha seguinte ao `WHILE`.

### Comandos Especiais (Manipulação de Memória e Histórico)

A linguagem suporta operações de estado utilizando as palavras reservadas `RES` e identificadores arbitrários para variáveis (`MEM`). A sintaxe segue a notação polonesa reversa:

#### Leitura de Histórico `RES`: `(N RES)`
Retorna o valor computado `N` expressões atrás no histórico da FPU. O índice `N` deve ser um inteiro não negativo, onde `0` representa o último resultado avaliado. Exemplo:
```
(0 RES)
```
Carrega o resultado imediatamente anterior.

#### Escrita em Memória `STORE`: `(V MEM)`
Armazena o valor `V` (que pode ser um literal numérico ou o resultado de uma expressão aninhada) na variável identificada por `MEM`. Exemplos:
```
(10.5 CONTADOR)
```
```
((5 2 +) X)
```

#### Leitura de Memória `LOAD`: `(MEM)`
Carrega na pilha da FPU o valor atual armazenado na variável identificada. Se a variável não houver sido inicializada, o valor padrão retornado é `0.0`. Exemplo:
```
((CONTADOR) 1 +)
```

## Gramática EBNF LL(1) Fatorada

Para garantir que o Analisador SEMÂNTICO opere de forma determinística, a gramática em Notação Polonesa Reversa (RPN) foi submetida à Fatoração à Esquerda. Isso eliminou os conflitos de derivação, e resultou na seguinte estrutura formal:

**Regras de Produção:**
1. `programa -> PARENTESE_ESQ START PARENTESE_DIR sequencia_execucao`
2. `sequencia_execucao -> PARENTESE_ESQ avaliacao_sequencia`
3. `avaliacao_sequencia -> END PARENTESE_DIR | corpo_expressao PARENTESE_DIR sequencia_execucao`
4. `expressao_aninhada -> PARENTESE_ESQ corpo_expressao PARENTESE_DIR`
5. `operando -> NUMERO | expressao_aninhada`
6. `corpo_expressao -> operando complemento_expressao | IDENTIFICADOR`
7. `complemento_expressao -> operando operacao | IDENTIFICADOR | RES | ε`
8. `operacao -> OPERADOR | OPERADOR_RELACIONAL | operando IFELSE | WHILE`

### Dicionário de Símbolos

**Terminais (Tokens):**
`PARENTESE_ESQ`, `PARENTESE_DIR`, `START`, `END`, `NUMERO`, `IDENTIFICADOR`, `OPERADOR`, `OPERADOR_RELACIONAL`, `IFELSE`, `WHILE`

**Não-Terminais (Variáveis da AST):**
`programa`, `sequencia_execucao`, `avaliacao_sequencia`, `expressao_aninhada`, `operando`, `corpo_expressao`, `complemento_expressao`, `operacao`

### Conjuntos FIRST e FOLLOW

O cálculo teórico exigido para provar a ausência de conflitos ambíguos na árvore sintática:

#### Conjuntos FIRST
* **FIRST(programa)** = { `PARENTESE_ESQ` }
* **FIRST(sequencia_execucao)** = { `PARENTESE_ESQ` }
* **FIRST(avaliacao_sequencia)** = { `END`, `IDENTIFICADOR`, `NUMERO`, `PARENTESE_ESQ` }
* **FIRST(expressao_aninhada)** = { `PARENTESE_ESQ` }
* **FIRST(operando)** = { `NUMERO`, `PARENTESE_ESQ` }
* **FIRST(corpo_expressao)** = { `IDENTIFICADOR`, `NUMERO`, `PARENTESE_ESQ` }
* **FIRST(complemento_expressao)** = { `IDENTIFICADOR`, `NUMERO`, `PARENTESE_ESQ`, `RES`, `ε` }
* **FIRST(operacao)** = { `NUMERO`, `OPERADOR`, `OPERADOR_RELACIONAL`, `PARENTESE_ESQ`, `WHILE` }

#### Conjuntos FOLLOW
* **FOLLOW(programa)** = { `$` }
* **FOLLOW(sequencia_execucao)** = { `$` }
* **FOLLOW(avaliacao_sequencia)** = { `$` }
* **FOLLOW(expressao_aninhada)** = { `IDENTIFICADOR`, `IFELSE`, `NUMERO`, `OPERADOR`, `OPERADOR_RELACIONAL`, `PARENTESE_ESQ`, `RES`, `WHILE` }
* **FOLLOW(operando)** = { `IDENTIFICADOR`, `IFELSE`, `NUMERO`, `OPERADOR`, `OPERADOR_RELACIONAL`, `PARENTESE_ESQ`, `RES`, `WHILE` }
* **FOLLOW(corpo_expressao)** = { `PARENTESE_DIR` }
* **FOLLOW(complemento_expressao)** = { `PARENTESE_DIR` }
* **FOLLOW(operacao)** = { `PARENTESE_DIR` }

### Tabela de Parsing LL(1)

A tabela LL(1) serve para guiar o parser preditivo descendente na determinação de qual regra gramatical (produção) deve ser aplicada a seguir, sem precisar de backtracking.

Células vazias indicam erro SEMÂNTICO. $\epsilon$ indica derivação para vazio.

#### Formato compacto
`M[Não-terminal, Terminal] = Produção`
```
M[avaliacao_sequencia, END] = { END PARENTESE_DIR }
M[avaliacao_sequencia, IDENTIFICADOR] = { corpo_expressao PARENTESE_DIR sequencia_execucao }
M[avaliacao_sequencia, NUMERO] = { corpo_expressao PARENTESE_DIR sequencia_execucao }
M[avaliacao_sequencia, PARENTESE_ESQ] = { corpo_expressao PARENTESE_DIR sequencia_execucao }
M[complemento_expressao, IDENTIFICADOR] = { IDENTIFICADOR }
M[complemento_expressao, NUMERO] = { operando operacao }
M[complemento_expressao, PARENTESE_DIR] = { EPSILON }
M[complemento_expressao, PARENTESE_ESQ] = { operando operacao }
M[complemento_expressao, RES] = { RES }
M[corpo_expressao, IDENTIFICADOR] = { IDENTIFICADOR }
M[corpo_expressao, NUMERO] = { operando complemento_expressao }
M[corpo_expressao, PARENTESE_ESQ] = { operando complemento_expressao }
M[expressao_aninhada, PARENTESE_ESQ] = { PARENTESE_ESQ corpo_expressao PARENTESE_DIR }
M[operacao, NUMERO] = { operando IFELSE }
M[operacao, OPERADOR] = { OPERADOR }
M[operacao, OPERADOR_RELACIONAL] = { OPERADOR_RELACIONAL }
M[operacao, PARENTESE_ESQ] = { operando IFELSE }
M[operacao, WHILE] = { WHILE }
M[operando, NUMERO] = { NUMERO }
M[operando, PARENTESE_ESQ] = { expressao_aninhada }
M[programa, PARENTESE_ESQ] = { PARENTESE_ESQ START PARENTESE_DIR sequencia_execucao }
M[sequencia_execucao, PARENTESE_ESQ] = { PARENTESE_ESQ avaliacao_sequencia }
```
 
#### Formato tabular
 
| Não-Terminal | `(` | `)` | `START` | `END` | `NUMERO` | `ID` | `OPERADOR` | `OP_REL` | `IFELSE` | `WHILE` | `RES` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **programa** | 1 | | | | | | | | | | |
| **sequencia_execucao** | 2 | | | | | | | | | | |
| **avaliacao_sequencia** | 3b | | | 3a | 3b | 3b | | | | | |
| **expressao_aninhada** | 4 | | | | | | | | | | |
| **operando** | 5b | | | | 5a | | | | | | |
| **corpo_expressao** | 6a | | | | 6a | 6b | | | | | |
| **complemento_expressao** | 7a | 7d | | | 7a | 7b | | | | | 7c |
| **operacao** | 8c | | | | 8c | | 8a | 8b | | 8d | |
 
#### Legenda
| Código | Produção |
| :--- | :--- |
| **1** | `PARENTESE_ESQ START PARENTESE_DIR sequencia_execucao` |
| **2** | `PARENTESE_ESQ avaliacao_sequencia` |
| **3a** | `END PARENTESE_DIR` |
| **3b** | `corpo_expressao PARENTESE_DIR sequencia_execucao` |
| **4** | `PARENTESE_ESQ corpo_expressao PARENTESE_DIR` |
| **5a** | `NUMERO` |
| **5b** | `expressao_aninhada` |
| **6a** | `operando complemento_expressao` |
| **6b** | `IDENTIFICADOR` |
| **7a** | `operando operacao` |
| **7b** | `IDENTIFICADOR` |
| **7c** | `RES` |
| **7d** | `ε` |
| **8a** | `OPERADOR` |
| **8b** | `OPERADOR_RELACIONAL` |
| **8c** | `operando IFELSE` |
| **8d** | `WHILE` |


## Tratamento e Recuperação de Erros

O analisador implementa **recuperação de erros** (*panic mode*) com granularidade de **linha**: ao encontrar um erro, ele **não interrompe** a análise no primeiro problema — registra o erro e prossegue, de modo a reportar **todos** os erros do programa em uma única execução.

### Fluxo de análise

1. **Análise léxica** — cada linha é tokenizada isoladamente. Se uma linha contém um erro léxico (ex.: número malformado `10..5`, operador inexistente `//`, caractere inválido `@`), o erro é registrado, os tokens parciais daquela linha são descartados e a análise segue para a próxima linha.
2. **Validação estrutural** — verifica-se que o programa possui as linhas obrigatórias `(START)` e `(END)`.
3. **Análise sintática** — executa **sempre**, mesmo que existam erros léxicos. Como as linhas lexicamente inválidas já tiveram seus tokens descartados, elas não chegam ao parser e **não geram erros SEMÂNTICOs falsos** (evitando o efeito *cascata*). Cada linha de expressão é analisada isoladamente: monta-se internamente um miniprograma `(START) <linha> (END)` e invoca-se o parser LL(1); se a linha falha, o erro é registrado e a análise continua na próxima linha.
4. **Relatório de erros** — todos os erros (léxicos e SEMÂNTICOs) são acumulados, **ordenados por número de linha** e exibidos juntos, indicando o tipo (`LEXICO`/`SINTATICO`), a linha e a mensagem.
5. **Gate de geração de código** — o código Assembly **só é gerado se não houver nenhum erro**. Havendo qualquer erro, o programa exibe o relatório e encerra com código de saída `1`, sem produzir `saida.s`.

### Mensagens de erro

As mensagens incluem sempre o **número da linha** e o **tipo** do erro. Exemplo de saída para um programa com múltiplos erros:

```
============================================================
 ERROS
------------------------------------------------------------
 Total: 3 lexicos, 2 sintaticos
------------------------------------------------------------
  Linha 2 | SINTATICO | Erro de sintaxe na linha 2: nenhuma regra em M[avaliacao_sequencia][OPERADOR] para o token '+'
  Linha 3 | LEXICO | Numero malformado na linha 3: 10..
  Linha 5 | LEXICO | Erro na linha 5 operador '//' nao existe. Use '/' para divisao inteira ou '|' para real.
  Linha 6 | LEXICO | Token invalido na linha 6 '@' na posicao 5
  Linha 8 | SINTATICO | Erro de sintaxe na linha 8: esperado 'PARENTESE_DIR', encontrado 'OPERADOR' (valor: '^')
============================================================
```

Os arquivos `tests/teste_erro_lexico.txt` e `tests/teste_erro_sintatico.txt` exercitam, respectivamente, a recuperação de erros léxicos e SEMÂNTICOs.


## Resultados

Para assegurar a conformidade com a norma IEEE 754 de 64 bits (Double Precision) exigida pelo edital, todos os resultados obtidos nos 32 LEDs do simulador foram submetidos a um processo de verificação cruzada.

#### Metodologia de Verificação

* **Cálculo Analítico:** Resolução manual da pilha RPN para determinar o valor decimal esperado de cada expressão.
* **Extração de Bits:** Captura dos estados lógicos dos LEDs (Palavra Alta e Palavra Baixa) a partir da injeção de JavaScript no DOM do CPULator. A montagem das palavras de 64 bits foi validada e comparada com a ferramenta online [BinaryConvert (Double Precision)](https://www.binaryconvert.com/result_double.html).

**Script de Captura (Bit Sniffer):**
```javascript
(function() {
    const leds = document.querySelectorAll('#devff200000 .dev_led_led');
    let binary = Array.from(leds)
        .map(led => led.classList.contains('dev_led_on') ? '1' : '0')
        .join('');
    let hex = parseInt(binary, 2).toString(16).toUpperCase().padStart(8, '0');
    console.log("%c ASMNATOR - Bit Sniffer ", "background: #222; color: #bada55; padding: 2px;");
    console.log("Binário (31-0): " + binary);
    console.log("Hexadecimal: 0x" + hex);
})();
```

#### Evidências de Teste (Casos de Sucesso)

A tabela abaixo detalha os testes realizados para validar a recursividade da gramática e a corretude do gerador de código para fluxos de controle e aritmética complexa.

| Caso de Teste | Expressão RPN Relevante | Resultado Esperado | Palavra Alta (Hex) | Palavra Baixa (Hex) | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Potência Recursiva (T2)** | `( ( ( ( 2 2 ^ ) 2 ^ ) 2 ^ ) )` | `256.0` | `0x40700000` | `0x00000000` |  OK |
| **Lógica Condicional (T3)** | `( ((0 RES) 500.0 >=) (512.0) (0.0) IFELSE )` | `512.0` | `0x40800000` | `0x00000000` |  OK |
| **Integração Final (T4)** | `( ((CONTADOR) 5 ==) (12 SAIDA) (2026 SAIDA) IFELSE )` | `12.0` | `0x40280000` | `0x00000000` |  OK |

#### Análise de Precisão IEEE 754

Tomando como exemplo o teste de **Lógica Condicional (T3)**, o valor decimal `512.0` é representado em hexadecimal de precisão dupla como `0x4080000000000000`. 
1. Ao pressionar **KEY1**, o simulador exibe a Palavra Alta: `0x40800000`.
2. Ao pressionar **KEY0**, o simulador exibe a Palavra Baixa: `0x00000000`.

A coincidência bit-a-bit entre o cálculo teórico e a saída do hardware valida a implementação da FPU e a sincronização de flags via `VMRS`.

## Saídas da Última Execução

Os artefatos gerados pela última execução do compilador (`teste2.txt`) estão organizados no diretório [`output/`](output/):

| Arquivo | Descrição |
| :--- | :--- |
| [`output/ast_saida.json`](output/ast_saida.json) | Árvore Sintática Abstrata (AST) serializada em JSON, produzida pelo parser LL(1) a partir do arquivo de entrada mais recente. |
| [`output/saida.s`](output/saida.s) | Código Assembly ARMv7 gerado pelo backend (`armv7_generator`), pronto para execução no simulador CPUlator-ARMv7 DEC1-SOC (v16.1). |

A AST é gerada pela função `gerarArvore()` em `include/parser.hpp` e exportada via `exportarAST()` em `include/ast_exporter.hpp`. O assembly é produzido pela função `gerarAssembly()` em `include/armv7_generator.hpp`. Ambos os arquivos são sobrescritos a cada execução do programa na pasta `build/Release/` que está ignorada pelo `.gitignore`