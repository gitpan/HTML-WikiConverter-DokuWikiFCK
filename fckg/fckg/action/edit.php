<?php
if(!defined('DOKU_INC')) define('DOKU_INC',realpath(dirname(__FILE__).'/../../../').'/');
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');
require_once(DOKU_PLUGIN.'action.php');

/**
 * @license    GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author     Pierre Spring <pierre.spring@liip.ch>
 */

class action_plugin_fckg_edit extends DokuWiki_Action_Plugin {
    //store the namespaces for sorting
    var $fck_location = "fckeditor";
    var $helper       = false;

    /**
     * Constructor
     */
    function action_plugin_fckg_edit()
    {
        $this->setupLocale();
        $this->helper =& plugin_load('helper', 'fckg');
    }

    function getInfo()
    {
        return confToHash(dirname(__FILE__).'../info.txt');
    }

    function register(&$controller)
    {
        $controller->register_hook('TPL_ACT_RENDER', 'BEFORE', $this, 'fckg_edit');
        $controller->register_hook('TPL_METAHEADER_OUTPUT', 'BEFORE', $this, 'fckg_edit_meta');
    }

    /**
     * fckg_edit_meta 
     *
     * load fck js
     * 
     * @param mixed $event 
     * @access public
     * @return void
     */
    function fckg_edit_meta(&$event)
    {
        global $ACT;
        // we only change the edit behaviour
        if ($ACT != 'edit'){
            return;
        }
        global $ID;
        global $REV;
        global $INFO;
        global $WASSHOW;
        // load the text and check if it is a fck
        if($INFO['exists']){
            if($RANGE){
                list($PRE,$text,$SUF) = rawWikiSlices($RANGE,$ID,$REV);
            }else{
                $text = rawWiki($ID,$REV);
            }
        }
        $event->data['script'][] = 
            array( 
                'type'=>'text/javascript', 
                'charset'=>'utf-8', 
                '_data'=>'',
        //        'src'=>DOKU_BASE.'lib/scripts/' .$this->fck_location. '/fckeditor.js'
                 'src'=>DOKU_BASE.'lib/plugins/fckg/' .$this->fck_location. '/fckeditor.js'
            );
        return;
    }

    /**
     * fckg_edit
     *
     * edit screen using fck
     *
     * @param & $event
     * @access public
     * @return void
     */
    function fckg_edit(&$event)
    {
        // we only change the edit behaviour
        if ($event->data != 'edit') {
            return;
        }
        // load xml and acl
        if (!$this->_preprocess()){
            return;
        }
        // print out the edit screen
        $this->_print();
        // prevent Dokuwiki normal processing of $ACT (it would clean the variable and destroy our 'index' value.
        $event->preventDefault();
        // index command belongs to us, there is no need to hold up Dokuwiki letting other plugins see if its for them
        $event->stopPropagation();
    }

    function _preprocess()
    {
        global $ID;
        global $REV;
        global $DATE;
        global $RANGE;
        global $PRE;
        global $SUF;
        global $INFO;
        global $SUM;
        global $lang;
        global $conf;

        //set summary default
        if(!$SUM){
            if($REV){
                $SUM = $lang['restored'];
            }elseif(!$INFO['exists']){
                $SUM = $lang['created'];
            }
        }
        //no text? Load it!
        if(!isset($text)){
            $pr = false; //no preview mode
            if($INFO['exists']){
                if($RANGE){
                    list($PRE,$text,$SUF) = rawWikiSlices($RANGE,$ID,$REV);
                }else{
                    $text = rawWiki($ID,$REV);
                }
            }else{
                //try to load a pagetemplate
                $data = array($ID);
                $text = trigger_event('HTML_PAGE_FROMTEMPLATE',$data,'pageTemplate',true);
            }
        }else{
            $pr = true; //preview mode
        }


        $this->xhtml = $this->_render_xhtml($text);

        return true;
    }

