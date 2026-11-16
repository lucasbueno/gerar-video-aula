# gerar-video-aula

Script Bash que transforma uma apresentação PowerPoint (`.pptx`) e um roteiro narrado (`.txt`) em uma vídeo-aula (`.mp4`).

## O que o script faz

Ao ser executado, o script:

1. Procura um arquivo `.pptx` na pasta atual e espera encontrar o roteiro `.txt` com o mesmo nome-base.
2. Divide o roteiro em blocos separados por linhas em branco. Cada bloco corresponde, na ordem, a um slide.
3. Usa o LibreOffice para converter a apresentação em PDF e o Poppler para exportar cada página como imagem.
4. Gera a narração de cada bloco com `edge-tts`, usando a voz `pt-BR-AntonioNeural` e velocidade `+15%`.
5. Combina cada imagem com seu áudio e concatena os segmentos em um arquivo `.mp4` com o mesmo nome-base da apresentação.
6. Remove os arquivos fragmentados e temporários após a montagem.

Blocos de roteiro e slides sem correspondência são ignorados. O script seleciona o primeiro `.pptx` encontrado; mantenha apenas a apresentação que deseja processar na pasta para evitar ambiguidades.

## Preparar os arquivos

Na mesma pasta, coloque a apresentação e um arquivo de texto com o mesmo nome-base. Por exemplo:

```text
2-1.pptx
2-1.txt
```

No roteiro, separe a fala de cada slide por uma linha em branco:

```text
Este é o texto narrado durante o primeiro slide.

Esta fala corresponde ao segundo slide.

E esta, ao terceiro.
```

Execute o script a partir dessa pasta:

```bash
bash gerar-aula.sh
```

O vídeo será salvo como `2-1.mp4`, no exemplo acima.

## Instalar dependências no Linux

As instruções abaixo são para distribuições baseadas em Debian, como Ubuntu e Linux Mint.

### Ferramentas do sistema

Instale o LibreOffice, o Poppler, o FFmpeg, o Python e o `pipx`:

```bash
sudo apt update
sudo apt install libreoffice poppler-utils ffmpeg python3 python3-full pipx
```

Esses pacotes fornecem os comandos `libreoffice`, `pdftoppm`, `ffmpeg` e `ffprobe`, além do ambiente necessário para instalar o `edge-tts`.

### [`edge-tts`](https://github.com/rany2/edge-tts)

Instale o `edge-tts` com `pipx`, que mantém o aplicativo Python isolado do Python do sistema:

```bash
pipx install edge-tts
pipx ensurepath
```

Depois, abra um novo terminal (ou atualize a configuração do shell) para que o diretório de aplicativos do `pipx` entre no `PATH`. Confira a instalação:

```bash
edge-tts --version
```

O `edge-tts` utiliza o serviço de síntese de voz online da Microsoft Edge; é necessária uma conexão com a internet durante a geração dos áudios.

## Verificar as dependências

O script também usa utilitários comuns do Bash, incluindo `awk`, `sed`, `grep`, `ls`, `sort`, `mv`, `rm` e `wc`. Para verificar os principais executáveis:

```bash
command -v libreoffice pdftoppm ffmpeg ffprobe edge-tts
```
