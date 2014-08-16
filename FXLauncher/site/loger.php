<?php
date_default_timezone_set('America/Sao_Paulo');
	$logger = new Logger("./m.log");
    $log_date = "[" . date("d m Y H:i") . "] ";
class Logger {
    var $file;
    var $error;
    function __construct($path)
    {
        $this->file = $path;
    }
    function WriteLine($text)
    {
        $fp = fopen($this->file, "a+");
        if($fp)
        {
            fwrite($fp,$text . "\n");
        } else {
            $this->error = "Entradas incorretas no arquivo log";
        }
        fclose($fp);
    }
    function Read()
    {
        if(file_exists($this->file))
        {
            return file_get_contents($this->file);
        } else {
            $this->error = "O arquivo n?o existe";
        }
    }
    function Clear()
    {
        $fp = fopen($this->file,"a+");
        if($fp)
        {
            ftruncate($fp,0);
        } else {
            $this->error = "Falha na leitura do arquivo log";
        }
        fclose($fp);
    }
}
?>