    function _print()
    {
        global $INFO;
        global $lang;
        global $ID;
        global $REV;
        global $DATE;
        global $PRE;
        global $SUF;
        global $SUM;
        $wr = $INFO['writable'];
        if($wr){
            if ($REV) print p_locale_xhtml('editrev');
            print p_locale_xhtml($include);
            $ro=false;
        }else{
            // check pseudo action 'source'
            if(!actionOK('source')){
                msg('Command disabled: source',-1);
                return false;
            }
            print p_locale_xhtml('read');
            $ro='readonly="readonly"';
        }
        if(!$DATE) $DATE = $INFO['lastmod'];
        echo  $this->helper->registerOnLoad(
            'var fck = new FCKeditor("wiki__text", "100%", "600"); 
             fck.BasePath = "'.DOKU_BASE.'lib/plugins/fckg/'.$this->fck_location.'/"; 
             fck.ToolbarSet = "Dokuwiki";  
             fck.ReplaceTextarea();'
             );
?>

   <form id="dw__editform" method="post" action="<?php echo script()?>" accept-charset="<?php echo $lang['encoding']?>"><div class="no">
      <input type="hidden" name="id"   value="<?php echo $ID?>" />
      <input type="hidden" name="rev"  value="<?php echo $REV?>" />
      <input type="hidden" name="date" value="<?php echo $DATE?>" />
      <input type="hidden" name="prefix" value="<?php echo formText($PRE)?>" />
      <input type="hidden" name="suffix" value="<?php echo formText($SUF)?>" />
    </div>

    <textarea name="wikitext" id="wiki__text" <?php echo $ro?> cols="80" rows="10" class="edit" tabindex="1"><?php echo "\n".$this->xhtml?></textarea>

<?php //bad and dirty event insert hook
$evdata = array('writable' => $wr);
trigger_event('HTML_EDITFORM_INJECTION', $evdata);
?>

    <div id="wiki__editbar">
      <div id="size__ctl"></div>
      <?php if($wr){?>
         <div class="editButtons">
            <input type="checkbox" name="fckg" value="fckg" checked="checked" style="display: none;"/>
            <input class="button" id="edbtn__save" type="submit" name="do[save]" value="<?php echo $lang['btn_save']?>" accesskey="s" title="<?php echo $lang['btn_save']?> [ALT+S]" tabindex="4" />
            <input class="button" id="ebtn__delete" type="submit" name="do[delete]" value="<?php echo $lang['btn_delete']?>" accesskey="p" title="<?php echo $lang['btn_delete']?> [ALT+P]" tabindex="5" />
<?php
/*
We use the preview event, to trigger back to wiki syntax ;)
<input class="button" id="edbtn__preview" type="submit" name="do[preview]" value="<?php echo $lang['btn_preview']?>" accesskey="p" title="<?php echo $lang['btn_preview']?> [ALT+P]" tabindex="5" />
 */
?>
            <input class="button" id="edbtn__preview" type="submit" name="do[preview]" value="Wiki Syntax" accesskey="p" title="<?php echo $lang['btn_preview']?> [ALT+P]" tabindex="5" />
            <input class="button" type="submit" name="do[draftdel]" value="<?php echo $lang['btn_cancel']?>" tabindex="6" />
         </div>
      <?php } ?>
      <?php if($wr){ ?>
        <div class="summary">
           <label for="edit__summary" class="nowrap"><?php echo $lang['summary']?>:</label>
           <input type="text" class="edit" name="summary" id="edit__summary" size="50" value="<?php echo formText($SUM)?>" tabindex="2" />
           <?php html_minoredit()?>
        </div>
      <?php }?>
    </div>
  </form>
<?php
    }

    /**
     * Renders a list of instruction to minimal xhtml
     *
     */
    function _render_xhtml($text){
        $mode = 'fckg';
        $instructions = p_get_instructions($text);
        if(is_null($instructions)) return '';

        // try default renderer first:
        $file = DOKU_INC."inc/parser/$mode.php";

        if(@file_exists($file)){
	
            require_once $file;
            $rclass = "Doku_Renderer_$mode";

            if ( !class_exists($rclass) ) {
                trigger_error("Unable to resolve render class $rclass",E_USER_WARNING);
                msg("Renderer for $mode not valid",-1);
                return null;
            }
            $Renderer = & new $rclass();
        }else{
            // Maybe a plugin is available?
            $Renderer =& plugin_load('renderer',$mode);
	    //echo "\$Renderer: $Renderer";
            if(is_null($Renderer)){
                msg("No renderer for $mode found",-1);
                return null;
            }
        }
        $Renderer->notoc();

        $Renderer->smileys = getSmileys();
        $Renderer->entities = getEntities();
        $Renderer->acronyms = getAcronyms();
        $Renderer->interwiki = getInterwiki();
        #$Renderer->badwords = getBadWords();

        // Loop through the instructions
        foreach ( $instructions as $instruction ) {
            // Execute the callback against the Renderer
            call_user_func_array(array(&$Renderer, $instruction[0]),$instruction[1]);
        }


        //set info array
        $info = $Renderer->info;

        // Post process and return the output
        $data = array($mode,& $Renderer->doc);
        trigger_event('RENDERER_CONTENT_POSTPROCESS',$data);
        $xhtml = $Renderer->doc;


        return $xhtml;
    }

} //end of action class
?>
