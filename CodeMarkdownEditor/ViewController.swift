//
//  ViewController.swift
//  CodeMarkdownEditor
//
//  Created by Scott Bauer on 9/5/22.
//

import Cocoa
import WebKit
import JavaScriptCore

class ViewController: NSViewController {

    @IBOutlet var webResults: WKWebView!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var convertBtn: NSButton!
    @IBOutlet var textView: NSTextView!
    
    var jsContext: JSContext!

    let consoleLog: @convention(block) (String) -> Void = { logMessage in
        print("\nJS Console:", logMessage)
    }
    
    func initializeJS() {
        self.jsContext = JSContext()
        
        // add exception handler
        self.jsContext.exceptionHandler = { context, exception in
            if let exc = exception {
                print("JS Exception:", exc.toString())
            }
        }
        
         // observe for console messages
        let consoleLogObject = unsafeBitCast(self.consoleLog, to: AnyObject.self)
        self.jsContext.setObject(consoleLogObject, forKeyedSubscript: "consoleLog" as (NSCopying & NSObjectProtocol))
        _ = self.jsContext.evaluateScript("consoleLog")
        
        if let jsSourcePath = Bundle.main.path(forResource: "jssource", ofType: "js") {
            do {
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                self.jsContext.evaluateScript(jsSourceContents)
                
                // fetch and evaluate the Snowdown script
                let snowdownScript = try String(contentsOf: URL(string: "https://cdn.rawgit.com/showdownjs/showdown/1.6.3/dist/showdown.min.js")!)
                self.jsContext.evaluateScript(snowdownScript)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // convert the block to an object
        let htmlResultsHandler = unsafeBitCast(self.markdownToHTMLHandler, to: AnyObject.self)
        self.jsContext.setObject(htmlResultsHandler, forKeyedSubscript: "handleConvertedMarkdown" as (NSCopying & NSObjectProtocol))
        _ = self.jsContext.evaluateScript("handleConvertedMarkdown")
        // handleConvertedMarkdown function will be available to JavaScript
    }
    
    let markdownToHTMLHandler: @convention(block) (String) -> Void = { htmlOutput in
        NotificationCenter.default.post(name: Notification.Name("markdownToHTMLNotification"), object: htmlOutput)
    }
    
    func convertMarkdownToHTML() {
        if let functionConvertMarkdownToHTML = self.jsContext.objectForKeyedSubscript("convertMarkdownToHTML") {
            _ = functionConvertMarkdownToHTML.call(withArguments: [textView.string])
            
        }
    }
    
    @objc func handleMarkdownToHTMLNotification(notification: Notification) {
        if let html = notification.object as? String {
            let newContent = "<html><head><style>body { background-color: cyan; } </style></head><body>\(html)</body></html>"
            self.webResults.loadHTMLString(newContent, baseURL: nil)
        }
    }

    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        initializeJS()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.handleMarkdownToHTMLNotification(notification:)), name: Notification.Name("markdownToHTMLNotification"), object: nil)

    }


    @IBAction func convert(_ sender: Any) {
        self.convertMarkdownToHTML()
    }
}

