<?php
/**
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Pierre Spring <pierre.spring@liip.ch>
 */
 
// must be run within Dokuwiki
if (!defined('DOKU_INC')) die();
 
class helper_plugin_fckg extends DokuWiki_Plugin {
 
  function getInfo(){
    return array(
      'author' => 'pierre spring',
      'email'  => 'pierre.spring@liip.ch',
      'date'   => '2007-05-15',
      'name'   => 'FCKW Plugin',
      'desc'   => 'Various Helper Functions',
      'url'    => 'https://fosswiki.liip.ch/display/FCKW/Home',
    );
  }
 
  function getMethods(){
    $result = array();
    $result[] = array(
      'name'   => 'registerOnLoad',
      'desc'   => 'register some javascript to the window.onload js event',
      'params' => array('js' => 'string'),
      'return' => array('html' => 'string'),
    );
    return $result;
  }

  function registerOnLoad($js){
  global $ID;
  $media_tmp_ns = preg_match('/:/',$ID) ? preg_replace('/:\w+$/',"",$ID,1) : "";    
    return <<<end_of_string

<script type='text/javascript'>

var oldonload = window.onload;
if (typeof window.onload != 'function') {
  window.onload = function(){
    $js
  }
} else {
  window.onload = function() 
  {
    oldonload();
    $js

  }
}

  function getCurrentWikiNS() {
        var   DWikiMediaManagerCommand_ns = '$media_tmp_ns';
        return DWikiMediaManagerCommand_ns;
  }


</script>
end_of_string;
  }
}
?>
