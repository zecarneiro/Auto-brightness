#!/bin/bash
# Autor: José M. C. Noronha
# Data: 13/06/2018

# ==============================================================================
# O código para verificar se o PC está ligado a bateria ou a fonte AC foi obtida
# do ficheiro "functions" localizado em /usr/lib/pm-utils. O nome da função que
# contém o código chama-se get_power_status()

# ==============================================================================
# Tempo usado para fazer as verificações
declare timeToSleep="30" # time in seconds

# ==============================================================================
# Nome do ficheiro, onde é possivel alterar o brilho
declare fileBrightness="brightness"

# Nome do ficheiro, onde é possivel alterar o brilho
declare fileMaxBrightness="max_brightness"

# Nome do ficheiro com a percentagem para o valor minimo /opt/AutoBrightness/
declare fileValue="/opt/AutoBrightness/valueMin"

# Array para armazenar todos os caminhos das pastas do video
declare -a arrayOfPathVideo

# Valor(%) com a informação do valor minimo em bateria
declare -i minValue
read minValue < $fileValue
 
# =========================== Funções ==========================================
# Remove caracteres de uma string
# characterToRemove = caracteres para eliminar
# stringToRemove = string necessaria para eliminar os caracteres
# newString = string a retorna
function removeCharacterString(){
	local characterToRemove="$1"
	local stringToRemove="$2"
	local newString

	# Remove character
	newString=$(echo "$stringToRemove" | tr -d "$characterToRemove")

	# Retorna a nova string
	echo "$newString"
}

# Verifica se existe ficheiro(s)/pasta(s) numa determinada localização
# path = localização a verificar
# Retorna bool
function existsFilesOrFolderInPath(){
	local path="$1"								# Recebe o pasta como primeiro argumento
	local numFolder=$( ls -1 "$path" | wc -l )	# A variavel numFolder recebe o numero de pastas/ficheiros que existem
	local response=0							# retorna true = 1 / false = 0

	# Se existem 1 ou mais ficheiros/pastas então response = true
	if [ $numFolder -gt 0 ]; then
		response=1
	fi

	# Retorna se existe ficheiros/pastas
	echo $response
}

# Obtém todas as localizações das pastas do video e introduz no array global
function getAllPathVideo(){
	# Declaracão
	local videoPath="/sys/class/backlight/"								# Caminho que contém as pastas das graficas
	local existFilesOrFolder=$(existsFilesOrFolderInPath $videoPath)	# Verifica se existe ficheiros/pastas

	# Se existir algum ficheiro/pasta em video_path então obtém todas as localizaçãoes
	if [ $existFilesOrFolder -eq 1 ]; then
		local -i index=0
		# Ciclo usado para receber os nomes dos ficheiros e pastas, caso existam, através
		# do comando ls, sendo a variavel folderVideo recebe o nome dos mesmos
		for folderVideo in $( ls $videoPath );
		do
			if [ -d $videoPath$folderVideo ]; then
				arrayOfPathVideo[$index]="$videoPath$folderVideo"
				index=index+1
			fi
		done
	fi
}

# Verifica o brilho activo
# checkMax = 1 se for para verificar o brilho máximo / 0 se for para verificar o brilho mínimo para a bateria
# response = 0 se o comparação for falsa / 1 se a comparação for verdadeira
function checkBrightness(){
	local checkMax=$1				# true = 1 / false = 0
	local -i response=0				# false = 0 / true = 1
	local -a arrayOfFullPathVideo	# Array onde é armazenado as localizações das pastas dos videos
	local -i valueToCompare			# Armazena o valor a comparar
	local -i valueActived			# Armazena o brilho definido

	# Obtenção de todas as localizações
	getAllPathVideo
	arrayOfFullPathVideo=("${arrayOfPathVideo[@]}")		# Cópia do array arrayOfPathVideo e armazena em arrayOfFullPathVideo 
	arrayOfPathVideo=()									# Elimino todos os elementos do arrayOfPathVideo

	# Percore o array das localizações
	for folderVideo in "${arrayOfFullPathVideo[@]}";
	do
		if [ -f $folderVideo/$fileBrightness ]&&[ -f $folderVideo/$fileMaxBrightness ]; then
			# Lê os valores dos brilhos máximos e os brilhos definidos
			read valueToCompare < "$folderVideo/$fileMaxBrightness"
			read valueActived < "$folderVideo/$fileBrightness"

			# Se for para verificar o brilho máximo
			if [ $checkMax -eq 1 ]; then
				# Se o brilho definido for igual ao brilho máximo
				if [ $valueToCompare -eq $valueActived ]; then
					response=1
					break
				fi
			else
				valueToCompare=valueToCompare*minValue/100		# Obtenção do valor mínimo definido em percentagem a partir do valor máximo

				# Se o brilho definido for igual ao brilho mínimo
				if [ $valueToCompare -eq $valueActived ]; then
					response=1
					break
				fi
			fi
		fi
	done

	# Return response
	echo $response
}

# Introduz o brilho
# isBattery = 1 então introduz o brilho para a bateria / 0 então introduz o brilho máximo
function setBrightness(){
	local -i isBattery=$1			# true = 1 / false = 0
	local -a arrayOfFullPathVideo	# Array onde é armazenado as localizações das pastas dos videos
	local -i valueToSet				# Brilho a introduzir

	# Obtenção de todas as localizações
	getAllPathVideo
	arrayOfFullPathVideo=("${arrayOfPathVideo[@]}")		# Copy an array to another
	arrayOfPathVideo=()

	for folderVideo in in "${arrayOfFullPathVideo[@]}";
	do
		if [ -f $folderVideo/$fileBrightness ]&&[ -f $folderVideo/$fileMaxBrightness ]; then
			read valueToSet < "$folderVideo/$fileMaxBrightness"

			if [ $isBattery -eq 1 ]; then
				valueToSet=valueToSet*minValue/100
			fi
			
			echo $valueToSet > "$folderVideo/$fileBrightness"
		fi
	done
}

# Função que altera o brilho quando a bateria está a ser usada
function onBattery(){
	local -a arrayOfFullPathVideo
	local -i setMin=$(checkBrightness 1)	

	# Caso o brilho não foi alterado pelo user( conta = tamanho_array ), então vou
	# alterar o brilho para o minimo
	if [ $setMin -eq 1 ]; then
		setBrightness 1
	fi
}

# Função que altera o brilho quando o carregador estiver ligado
function onAC(){
	local -a arrayOfFullPathVideo
	local -i setMax=$(checkBrightness 0)

	# Caso o brilho não foi alterado pelo user( conta = tamanho_array ), então vou
	# alterar o brilho para o minimo
	if [ $setMax -eq 1 ]; then
		setBrightness 0
	fi
}

# ============================== Main =====================================
# Ciclo infinito/Execução do script
while [ 1 ] ; do
	# Verifica se está ligado a batteria ou a corrente electrica
	on_ac_power
	case "$?" in
	# Se for 0 quer dizer que o carregador está ligado
	# Então é chamada a função carregador_ligado()
	"0")
		# Vou a para a função carregador_ligado
	    onAC
	;;

	# Se for 1 quer dizer que a bateria está a ser usada
	# Então é chamada a função ligado_a_bateria()
	"1")
		# Vou a para a função ligado_a_bateria
	    onBattery
	;;
	esac

	# Adormece x segundos
	sleep $timeToSleep
done
