<?php
/**
 * Plugin Align: Sets new colors for text and background.
 * 
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Myron Turner <turnermm02@shaw.ca>
 */

// Syntax: <align [left | number px]>
 
// must be run within Dokuwiki
if(!defined('DOKU_INC')) die();
 
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'syntax.php');
 
/**
 * All DokuWiki plugins to extend the parser/rendering mechanism
 * need to inherit from this class
 */
class syntax_plugin_fckg_align extends DokuWiki_Syntax_Plugin {
 
    /**
     * return some info
     */
    function getInfo(){
        return array(
            'author' => 'Myron Turner',
            'email'  => 'turnermm02@shaw.ca',
            'date'   => '2007-12-26',
            'name'   => 'fckg Alignment Plugin',
            'desc'   => 'Sets CSS text and margin alignment',
            'url'    => 'http://www.mturner.org/development/',
        );
    }
 
    function getType(){ return 'formatting'; }
    function getAllowedTypes() { return array('formatting', 'substition', 'disabled'); }   
    function getSort(){ return 160; }
    function connectTo($mode) { $this->Lexer->addEntryPattern('<align.*?>(?=.*?</align>)',$mode,'plugin_fckg_align'); }
    function postConnect() { $this->Lexer->addExitPattern('</align>','plugin_fckg_align'); }
 
 
    /**
     * Handle the match
     */
    function handle($match, $state, $pos, &$handler){


        switch ($state) {
          case DOKU_LEXER_ENTER :
                
                list($type, $val) = preg_split("/\s+/u", substr($match, 1, -1), 2);

                if(!isset($type)) return array($state, '');
                if(!isset($val)) {
                      return array($state, '<p>');
                }
                
                if(preg_match('/\d+px/',$val)) {    // margin-left <n>px
                   $val = trim($val);
                   if($val == '0px') {
                           return array($state, "<br /><p style='margin-left:$val'>");
                   }
                   return array($state, "<p style='margin-left:$val'>");
                }
                return array($state, "<p style='text-align:$val'>");
                
 
          return array($state, $match);

          case DOKU_LEXER_UNMATCHED :  return array($state, $match);
          case DOKU_LEXER_EXIT :       return array($state,$match);
        }
        return array();
    }
 
    /**
     * Create output
     */
    function render($mode, &$renderer, $data) {
        if($mode == 'xhtml'){
            list($state, $match) = $data;
           
            switch ($state) {
              case DOKU_LEXER_ENTER :      

                $renderer->doc .= $match; 
                break;
 
              case DOKU_LEXER_UNMATCHED :  $renderer->doc .= $renderer->_xmlEntities($match); break;
              case DOKU_LEXER_EXIT :       $renderer->doc .= "</p>"; break;
            }
            return true;
        }
        return false;
    }
 
 
}
?>
