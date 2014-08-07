<?php

error_reporting(E_ALL);
ini_set('date.timezone', 'UTC');
date_default_timezone_set('UTC');

// variables
$PnDir = getcwd();
$sysroot = env('SystemRoot');
$htd_dir = env('htd_dir');
$php_dir = str_replace('\\','/',env('php_dir'));
$htd_cfg = $htd_dir.'\conf\httpd.conf';
$php_ini = $php_dir.'\php.ini';

// Load
if (count($argv) > 1) {
  $a = implode(' ',$argv);
  $a = substr($a, strlen($argv[0]) + 1);
  $a = str_replace('`', '"', $a);
  eval($a);
}
exit;
// end of Load


// �˳�(��Ϣ $m, ������� $n);
function quit($m, $n) {
  echo "\r\n ".$m."\r\n";
  exit($n);
}


function env($n) { return getenv($n); }


function rpl($a, $b, $c) { return str_replace($a, $b, $c);}


// ���¶��� preg_replace()
function regrpl($p, $r, $s) {
  $p = '/'.$p.'/im';
  $s = preg_replace($p, $r, $s);
  if ($s === NULL) quit('regrpl(): ����! Ϊ�������ݶ���ֹ.', 1);
  return $s;
}


// ��ȡ�������ļ� $fn ������
function rfile($fn) {
  if (file_exists($fn)) {
    $handle = fopen($fn, 'r');
    $c = fread($handle, filesize($fn));
    fclose($handle);
    return $c;
  } else {
    quit('�ļ� '.$fn.' ������', 1);
  }
}


// д������ $c ���ļ� $fn
function wfile($fn, $c) {
  if (!is_writable($fn) && file_exists($fn))
    quit('�ļ� '.$fn.' ����д', 1);
  else {
    $handle = fopen($fn, 'w');
    if (fwrite($handle, $c) === FALSE)
      quit('д���ļ� '.$fn.' ʧ��', 1);
    fclose($handle);
  }
}


// �����ļ� $a �� $b
function cp($a, $b) {
  $c = rfile($a);
  wfile($b, $c);
}


// ���ļ� $fn ʹ��������ʽ $p �滻Ϊ $r
function frpl($fn, $p, $r) {
  global $htd_dir, $php_dir, $htd_cfg, $vhs_cfg, $php_ini;

  $s = rfile($fn);
  $p = '/'.$p.'/im';
  $s = preg_replace($p, $r, $s);
  wfile($fn, $s);
}


function chk_path($path) {
  $str = regrpl('[^\x80-\xff]+', '', $path);
  if (!$str) exit(0);
  echo "\r\n # ·�����ɺ���˫�ֽ��ַ�: ".$str."\r\n";
  echo "\r\n # ���� Apache + PHP ��������������.";
  echo "\r\n # �뻻һ������Ӣ���ַ���·������.\r\n\r\n";
  exit(1);
}


// check port
// ���˿��Ƿ�ռ��. netstat + tasklist
function chk_port($port) {
  $s = shell_exec('netstat.exe -ano');
  $tok = strtok($s, ' ');
  $pid = NULL;
  while ($tok) {
    if ($tok == '0.0.0.0:'.$port) {
      for ($i=3; $i; $i--)
        $pid = rtrim(strtok(' '));
      if (is_numeric($pid))
        break;
    }
    $tok = strtok(' ');
  }

  $task = NULL;
  if (is_numeric($pid)) {
    $lst = array(
      'WebThunder.exe'  => 'Web Ѹ��',
      'inetinfo.exe'    => 'IIS',
      'Thunder5.exe'    => 'Ѹ��5',
      'httpd.exe'       => 'Apache 2.2',
      'mysqld-nt.exe'   => 'MySQL',
      'mysqld.exe'   => 'MySQL');
    $s = shell_exec('tasklist.exe /fi "pid eq '.$pid.'" /nh');
    $task = trim(strtok($s, ' '));
    $d = ' ';
    if (isset($lst[$task]))
      $d = ' "'.$lst[$task].'" ';
    quit(' �˿� '.$port.' �ѱ�'.$d.'('.$task.' PID '.$pid.') ʹ��!', 1);
  }
}


// change httpd port
function chg_port($newport) {
  global $htd_cfg, $vhs_cfg;
  if (file_exists($htd_cfg)) {
    $c = rfile($htd_cfg);
    $c = regrpl('^([ \t]*Listen[ \t]+[^:]+):\d+(\r\n)', '$1:'.$newport.'$2', $c);
    $c = regrpl('^([ \t]*Listen)[ \t]+\d+(\r\n)', '$1 '.$newport.'$2', $c);
    $c = regrpl('^([ \t]*ServerName[ \t]+[^:]+):\d+(\r\n)', '$1:'.$newport.'$2', $c);
    wfile($htd_cfg, $c);
  }

  if (file_exists($vhs_cfg)) frpl($vhs_cfg, '(ServerName[ \t]+[^:]+):\d+', '$1:'.$newport);
  frpl('Pn/Config.cmd', '^(set htd_port)=\d+(\r\n)', '$1='.$newport.'$2');
}


// update config
function upcfg() {
  global $htd_dir, $php_dir, $htd_cfg, $php_ini, $PnDir, $sysroot;

  // php.ini
  $str = rfile($php_ini);
  $str = regrpl('^(extension_dir)[ \t]+=[ \t]+"[^"]+"', '$1 = "'.$php_dir.'/ext"', $str);
  wfile($php_ini, $str);

  // httpd.conf
  $str = rfile($htd_cfg);
  $str = regrpl('(php5_module )\S+', '$1"'.$php_dir.'/php5apache2_2.dll"', $str);
  $str = regrpl('(PHPIniDir )\S+'  , '$1'.$php_dir, $str);
  wfile($htd_cfg, $str);

}

// check mysql connection
function chk_mysql($port, $pwd) {
  dl('php_mysql.dll');
  for($n=0; $n<3; $n++) {
    $link = @mysql_connect('localhost:'.$port, 'root', $pwd);
    if ($link) {
      mysql_close($link);
      exit();
    }
    $errno = mysql_errno();
    if ($errno === 1045) exit($errno);
    echo ' # �������� MySQL, ���Ե�...'."\r\n";
    sleep(2);
  }
  exit($errno);
}

?>