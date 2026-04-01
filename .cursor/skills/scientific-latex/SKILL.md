---
name: scientific-latex
description: "LaTeX científico MLMS Studio (elsarticle, BibTeX, pdflatex/bibtex, Markdown→TeX, amsmath). Use em artigos LaTeX, templates Elsevier, matemática com amsmath e correção de build."
---

# LaTeX científico

## Documentação de referência (LaTeX Project)

* Índice oficial de documentação: [LaTeX Documentation](https://www.latex-project.org/help/documentation/) — inclui guias do núcleo LaTeX2e e materiais por tópico.
* Autores (recursos e novidades do formato): [LaTeX2e for authors — new features](https://www.latex-project.org/help/documentation/usrguide.pdf) e [versão histórica](https://www.latex-project.org/help/documentation/usrguide-historic.pdf) para comandos introduzidos entre 1994 e 2020.
* **Matemática complexa:** guia oficial do pacote — [User’s Guide for the amsmath Package](https://www.latex-project.org/help/documentation/amsldoc.pdf) (LaTeX Project; espelha a documentação AMS para `amsmath`).

## Âmbito

* Repositório: raiz do workspace; árvore principal de LaTeX em `latex/articlelsevier/`.
* Template de entrada: `latex/articlelsevier/main.tex` (classe `elsarticle`, estilo numérico ou harvard conforme o arquivo).
* Bibliografia: `latex/articlelsevier/mendeley.bib` (ajustar `\bibliography{...}` no `.tex` se mudar o nome).

## Ferramentas

* Compilador PDF: **pdfLaTeX** (`pdflatex --version` — TeX Live disponível no ambiente).
* Fluxo típico num artigo com referências:

```bash
cd latex/articlelsevier
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

* Limpar auxiliares quando necessário: `rm -f main.aux main.bbl main.blg main.log main.out main.toc` (adaptar ao nome do arquivo principal).

## Boas práticas

* Manter **preâmbulo** mínimo e pacotes já usados no projeto; evitar duplicar `\usepackage` com o template `elsarticle`.
* Figuras: preferir PDF/EPS/PNG coerentes com `graphicx`; caminhos relativos ao diretório do `.tex`.
* Alinhar conteúdo com rascunhos em `documentation/` quando a task pedir sincronização Markdown → LaTeX (preservar estrutura IMRAD se for manuscrito).
* Erros de compilação: ler a **primeira** causa em `main.log`; corrigir pacotes faltantes ou chaves BibTeX antes de iterar às cegas.

## Expressão matemática (pdfLaTeX + amsmath)

* No preâmbulo, quando o template ainda não carregar: `\usepackage{amsmath}` (e, se necessário, `amssymb` / `amsfonts` para símbolos AMS). O `elsarticle` costuma conviver bem com `amsmath`; evitar duplicar o mesmo pacote.
* **Modo inline:** `\( ... \)` ou `$ ... $` (preferir `\( \)` em texto novo por clareza).
* **Modo destacado:** `\[ ... \]` ou ambiente `equation` / `equation*`; para várias linhas alinhadas usar `align` / `align*` em vez de empilhar `\\` dentro de `equation`.
* **Alinhamento e estruturas:** `align`, `gather`, `split` (dentro de outro ambiente), `cases`, matrizes (`matrix`, `pmatrix`, `bmatrix`, etc.) — detalhes e exemplos no [amsldoc.pdf](https://www.latex-project.org/help/documentation/amsldoc.pdf).
* **Números de equação:** usar `equation` + `\label`/`\eqref`; em cadeias alinhadas, controlar numeração com `\notag` ou ambiente `align` conforme o guia AMS.
* **Operadores e funções:** `\DeclareMathOperator` (requer `amsmath`) para operadores como `\rank`, `\tr` com espaçamento correto.
* **Delimitadores:** `\left` / `\right` para parênteses/colchetes que crescem com o conteúdo; para normas absolutas repetidas, considerar `\lvert`/`\rvert` (AMS).
* Conferir sempre o **amsldoc** para ambientes específicos (`multline`, `subequations`, etc.) antes de reinventar layout com caixas ou espaçamento manual.

## O que não fazer

* Não alterar licença ou copyright dos arquivos do bundle Elsarticle salvo pedido explícito.
* Não introduzir motores alternativos (LuaLaTeX/XeLaTeX) sem confirmar dependências no ambiente.

## Relação com outros skills

* Para redação longa em prosa e normas de publicação amplas, combinar com **scientific-writing** ou **venue-templates** quando estiverem disponíveis no agente.
