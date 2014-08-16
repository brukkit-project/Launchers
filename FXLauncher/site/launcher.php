<?php
    header('Content-Type: text/html; charset=UTF-8');
	define('INCLUDE_CHECK',true);
	include("connect.php");
	include_once("loger.php");
	include_once("security.php");
    @$x  = $_POST['action'];
    @$x = str_replace(" ", "+", $x);
    @$yd = Security::decrypt($x, $key2);
    @list($action, $client, $login, $postPass, $launchermd5, $ctoken) = explode(':', $yd);

	if(!file_exists($uploaddirs)) die ("O caminho para a skin não é uma pasta! Especifique o caminho correto.");
	if(!file_exists($uploaddirp)) die ("O caminho para a capa não é uma pasta! Especifique o caminho correto.");
	
	try {
		
	if (!preg_match("/^[a-zA-Z0-9_-]+$/", $login) || !preg_match("/^[a-zA-Z0-9_-]+$/", $postPass) || !preg_match("/^[a-zA-Z0-9_-]+$/", $action)) {
	
		exit(Security::encrypt("errorLogin<$>", $key1));
    }	
	

    if($ctoken == "null") {


	if($crypt === 'hash_md5' || $crypt === 'hash_authme' || $crypt === 'hash_xauth' || $crypt === 'hash_cauth' || $crypt === 'hash_joomla' || $crypt === 'hash_joomla_new' || $crypt === 'hash_wordpress' || $crypt === 'hash_dle' || $crypt === 'hash_launcher' || $crypt === 'hash_drupal' || $crypt === 'hash_imagecms') {
		$stmt = $db->prepare("SELECT $db_columnUser,$db_columnPass FROM $db_table WHERE $db_columnUser= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$stmt->bindColumn($db_columnPass, $realPass);
		$stmt->bindColumn($db_columnUser, $realUser);
		$stmt->fetch();
	} else if ($crypt === 'hash_ipb' || $crypt === 'hash_vbulletin' || $crypt === 'hash_punbb') {
		
		$stmt = $db->prepare("SELECT $db_columnUser,$db_columnPass,$db_columnSalt FROM $db_table WHERE $db_columnUser= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$stmt->bindColumn($db_columnPass, $realPass);
		$stmt->bindColumn($db_columnSalt, $salt);
		$stmt->bindColumn($db_columnUser, $realUser);
		$stmt->fetch();
	} else if($crypt == 'hash_xenforo') {
		
		$stmt = $db->prepare("SELECT scheme_class, $db_table.$db_columnId,$db_table.$db_columnUser,$db_tableOther.$db_columnId,$db_tableOther.$db_columnPass FROM $db_table, $db_tableOther WHERE $db_table.$db_columnId = $db_tableOther.$db_columnId AND $db_table.$db_columnUser= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$stmt->bindColumn($db_columnPass, $salt);
		$stmt->bindColumn($db_columnUser, $realUser);
		$stmt->fetch();
		$stmt->execute();
		$stmt->bindColumn($db_columnPass, $realPass);
		$stmt->bindColumn('scheme_class', $scheme_class);
		$stmt->fetch();	
		$realPass = substr($realPass,22,64);
		if($scheme_class==='XenForo_Authentication_Core') {
			$salt = substr($salt,105,64);
		} else $salt = false;
	} else die(Security::encrypt("badhash<$>", $key1));

	$checkPass = hash_name($crypt, $realPass, $postPass, @$salt);

	if($useantibrut) {	
		$ip  = getenv('REMOTE_ADDR');	
		$time = time();
		$bantime = $time+(10);
		$stmt = $db->prepare("Select sip,time From sip Where sip='$ip' And time>'$time'");
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$real = $row['sip'];
		if($ip == $real) {
			$stmt = $db->prepare("DELETE FROM sip WHERE time < '$time';");
			$stmt->execute();
			exit(Security::encrypt("temp<$>", $key1));
		}
		
		if ($login !== $realUser) {
			$stmt = $db->prepare("INSERT INTO sip (sip, time)VALUES ('$ip', '$bantime')");
			$stmt->execute();
			exit(Security::encrypt("errorLogin<$>", $key1));
		}
		if(!strcmp($realPass,$checkPass) == 0 || !$realPass) {
			$stmt = $db->prepare("INSERT INTO sip (sip, time)VALUES ('$ip', '$bantime')");
			$stmt->execute();
			exit(Security::encrypt("errorLogin<$>", $key1));
		}

    } else {
		if ($login !== $realUser) {
			exit(Security::encrypt("errorLogin<$>", $key1)); }
		if(!strcmp($realPass,$checkPass) == 0 || !$realPass) die(Security::encrypt("errorLogin<$>", $key1));
    }}

        if($ctoken == "null") {
         	$acesstoken = token();
        } else {
         	$acesstoken = $postPass;
        }
		$sessid = token();
        $stmt = $db->prepare("SELECT id, user, token FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$rU = $stmt->fetch(PDO::FETCH_ASSOC);
		if($rU['user'] != null) {
            $realUser = $rU['user'];
		}

        if($ctoken != "null") {

		if($rU['token'] != $acesstoken ) {
	        	exit(Security::encrypt("errorLogin<$>", $key1));
			}
	    }
		if($login == $rU['user']) {
            if($ctoken == "null") {
				$stmt = $db->prepare("UPDATE usersession SET session = '$sessid', token = :token WHERE user= :login");
				$stmt->bindValue(':token', $acesstoken);
            }
            else {
            	$stmt = $db->prepare("UPDATE usersession SET session = '$sessid' WHERE user= :login");
            }
			$stmt->bindValue(':login', $login);
			$stmt->execute();
		}
		else if($ctoken == "null" || $login != $rU['user']) {
			$stmt = $db->prepare("INSERT INTO usersession (user, session, md5, token) VALUES (:login, '$sessid', :md5, '$acesstoken')");
			$stmt->bindValue(':login', $realUser);
			$stmt->bindValue(':md5', md5($realUser));
			$stmt->execute();
		}
	
	if($useban) {
	    $time = time();
	    $tipe = '2';
		$stmt = $db->prepare("Select name From $banlist Where name= :login And type<'$tipe' And temptime>'$time'");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
	    if($stmt->rowCount()) {
			$stmt = $db->prepare("Select name,temptime From $banlist Where name= :login And type<'$tipe' And temptime>'$time'");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			exit(Security::encrypt('Banimento temporário para '.date('d.m.Yг. H:i', $row['temptime'])." Hora do servidor", $key1));
	    }
			$stmt = $db->prepare("Select name From $banlist Where name= :login And type<'$tipe' And temptime='0'");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
		if($stmt->rowCount()) {
	      exit(Security::encrypt("Ban eterno", $key1));
	    }
	}
	if($action == 'getpersonal' && !$usePersonal) die("LK está desativado");
	if($action == 'uploadskin' && !$canUploadSkin) die("Função não está disponível");
	if($action == 'uploadcloak' && !$canUploadCloak) die("Função não está disponível");
	if($action == 'buyvip' && !$canBuyVip) die("Função não está disponível");
	if($action == 'buypremium' && !$canBuyPremium) die("Função não está disponível");
	if($action == 'buyunban' && !$canBuyUnban) die("Função não está disponível");
	if($action == 'exchange' && !$canExchangeMoney) die("Função não está disponível");
	if($action == 'activatekey' && !$canActivateVaucher) die("Função não está disponível");

	if($action == 'exchange' || $action == 'getpersonal') {
			$stmt = $db->prepare("SELECT username,balance FROM iConomy WHERE username= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$rowicon = $stmt->fetch(PDO::FETCH_ASSOC);
			$iconregistered = true;
		
		if(!$rowicon['balance']) {
			$stmt = $db->prepare("INSERT INTO `iConomy` (`username`, `balance`, `status`) VALUES (:login, '$initialIconMoney.00', '0');");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$iconregistered = false;
		}
	}
    
	if($action == 'auth') {

	if($checklauncher) {
	if($launchermd5 != null) {
    if($launchermd5 == @$md5launcherexe) {
		    $check = "1";
		    }
		    if($launchermd5 == @$md5launcherjar) {
		       $check = "1";
		    }
		}
		if(!@$check == "1") {
			exit(Security::encrypt("badlauncher<$>_$masterversion", $key1));
		}
	}

        if($assetsfolder)
        { $z = "/"; } else { $z = ".zip"; }

		if(!file_exists("clients/assets".$z)||!file_exists("clients/".$client."/bin/")||!file_exists("clients/".$client."/mods/")||!file_exists("clients/".$client."/coremods/")||!file_exists("clients/".$client."/config.zip"))
		die(Security::encrypt("client<$> $client", $key1));

    	$md5us = md5($realUser);
        $md5user  = strtoint(xorencode($md5us, $protectionKey));
        $md5zip	  = @md5_file("clients/".$client."/config.zip");
        $md5ass	  = @md5_file("clients/assets.zip");
        $sizezip  = @filesize("clients/".$client."/config.zip");
        $sizeass  = @filesize("clients/assets.zip");
		$echo1    =  "$masterversion<:>$md5user<:>".$md5zip."<>".$sizezip."<:>".$md5ass."<>".$sizeass."<br>".$realUser.'<:>'.strtoint(xorencode($sessid, $protectionKey)).'<br>'.$acesstoken.'<br>';

        if($assetsfolder) {
            echo Security::encrypt($echo1.str_replace("\\", "/",checkfiles('clients/'.$client.'/bin/').checkfiles('clients/'.$client.'/mods/').checkfiles('clients/'.$client.'/coremods/').checkfiles('clients/assets')).'<::>assets/indexes<:b:>assets/objects<:b:>assets/virtual<:b:>'.$client.'/bin<:b:>'.$client.'/mods<:b:>'.$client.'/coremods<:b:>', $key1);
        } else {
            echo Security::encrypt($echo1.
            	str_replace("\\", "/",checkfiles('clients/'.$client.'/bin/').checkfiles('clients/'.$client.'/mods/').checkfiles('clients/'.$client.'/coremods/')).'<::>'.$client.'/bin<:b:>'.$client.'/mods<:b:>'.$client.'/coremods<:b:>', $key1);
        }
  
	} else if($action == 'getpersonal') {
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$realmoney = $row['realmoney'];

		if($iconregistered) {	
			$stmt = $db->prepare("SELECT username,balance FROM iConomy WHERE username= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			$iconmoney = $row['balance'];
		} else $iconmoney = "0.0";
		
		if($canBuyVip || $canBuyPremium) {
			
			$stmt = $db->prepare("SELECT name,permission,value FROM permissions WHERE name= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			$datetoexpire = 0;
			if(!$stmt) $ugroup = 'User'; else {
				$group = $row['permission'];
				if($group == 'group-premium-until')
				{
					$ugroup = 'Premium';
					$datetoexpire = $row['value'];
				} else if($group == 'group-vip-until')
				{
					$ugroup = 'VIP';
					$datetoexpire = $row['value'];
				} else $ugroup = 'User';
			}
		} else {
			$datetoexpire = 0;
			$ugroup = 'User';
		}
	
		if($canUseJobs) {
			$stmt = $db->prepare("SELECT job FROM jobs WHERE username= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$sql = $stmt->fetch(PDO::FETCH_ASSOC);
			$query = $sql['job'];
			if($query == '') { $jobname = "Desempregado"; $joblvl = 0; $jobexp = 0; } else {
				$stmt = $db->prepare("SELECT * FROM jobs WHERE username= :login");
				$stmt->bindValue(':login', $login);
				$stmt->execute();
				
				while($data = $stmt->fetch(PDO::FETCH_ASSOC))
				{
					if ($data["job"] === 'Miner') $data["job"] = 'Minerador';
					if ($data["job"] === 'Woodcooter') $data["job"] = 'Lenhador';
					if ($data["job"] === 'Builder') $data["job"] = 'Construtor';
					if ($data["job"] === 'Digger') $data["job"] = 'Escavador';
					if ($data["job"] === 'Farmer') $data["job"] = 'Agricultor';
					if ($data["job"] === 'Hunter') $data["job"] = 'Caçador';
					if ($data["job"] === 'Fisherman') $data["job"] = 'Pescador';
					if ($data["job"] === 'Weaponsmith') $data["job"] = 'Armeiro';
					
					$jobname = $data['job'];
					$joblvl = $data["level"];
					$jobexp = $data["experience"];
				}
			}
		} else { $jobname = "nojob"; $joblvl = -1; $jobexp = -1; }
		
		$canUploadSkin 		= (int)$canUploadSkin;
		$canUploadCloak		= (int)$canUploadCloak;
		$canBuyVip	   		= (int)$canBuyVip;
		$canBuyPremium 		= (int)$canBuyPremium;
		$canBuyUnban   		= (int)$canBuyUnban;
		$canActivateVaucher = (int)$canActivateVaucher;
		$canExchangeMoney	= (int)$canExchangeMoney;
	
		if($canBuyUnban == 1) {
		    $ty = 2;
			$stmt = $db->prepare("SELECT name,type FROM $banlist WHERE name= :login and type<'$ty'");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$sql2 = $stmt->fetch(PDO::FETCH_ASSOC);
			$query2 = $sql2['name'];
			if(strcasecmp($query2, $login) == 0) $ugroup = "Banned";
		}
		
		echo "$canUploadSkin$canUploadCloak$canBuyVip$canBuyPremium$canBuyUnban$canActivateVaucher$canExchangeMoney<:>$iconmoney<:>$realmoney<:>$cloakPrice<:>$vipPrice<:>$premiumPrice<:>$unbanPrice<:>$exchangeRate<:>$ugroup<:>$datetoexpire<:>$jobname<:>$joblvl<:>$jobexp";
	} else
//============================================Funções====================================//

	if($action == 'activatekey') {
		$key = $_POST['key'];
		$stmt = $db->prepare("SELECT * FROM `sashok724_launcher_keys` WHERE `key` = :k"); 
		$stmt->bindValue(':k', $key);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$amount = $row['amount'];
		if($amount) {
			$stmt = $db->prepare("UPDATE usersession SET realmoney = realmoney + $amount WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$stmt = $db->prepare("DELETE FROM `sashok724_launcher_keys` WHERE `key` = :k");
			$stmt->bindValue(':k', $key);
			$stmt->execute();	
			$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);	
			$money = $row['realmoney'];
			echo "success:".$money;
		} else echo "keyerr";
	} else if($action == 'uploadskin') {
		if(!is_uploaded_file($_FILES['ufile']['tmp_name'])) die("nofile");
		$imageinfo = getimagesize($_FILES['ufile']['tmp_name']);
		if($imageinfo['mime'] != 'image/png' || $imageinfo["0"] != '64' || $imageinfo["1"] != '32') die("skinerr");
		$uploadfile = "".$uploaddirs."/".$login.".png";
		if(move_uploaded_file($_FILES['ufile']['tmp_name'], $uploadfile)) echo "success";
		else echo "fileerr";
	} else if($action == 'uploadcloak') {
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$query = $row['realmoney']; if($query < $cloakPrice) die("moneyno");
		if(!is_uploaded_file($_FILES['ufile']['tmp_name'])) die("nofile");
		$imageinfo = getimagesize($_FILES['ufile']['tmp_name']);
		$go = false;
		if(($imageinfo['mime'] != 'image/png' || $imageinfo["0"] == '64' || $imageinfo["1"] == '32')){
		$go = true;
		} else echo 'cloakerr';
		if($go) {
		$uploadfile = "".$uploaddirp."/".$login.".png";
		if(!move_uploaded_file($_FILES['ufile']['tmp_name'], $uploadfile)) die("fileerr");
		$stmt = $db->prepare("UPDATE usersession SET realmoney = realmoney - $cloakPrice WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		echo "success:".$row['realmoney'];
	}} else if($action == 'buyvip') {
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$query = $row['realmoney']; if($query < $vipPrice) die("moneyno");
	    $stmt = $db->prepare("SELECT name,permission FROM permissions WHERE name= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$group = $row['permission'];
		$pexdate = time() + 2678400;
		if($group == 'group-vip-until') {	
			$stmt = $db->prepare("UPDATE usersession SET realmoney=realmoney-$vipPrice WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$stmt = $db->prepare("UPDATE permissions SET value=value+2678400 WHERE name= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
		} else {
			$stmt = $db->prepare("INSERT INTO permissions (id, name, type, permission, world, value) VALUES (NULL, :login, '1', 'group-vip-until', ' ', '$pexdate')");
			$stmt->bindValue(':login', $login);
			$stmt->execute();	
			$stmt = $db->prepare("INSERT INTO permissions_inheritance (id, child, parent, type, world) VALUES (NULL, :login, 'vip', '1', NULL)");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$stmt = $db->prepare("UPDATE usersession SET realmoney=realmoney-$vipPrice WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
		}
			$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			echo "success:".$row['realmoney'].":";
			$stmt = $db->prepare("SELECT name,permission,value FROM permissions WHERE name= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			echo $row['value'];
	} else if($action == 'buypremium') {
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$query = $row['realmoney']; if($query < $premiumPrice) die("moneyno");
		$stmt = $db->prepare("SELECT name,permission FROM permissions WHERE name= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$group = $row['permission'];
		$pexdate = time() + 2678400;
		if($group == 'group-premium-until') {
			$stmt = $db->prepare("UPDATE usersession SET realmoney=realmoney-$premiumPrice WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$stmt = $db->prepare("UPDATE permissions SET value=value+2678400 WHERE name= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
		} else {
			$stmt = $db->prepare("INSERT INTO permissions (id, name, type, permission, world, value) VALUES (NULL, :login, '1', 'group-premium-until', ' ', '$pexdate')");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$stmt = $db->prepare("INSERT INTO permissions_inheritance (id, child, parent, type, world) VALUES (NULL, :login, 'premium', '1', NULL)");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$stmt = $db->prepare("UPDATE usersession SET realmoney=realmoney-$premiumPrice WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
		}
			$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			echo "success:".$row['realmoney'].":";
			$stmt = $db->prepare("SELECT name,permission,value FROM permissions WHERE name= :login");
			$stmt->bindValue(':login', $login);
			$stmt->execute();
			$row = $stmt->fetch(PDO::FETCH_ASSOC);
			echo $row['value'];
	} else if($action == 'buyunban') {
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$sql1 = $stmt->fetch(PDO::FETCH_ASSOC);
		$query1 = $sql1['realmoney'];
		$stmt = $db->prepare("SELECT name FROM $banlist WHERE name= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$sql2 = $stmt->fetch(PDO::FETCH_ASSOC);
		$query2 = $sql2['name'];
		if(strcasecmp($query2, $login) == 0) {
			if($query1 >= $unbanPrice) {
				if($canBuyVip || $canBuyPremium) {
					$stmt = $db->prepare("SELECT name,permission,value FROM permissions WHERE name= :login");
					$stmt->bindValue(':login', $login);
					$stmt->execute();
					$row = $stmt->fetch(PDO::FETCH_ASSOC);
					$group = $row['permission'];
					if(!$stmt) $ugroup = 'User'; else {
						if($group == 'group-premium-until') $ugroup = 'Premium';
						else if($group == 'group-vip-until') $ugroup = 'VIP';
						else $ugroup = 'User';
					}
				} else $ugroup = 'User';
					$stmt = $db->prepare("DELETE FROM $banlist WHERE name= :login");
					$stmt->bindValue(':login', $login);
					$stmt->execute();
					$stmt = $db->prepare("UPDATE usersession SET realmoney=realmoney-$unbanPrice WHERE user= :login");
					$stmt->bindValue(':login', $login);
					$stmt->execute();
					$stmt = $db->prepare("SELECT $db_columnUser,realmoney FROM usersession WHERE user= :login");
					$stmt->bindValue(':login', $login);
					$stmt->execute();
					$row = $stmt->fetch(PDO::FETCH_ASSOC);
				echo "success:".$row['realmoney'].":".$ugroup;
			} else die('moneyno');
		} else die("banno");
	} else if($action == 'exchange') {
		$wantbuy =$_POST ['buy'];
		$gamemoneyadd = ($wantbuy * $exchangeRate);
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$query = $row['realmoney'];
		if($wantbuy == '' || $wantbuy < 1) die("ecoerr");
		if(!$iconregistered) die("econo");
		if($query < $wantbuy) die("moneyno");
		$stmt = $db->prepare("UPDATE iConomy SET balance = balance + $gamemoneyadd WHERE username= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$stmt = $db->prepare("UPDATE usersession SET realmoney = realmoney - :wantbuy WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->bindValue(':wantbuy', $wantbuy);
		$stmt->execute();
		$stmt = $db->prepare("SELECT user,realmoney FROM usersession WHERE user= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$money = $row['realmoney'];
		$stmt = $db->prepare("SELECT username,balance FROM iConomy WHERE username= :login");
		$stmt->bindValue(':login', $login);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		$iconmoney = $row['balance'];
		echo "success:".$money.":".$iconmoney;
	} else echo "Sua consulta é inválida";
	
	} catch(PDOException $pe) {
		die(Security::encrypt("errorsql<$>", $key1).$logger->WriteLine($log_date.$pe));  //Saída de erro do MySQL em m.log
	}
	//===================================== Funções auxiliares ==================================//

	function xorencode($str, $key) {
		while(strlen($key) < strlen($str)) {
			$key .= $key;
		}
		return $str ^ $key;
	}

	function strtoint($text) {
		$res = "";
		for ($i = 0; $i < strlen($text); $i++) $res .= ord($text{$i}) . "-";
		$res = substr($res, 0, -1);
		return $res;
	}

	function hash_name($ncrypt, $realPass, $postPass, $salt) {
		$cryptPass = false;
		
		if ($ncrypt === 'hash_xauth') {
				$saltPos = (strlen($postPass) >= strlen($realPass) ? strlen($realPass) : strlen($postPass));
				$salt = substr($realPass, $saltPos, 12);
				$hash = hash('whirlpool', $salt . $postPass);
				$cryptPass = substr($hash, 0, $saltPos) . $salt . substr($hash, $saltPos);
		}

		if ($ncrypt === 'hash_md5' or $ncrypt === 'hash_launcher') {
				$cryptPass = md5($postPass);
		}

		if ($ncrypt === 'hash_dle') {
				$cryptPass = md5(md5($postPass));
		}

		if ($ncrypt === 'hash_cauth') {
				if (strlen($realPass) < 32) {
						$cryptPass = md5($postPass);
						$rp = str_replace('0', '', $realPass);
						$cp = str_replace('0', '', $cryptPass);
						(strcasecmp($rp,$cp) == 0 ? $cryptPass = $realPass : $cryptPass = false);
				}
				else $cryptPass = md5($postPass);
		}

		if ($ncrypt === 'hash_authme') {
				$ar = preg_split("/\\$/",$realPass);
				$salt = $ar[2];
				$cryptPass = '$SHA$'.$salt.'$'.hash('sha256',hash('sha256',$postPass).$salt);
		}

		if ($ncrypt === 'hash_joomla') {
				$parts = explode( ':', $realPass);
				$salt = $parts[1];
				$cryptPass = md5($postPass . $salt) . ":" . $salt;
		}
				
		if ($ncrypt === 'hash_imagecms') {
		        $majorsalt = '';
				if ($salt != '') {
					$_password = $salt . $postPass;
				} else {
					$_password = $postPass;
				}
				
				$_pass = str_split($_password);
				
				foreach ($_pass as $_hashpass) {
					$majorsalt .= md5($_hashpass);
				}
				
				$cryptPass = crypt(md5($majorsalt), $realPass);
		}

		if ($ncrypt === 'hash_joomla_new' or $ncrypt === 'hash_wordpress' or $ncrypt === 'hash_xenforo') {
		
				if($ncrypt === 'hash_xenforo' and $salt!==false) {
					return $cryptPass = hash('sha256', hash('sha256', $postPass) . $salt);
				}
				
				$itoa64 = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
				$cryptPass = '*0';
				if (substr($realPass, 0, 2) == $cryptPass)
					$cryptPass = '*1';

				$id = substr($realPass, 0, 3);
				# We use "$P$", phpBB3 uses "$H$" for the same thing
				if ($id != '$P$' && $id != '$H$')
					return $cryptPass = crypt($postPass, $realPass);

				$count_log2 = strpos($itoa64, $realPass[3]);
				if ($count_log2 < 7 || $count_log2 > 30)
					return $cryptPass = crypt($postPass, $realPass);

				$count = 1 << $count_log2;

				$salt = substr($realPass, 4, 8);
				if (strlen($salt) != 8)
					return $cryptPass = crypt($postPass, $realPass);

					$hash = md5($salt . $postPass, TRUE);
					do {
						$hash = md5($hash . $postPass, TRUE);
					} while (--$count);

				$cryptPass = substr($realPass, 0, 12);
				
				$encode64 = '';
				$i = 0;
				do {
					$value = ord($hash[$i++]);
					$encode64 .= $itoa64[$value & 0x3f];
					if ($i < 16)
						$value |= ord($hash[$i]) << 8;
					$encode64 .= $itoa64[($value >> 6) & 0x3f];
					if ($i++ >= 16)
						break;
					if ($i < 16)
						$value |= ord($hash[$i]) << 16;
					$encode64 .= $itoa64[($value >> 12) & 0x3f];
					if ($i++ >= 16)
						break;
					$encode64 .= $itoa64[($value >> 18) & 0x3f];
				} while ($i < 16);
				
				$cryptPass .= $encode64;

				if ($cryptPass[0] == '*')
					$cryptPass = crypt($postPass, $realPass);
		}
		
		if ($ncrypt === 'hash_ipb') {
				$cryptPass = md5(md5($salt).md5($postPass));
		}
		
		if ($ncrypt === 'hash_punbb') {
				$cryptPass = sha1($salt.sha1($postPass));
		}

		if ($ncrypt === 'hash_vbulletin') {
				$cryptPass = md5(md5($postPass) . $salt);
		}

		if ($ncrypt === 'hash_drupal') {
				$setting = substr($realPass, 0, 12);
				$itoa64 = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
				$count_log2 = strpos($itoa64, $setting[3]);
				$salt = substr($setting, 4, 8);
				$count = 1 << $count_log2;
				$input = hash('sha512', $salt . $postPass, TRUE);
				do $input = hash('sha512', $input . $postPass, TRUE);
				while (--$count);

				$count = strlen($input);
				$i = 0;
		  
				do {
						$value = ord($input[$i++]);
						$cryptPass .= $itoa64[$value & 0x3f];
						if ($i < $count) $value |= ord($input[$i]) << 8;
						$cryptPass .= $itoa64[($value >> 6) & 0x3f];
						if ($i++ >= $count) break;
						if ($i < $count) $value |= ord($input[$i]) << 16;
						$cryptPass .= $itoa64[($value >> 12) & 0x3f];
						if ($i++ >= $count) break;
						$cryptPass .= $itoa64[($value >> 18) & 0x3f];
				} while ($i < $count);
				$cryptPass =  $setting . $cryptPass;
				$cryptPass =  substr($cryptPass, 0, 55);
		}
		
		return $cryptPass;
	}

	    function checkfiles($path) {
        $objects = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($path), RecursiveIteratorIterator::SELF_FIRST);
        $massive = "";
		    foreach($objects as $name => $object) {
			    $basename = basename($name);
			    $isdir = is_dir($name);
			    if ($basename!="." and $basename!=".." and !is_dir($name)){
			     	$str = str_replace('clients/', "", str_replace($basename, "", $name));
			     	$massive = $massive.$str.$basename.':>'.md5_file($name).':>'.filesize($name).'<:>';
			    }
		    }
		    return $massive;
        }

        function token() {
        $chars="0123456789abcdef";
        $max=64;
        $size=StrLen($chars)-1;
        $password=null;
        while($max--)
        $password.=$chars[rand(0,$size)];

          return 'token'.$password;
        }

?>
