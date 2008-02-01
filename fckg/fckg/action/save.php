<?php
if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'action.php');

/**
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Pierre Spring <pierre.spring@liip.ch>
 */

class action_plugin_fckg_save extends DokuWiki_Action_Plugin {
    /**
     * Constructor
     */
    function action_plugin_fckg_save(){
    }

    function getInfo() {
        return array(
            'author' => 'Pierre Spring',
            'email'  => 'pierre.spring@liip.ch',
            'date'   => '2007-Mai-08',
            'name'   => 'fckg_save',
            'desc'   => 'Save Plugin for the Dokuwiki FCKW Plugin',
            'url'    => 'https://fosswiki.liip.ch/display/FCKW/Home');
    }

    function register(&$controller) {
        $controller->register_hook('DOKUWIKI_STARTED', 'BEFORE', $this, 'fckg_save_preprocess');
    }

    function fckg_save_preprocess(&$event){
        global $ACT;
        if (!isset($_REQUEST['fckg']) || ! is_array($ACT) || !(isset($ACT['save']) || isset($ACT['preview']))) return;
        global $TEXT;
        if (!$TEXT) return;

	   
        // transform html back into wiki syntax
        $host = escapeshellarg($_SERVER['HTTP_HOST']);
        $TEXT = shell_exec('echo ' . escapeshellarg($TEXT) . ' | html2wiki -dialect DokuWikiFCK --base-uri=' . $host);

        //remove links around images
        $TEXT = preg_replace('/\[\[[^{]*({{[^}]*}})[^\]]*]]/', "$1", $TEXT);
        // this is a bit hacky. and dirty. but if you want to know, why i did so, ask me, and i'll tell you ;)
        $TEXT = preg_replace('/(({{)|(\[\[))\//', '$1http://'.$_SERVER['HTTP_HOST'].'/', $TEXT);
        $TEXT = html_entity_decode($TEXT, ENT_NOQUOTES, 'UTF-8');
    
    }

} //end of action class
?>
