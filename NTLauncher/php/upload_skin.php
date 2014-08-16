<?php	
	$login = trim($_POST['user']);
	
	if ( (strlen($login) < 3) || (!preg_match('/^[0-9a-zA-Z]+$/', $login)) ) { echo "FAIL"; exit; }
	
	if( is_uploaded_file($_FILES['skin']['tmp_name']) )
	{ 
		move_uploaded_file( $_FILES["skin"]["tmp_name"], "MinecraftSkins/$login.png" );
		echo "OK";
	} else { 
		echo "FAIL"; 
	}
?>