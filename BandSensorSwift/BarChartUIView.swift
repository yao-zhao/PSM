//
//  BarChartUIView.swift
//  Pulsymetrics
//
//  Created by YZ on 6/21/15.
//  Copyright (c) 2015 New Thistle LLC. All rights reserved.
//

import UIKit

@IBDesignable class BarChartUIView: UIView {
    
    //1 - the properties for the gradient
    @IBInspectable var startColor: UIColor = UIColor.redColor()
    @IBInspectable var endColor: UIColor = UIColor.greenColor()
    var heartdatastream=[heart_data]() //empty array data for heart beat data measurement
    
    override func drawRect(rect: CGRect) {
        
        let width = rect.width
        let height = rect.height
        
        //set up background clipping area
        var path = UIBezierPath(roundedRect: rect,
            byRoundingCorners: UIRectCorner.AllCorners,
            cornerRadii: CGSize(width: 8.0, height: 8.0))
        path.addClip()
        
        //2 - get the current context
        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.CGColor, endColor.CGColor]
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = [0.0, 1.0]
        
        //5 - create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace,
            colors,
            colorLocations)
        
        //6 - draw the gradient
        var startPoint = CGPoint.zeroPoint
        var endPoint = CGPoint(x:0, y:self.bounds.height)
        CGContextDrawLinearGradient(context,
            gradient,
            startPoint,
            endPoint,
            0)
        
        //calculate the x point
        let margin:CGFloat = 10.0
        var columnXPoint = { (column:Int) -> CGFloat in
            //Calculate gap between points
            let spacer = (width - margin*2-4 ) /
                CGFloat(60)
            var x:CGFloat = CGFloat(column) * spacer
            x += margin + 2
            return x
        }
        
        // calculate the y point
        
        let topBorder:CGFloat = 20
        let bottomBorder:CGFloat = 20
        let maxYValue:CGFloat = 120
        let graphHeight = height - topBorder - bottomBorder
        var columnYPoint = { (graphPoint:UInt) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) /
                CGFloat(maxYValue) * graphHeight
            y = graphHeight + topBorder - y // Flip the graph
            return y
        }
        
        // draw the line graph
        
        UIColor.whiteColor().setFill()
        UIColor.whiteColor().setStroke()
        
        if self.heartdatastream.count>0 {
        //set up the points line
        var graphPath = UIBezierPath()
        //go to start of line
        println(columnYPoint(self.heartdatastream[0].heart_rate))
        println(CGPoint(x:columnXPoint(0),y:columnYPoint(self.heartdatastream[0].heart_rate)))
            
        graphPath.moveToPoint(CGPoint(x:columnXPoint(0),y:columnYPoint(self.heartdatastream[0].heart_rate)))
        //add points for each item in the graphPoints array
        //at the correct (x, y) for the point
        for i in 1..<self.heartdatastream.count {
            let nextPoint = CGPoint(x:columnXPoint(i),
                y:columnYPoint(self.heartdatastream[i].heart_rate))
            graphPath.addLineToPoint(nextPoint)
        }
        graphPath.stroke()
        }
    }
}