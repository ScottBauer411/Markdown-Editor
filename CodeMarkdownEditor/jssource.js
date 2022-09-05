function convertMarkdownToHTML(source) {
    var converter = new showdown.Converter();
    var htmlResult = converter.makeHtml(source);
    
    consoleLog(htmlResult);
    
    handleConvertedMarkdown(htmlResult);
}
