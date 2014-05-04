// http://docs.cksource.com/CKEditor_3.x/Developers_Guide/Toolbar
// http://docs.ckeditor.com/#!/api/CKEDITOR.config
// http://stackoverflow.com/questions/9142293/how-to-configure-ckeditor-in-rails-3-1-gem-asset-pipeline
// Others:
// http://www.tinymce.com/
// http://stackoverflow.com/questions/9876071/wysiwyg-recommendations-for-my-rails-app
// http://jhtmlarea.codeplex.com/
// http://www.aloha-editor.org/
// And very cool full page editing:
// http://jejacks0n.github.io/mercury/

// Resizing: http://mikebranski.com/blog/disable-editor-resizing-in-ckeditor/

CKEDITOR.editorConfig = function( config )
{
    config.toolbar = 'MyToolbar';
    config.resize_enabled = false;                      // http://mikebranski.com/blog/disable-editor-resizing-in-ckeditor/
    config.removePlugins = 'elementspath';              // http://ckeditor.com/forums/CKEditor-3.x/Remove-tags-bottom-bar

    // http://docs.ckeditor.com/#!/api/CKEDITOR.config
    config.toolbar_MyToolbar =
        [
            { name: 'styles', items : [ 'Styles','Format' ] },
            { name: 'basicstyles', items : [ 'Bold','Italic','Strike','-','RemoveFormat' ] },
            { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','Outdent','Indent','-','Blockquote' ] },
            { name: 'links', items : [ 'Link','Unlink','Anchor' ] }
        ];
};