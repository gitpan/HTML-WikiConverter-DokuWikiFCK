<?php
/**
 * 
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Myron Turner <turnermm02@shaw.ca>
 */

// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();
 
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');
 
/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_fckg_indent extends DokuWiki_Syntax_Plugin {
 
   
    /**
     * return some info
     */
    function getInfo(){
        return array(
            'author' => 'Myron Turner',
            'email'  => 'turnermm02@shaw.ca',
            'date'   => '2007-07-26',
            'name'   => 'indent Plugin',
            'desc'   => 'handles space-bar indenting for gckg',
            'url'    => 'http://www.mturner.org/development/',
        );
    }
 
    function getType(){ return 'formatting'; }
    function getAllowedTypes() { return array('disabled'); }   
    function getSort(){ return 190; }
    function connectTo($mode) {
         $this->Lexer->addSpecialPattern('<indent.*?</indent>',$mode,'plugin_fckg_indent'); 
	$this->Lexer->addSpecialPattern('<br />',$mode,'plugin_fckg_indent'); 
       }

    function handle($match, $state, $pos, &$handler){    

    $match = preg_replace('/(&#183;){2}/', "&nbsp;", $match);
    $match = preg_replace('/(\xb7){2}/', "&nbsp;", $match);
    $match = preg_replace('/&#183;/', "&nbsp;", $match);
    $match = preg_replace('/\xb7/', "&nbsp;", $match);
	  
      return array( $state, $match);
             
    }
      

    /**
     * Create output
     */
    function render($mode, &$renderer, $data) {

        if($mode == 'xhtml'){
            list($state, $match) = $data;
            $renderer->doc .= $match;          
            return true;         
         }
        
              
        return false;
    } 


}
 

