#!/bin/bash
# Autor: José M. C. Noronha
# Data: 16/01/2017

# ==============================================================================
# O código para verificar se o PC está ligado a bateria ou a fonte AC foi obtida
# do ficheiro "functions" localizado em /usr/lib/pm-utils. O nome da função que
# contém o código chama-se get_power_status()

# ==============================================================================
# Nas linhas echo deve conter o valor do brilho que deseja, como também o
# caminho do ficheiro brightness, que no meu caso é:
# /sys/class/backlight/acpi_video0
# /sys/class/backlight/acpi_video1
# Eu altero os dois ficheiros porque o meu PC tem duas placas, uma da Nvida e
# outra da Intel. Por isso, aconselho a verificar quantas pastas existem.
# Resumindo, caso queira alterar a intensidade do brilho de forma automatica, o
# brilho tem que ter a itensidade = (brilho_minimo ou brilho_max)

# Deve verificar qual o valor do brilho maximo e do brilho minimo no interior
# dessas pastas através dos ficheiros com o nome, "max_brightness" para o brilho
# maximo. Para o brilho minimo deve alterar para o brilho minimo e abrir atraves
# do teclado, de seguida deve abrir os ficheiros brightness no qual deve idicar
# o valor que lá estão no variavel brilho minimo
brilho_maximo_default="10"
brilho_minimo_default="0"

# ==============================================================================
# Tempo usado para fazer as verificações
tempo_do_sleep="30" # tempo em segundos

# brilho_minimo_user = brilho minimo desejado quando estiver ligado a bateria
# brilho_maximo_user = brilho máximo desejado quando estiver ligado a corrente
# electrica
# NOTA: É importante salientar que os valores devem estar na escala entre o
# brilho_minimo_default - brilho_maximo_default.
brilho_minimo_user="0"
brilho_maximo_user="10"

# ==============================================================================
# Caminho que contém a pasta que cujo o nome está armazanado na variavel
# video_folder
video_path="/sys/class/backlight/"

# Nome do ficheiro, onde é possivel alterar o brilho
file_brightness="brightness"

# Nome do ficheiro, onde é possivel alterar o brilho
file_max_brightness="max_brightness"

# A variavel num_folder recebe o numero de pastas que existem
num_folder=$( ls -1 $video_path | wc -l )

# Se não existir nenhuma pasta no caminho da variavel video_path, então o script
# termina a sua execução
if [ $num_folder -eq "0" ];
then
  # Sai
  exit
fi

# Variavel que vai selecionar a posicao da tabela onde armazado os dados
posicao="0"

# Ciclo usado para receber os nomes dos ficheiros e pastas, caso existam, através
# do comando ls, sendo a variavel folder_video recebe o nome dos mesmos
for folder_video in $( ls $video_path );
do
  # Variaveis usadas apenas para armazenar o caminho para max_brightness e
  # brightness por forma a que seja verificada a existencia das mesmas na
  # condição seguinte, ou seja, essas variaveis, são usadas apenas neste ciclo
  full_brightness_exist=$video_path$folder_video/$file_brightness
  full_brightness_max_exist=$video_path$folder_video/$file_max_brightness

  # Se o ficheiro brightness e max_brightness existirem, então vou verificar se
  # o brilho maximo pre-definido e introduzido pelo utilizador são iguais, logo,
  # armazeno caminho dos ficheiros nas Variaveis abaixo, caso contrario, não
  # faço nada
  if [ -f $full_brightness_exist ]&&[ -f $full_brightness_max_exist ]; then
    # Vou lêr o valor que está no ficheiro max_brightness, ficheiro este que
    # contém o valor para o brilho maximo
    read maximo < $video_path$folder_video/$file_max_brightness

    # Verifico se o brilho maximo é igual ao brilho_maximo_default introduzido
    # pelo user
    if [ $maximo -eq $brilho_maximo_default ]; then
      # Variavel que vai armazenar o caminho para o ficeiro que sera usado para
      # alterar o brilho
      full_path_brightness[$posicao]=$video_path$folder_video/$file_brightness

      # Incremento o posicao, ou seja, posicao++
      posicao=$((posicao+1))
    fi
  fi
done

# Vou armazenar o tamanho da tabela
tamanho_array=${#full_path_brightness[@]}

# ==============================================================================
# Essas variaveis são usadas para indicar se o brilho já foi alterado ou não
# neste caso, para o maximo, ou minimo, evitando assim, caso o brilho estiver no
# maximo e o carregador ainda estiver ligado, evita que a escrita no ficheiro
# brightness só é feito uma e unica vez. O mesmo se aplica para
# quando a bateria estiver a ser usada
# Se:
#   brilho_alterado = 1, então o brilho foi alterado para o maximo
#   brilho_alterado = 0, então o brilho foi alterado para o minimo
# Estou a usar a função para verificar se o PC está ligado a bateria ou o
# carregador para que seja, atribuido os valores correctos a brilho_alterado
on_ac_power
case "$?" in
  # Como o carregador está ligado, então vou assumir que o brilho estava no
  # minimo para que o brilho seja alterado para o maximo
  "0") brilho_alterado="0" ;;

  # Como a bateria está a ser usada, então vou assumir que o brilho estava no
  # maximo para que o brilho seja alterado para o minimo
  "1") brilho_alterado="1" ;;
