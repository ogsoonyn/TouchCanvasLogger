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
        view.isHidden = true
        
        return view
    }()
    
    @IBOutlet weak var naviItem: UINavigationItem!
   
    var canvasView: CanvasView {
        return view as! CanvasView
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        canvasView.addSubview(reticleView)
        
        // initialize toolbar
        initToolBar()
        
        // observe notification event
        NotificationCenter.default.addObserver(self, selector: #selector(dumpLogAndQuit), name: NSNotification.Name(rawValue: "HomeKeyPressed"), object: nil)
    }
    
    
    fileprivate var toolBar : UIToolbar!
    
    func initToolBar(){
        // Set toolbar size
        toolBar = UIToolbar(frame: CGRect(x: 0, y: self.view.bounds.size.height - 44, width: self.view.bounds.size.width, height: 44.0))

        // Set toolbar pos
        toolBar.layer.position = CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height-20.0)
        
        // initialize [Coodinate Viewer]
        naviLabel.frame = CGRect(x: 0,y: 10,width: 500,height: 30) // Magic Number!!
        naviLabel.textColor = UIColor.black
        naviLabel.backgroundColor = UIColor.clear
        naviLabel.textAlignment = NSTextAlignment.center
        naviLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 26, weight: 0.5)
        naviLabel.text = "(Pos.x, Pos.y) : Force"
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // initialize Buttons
        let assistBtn = UIBarButtonItem(title: "Assist Line", style: .plain, target: self, action: #selector(toggleShowAssistLine))
        let logBtn = UIBarButtonItem(title: "Start Log", style: .plain, target: self, action: #selector(outputLogFile))

        let itemLabel = UIBarButtonItem(customView: naviLabel)

        toolBar.items = [itemLabel, spacer, assistBtn, logBtn]
        canvasView.addSubview(toolBar)
    }
    
    // MARK: Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        //naviItem.title = touchToString(touches.first!)
        naviLabel.text = touchToString(touches.first!)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    reticleView.isHidden = false
                    updateReticleViewWithTouch(touch, event: event)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        //naviItem.title = touchToString(touches.first!)
        naviLabel.text = touchToString(touches.first!)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    updateReticleViewWithTouch(touch, event: event)
                    
                    // Use the last predicted touch to update the reticle.
                    guard let predictedTouch = event?.predictedTouches(for: touch)?.last else { return }
                    
                    updateReticleViewWithTouch(predictedTouch, event: event, isPredicted: true)
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        canvasView.drawTouches(touches, withEvent: event)
        canvasView.endTouches(touches, cancel: false)
        //naviItem.title = touchToString(touches.first!)
        naviLabel.text = touchToString(touches.first!)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    reticleView.isHidden = true
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		canvasView.endTouches(touches, cancel: true)
        
        if visualizeAzimuth {
            for touch in touches {
                if touch.type == .stylus {
                    reticleView.isHidden = true
                }
            }
        }
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        canvasView.updateEstimatedPropertiesForTouches(touches)
    }
    
    // MARK: Actions
    @IBAction func toggleLine(_ sender: UIButton) {
        canvasView.isPoint = !canvasView.isPoint
        //sender.selected = canvasView.isPoint
        if(canvasView.isPoint){
            sender.setTitle("Point", for: UIControlState())
        }else{
            sender.setTitle("Line", for: UIControlState())
        }
    }
    
    @IBAction func toggleShowAssistLine(_ sender: UIButton){
        canvasView.showAssistLines = !canvasView.showAssistLines
        sender.isSelected = canvasView.showAssistLines
    }

    @IBAction func clearView(_ sender: UIBarButtonItem) {
        canvasView.clear()
    }
    
    @IBAction func toggleDebugDrawing(_ sender: UIButton) {
        canvasView.isDebuggingEnabled = !canvasView.isDebuggingEnabled
        visualizeAzimuth = !visualizeAzimuth
        sender.isSelected = canvasView.isDebuggingEnabled
    }
    
    @IBAction func toggleUsePreciseLocations(_ sender: UIButton) {
        canvasView.usePreciseLocations = !canvasView.usePreciseLocations
        sender.isSelected = canvasView.usePreciseLocations
    }
    
    @IBAction func showInfo(_ sender: UIButton) {
        popupInformation()
    }
    
    
    @IBAction func outputLogFile(_ sender: AnyObject) {
        // get log file name
        let alert = UIAlertController(title: "ログ取得", message: "ログファイル名を指定してStartを押すと、ログ取得を開始します。\nログ取得を終了するには、ホームボタンを押してください。", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Start", style: .default){ (action: UIAlertAction!) -> Void in
            // show text via console
            self.logFileName = alert.textFields![0].text!
            //self.label.text = textField.text

            // hide navigation bar
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            //self.navigationController?.setToolbarHidden(true, animated: true)
            self.toolBar.isHidden = true

            // clear log
            self.canvasView.clear()
        
            self.canvasView.isLogging = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default){ (action: UIAlertAction!) -> Void in
        }
        
        // add textfield to UIAlertController
        alert.addTextField{ (textfield:UITextField!) -> Void in
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        
    }
    
    // MARK: Rotation
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
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
        //self.navigationController?.setToolbarHidden(false, animated: true)
        self.toolBar.isHidden = false
        
        canvasView.isLogging = false
    }
    
    func touchToString(_ touch: UITouch) -> String{
        var ret = ""
        if(canvasView.usePreciseLocations){
            let point = touch.preciseLocation(in: touch.view)
            ret = pointToString(point, digit: 4) + " : " + forceToString(touch, digit: 6)
        }else{
            let point = touch.location(in: touch.view)
            ret = pointToString(point, digit: 2) + " : " + forceToString(touch, digit: 3)
        }
        return ret
    }
    
    func forceToString(_ touch: UITouch, digit: Int) -> String{

        let format = "%." + digit.description + "f"
        return String.init(format: format, touch.force)
    }
    
    
    func pointToString(_ point: CGPoint, digit: Int) -> String{
        let format = "(%." + digit.description + "f, %." + digit.description + "f)"
        return String.init(format: format, point.x, point.y)
    }

    func updateReticleViewWithTouch(_ touch: UITouch?, event: UIEvent?, isPredicted: Bool = false) {
        guard let touch = touch, touch.type == .stylus else { return }
        
        reticleView.predictedDotLayer.isHidden = !isPredicted
        reticleView.predictedLineLayer.isHidden = !isPredicted
        
        let azimuthAngle = touch.azimuthAngle(in: view)
        let azimuthUnitVector = touch.azimuthUnitVector(in: view)
        let altitudeAngle = touch.altitudeAngle
        
        if isPredicted {
            reticleView.predictedAzimuthAngle = azimuthAngle
            reticleView.predictedAzimuthUnitVector = azimuthUnitVector
            reticleView.predictedAltitudeAngle = altitudeAngle
        }
        else {
            let location = touch.preciseLocation(in: view)
            reticleView.center = location
            reticleView.actualAzimuthAngle = azimuthAngle
            reticleView.actualAzimuthUnitVector = azimuthUnitVector
            reticleView.actualAltitudeAngle = altitudeAngle
        }
    }
    
    func popupInformation(){
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appname: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        // create popup
        let alert = UIAlertController(
            title: appname,
            message: "Version: " + version + "\nBuild: " + build,
            preferredStyle: .alert)
        
        // add button to alert
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // show alert
        present(alert, animated: true, completion: nil)
    }
}
