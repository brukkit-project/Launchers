<?php
	if(!defined('INCLUDE_CHECK')) die("You don't have permissions to run this");
	include_once("loger.php");
	include_once("security.php");
	/* Senha hash método para integração com sobre a liberação de plugins/portais/cms/fóruns
	'hash_md5' 			- md5 hashing
	'hash_authme'   	- integração com o plugin AuthMe
	'hash_cauth' 		- integração com o plugin Cauth
	'hash_xauth' 		- integração com o plugin xAuth
	'hash_joomla' 		- integração com o Joomla (v1.6- v1.7)
	'hash_ipb' 			- integração com IPB
	'hash_xenforo' 		- integração com XenForo
	'hash_wordpress' 	- integração com WordPress
	'hash_vbulletin' 	- integração com vBulletin
	'hash_dle' 			- integração com DLE
	'hash_drupal'     	- integração com Drupal (v.7)
	'hash_launcher'		- integração com o Launcher (Cadastro através do launcher)
	*/
	$crypt 				= 'hash_md5';
	
	$db_host			= 'localhost'; 	// Endereço IP MySQL
	$db_port			= '3306'; 		// Porta de banco de dados
	$db_user			= 'root'; 		// Usuário do banco de dados
	$db_pass			= 'root'; 		// Senha do banco de dados
	$db_database		= 'w'; 			// Nome do banco de dados
	
	$db_table       	= 'accounts'; 				//Tabela com os usuários
	$db_columnId  		= 'id'; 					//Coluna com o ID de usuário
	$db_columnUser  	= 'login'; 					//Coluna com nomes de usuário
	$db_columnPass  	= 'password';			 	//Coluna com senhas de usuário
	$db_tableOther 		= 'xf_user_authenticate'; 	//Autenticação suplementar para XenForo, não altere
	$db_columnSalt  	= 'members_pass_salt'; 		//Ajustável para IPB e vBulletin:, IPB - members_pass_salt, vBulletin - salt
    $db_columnIp  		= 'ip'; 					//Coluna com IP dos usuários
	
	$db_columnDatareg   = 'create_time'; 	//Coluna de data de inscrição
	$db_columnMail      = 'email'; 			//Coluna de e-mail

	$banlist            = 'banlist'; 		//Tabela plugin Ultrabans
	
	$useban             =  false; //Banimentos no servidor - banimentos pelo launcher - Ultrabans plugin
	$useantibrut        =  true; //Proteção contra re-login frequentes (pausa de 1 minuto )
	
	$masterversion  	= 'final_RC4'; //Versão do Launcher (a mesma configurada no launcher)
	$protectionKey		= '1234567890'; 
	$key1               = "1234567891234567"; //Igual a configuração do launcher
	$key2               = "1234567891234567"; //Igual a configuração do launcher
    $skinurl            = 'http://meusite.com.br/site/MinecraftSkins/'; //Link para skins (à partir do Bukkit/Spigot 1.7.9)
    $checklauncher      = false; //Verificação do hash Launcher
	$md5launcherexe     = md5(@file_get_contents("launcher/fix.exe"));  // Verifica o MD5
	$md5launcherjar     = md5(@file_get_contents("launcher/fix.jar"));  // Verifica o MD5

	$assetsfolder       = false; //Baixar assets a partir de uma pasta ou arquivo (true=de uma pasta false=do arquivo)

//========================= Configurações do Launcher =======================//	
	
	$uploaddirs         = 'MinecraftSkins';  //Pasta das skins
	$uploaddirp         = 'MinecraftCloaks'; //Pasta das capas
	
	$usePersonal 		=  true; //Usar conta pessoal
	$canUploadSkin		=  true; //Possibilita enviar skins
	$canUploadCloak		=  true; //Possibilita enviar capas
	$canBuyVip			=  true; //Permite adquirir VIP
	$canBuyPremium		=  true; //Permite adquirir Premium
	$canBuyUnban		=  true; //Permite adquirir Unban
	$canActivateVaucher =  true; //Permite ativar voucher
	$canExchangeMoney   =  true; //Permite alterar dinheiro Realmoney -> IConomy
	$canUseJobs			=  true; //Permite usar o Jobs
	$usecheck			=  true; //Permite logar no launcher
	
	$cloakPrice			=  0;    //Preço da capa (R$)
	$vipPrice			=  100;  //Preço do VIP (R$/mês)
	$premiumPrice		=  250;  //Preço do Premium (R$/mês)
	$unbanPrice			=  150;  //Preço do Unban (R$)
	
	$initialIconMoney	=  30;  //Quantia de dinheiro que o player começa (iEconomy)
	$exchangeRate		=  200; //Taxa de câmbio Realmoney -> IConomy
	
	//NÃO ALTERE NADA ABAIXO
	try {
		$db = new PDO("mysql:host=$db_host;port=$db_port;dbname=$db_database", $db_user, $db_pass);
		$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
		$db->exec("set names utf8");
	} catch(PDOException $pe) {
		die(Security::encrypt("errorsql", $key1).$logger->WriteLine($log_date.$pe));  //Saída de erro do MySQL em m.log
	}
?>