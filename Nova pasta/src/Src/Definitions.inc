{

################################################################################
#                                                                              #
#             ##   ##  ##########  ##           ######     ######              #
#             ###  ##  #   ##   #  ##           #    #     #    #              #
#             ## # ##      ##      ##              ###     #    #              #
#             ##  ###      ##      ##    #      #    #     #    #              #
#             ##   ##      ##      #######      ######  #  ######              #
#                                                                              #
################################################################################

 Arquivo de definição de constantes de compilação condicional, afetando lançador funcional


}

// Definições gerais do Launcher:

{$DEFINE DETECT_JAVA_PATH}      // Detecta automáticamente o caminho do Java
{$DEFINE MULTISERVER}           // Ativar o suporte de vários servidores
{$DEFINE LOCAL_SERVERS_LIST}    // Lista local de servidores
//{$DEFINE CUSTOM_JAVA}         // Possibilita usar o seu próprio Java (utilize Main.zip)
{$DEFINE SALTED_HASH}           // Define o has do cliente (não modifique)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Hashing de senhas, sinalizadores podem ser combinados (indo por ordem de desempenho):

//{$DEFINE MD5}
{$DEFINE DOUBLE_MD5} // Utilizado no DLE
//{$DEFINE SHA1}
//{$DEFINE SHA256}
//{$DEFINE SHA384}
//{$DEFINE SHA512}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// Configurações de segurança:

//{$DEFINE LAUNCH_PERIMETER}    // Inclusão de proteção anti-depuração (SZPU "Perímetro"))

{$DEFINE CONTROL_PROCESSES}   // Lançar processos de controle:
   {$DEFINE USE_INJECTORS}    //  - Injetores
   {$DEFINE USE_WATCHDOG}     //  - Rastreamento

{$DEFINE BEACON}              // Light - verifica o cliente durante o jogo
{$DEFINE EURISTIC_DEFENCE}    // Busca launchers secundários em execução


//HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH