/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller that hosts a `CanvasView` for the user to interact with.
*/

import UIKit

class ViewController: UIViewController {
    // MARK: Properties
    
    var visualizeAzimuth = false
    var logFileName = "log"
    let naviLabel = UILabel()
    
    let reticleView: ReticleView = {
        let view = ReticleView(frame: CGRect.null)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidden = true
        
        return view
    }()
    
    @IBOutlet weak var naviItem: UINavigationItem!
   
    var canvasView: CanvasView {
        return view as! CanvasView
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        canvasView.addSubview(reticleView)
        naviLabel.frame = CGRectMake(0,10,320,25) // Magic Number!!
        naviLabel.textColor = UIColor.blackColor()
        naviLabel.backgroundColor = UIColor.clearColor()
        naviLabel.textAlignment = NSTextAlignment.Center
        naviLabel.font = UIFont.monospacedDigitSystemFontOfSize(24, weight: 0.5)
        naviLabel.text = "(Pos.x, Pos.y) : Force"
        
        naviItem.titleView = naviLabel
        
        // observe notification event
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dumpLogAndQuit), name: "HomeKeyPressed", object: nil)
    }
    
    // MARK: Touch Handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        //naviItem.title = touchToString(touches.first!)
        naviLabel.text = touchToString(touches.first!)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    reticleView.hidden = false
                    updateReticleViewWithTouch(touch, event: event)
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        //naviItem.title = touchToString(touches.first!)
        naviLabel.text = touchToString(touches.first!)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    updateReticleViewWithTouch(touch, event: event)
                    
                    // Use the last predicted touch to update the reticle.
                    guard let predictedTouch = event?.predictedTouchesForTouch(touch)?.last else { return }
                    
                    updateReticleViewWithTouch(predictedTouch, event: event, isPredicted: true)
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        canvasView.endTouches(touches, cancel: false)
        //naviItem.title = touchToString(touches.first!)
        naviLabel.text = touchToString(touches.first!)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    reticleView.hidden = true
                }
            }
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
		canvasView.endTouches(touches, cancel: true)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .Stylus {
                    reticleView.hidden = true
                }
            }
        }
    }
    
    override func touchesEstimatedPropertiesUpdated(touches: Set<UITouch>) {
        canvasView.updateEstimatedPropertiesForTouches(touches)
    }
    
    // MARK: Actions
    @IBAction func toggleLine(sender: UIButton) {
        canvasView.isPoint = !canvasView.isPoint
        sender.selected = canvasView.isPoint

    }


    @IBAction func clearView(sender: UIBarButtonItem) {
        canvasView.clear()
    }
    
    @IBAction func toggleDebugDrawing(sender: UIButton) {
        canvasView.isDebuggingEnabled = !canvasView.isDebuggingEnabled
        visualizeAzimuth = !visualizeAzimuth
        sender.selected = canvasView.isDebuggingEnabled
    }
    
    @IBAction func toggleUsePreciseLocations(sender: UIButton) {
        canvasView.usePreciseLocations = !canvasView.usePreciseLocations
        sender.selected = canvasView.usePreciseLocations
    }
    
    @IBAction func outputLogFile(sender: AnyObject) {
        // get log file name
        let alert = UIAlertController(title: "Notice", message: "Input log file name", preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Done", style: .Default){ (action: UIAlertAction!) -> Void in
            // show text via console
            self.logFileName = alert.textFields![0].text!
            //self.label.text = textField.text

            // hide navigation bar
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        
            // clear log
            self.canvasView.clear()
        
            self.canvasView.isLogging = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default){ (action: UIAlertAction!) -> Void in
        }
        
        // add textfield to UIAlertController
        alert.addTextFieldWithConfigurationHandler{ (textfield:UITextField!) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    // MARK: Rotation
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
       //return [.LandscapeLeft, .LandscapeRight]
    }
    
    // MARK: Convenience
    func dumpLogAndQuit(){
        // output log file
        canvasView.debugLog(logFileName)
        
        // clear log
        canvasView.clear()
        
        // show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        canvasView.isLogging = false
    }
    
    func touchToString(touch: UITouch) -> String{
        var point = touch.locationInView(touch.view)
        if(canvasView.usePreciseLocations){
            point = touch.preciseLocationInView(touch.view)
        }
        return pointToString(point) + " : " + String.init(format: "%.2f", touch.force)
    }
    
    func pointToString(point: CGPoint) -> String{
        return String.init(format: "(%.2f, %.2f)", point.x, point.y)
    }
    
    
    func updateReticleViewWithTouch(touch: UITouch?, event: UIEvent?, isPredicted: Bool = false) {
        guard let touch = touch where touch.type == .Stylus else { return }
        
        reticleView.predictedDotLayer.hidden = !isPredicted
        reticleView.predictedLineLayer.hidden = !isPredicted
        
        let azimuthAngle = touch.azimuthAngleInView(view)
        let azimuthUnitVector = touch.azimuthUnitVectorInView(view)
        let altitudeAngle = touch.altitudeAngle
        
        if isPredicted {
            reticleView.predictedAzimuthAngle = azimuthAngle
            reticleView.predictedAzimuthUnitVector = azimuthUnitVector
            reticleView.predictedAltitudeAngle = altitudeAngle
        }
        else {
            let location = touch.preciseLocationInView(view)
            reticleView.center = location
            reticleView.actualAzimuthAngle = azimuthAngle
            reticleView.actualAzimuthUnitVector = azimuthUnitVector
            reticleView.actualAltitudeAngle = altitudeAngle
        }
    }
}
