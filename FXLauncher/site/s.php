<?php
define('INCLUDE_CHECK',true);
include("connect.php");
@$get = $_GET['user'];
list($md5) = explode('?', $get);

$stmt = $db->prepare("SELECT user,md5 FROM usersession WHERE md5= :md5");
$stmt->bindValue(':md5', $md5);
$stmt->execute();
$stmt->bindColumn($db_columnUser, $realUser);
$stmt->fetch();
$time = time();
$base64 = '{"timestamp":"'.$time.'","profileId":"'.$md5.'","profileName":"'.$realUser.'","isPublic":true,"textures":{"SKIN":{"url":"'.$skinurl .''.$realUser.'.png"}}}';
echo '{"id":"'.$md5.'","name":"'.$realUser.'","properties":[{"name":"textures","value":"'.base64_encode($base64).'","signature":""}]}';