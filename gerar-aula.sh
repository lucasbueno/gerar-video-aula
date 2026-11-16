#!/bin/bash

# --- CONFIGURAÇÕES ---
VOZ="pt-BR-AntonioNeural"

# Evita falhas se a pasta estiver vazia
shopt -s nullglob
arquivos_pptx=(*.pptx)

if [ ${#arquivos_pptx[@]} -eq 0 ]; then
    echo "❌ Erro: Nenhum arquivo .pptx encontrado na pasta."
    exit 1
fi

# Captura dinamicamente o nome da aula (ex: "2-1.pptx" gera o NOME_BASE "2-1")
PPTX="${arquivos_pptx[0]}"
NOME_BASE="${PPTX%.*}"
TXT_MESTRE="${NOME_BASE}.txt"
ARQUIVO_FINAL="${NOME_BASE}.mp4"

echo "================================================="
echo "  Iniciando Produção Automática: $NOME_BASE"
echo "================================================="

if [ ! -f "$TXT_MESTRE" ]; then
    echo "❌ Erro: O roteiro '$TXT_MESTRE' não foi encontrado!"
    echo "Crie este arquivo com as falas separadas por uma linha em branco."
    exit 1
fi

# ===================================================
# FASE 1: DIVISÃO DO ROTEIRO (TXT MESTRE -> SLIDES)
# ===================================================
echo ">> FASE 1/4: Quebrando roteiro único em parágrafos..."

# O 'NF' garante que blocos vazios ou apenas com espaços sejam ignorados.
# O '++i' garante que a numeração dos arquivos (1, 2, 3) não pule nenhum número.
sed 's/\r$//' "$TXT_MESTRE" | awk -v base="$NOME_BASE" -v RS='' 'NF {print $0 > (base "-" ++i ".txt")}'

num_txts=$(ls ${NOME_BASE}-*.txt 2>/dev/null | wc -l)
echo "✓ Roteiro dividido em $num_txts partes válidas (Ex: ${NOME_BASE}-1.txt)."

# ===================================================
# FASE 2: EXTRAÇÃO DOS SLIDES (PPTX -> PNG)
# ===================================================
echo ">> FASE 2/4: Extraindo imagens do $PPTX..."

PDF_TEMP="${NOME_BASE}.pdf"
libreoffice --headless --convert-to pdf "$PPTX" > /dev/null 2>&1
pdftoppm -png -scale-to-x 1920 -scale-to-y 1080 "$PDF_TEMP" img_temp

for arquivo in img_temp-*.png; do
    numero=$(echo "$arquivo" | grep -o '[0-9]\+' | sed 's/^0*//')
    # Renomeia para o formato "2-1-1.png", "2-1-2.png"
    mv "$arquivo" "${NOME_BASE}-${numero}.png"
done

rm -f "$PDF_TEMP"
echo "✓ Slides convertidos para imagens."

# ===================================================
# FASE 3: GERAÇÃO DE VOZ E MONTAGEM
# ===================================================
echo ">> FASE 3/4: Gerando áudios e renderizando os vídeos individuais..."
rm -f lista_concat.txt

# O loop agora filtra especificamente os arquivos no formato "2-1-*.png"
for img in $(ls ${NOME_BASE}-*.png | sort -V 2>/dev/null); do
    base_fatia="${img%.png}"
    txt_slide="${base_fatia}.txt"
    audio_slide="${base_fatia}.mp3"
    video_temp="${base_fatia}.mp4"

    if [ -f "$txt_slide" ]; then
        echo "   Processando $base_fatia..."

        # 1. Gera o áudio a partir do txt cortado
        edge-tts --voice "$VOZ" --rate=+15% --file "$txt_slide" --write-media "$audio_slide"

        # 2. Mede a duração
        duracao=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audio_slide")

        # 3. Junta imagem e áudio
        ffmpeg -hide_banner -loglevel error -y -loop 1 -framerate 2 -i "$img" -i "$audio_slide" \
               -c:v libx264 -tune stillimage -vf "scale=1920:1080" -pix_fmt yuv420p \
               -c:a aac -b:a 192k -t "$duracao" "$video_temp"

        echo "file '$video_temp'" >> lista_concat.txt
    else
        echo "   ⚠️ Aviso: Texto '$txt_slide' não encontrado. Slide ignorado."
    fi
done

# ===================================================
# FASE 4: CONCATENAÇÃO E LIMPEZA
# ===================================================
echo ">> FASE 4/4: Unindo tudo no vídeo final..."

if [ -f lista_concat.txt ]; then
    ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i lista_concat.txt -c copy "$ARQUIVO_FINAL"

    echo ">> Limpando arquivos temporários fragmentados..."
    # Apaga estritamente os fragmentos com hífen extra, garantindo a segurança de "2-1.txt" e "2-1.mp4"
    rm -f ${NOME_BASE}-*.txt ${NOME_BASE}-*.png ${NOME_BASE}-*.mp3 ${NOME_BASE}-*.mp4 img_temp* lista_concat.txt

    echo "================================================="
    echo " 🎉 SUCESSO! A aula está pronta: $ARQUIVO_FINAL"
    echo "================================================="

else
    echo "❌ Erro: Nenhum par de slide/áudio válido foi processado."
fi
