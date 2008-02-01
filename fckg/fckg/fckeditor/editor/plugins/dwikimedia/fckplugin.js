//fckplugin.js
/*
 * your plugin must be put in the 'editor/plugins/#plug-in name#' (the name is specified in fckconfig.js -> addPlugin, see below)
 * in my case this is 'editor/plugins/dwikimedia/'
 *
 * DokuWiki Media Manager plugin
 * @author: Myron Turner, http://www.mturner.org/development
   Based on prototype by Tim Struyf, Roots Software (http://www.roots.be), tim.struyf@roots.be
 */
var DWikiMediaCommand=function(){
        //create our own command, we dont want to use the FCKDialogCommand because it uses the default fck layout and not our own
};
DWikiMediaCommand.prototype.Execute=function(){
}
DWikiMediaCommand.GetState=function() {
        return FCK_TRISTATE_OFF; //we dont want the button to be toggled
}
DWikiMediaCommand.Execute=function() {

//var DWiki_base = FCKConfig.BasePath.replace('scripts/fckeditor/editor/',"");
var DWiki_base = window.location.pathname;
var DWiki_lib = DWiki_base.replace(/plugins.*/,"");

var ns = "";
if(top.getCurrentWikiNS) {
var ns = top.getCurrentWikiNS();
}


  
var url= DWiki_lib + 'exe/mediamanager.php?ns='+ ns;

        //open a popup window when the button is clicked
        window.open(url, 'mediamanager', 
               'width=750,height=500,left=20,top=20,scrollbars=yes,resizable=yes');
}
FCKCommands.RegisterCommand('Add_Images', DWikiMediaCommand ); //otherwise our command will not be found
var oDWikiMediaVariables = new FCKToolbarButton('Add_Images', 'Upload images');
oDWikiMediaVariables.IconPath = FCKConfig.PluginsPath + 'dwikimedia/image.png'; //specifies the image used in the toolbar
FCKToolbarItems.RegisterItem( 'Add_Images', oDWikiMediaVariables );


