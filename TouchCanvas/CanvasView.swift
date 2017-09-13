/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `CanvasView` tracks `UITouch`es and represents them as a series of `Line`s.
*/

import UIKit

class CanvasView: UIView {
    // MARK: Properties
    
    let isPredictionEnabled = UIDevice.current.userInterfaceIdiom == .pad
    let isTouchUpdatingEnabled = true
    var isLogging = false
    
    var isPoint = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    
    var showAssistLines = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    
    var usePreciseLocations = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var isDebuggingEnabled = false {
        didSet {
            needsFullRedraw = true
            setNeedsDisplay()
        }
    }
    var needsFullRedraw = true
    
    /// Array containing all line objects that need to be drawn in `drawRect(_:)`.
    var lines = [Line]()

    /// Array containing all line objects that have been completely drawn into the frozenContext.
    var finishedLines = [Line]()

    
    /** 
        Holds a map of `UITouch` objects to `Line` objects whose touch has not ended yet.
    
        Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
        in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
        be accessed in `NSResponder` callbacks and methods called from them.
    */
    let activeLines = NSMapTable<AnyObject, AnyObject>.strongToStrongObjects()
    
    /**
        Holds a map of `UITouch` objects to `Line` objects whose touch has ended but still has points awaiting
        updates.
        
        Use `NSMapTable` to handle association as `UITouch` doesn't conform to `NSCopying`. There is no value
        in accessing the properties of the touch used as a key in the map table. `UITouch` properties should
        be accessed in `NSResponder` callbacks and methods called from them.
    */
    let pendingLines = NSMapTable<AnyObject, AnyObject>.strongToStrongObjects()
    
    /// A `CGContext` for drawing the last representation of lines no longer receiving updates into.
    lazy var frozenContext: CGContext = {
        let scale = self.window!.screen.scale
        var size = self.bounds.size
        
        size.width *= scale
        size.height *= scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        context!.setLineCap(.round)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        context!.concatenate(transform)
        
        return context!
    }()
    
    /// An optional `CGImage` containing the last representation of lines no longer receiving updates.
    var frozenImage: CGImage?
    
    // MARK: Drawing
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        
        context.setLineCap(.round)