esac

# ==============================================================================
# Vou introduzir o valor do brilho máximo, assim que o script iniciar a sua
# primeira execução durante o boot. Por forma a garantir que todos os ficheiros
# tenham o mesmo numero para o briho.
for (( i = 0; i < $tamanho_array; i++ )); do
  echo $brilho_maximo_user > ${full_path_brightness[$i]}
done

# =========================== Funções ==========================================
# Função que confirma se o brilho foi alterado por teclado, ou não. Ou seja, são
# percorridos todos os ficheiros brightness, para varificar se os valores são
# iguais, e caso sejam, a variavel conta é incrementada. E caso o valor do conta
# for igual ao numero de ficheiros brightness existentes, então o aumento ou a
# diminuição do brilho pode avançar
confirma_mudar_brilho(){
  conta="0"
  for (( i = 0; i < $tamanho_array; i++ )); do
    if [ $(cat ${full_path_brightness[$i]}) -eq $valor_comparar ];
    then
      conta=$((conta+1))
    else
      break
    fi
  done
}

# Função que altera o brilho quando a bateria está a ser usada
ligado_a_bateria(){
  # Como quero alterar para o brilho minimo, então o brilho deve estar no
  # maximo, logo, a variavel valor_comparar deve ser igual a brilho_maximo
  # para verificarmos se o brilho foi alterado pelo utilizador através do
  # teclado ou nas definições
  valor_comparar=$brilho_maximo_user

  # Vou para a função confirma_mudar_brilho, usada para verificar se o brilho
  # foi alterado pelo user
  confirma_mudar_brilho

  # Caso o brilho não foi alterado pelo user( conta = tamanho_array ), então vou
  # alterar o brilho para o minimo
  if [ $conta -eq $tamanho_array ]; then
    for (( i = 0; i < $tamanho_array; i++ )); do
      echo $brilho_minimo_user > ${full_path_brightness[$i]}
    done
  fi
}

# Função que altera o brilho quando o carregador estiver ligado
carregador_ligado(){
  # Como quero alterar para o brilho maximo, então o brilho deve estar no
  # minimo, logo, a variavel valor_comparar deve ser igual a brilho_minimo
  # para verificarmos se o brilho foi alterado pelo utilizador através do
  # teclado ou nas definições
  valor_comparar=$brilho_minimo_user

  # Vou para a função confirma_mudar_brilho, usada para verificar se o brilho
  # foi alterado pelo user
  confirma_mudar_brilho

  # Caso o brilho não foi alterado pelo user( conta = tamanho_array ), então vou
  # alterar o brilho para o maximo
  if [ $conta -eq $tamanho_array ]; then
    for (( i = 0; i < $tamanho_array; i++ )); do
      echo $brilho_maximo_user > ${full_path_brightness[$i]}
    done
  fi
}

# ============================== Principal =====================================
# Ciclo infinito/Execução do script
while [ 1 ] ; do
  # Verifica se está ligado a batteria ou a corrente electrica
  on_ac_power
  case "$?" in
    # Se for 0 quer dizer que o carregador está ligado
    # Então é chamada a função carregador_ligado()
    "0")
      # Se o brilho está no minimo( brilho_alterado = 0 ), então deve ser
      # introduzido o brilho maximo, visto que o carregador está ligado
      if [ $brilho_alterado -eq "0" ]; then
        # Vou a para a função carregador_ligado
        carregador_ligado

        # Visto que o brilho já está no maximo, então devo indicar que o brilho
        # já foi alterado para o maximo, ou seja, já não será necessário alterar
        # para o brilho maximo caso o PC ainda estiver ligado ao carregador
        brilho_alterado="1"
      fi
    ;;

    # Se for 1 quer dizer que a bateria está a ser usada
    # Então é chamada a função ligado_a_bateria()
    "1")
      # Se o brilho está no maximo( brilho_alterado = 1 ), então deve ser
      # introduzido o brilho minimo, visto que a bateria está a ser usada
      if [ $brilho_alterado -eq "1" ]; then
        # Vou a para a função ligado_a_bateria
        ligado_a_bateria

        # Visto que o brilho já está no minimo, então devo indicar que o brilho
        # já foi alterado para o minimo, ou seja, já não será necessário alterar
        # para o brilho minimo caso o PC ainda estiver ligado a bateria
        brilho_alterado="0"
      fi
    ;;
  esac

  # Adormece x segundos
  sleep $tempo_do_sleep
done
