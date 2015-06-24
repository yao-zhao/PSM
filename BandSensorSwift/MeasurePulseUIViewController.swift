//
//  UserProfileUIViewController.swift
//  Pulsymetrics
//
//  Created by YZ on 5/20/15.
//  Copyright (c) 2015 New Thistle LLC. All rights reserved.
//
import UIKit

class MeasurePulseUIViewController: UIViewController, MSBClientManagerDelegate {

    // button and the connection status
    @IBOutlet weak var StatusButton: UIButton!
    var connection_status = MSBandStatus.Disconnected {
        didSet {
            switch connection_status{
            case .Disconnected:
                self.outputbuttontext("Connect to the band")
            case .Connecting:
                self.outputbuttontext("Pleaes wait, connecting...")
            case .Connected:
                self.outputbuttontext("Start Measurement")
            case .Measuring:
                self.outputbuttontext("Stop Measurement")
            case .Failtoconnect:
                self.outputbuttontext("Connect to the band")
            }
        }
    }
    
    
    @IBOutlet weak var BarChart: BarChartUIView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    weak var client: MSBClient? // MS client
    var heartdatastream=[heart_data]()//empty array data for heart beat data measurement

    var last_time_stamp = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // connecting the band
        MSBClientManager.sharedManager().delegate = self
        if self.connection_status == MSBandStatus.Disconnected {
            self.connection_status = MSBandStatus.Disconnected
        }
        if self.connection_status != MSBandStatus.Connecting{
            self.ActivityIndicator.hidden = true
        }
     }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func ButtonAction(sender: AnyObject){
        switch self.connection_status{
        case MSBandStatus.Disconnected, MSBandStatus.Failtoconnect:
            self.connection_status = MSBandStatus.Connecting
            self.ActivityIndicator.hidden = false
            self.ActivityIndicator.startAnimating()
            self.connectingBand()
            break
        case MSBandStatus.Connecting:
            break
        case MSBandStatus.Measuring:
            self.client!.sensorManager.stopHeartRateUpdatesErrorRef(nil)
            self.connection_status = MSBandStatus.Connected
            break
        case MSBandStatus.Connected:
            last_time_stamp = NSDate()
            self.client!.sensorManager.startHeartRateUpdatesToQueue(nil, errorRef: nil, withHandler: measuredata)
            self.connection_status = MSBandStatus.Measuring
            break
        }
        
    }
    
    // connecting to the band
    func connectingBand() {
        if let client = MSBClientManager.sharedManager().attachedClients().first as? MSBClient {
            self.client = client
            MSBClientManager.sharedManager().connectClient(self.client)
            let consent:MSBUserConsent = client.sensorManager.heartRateUserConsent()
            println(consent.rawValue)
            switch consent {
            case .Granted:
                println("Seonsor access granted. ")
            case .NotSpecified:
                println("Sensor access not specified. ")
                client.sensorManager.requestHRUserConsentWithCompletion({ (consent:Bool, error:NSError!) -> Void in
                })
            case .Declined:
                println("Sensor access declined. ")
                client.sensorManager.requestHRUserConsentWithCompletion({ (consent:Bool, error:NSError!) -> Void in
                })
            default:
                break
            }
        }
        else {
            self.connection_status = MSBandStatus.Failtoconnect
        }
    }
    
    // output to text file
    func outputbuttontext(message: String) {
        self.StatusButton.setTitle(message, forState: nil)
    }
    
    // Mark - Client Manager Delegates
    func clientManager(clientManager: MSBClientManager!, clientDidConnect client: MSBClient!) {
        self.connection_status = MSBandStatus.Connected
        self.ActivityIndicator.stopAnimating()
        self.ActivityIndicator.hidden = true
    }
    
    func clientManager(clientManager: MSBClientManager!, clientDidDisconnect client: MSBClient!) {
        self.connection_status = MSBandStatus.Disconnected
    }
    
    func clientManager(clientManager: MSBClientManager!, client: MSBClient!, didFailToConnectWithError error: NSError!) {
        self.connection_status = MSBandStatus.Failtoconnect
    }
    
    // measure heart rate and save it to the array
    func measuredata(heartratedata:MSBSensorHeartRateData!, error:NSError!) -> Void {
        let new_time = NSDate()
        let time_interval = NSDate().timeIntervalSinceDate(self.last_time_stamp)
        self.last_time_stamp = new_time
        let new_heart_data = heart_data(time_stamp:UInt(DISPATCH_TIME_NOW),heart_rate:heartratedata.heartRate,quality:heartratedata.quality.rawValue)
        self.heartdatastream.append(new_heart_data)
        self.BarChart.heartdatastream.append(new_heart_data)
        self.BarChart.setNeedsDisplay()
        if self.heartdatastream.count == 60 {
            self.connection_status = MSBandStatus.Connected
        }
        return
    }
}


// data structure to save each data point for heart rate measurement
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

// MS band status
enum MSBandStatus {
    case Disconnected
    case Connected
    case Connecting
    case Measuring
    case Failtoconnect
}