        if (needsFullRedraw) {
            setFrozenImageNeedsUpdate()
            frozenContext.clear(bounds)
            for array in [finishedLines,lines] {
                for line in array {
                    line.drawCommitedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations, isPoint: isPoint)
                }
            }
            needsFullRedraw = false
        }

        frozenImage = frozenImage ?? frozenContext.makeImage()
        
        if let frozenImage = frozenImage {
            context.draw(frozenImage, in: bounds)
        }
        
        for line in lines {
            line.drawInContext(context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations, isPoint: isPoint)
        }
        
        if(!isLogging && showAssistLines){
            drawAssistLines()
            drawAssistScaleMark()
        }

    }
    
    func drawText(_ text: NSString, pos: CGPoint){
        // write text
        text.draw(at: pos,
                         withAttributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 42)])
    }
    
    func drawAssistLines(){
        let boundSize = UIScreen.main.bounds
        let context = UIGraphicsGetCurrentContext()
        let color = UIColor(red: 19/255, green: 144/255, blue: 255/255, alpha: 1.0)
        
        context!.setStrokeColor(color.cgColor)
        
        context!.beginPath()
        
        context!.move(to: CGPoint(x: boundSize.width/2, y: 0))
        context!.addLine(to: CGPoint(x: boundSize.width/2, y: boundSize.height))
        
        context!.move(to: CGPoint(x: 0, y: boundSize.height/3))
        context!.addLine(to: CGPoint(x: boundSize.width, y: boundSize.height/3))
        
        context!.move(to: CGPoint(x: 0, y: boundSize.height/3*2))
        context!.addLine(to: CGPoint(x: boundSize.width, y: boundSize.height/3*2))

        let pos1 = CGPoint(x: boundSize.width/2, y: boundSize.height/3)
        let pos2 = CGPoint(x: boundSize.width/2, y: boundSize.height/3*2)
        let font = UIFont.monospacedDigitSystemFont(ofSize: 42, weight: 0.5)
        
        
        NSString.init(format: "(%.1f, %.1f)", pos1.x, pos1.y)
            .draw(at: pos1, withAttributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: color])
        NSString.init(format: "(%.1f, %.1f)", pos2.x, pos2.y)
            .draw(at: pos2, withAttributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: color])
        
        
        //CGContextAddLineToPoint(context, location.x, location.y)
        context!.setLineWidth(1)
        context!.strokePath()
        
    }
    
    func drawAssistScaleMark(){
        let boundSize = UIScreen.main.bounds
        let context = UIGraphicsGetCurrentContext()
        let color = UIColor(red: 19/255, green: 144/255, blue: 255/255, alpha: 0.7)
        
        context!.setStrokeColor(color.cgColor)
        context!.beginPath()

        let firstpos = 3.25 as CGFloat
        let intv = 2.5 as CGFloat
        var h = firstpos as CGFloat

        while h < bounds.size.height {
            var len = 70 as CGFloat
            if (h-firstpos).truncatingRemainder(dividingBy: (intv*10)) == 0 {
                len *= 1.5
            }else if (h-firstpos).truncatingRemainder(dividingBy: (intv*5)) == 0{
                len *= 1.25
            }

            context!.move(to: CGPoint(x: boundSize.width/2, y: h))
            context!.addLine(to: CGPoint(x: boundSize.width/2 - len, y: h))
            h += intv
        }
        
        context!.setLineWidth(0.5)
        context!.strokePath()
    }
    
    func setFrozenImageNeedsUpdate() {
        frozenImage = nil
    }
    
    // MARK: Actions
    
    func clear() {
        activeLines.removeAllObjects()
        pendingLines.removeAllObjects()
        lines.removeAll()
        finishedLines.removeAll()
        needsFullRedraw = true
        setNeedsDisplay()
    }
    
    // MARK: Convenience
    func outputToFile(_ contents: String, filename: String){
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            + "/" + filename
        
        do {
            try contents.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // error
        }
    }
    
    func debugLog(_ filename: String){
        //print(lines.count.description + "lines")
        //print(finishedLines.count.description + "lines (finished)")
        var message = "Timestamp, Force, LocationX, LocationY, PreciseLocationX, PreciseLocationY, Type, AltitudeAngle, AzimuthAngle, PointType\n"

        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let logFileName = outFormatter.string(from: Date()) + "_"+filename+".csv"
        
        lines.forEach{
            message += ($0).myDebugDescription() + "\n"
        }
        
        finishedLines.forEach{
            message += ($0).myDebugDescription() + "\n"
        }
        
        outputToFile(message, filename: logFileName)
    }
    
    func drawTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        var updateRect = CGRect.null
        
        for touch in touches {
            // Retrieve a line from `activeLines`. If no line exists, create one.
            let line = activeLines.object(forKey: touch) as? Line ?? addActiveLineForTouch(touch)
            
            /*
                Remove prior predicted points and update the `updateRect` based on the removals. The touches 
                used to create these points are predictions provided to offer additional data. They are stale 
                by the time of the next event for this touch.
            */
            updateRect = updateRect.union(line.removePointsWithType(.Predicted))
            
            /*
                Incorporate coalesced touch data. The data in the last touch in the returned array will match
                the data of the touch supplied to `coalescedTouchesForTouch(_:)`
            */
            let coalescedTouches = event?.coalescedTouches(for: touch) ?? []
            let coalescedRect = addPointsOfType(.Coalesced, forTouches: coalescedTouches, toLine: line, currentUpdateRect: updateRect)
            updateRect = updateRect.union(coalescedRect)
            
            /*
                Incorporate predicted touch data. This sample draws predicted touches differently; however, 
                you may want to use them as inputs to smoothing algorithms rather than directly drawing them. 
                Points derived from predicted touches should be removed from the line at the next event for 
                this touch.
            */
            if isPredictionEnabled {
                let predictedTouches = event?.predictedTouches(for: touch) ?? []
                let predictedRect = addPointsOfType(.Predicted, forTouches: predictedTouches, toLine: line, currentUpdateRect: updateRect)
                updateRect = updateRect.union(predictedRect)
            }
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func addActiveLineForTouch(_ touch: UITouch) -> Line {
        let newLine = Line()
        
        activeLines.setObject(newLine, forKey: touch)
        
        lines.append(newLine)
        
        return newLine
    }
    
    func addPointsOfType(_ type: LinePoint.PointType, forTouches touches: [UITouch], toLine line: Line, currentUpdateRect updateRect: CGRect) -> CGRect {
        var accumulatedRect = CGRect.null
        var type = type
		
        for (idx, touch) in touches.enumerated() {
            let isStylus = touch.type == .stylus
            
            // The visualization displays non-`.Stylus` touches differently.
            if !isStylus {
                type.formUnion(.Finger)
            }
            
            // Touches with estimated properties require updates; add this information to the `PointType`.
            if isTouchUpdatingEnabled && !touch.estimatedProperties.isEmpty {
                type.formUnion(.NeedsUpdate)
            }
            
            // The last touch in a set of `.Coalesced` touches is the originating touch. Track it differently.
            if type.contains(.Coalesced) && idx == touches.count - 1 {
                type.subtract(.Coalesced)
                type.formUnion(.Standard)
            }
            
            let touchRect = line.addPointOfType(type, forTouch: touch)
            accumulatedRect = accumulatedRect.union(touchRect)
            
            commitLine(line)
        }
        
        return updateRect.union(accumulatedRect)
    }
    
    func endTouches(_ touches: Set<UITouch>, cancel: Bool) {
        var updateRect = CGRect.null
        
        for touch in touches {
            // Skip over touches that do not correspond to an active line.
            guard let line = activeLines.object(forKey: touch) as? Line else { continue }
            
            // If this is a touch cancellation, cancel the associated line.
            if cancel { updateRect = updateRect.union(line.cancel()) }
            
            // If the line is complete (no points needing updates) or updating isn't enabled, move the line to the `frozenImage`.
            if line.isComplete || !isTouchUpdatingEnabled {
                finishLine(line)
            }
            // Otherwise, add the line to our map of touches to lines pending update.
            else {
                pendingLines.setObject(line, forKey: touch)
            }
            
            // This touch is ending, remove the line corresponding to it from `activeLines`.
            activeLines.removeObject(forKey: touch)
        }
        
        setNeedsDisplay(updateRect)
    }
    
    func updateEstimatedPropertiesForTouches(_ touches: Set<NSObject>) {
        guard isTouchUpdatingEnabled, let touches = touches as? Set<UITouch> else { return }
        
        for touch in touches {
            var isPending = false
            
            // Look to retrieve a line from `activeLines`. If no line exists, look it up in `pendingLines`.
            let possibleLine: Line? = activeLines.object(forKey: touch) as? Line ?? {
                let pendingLine = pendingLines.object(forKey: touch) as? Line
                isPending = pendingLine != nil
                return pendingLine
            }()
            
            // If no line is related to the touch, return as there is no additional work to do.
            guard let line = possibleLine else { return }
            
            switch line.updateWithTouch(touch) {
                case (true, let updateRect):
                    setNeedsDisplay(updateRect)
                default:
                    ()
            }
            
            // If this update updated the last point requiring an update, move the line to the `frozenImage`.
            if isPending && line.isComplete {
                finishLine(line)
                pendingLines.removeObject(forKey: touch)
            }
            // Otherwise, have the line add any points no longer requiring updates to the `frozenImage`.
            else {
                commitLine(line)
            }
            
        }
    }
    
    func commitLine(_ line: Line) {
        // Have the line draw any segments between points no longer being updated into the `frozenContext` and remove them from the line.
        line.drawFixedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations, isPoint: isPoint)
        setFrozenImageNeedsUpdate()
    }
    
    func finishLine(_ line: Line) {
        // Have the line draw any remaining segments into the `frozenContext`. All should be fixed now.
        line.drawFixedPointsInContext(frozenContext, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocations, isPoint: isPoint, commitAll: true)
        setFrozenImageNeedsUpdate()
        
        // Cease tracking this line now that it is finished.
        lines.remove(at: lines.index(of: line)!)

        // Store into finished lines to allow for a full redraw on option changes.
        finishedLines.append(line)
    }
}
