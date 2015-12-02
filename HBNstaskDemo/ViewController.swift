//
//  ViewController.swift
//  HBNstaskDemo
//
//  Created by Sullivan.Gu on 15/12/2.
//  Copyright © 2015年 Sullivan.Gu. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var runButton: NSButton!
    @IBOutlet weak var stdinEnterButton: NSButton!
    @IBOutlet weak var commandSelector: NSPopUpButton!
    @IBOutlet weak var argumentTextField: NSTextField!
    @IBOutlet weak var stdinTextField: NSTextField!
    @IBOutlet var stdoutTextVIew: NSTextView!
    @IBOutlet var stderrTextView: NSTextView!

    var task:NSTask!
    var isRunning = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.commandSelector.removeAllItems()
        self.commandSelector.addItemsWithTitles(["/bin/sh","/sbin/ping"])
        self.stderrTextView.textColor = NSColor.redColor()
    }

    override var representedObject: AnyObject? {
        didSet {}
    }
    
    //private method 
    func append(moreString:String, toTextView:NSTextView) {
        toTextView.textStorage?.mutableString.setString(toTextView.string! + moreString)
        toTextView.scrollRangeToVisible(NSMakeRange((toTextView.string!.characters.count), 0))
    }
    
    func stopTask() {
        self.isRunning = false
        self.runButton.title = "Start"
        
        //stop
        self.task!.terminate()
        self.task = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func taskTerimated(notif:NSNotification) {
        let task:NSTask = notif.object as! NSTask
        let reason:NSTaskTerminationReason = task.terminationReason
        let status = task.terminationStatus
        self.append("taskTerimated reason:\(reason) status:\(status)\n", toTextView: self.stdoutTextVIew)
        NSNotificationCenter.defaultCenter().removeObserver(self);
        self.isRunning = false
        self.runButton.title = "Start"
        self.task = nil

    }
    
    func newOutput(notif:NSNotification) {
        let fh:NSFileHandle = notif.object as! NSFileHandle
        let output = fh.availableData
        let outString = String(data: output, encoding: NSUTF8StringEncoding)
        fh.waitForDataInBackgroundAndNotify()
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.append(outString!, toTextView: self.stdoutTextVIew)
        }
    }
    
    func newErr(notif:NSNotification) {
        let fh:NSFileHandle = notif.object as! NSFileHandle
        let output = fh.availableData
        let outString = String(data: output, encoding: NSUTF8StringEncoding)
        fh.waitForDataInBackgroundAndNotify()
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.append(outString!, toTextView:self.stderrTextView)
        }
    }
    
    func startTask() {
        self.isRunning = true
        self.runButton.title = "Stop"
        
        
        //init task
        self.task = NSTask()
        self.task.launchPath = self.commandSelector.titleOfSelectedItem
        self.task.arguments = self.argumentTextField.stringValue.componentsSeparatedByString(" ");
        
        self.append("start task:" + self.task.launchPath! + " " + self.argumentTextField.stringValue + "\n", toTextView: self.stdoutTextVIew)
        
        //config pipe
        let outPipe:NSPipe = NSPipe()
        let errPipe:NSPipe = NSPipe()
        let inPipe:NSPipe = NSPipe()
        
        
        outPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        errPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newOutput:", name: NSFileHandleDataAvailableNotification, object: outPipe.fileHandleForReading)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newErr:", name: NSFileHandleDataAvailableNotification, object: errPipe.fileHandleForReading)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "taskTerimated:", name: NSTaskDidTerminateNotification, object:self.task)
        
        self.task.standardOutput = outPipe;
        self.task.standardError = errPipe;
        self.task.standardInput = inPipe;

        
        //launch
        self.task.launch()
    }
    
    //event
    @IBAction func stdinEnterClicked(sender: NSButton) {
        
    }
    @IBAction func runButtonClicked(sender: NSButton) {
        if self.isRunning {
            stopTask()
        }else {
            startTask()
        }
    }
}

