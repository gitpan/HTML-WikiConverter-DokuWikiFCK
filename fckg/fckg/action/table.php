<?php
/**
 *
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Myron Turner <turnermm02@shaw.ca>
 */
 
if(!defined('DOKU_INC')) die();
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'action.php');

 
class action_plugin_fckg_table extends DokuWiki_Action_Plugin { 

  
  /**
   * return some info
   */
  function getInfo(){
    return array(
		 'author' => 'Myron Turner',
		 'email'  => 'turnermm03@shaw.ca',
		 'date'   => '2007-09-18',
		 'name'   => 'table fromatter',
		 'desc'   => 'handles table formatting for fckg',
		 'url'    => 'http://www.mturner.org',
		 );
  }
 

  /*
   * Register its handlers with the dokuwiki's event controller
   */
  function register(&$controller) {
    $controller->register_hook('TPL_CONTENT_DISPLAY', 'BEFORE', $this, 'write_event_before');
  }



   function write_event_before (&$event, $param) {

     $rev_text="";

      preg_match('/(<table.*\/table>)/ms', $event->data, $tables); 
              if(isset($tables[1])) {
              $rev_text = preg_replace_callback(            
                        "|(<td.*?>.*?</td>)|ms",
                          "td_color_spec",
                          $tables[1]);

         $event->data = preg_replace('/<table.*\/table>/ms',$rev_text, $event->data); 
      }

   }

   
}

 // the callback function
  function td_color_spec($matches)
  {

// Selects the first non-white indent color as cell background
   if(preg_match_all('/<indent\s+style=\s*"color:(.*?)>/', $matches[1], $color)) {
           if(count($color[1] > 1)) {
                $i_colors = $color[1];
                $i_color = "white"; 
                for($i=0; $i< count($i_colors); $i++) {
                   $i_colors[$i] = trim($i_colors[$i]);
                   $i_colors[$i] = preg_replace('/[\s\'\"]/',"",$i_colors[$i]);                   

                   if($i_colors[$i] != 'white') {
                      $i_color = $i_colors[$i];
                      $matches[1] = preg_replace('/color:\s*white/', "color:$i_color", $matches[1]); 
                      break;  
                   }
                }

           }
           else { 

               $i_color = trim($color[1][0]);
               $i_color = preg_replace('/[\s\'\"]/',"",$i_color);            
           }

            
           return preg_replace('/<td.*?>/', "<td style='background-color:$i_color'>", $matches[1]);          
   }


// Select the first background-color as cell background
   preg_match_all('/background-color:(.*?);/',$matches[1], $bg_color);
   if(count($bg_color[1] > 1)) {
     $color_1 = trim($bg_color[1][0]);
     $color_2 = trim($bg_color[1][1]);
     $color_1 = preg_replace('/\s/',"",$color_1); 
     $color_2 = preg_replace('/\s/',"",$color_2); 
     if($color_1 == $color_2){
        return preg_replace('/<td>/', "<td style='background-color:$color_1'>", $matches[1]);      
     }
   }

   return $matches[1];
  }
 


