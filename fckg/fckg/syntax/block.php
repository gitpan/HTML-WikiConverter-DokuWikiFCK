<?php
/**
 * Plugin Color: Sets new colors for text and background.
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

/*
 *  <block width:padding:left-align>text</block>
 *   width in percent, padding in pixels,left-align in pixels
 *   All these values are optional
*/

class syntax_plugin_fckg_block extends DokuWiki_Syntax_Plugin {
 
    /**
     * return some info
     */
    function getInfo(){
        return array(
            'author' => 'Myron Turner',
            'email'  => 'turnermm02@shaw.ca',
            'date'   => '2007-12-26',
            'name'   => 'HTML Block Markup',
            'desc'   => 'Controls font size, face, and block configuration',
            'url'    => 'http://www.mturner.org/development',
        );
    }
 
    function getType(){ return 'formatting'; }
    function getAllowedTypes() { return array('formatting', 'substition', 'disabled'); }   
    function getSort(){ return 160; }
    function connectTo($mode) { $this->Lexer->addEntryPattern('<block.*?>(?=.*?</block>)',$mode,'plugin_fckg_block'); }
    function postConnect() { $this->Lexer->addExitPattern('</block>','plugin_fckg_block'); }
 
 
    /**
     * Handle the match
     */
    function handle($match, $state, $pos, &$handler){

        $padding = 0;
        $width = "100%";
        $margin = "auto";
        $bgcolor = 'white';

        switch ($state) {
          case DOKU_LEXER_ENTER :

                list($type, $val) = preg_split("/\s+/u", substr($match, 1, -1), 2);

                if(!isset($type)) return array($state, '');
                if(!isset($val)) {
                      return array($state, '<div><blockquote>');
                }
                if(preg_match('/(\d+):(\d+):(.*)/',$val, $matches)) {   
                   $width = $matches[1] .'%';
                   $padding = $matches[2] . 'px';                   
                   $bgcolor = $matches[3];    
                }
                elseif(preg_match('/(\d+):(\d+)/',$val, $matches)) {   
                   $width = $matches[1] .'%';
                   $padding = $matches[2] . 'px';                   
                }
                elseif(preg_match('/(\d+):_dummy_/',$val, $matches)) {     
                   $width = $matches[1] .'%';
                }
                elseif(preg_match('/_dummy_:(\d+)/',$val, $matches)) {     
                   $padding = $matches[1] . 'px';                   
                }

                return array($state, "<div style='border-left:0px;width:$width; padding:$padding;margin:$margin;background-color:$bgcolor'>"
                  ."<blockquote style='border-left:0px;'>");
                
 
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
              case DOKU_LEXER_EXIT :       $renderer->doc .= "</blockquote></div>"; break;
            }
            return true;
        }
        return false;
    }
 
     function _isValid($c) {
        $c = trim($c);
 
        $pattern = "/
            ([a-zA-z]+)|                                #colorname - not verified
            (\#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}))|        #colorvalue
            (rgb\(([0-9]{1,3}%?,){2}[0-9]{1,3}%?\))     #rgb triplet
            /x";
 
        if (preg_match($pattern, $c)) return $c;
 
        return "";
    }

}
?>
