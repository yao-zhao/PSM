//
//  UserProfileUIViewController.swift
//  Pulsymetrics
//
//  Created by YZ on 5/20/15.
//  Copyright (c) 2015 New Thistle LLC. All rights reserved.
//
import UIKit

class MeasurePulseUIViewController: UIViewController, MSBClientManagerDelegate {

    @IBOutlet weak var txtOutput: UITextView!  // status window
    @IBOutlet weak var hearbeatLabel: UILabel! // current reading
    weak var client: MSBClient? // MS client
    var heartdatastream=[heart_data]() //empty array data for heart beat data measurement
    var last_time_stamp = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        MSBClientManager.sharedManager().delegate = self
        if let client = MSBClientManager.sharedManager().attachedClients().first as? MSBClient {
            self.client = client
            MSBClientManager.sharedManager().connectClient(self.client)
            self.output("Please wait. Connecting to Band...")
            let consent:MSBUserConsent = client.sensorManager.heartRateUserConsent()
            println(consent.rawValue)
            switch consent {
            case .Granted:
                println("access granted")
            case .NotSpecified:
                println("access not specified")
                client.sensorManager.requestHRUserConsentWithCompletion({ (consent:Bool, error:NSError!) -> Void in
                })
            case .Declined:
                println("access declined")
                client.sensorManager.requestHRUserConsentWithCompletion({ (consent:Bool, error:NSError!) -> Void in
                })
            default:
                break
            }
        }
        else {
            self.output("Failed! No Bands attached.")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func runExampleCode(sender: AnyObject) {
        if let client = self.client {
            
            // check if th device is connected or not
            if client.isDeviceConnected == false {
                self.output("Band is not connected. Please wait....")
                return
            }
            
            // measure heart beat and quality of measurements
            last_time_stamp = NSDate()
            client.sensorManager.startHeartRateUpdatesToQueue(nil, errorRef: nil, withHandler: measuredata)
            
            
//            client.sensorManager.startHeartRateUpdatesToQueue(nil, errorRef: nil, withHandler: { (heartratedata: MSBSensorHeartRateData!, error: NSError!) in
//                self.hearbeatLabel.text = NSString(format: "HeartRate: %+0.2d Quality: %d",heartratedata.heartRate, heartratedata.quality.rawValue) as String
//                //                self.accelLabel.text = String(heartratedata.quality.rawValue)
//            })

            println(1)
    
            //Stop Accel updates after 60 seconds
            let delay = 60.0 * Double(NSEC_PER_SEC)
            var time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue(), {
                self.output("Stopping Accelerometer updates...")
                if let client = self.client {
                    client.sensorManager.stopAccelerometerUpdatesErrorRef(nil)
                }
            })
        } else {
            self.output("Band is not connected. Please wait....")
        }
    }
    
    func output(message: String) {
        self.txtOutput.text = NSString(format: "%@\n%@", self.txtOutput.text, message) as String
        let p = self.txtOutput.contentOffset
        self.txtOutput.setContentOffset(p, animated: false)
        self.txtOutput.scrollRangeToVisible(NSMakeRange(self.txtOutput.text.lengthOfBytesUsingEncoding(NSASCIIStringEncoding), 0))
    }
    
    // Mark - Client Manager Delegates
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        self.output("Band connected.")
    }
    
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        self.output(")Band disconnected.")
    }
    
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        self.output("Failed to connect to Band.")
        self.output(error.description)
    }
    
    func measuredata(heartratedata:MSBSensorHeartRateData!, error:NSError!) -> Void {
        println(2)
        let new_time = NSDate()
        let time_interval = NSDate().timeIntervalSinceDate(self.last_time_stamp)
        self.last_time_stamp = new_time
        self.hearbeatLabel.text = NSString(format: "HeartRate2: %+0.2d Quality: %d",heartratedata.heartRate, heartratedata.quality.rawValue) as String
        heartratedata
        self.heartdatastream.append(heart_data(time_stamp:UInt(DISPATCH_TIME_NOW),heart_rate:heartratedata.heartRate,quality:heartratedata.quality.rawValue))
        self.output("number of data points" + String(self.heartdatastream.count) + " interval " + time_interval.description)
        self.output ("heart beat " + String(heartratedata.heartRate) + " quality " + String(heartratedata.quality.rawValue))
        return
    }
}

class heart_data:NSObject {
    var time_stamp:UInt = 0
    var heart_rate:UInt = 0
    var quality:UInt = 0
    init(time_stamp:UInt,heart_rate:UInt,quality:UInt){
        self.time_stamp=time_stamp
        self.heart_rate=heart_rate
        self.quality=quality
    }
}



