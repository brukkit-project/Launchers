/*launcher, compilado 01.08.2014, versão: 121 */


package net.launcher.run;

public class Settings
{
	/** Configurações */
	public static final String  title		         = "Launcher"; //Insira o nome do seu launcher
	public static final String  titleInGame  	     = "Minecraft"; //Título após o login
	public static final String  baseconf		     = "meuserver"; //Pasta com o arquivo de configuração
	public static final String  pathconst		     = "meuserver/%SERVERNAME%"; //Nome da pasta com o minecraft (com o nome do seu servdirp)
	public static final String  skins                = "MinecraftSkins/"; //Pasta das skins
	public static final String  cloaks               = "MinecraftCloaks/"; //Pasta das capas
	/** Configurações Web */
	public static final String  domain	 	         = "meuserver.com.br";//Site do servidor
	public static final String  siteDir		         = "site";//Pasta com os arquivos do launcher para atualizações e etc.
	public static final String  updateFile		     = "http://meuserver.com.br/site/launcher/test";//Link para atualizar o launcher. Não escreva no final ".Exe .Jar"!
	public static final String  buyVauncherLink      = "http://meuservidor.buycraft.com"; //Site da loja do servidor
	public static final String  iMusicname           = "001.mp3";//Som que ira tocar ao iniciar o launcher (modifique, é o som do palaystation 1 kkk)
	
	public static int height                         = 532;      //Altura do launcher
	public static int width                          = 900;      //Largura do launcher
        
	public static String[] servers =
	{
		"Offline, localhost, 25565, 1.5.2",//Nome, ip, porta, versão
	};

	/** Opções de configuração Painel **/
	public static final String[] links = 
	{
		// Para desabilitar adicionar o endereço do link #
		" Cadastro ::http://",
	};

	/** Configurações da estrutura do Launcher */
	public static boolean useAutoenter	         =  false;  //Função auto-conectarse ao servidor selecionado
	public static boolean useRegister		     =  true;   //Cadastro pelo launcher
	public static boolean useMulticlient		 =  true;   //Habilita o multicliente
	public static boolean useStandartWB		     =  true;   //Use o navegador padrão para abrir links
	public static boolean usePersonal		     =  true;   //Habilita "Minha Conta"
	public static boolean customframe 		     =  true;   //Habilita customização do frame
	public static boolean useConsoleHider		 =  false;  //Habilita ou desabilita o console
	public static boolean useModCheckerTimer	 =  true;   //Verifica o arquvio jar em cada 30 segundos
	public static int     useModCheckerint       =  2;      //Número de vezes que irá verificar o jar do jogador.
	public static boolean assetsfolder           =  false;  //Baixar assets a partir de uma pasta ou arquivo (true=de uma pasta false=de um arquivo) no connect.php deve possui a mesma configuração.

	public static final String protectionKey	 = "1234567890"; //Chave de proteção
	public static final String key1              = "1234567891234567"; //Chave de proteção com 16 caracteres
	public static final String key2              = "1234567891234567"; //Chave de proteção com 16 caracteres
	

	public static boolean debug		 	         =  true; //Habilita modo de depuração
	public static boolean drawTracers		     =  false; //Processa as bordas do launcher
	public static final String masterVersion     = "final_RC4"; //Versão do Launcher

	public static boolean patchDir 		         =  true; //Use a substituição automática do diretório do jogo (verdadeiro/falso)
	
	public static void onStart() {}
	public static void onStartMinecraft() {}
	
}
