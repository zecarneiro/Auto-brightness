# Auto-brightness
# Script com o objectivo de alterar o brilho do portátil quando ligado a fonte AC ou bateria

Deve editar o ficheiro rc.local para iniciar automaticamente com previlégios
sudo, com o seguinte comando:
sudo editor_de_texto /etc/rc.local

e adicionar na ultima linha, antes do "exit 0" o seguinte comando:
sh /opt/Auto_brightness/auto_brightness.sh
ou correr os seguintes comandos

1 - Com este comando eu vou remover todas as linhas que contêm o texto "exit 0", onde
  d = linha
  -i = alteração permanente, ou seja, remove e salva
    -> sudo sed -i '/exit 0/d' /etc/rc.local

2 - Com este comando vou acrescentar a ultima linha o texto "sh..." e "exit 0", onde
  >> = significa escrever no ficheiro, mas a partir da ultima linha
  bash -C '...' = faz com que "echo ..." seja executado
    -> sudo bash -c 'echo "./opt/Auto_brightness/auto_brightness.sh" >> /etc/rc.local'
    -> sudo bash -c 'echo "exit 0" >> /etc/rc.local'
==============================================================================

==============================================================================
Deve reiniciar o PC
==============================================================================

NOTA: Para mais informações deve lêr os comentarios que estão no script
