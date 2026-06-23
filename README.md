# Compilador RPN → ARMv7

Lucas Franco de Mello
PUCPR - Linguagens Formais e Compiladores - C++23.

Compilador para uma linguagem em **notação polonesa reversa (RPN)**. Pipeline completo:

**léxico (FSM)** → **sintático LL(1)** → **semântico (tipos)** → **Assembly ARMv7** → **hexadecimal (código de máquina)**.

O Assembly (`saida.s`) e o **hexadecimal** (`saida.hex`) são gerados para o processador **ARMv7 (v16.1)** simulado no [CPUlator DE1-SoC](https://cpulator.01xz.net/?sys=arm-de1soc). Os valores são tratados como `double` IEEE 754 (64 bits) na FPU.

O hexadecimal é produzido por um **montador interno** (`src/hex_emitter.cpp`): ele converte cada instrução do Assembly no seu opcode ARMv7 de 32 bits, sem depender de toolchain externa. As codificações de cada instrução foram validadas contra o `arm-none-eabi-as`.

## Build & Execução

Requer **CMake** + **MSVC** (VS Build Tools 2022, C++23). Pelo *Developer PowerShell for VS 2022*, na raiz:

```powershell
cmake -S . -B build
cmake --build build --config Release
```

Executável em `build\Release\AnalisadorSemantico.exe`. Recebe **um** argumento: o arquivo `.txt` com o programa RPN (uma expressão por linha, entre `(START)` e `(END)`).

```powershell
.\build\Release\AnalisadorSemantico.exe .\tests\teste1.txt
```

Os artefatos são escritos **no diretório de onde o programa é executado**.

### Saídas

| Arquivo | Quando | Conteúdo |
| :--- | :--- | :--- |
| `tokens.txt` | sempre | Vetor de tokens (saída do léxico). |
| `ast_inicial.json` | sem erros | AST **antes** da semântica (todos os nós `DESCONHECIDO`). |
| `ast_atribuida.json` | sem erros | AST **atribuída** (com `tipoDado` e `linha` por nó). |
| `saida.s` | sem erros | Assembly ARMv7. |
| `saida.hex` | sem erros | **Código de máquina**: uma palavra de 32 bits (hex) por linha, little-endian, contíguo a partir de `0x0`. |
| `TABELA_SIMBOLOS.md` | sem erros | Variáveis, tipos, linha de definição e usos. |
| `ERROS_SEMANTICOS.md` | sempre | Relatório de erros (vazio se válido). |

Havendo **qualquer** erro (léxico/sintático/semântico), o programa imprime o relatório, **não gera Assembly nem hexadecimal** e sai com código `1`.

### Carregar no CPUlator

O [CPUlator DE1-SoC](https://cpulator.01xz.net/?sys=arm-de1soc) tem duas opções:

- **Assembly** (`saida.s`): cole no editor e clique em *Compile and Load*.
- **Hexadecimal** (`saida.hex`): menu **Load memory from file** → selecione `saida.hex` e configure **endereço inicial `0`**, **tamanho do elemento `4 bytes`** e **base `hexadecimal`**. O *Load memory* não altera o PC, então garanta **PC = `0`** antes de executar.

Em ambos, para exibir valores nos LEDs ou em outros periféricos, use o comando `WRITE` no programa RPN. Ao final da execução o programa trava em um laço infinito (`B _fim_programa`).

## Linguagem (RPN)

Operandos sempre **precedem** o operador. Todas as estruturas seguem RPN.

### Tipos

Estática e fortemente tipada. **Sem coerção** implícita entre `int` e `real`; o tipo da variável é inferido no uso e **fixado** na primeira definição.

| Tipo | Literais |
| :--- | :--- |
| `int` | `42`, `1024` (sem ponto) |
| `real` | `3.14`, `10.0` (com ponto) |
| `bool` | `TRUE`, `FALSE` e relacionais |

### Operadores

| Operador | Operandos | Resultado |
| :--- | :--- | :--- |
| `+` `-` `*` | mesmo tipo numérico | mesmo tipo |
| `\|` divisão real | mesmo tipo numérico | `real` |
| `^` potência | base `int`/`real`, expoente `int` | tipo da base |
| `/` `%` divisão inteira, resto | só `int` | `int` |
| `< > <= >=` | mesmo tipo numérico | `bool` |
| `== !=` | mesmo tipo | `bool` |

### Estruturas e memória

| Construção | Sintaxe | Notas |
| :--- | :--- | :--- |
| Condicional | `( (cond) (verdadeiro) (falso) IFELSE )` | `cond` `bool`; ramos do mesmo tipo. |
| Laço | `( (cond) (corpo) WHILE )` | avalia `cond` antes de cada iteração. |
| Sequência/bloco | `( (A) (B) )` | executa `A`, depois `B`; permite vários comandos no corpo de um `WHILE`/`IFELSE`. A justaposição é **2 a 2** (limite LL(1)); para 3+ comandos, aninhe em pares: `( (A B) C )`. |
| Escrita memória | `(V MEM)` | define **e** inicializa a variável. |
| Leitura memória | `(MEM)` | erro semântico se nunca definida. |
| Histórico | `(N RES)` | resultado `N` expressões atrás (`0` = último). |
| Escrita periférico | `(valor endereço WRITE)` | converte ambos para **inteiro 32 bits** (`VCVT.S32.F64` para o valor, `VCVT.U32.F64` para o endereço) e executa `STR` no endereço. Os registradores ARM são de 32 bits, portanto apenas os 32 bits inferiores do valor convertido são escritos. |
| Atraso | `(ms DELAY)` | espera `ms` milissegundos usando o A9 Private Timer. |

```
( (A B >) (A B +) (A B -) IFELSE )          *{ se A>B então A+B senão A-B }*
( ((CONTADOR) 10 <) (((CONTADOR) 1 +) CONTADOR) WHILE )
(10 3 +)        *{ ok: int }*       (10 2.5 +)   *{ erro: mistura int/real }*
```

Comentários: `*{ ... }*`. Veja `tests/teste1.txt`..`teste4.txt` (válidos) e `tests/teste_erro_*.txt` (erros). Exemplos de I/O: `tests/mello_morse.txt` (nome "MELLO" em código Morse no LED) e `tests/piscar.txt` (pisca-pisca infinito com `WHILE` + `WRITE` + `DELAY`).

## Gramática LL(1)

Gramática **LL(1)** fatorada à esquerda e livre de conflitos. FIRST/FOLLOW e a tabela de parsing são **calculados dinamicamente** por `src/gramatica.cpp` e impressos no início de cada execução.

**Terminais:** `(` `)` `START` `END` `NUMERO` `IDENTIFICADOR` `OPERADOR` (`+ - * | / % ^`) · `OPERADOR_RELACIONAL` (`== != < > <= >=`) · `IFELSE` `WHILE` `RES` `TRUE` `FALSE`.
**Não-terminais:** `programa` `sequencia_execucao` `avaliacao_sequencia` `expressao_aninhada` `operando` `corpo_expressao` `complemento_expressao` `resto_complemento` `operacao`.

```ebnf
programa              = "(" , "START" , ")" , sequencia_execucao ;
sequencia_execucao    = "(" , avaliacao_sequencia ;
avaliacao_sequencia   = "END" , ")" | corpo_expressao , ")" , sequencia_execucao ;
expressao_aninhada    = "(" , corpo_expressao , ")" ;
operando              = NUMERO | TRUE | FALSE | IDENTIFICADOR | RES | expressao_aninhada ;
corpo_expressao       = operando , complemento_expressao ;
complemento_expressao = operando , resto_complemento | ε ;
resto_complemento     = operacao | ε ;
operacao              = OPERADOR | OPERADOR_RELACIONAL | WHILE | operando , "IFELSE" ;
```

A RPN é capturada por `corpo_expressao`: operandos precedem a operação; `operando → expressao_aninhada` permite aninhamento ilimitado.

### Atributos (gramática atribuída)

Cada construção gera um nó na AST (`ASTNode`) e recebe `tipoDado` em `verificarTipos`. `reduzirFrame` (`src/parser.cpp`) decide entre `MEMORIA_LOAD`/`MEMORIA_STORE` conforme o `IDENTIFICADOR` apareça sozinho ou após um valor.

| Forma RPN | Token / produção | Nó da AST | `tipoDado` |
|-----------|------------------|-----------|------------|
| `42`, `3.14` | `NUMERO` | `NUMERO_LITERAL` | `INT` sem ponto, `REAL` com ponto |
| `TRUE`, `FALSE` | `TRUE`/`FALSE` | `BOOL_LITERAL` | `BOOL` |
| `(MEM)` | `IDENTIFICADOR` isolado | `MEMORIA_LOAD` | tipo da variável na tabela |
| `(V MEM)` | `operando IDENTIFICADOR` | `MEMORIA_STORE` | tipo de `V` (fixa a variável) |
| `(N RES)` | `operando RES` | `MEMORIA_RES` | tipo do resultado `N` atrás; `N` é `INT` |
| `(A B op)` | `OPERADOR` | `INSTRUCAO_VFP` | `+ - *` preservam; `^` preserva a base; `\|`→`REAL`; `/ %`→`INT` |
| `(A B rel)` | `OPERADOR_RELACIONAL` | `INSTRUCAO_CMP` | `BOOL` |
| `(C T E IFELSE)` | `operando IFELSE` | `COMANDO_IFELSE` | tipo comum dos ramos; `C` é `BOOL` |
| `(C B WHILE)` | `WHILE` | `COMANDO_WHILE` | tipo do corpo; `C` é `BOOL` |
| `(A B)` justaposto | `operando operando` (`resto_complemento → ε`) | `SEQUENCIA` | `?` (void); emite os filhos em ordem |

### FIRST / FOLLOW

| Não-terminal | FIRST | FOLLOW |
|--------------|-------|--------|
| `programa` | `(` | `$` |
| `sequencia_execucao` | `(` | `$` |
| `avaliacao_sequencia` | `END` `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` | `$` |
| `expressao_aninhada` | `(` | `OPERADOR` `OPERADOR_RELACIONAL` `IFELSE` `WHILE` `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` |
| `operando` | `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` | `OPERADOR` `OPERADOR_RELACIONAL` `IFELSE` `WHILE` `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` |
| `corpo_expressao` | `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` | `)` |
| `complemento_expressao` | `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` | `)` |
| `resto_complemento` | `OPERADOR` `OPERADOR_RELACIONAL` `WHILE` `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` | `)` |
| `operacao` | `OPERADOR` `OPERADOR_RELACIONAL` `WHILE` `NUMERO` `TRUE` `FALSE` `IDENTIFICADOR` `RES` `(` | `)` |

### Tabela de parsing LL(1)

`M[Não-terminal, Terminal] = Produção`. Células vazias = erro sintático; `ε` = derivação vazia.

```
M[programa, (]                       = ( START ) sequencia_execucao
M[sequencia_execucao, (]             = ( avaliacao_sequencia
M[avaliacao_sequencia, END]          = END )
M[avaliacao_sequencia, ( NUMERO TRUE FALSE IDENTIFICADOR RES] = corpo_expressao ) sequencia_execucao
M[expressao_aninhada, (]             = ( corpo_expressao )
M[operando, NUMERO]                  = NUMERO
M[operando, TRUE]                    = TRUE
M[operando, FALSE]                   = FALSE
M[operando, IDENTIFICADOR]           = IDENTIFICADOR
M[operando, RES]                     = RES
M[operando, (]                       = expressao_aninhada
M[corpo_expressao, ( NUMERO TRUE FALSE IDENTIFICADOR RES] = operando complemento_expressao
M[complemento_expressao, ( NUMERO TRUE FALSE IDENTIFICADOR RES] = operando resto_complemento
M[complemento_expressao, )]          = ε
M[resto_complemento, OPERADOR OPERADOR_RELACIONAL WHILE ( NUMERO TRUE FALSE IDENTIFICADOR RES] = operacao
M[resto_complemento, )]              = ε
M[operacao, OPERADOR]                = OPERADOR
M[operacao, OPERADOR_RELACIONAL]     = OPERADOR_RELACIONAL
M[operacao, WHILE]                   = WHILE
M[operacao, ( NUMERO TRUE FALSE IDENTIFICADOR RES] = operando IFELSE
```

A ausência de colisão em qualquer `M[A, t]` prova que a gramática é **LL(1)**.

## Regras de tipos (cálculo de sequentes)

Implementadas em `verificarTipos` (`src/semantic_analyzer.cpp`). O julgamento `Γ ⊢ e : τ` lê-se *"no contexto `Γ` (tabela de símbolos), a expressão `e` tem tipo `τ`"*. O tipo `?` (`DESCONHECIDO`) é coringa: operandos já `?` (por erro anterior) não disparam novos erros, quebrando cascata de falsos positivos.

**Literais**

```math
\frac{\text{n é dígitos}}{\Gamma \vdash n : int}\ (T\text{-}Int) \qquad
\frac{\text{r tem ponto}}{\Gamma \vdash r : real}\ (T\text{-}Real) \qquad
\frac{}{\Gamma \vdash TRUE/FALSE : bool}\ (T\text{-}Bool)
```

**Memórias.** `construirTabelaSimbolos` insere cada `MEM` definida como `MEM : ?`; `verificarTipos` resolve no primeiro `(V MEM)`. Ler memória nunca definida é erro semântico.

```math
\frac{(MEM : \tau) \in \Gamma}{\Gamma \vdash (MEM) : \tau}\ (T\text{-}Load) \qquad
\frac{\Gamma \vdash V : \tau \quad (MEM : ?) \in \Gamma \quad \tau \neq ?}{\Gamma[MEM \mapsto \tau] \vdash (V\ MEM) : \tau}\ (T\text{-}Store\text{-}Def)
```

```math
\frac{\Gamma \vdash V : \tau \quad (MEM : \tau) \in \Gamma}{\Gamma \vdash (V\ MEM) : \tau}\ (T\text{-}Store\text{-}Ok) \qquad
\frac{\Gamma \vdash V : \tau' \quad (MEM : \tau) \in \Gamma \quad \tau,\tau' \neq ? \quad \tau \neq \tau'}{\text{Erro Semântico}}\ (T\text{-}Store\text{-}Err)
```

**Histórico `(N RES)`** - `N` inteiro `≥ 0`; tipo = o do resultado `N` posições atrás (`0` = último). `N` negativo é erro.

```math
\frac{\Gamma \vdash N : int \quad N \geq 0 \quad H[\,|H|-1-N\,] = \tau}{H ; \Gamma \vdash (N\ RES) : \tau}\ (T\text{-}Res)
```

**Aritméticos `+ - *`** - mesmo tipo numérico, preserva o tipo (sem coerção int/real):

```math
\frac{\Gamma \vdash a : \tau \quad \Gamma \vdash b : \tau \quad \tau \in \{int, real\}}{\Gamma \vdash (a\ b\ op) : \tau}\ (T\text{-}Arit),\ op \in \{+,-,*\}
```

**Divisão real `|` e potência `^`** - `|` resulta sempre `real`; `^` exige expoente `int` e preserva o tipo da base:

```math
\frac{\Gamma \vdash a : \tau \quad \Gamma \vdash b : \tau \quad \tau \in \{int, real\}}{\Gamma \vdash (a\ b\ |) : real}\ (T\text{-}DivReal) \qquad
\frac{\Gamma \vdash a : \tau \quad \Gamma \vdash b : int \quad \tau \in \{int, real\}}{\Gamma \vdash (a\ b\ \hat{}\,) : \tau}\ (T\text{-}Pow)
```

**Divisão inteira `/` e resto `%`** - exclusivos de `int`:

```math
\frac{\Gamma \vdash a : int \quad \Gamma \vdash b : int}{\Gamma \vdash (a\ b\ op) : int}\ (T\text{-}DivInt),\ op \in \{/, \%\}
```

**Relacionais** - ordenação `< > <= >=` exige numéricos do mesmo tipo; igualdade `== !=` aceita qualquer tipo igual; ambos resultam `bool`:

```math
\frac{\Gamma \vdash a : \tau \quad \Gamma \vdash b : \tau \quad \tau \in \{int, real\}}{\Gamma \vdash (a\ b\ op) : bool}\ (T\text{-}Ord) \qquad
\frac{\Gamma \vdash a : \tau \quad \Gamma \vdash b : \tau \quad \tau \in \{int, real, bool\}}{\Gamma \vdash (a\ b\ op) : bool}\ (T\text{-}Eq)
```

**Controle** - `IFELSE` exige condição `bool` e ramos do mesmo tipo; `WHILE` exige condição `bool`:

```math
\frac{\Gamma \vdash c : bool \quad \Gamma \vdash e_1 : \tau \quad \Gamma \vdash e_2 : \tau}{\Gamma \vdash (c\ e_1\ e_2\ IFELSE) : \tau}\ (T\text{-}IfElse) \qquad
\frac{\Gamma \vdash c : bool \quad \Gamma \vdash corpo : \tau}{\Gamma \vdash (c\ corpo\ WHILE) : \tau}\ (T\text{-}While)
```

Os erros de tipo são acumulados como `SEMANTICO`; o Assembly só é gerado com zero pendências.

## Captura dos bits dos LEDs no console do CPUlator

```javascript
(function(){
  const leds = document.querySelectorAll('#devff200000 .dev_led_led');
  const bin = Array.from(leds).map(l => l.classList.contains('dev_led_on')?'1':'0').join('');
  console.log("Bin(31-0): "+bin+"  Hex: 0x"+parseInt(bin,2).toString(16).toUpperCase().padStart(8,'0'));
})();
```
