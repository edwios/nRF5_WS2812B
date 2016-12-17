//
//  ViewController.swift
//  MagicLightLE
//
//  Created by Edwin Tam on 12/12/2016.
//  Copyright © 2016 Edwin Tam. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

extension UIColor {
    
    func rgb() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            if (fRed.isNaN || (fRed < 0.0)) {
                fRed = 0.0
            }
            if (fGreen.isNaN || (fGreen < 0.0)) {
                fGreen = 0.0
            }
            if (fBlue.isNaN || (fBlue < 0.0)) {
                fBlue = 0.0
            }
            if (fAlpha.isNaN || (fAlpha < 0.0)) {
                fAlpha = 0.0
            }
            
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}

extension ViewController: HSBColorPickerDelegate {
    func HSBColorColorPickerTouched(sender:HSBColorPicker, color:UIColor,    point:CGPoint, state:UIGestureRecognizerState) {
        if (LEDConnected) { // Act only when connected
//            if (CFDateGetTimeIntervalSinceDate(Date() as CFDate!, lastTouchTime as CFDate!) > 1.5) {
            if (abs(lastTouchTime.timeIntervalSince(Date())) > 0.5) {
                lastTouchTime = Date()
                // Handle color touched only per 1.2 seconds
                var dataArray = [UInt8](repeating: 0, count: 4)
                self.apple_rgbcolor = color
                let rgb = color.rgb()
                dataArray[0] = UInt8((rgb! & 0xFF000000) >> 24)
                dataArray[1] = UInt8((rgb! & 0x00FF0000) >> 16)
                dataArray[2] = UInt8((rgb! & 0x0000FF00) >> 8)
                dataArray[3] = UInt8((rgb! & 0x000000FF))
                let data = Data.init(bytes:dataArray)
                ledcolorPeripheral?.writeValue(data, for: ledcolorCharacteristic!, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
}


// Conform to CBCentralManagerDelegate, CBPeripheralDelegate protocols
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var controlContainerView: UIView!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var colorPickerView: UIView!
    
    let debug = false
    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    // UI-related
    let messageLabelFontName = "HelveticaNeue-Thin"
    let messageLabelFontSizeMessage:CGFloat = 56.0
    let messageLabelFontSizeTemp:CGFloat = 40.0
    
    var visibleBackgroundIndex = 0
    var invisibleBackgroundIndex = 1
    let defaultInitialColor = UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0)
    var lastColor=UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0)
    var circleDrawn = false
    var keepScanning = false
    
    // Core Bluetooth properties
    var centralManager:CBCentralManager!
    var blePeripheral:CBPeripheral?
    var ledcolorCharacteristic:CBCharacteristic?
    var ledcolorPeripheral:CBPeripheral?
    var ledcolorDescriptor:CBDescriptor?
    var colorPicker:HSBColorPicker?
    var LEDConnected = false
    var lastTouchTime = Date()
    var apple_rgbcolor=UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0)
    
    // Be careful, the advertised name may be the Short name.
    let blePeripheralName = "MagicLi"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = self
        self.lastColor = defaultInitialColor
        self.apple_rgbcolor = UIColor(red:0.0, green:0.0, blue:0.0, alpha:1.0)
        
        // Create our CBCentral Manager
        // delegate: The delegate that will receive central role events. Typically self.
        // queue:    The dispatch queue to use to dispatch the central role events.
        //           If the value is nil, the central manager dispatches central role events using the main queue.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Central Manager Initialization Options (Apple Developer Docs): http://tinyurl.com/zzvsgjh
        //  CBCentralManagerOptionShowPowerAlertKey
        //  CBCentralManagerOptionRestoreIdentifierKey
        //      To opt in to state preservation and restoration in an app that uses only one instance of a
        //      CBCentralManager object to implement the central role, specify this initialization option and provide
        //      a restoration identifier for the central manager when you allocate and initialize it.
        //centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        
        // configure initial UI
        messageLabel.font = UIFont(name: messageLabelFontName, size: messageLabelFontSizeMessage)
        messageLabel.text = "Searching"
        circleView.isHidden = true
        view.bringSubview(toFront: backgroundImageView)
        backgroundImageView.alpha = 1
        view.bringSubview(toFront: controlContainerView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.lastColor != defaultInitialColor {
            updateLEDColorDisplay()
        }
    }
    
    
    // MARK: - Handling User Interaction
    
    @IBAction func handleDisconnectButtonTapped(_ sender: AnyObject) {
        // if we don't have a sensor tag, start scanning for one...
        if self.blePeripheral == nil {
            keepScanning = true
            resumeScan()
            return
        } else {
            disconnect()
        }
    }
    
    func disconnect() {
        if let blePeripheral = self.blePeripheral {
            LEDConnected = false
            ledcolorCharacteristic = nil
            ledcolorPeripheral = nil
            centralManager.cancelPeripheralConnection(blePeripheral)
        }
    }
    
    
    // MARK: - Bluetooth scanning
    
    func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        if (debug) {print("DEBUG: PAUSING SCAN...")}
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
        disconnectButton.isEnabled = true
    }
    
    func resumeScan() {
        if keepScanning {
            // Start scanning again...
            if (debug) {print("DEBUG: RESUMING SCAN!")}
            disconnectButton.isEnabled = false
            messageLabel.font = UIFont(name: messageLabelFontName, size: messageLabelFontSizeMessage)
            messageLabel.text = "Searching"
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            disconnectButton.isEnabled = true
        }
    }
    
    
    // MARK: - Updating UI
    
    func updateLEDColorDisplay() {
        if !circleDrawn {
            drawCircle()
        } else {
            circleView.isHidden = false
        }
        
        messageLabel.font = UIFont(name: messageLabelFontName, size: messageLabelFontSizeTemp)
        messageLabel.text = "MagicLight"

    }
    
    func drawCircle() {
        circleView.isHidden = false
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: circleView.frame.width, height: circleView.frame.height)).cgPath
        circleView.layer.addSublayer(circleLayer)
        circleLayer.lineWidth = 8
        circleLayer.strokeColor = self.apple_rgbcolor.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleDrawn = true
    }
    
    func drawArc() {
        circleView.isHidden = false
        let arcLayer = CAShapeLayer()
        arcLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: circleView.frame.width, height: circleView.frame.height)).cgPath
        circleView.layer.addSublayer(arcLayer)
        arcLayer.lineWidth = 8
        arcLayer.strokeColor = UIColor.orange.cgColor
        arcLayer.fillColor = UIColor.clear.cgColor
        circleDrawn = true
    }
    
    func tensValue(_ temperature:Int) -> Int {
        var temperatureTens = 10;
        if (temperature > 1999) {
            if (temperature > 9999) {
                temperatureTens = 100;
            } else {
                temperatureTens = 10 * Int(floor( Double(temperature / 1000) + 0.5 ))
            }
        }
        return temperatureTens
    }
    
    func displayColor(_ data:Data) {
        // We'll get four bytes of data back, so we divide the byte count by one
        // because we're creating an array that holds four 8-bit (one-byte) values
        let dataLength = data.count / MemoryLayout<UInt8>.size
        var dataArray = [UInt8](repeating: 0, count: dataLength)
        (data as NSData).getBytes(&dataArray, length: dataLength * MemoryLayout<Int8>.size)
        if (debug) {
            // output values for debugging/diagnostic purposes
            for i in 0 ..< dataLength {
                let nextInt:UInt8 = dataArray[i]
                print("next byte: \(nextInt)")
            }
        }
        let colorRed:UInt8 = dataArray[1]
        let colorGreen:UInt8 = dataArray[2]
        let colorBlue:UInt8 = dataArray[3]
        
        let temp = UIColor.init(red: CGFloat(colorRed)/255.0, green: CGFloat(colorGreen)/255.0, blue: CGFloat(colorBlue)/255.0, alpha:1.0)
        self.lastColor = temp
        self.apple_rgbcolor = lastColor
        if (debug) {print("DEBUG: LAST Color CAPTURED: \(lastColor)")}
        
        if UIApplication.shared.applicationState == .active {
            updateLEDColorDisplay()
        }
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    // Invoked when the central manager’s state is updated.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var showAlert = true
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
            
            if (debug) {print(message)}
            keepScanning = true
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            //centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            // Option 2: Scan for devices that have the service you're interested in...
            let blePeripheralAdvertisingUUID = CBUUID(string: Device.MagicLightServiceUUID)
            if (debug) {print("DEBUG: Scanning for blePeripheral adverstising with UUID: \(blePeripheralAdvertisingUUID)")}
            centralManager.scanForPeripherals(withServices: [blePeripheralAdvertisingUUID], options: nil)
            
        }
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (debug) {print("DEBUG: centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")}
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if (debug) {
                print("DEBUG: NEXT PERIPHERAL NAME: \(peripheralName)")
                print("DEBUG: NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            }
            if peripheralName == blePeripheralName {
                if (debug) {print("DEBUG: MAGICLIGHT FOUND! ADDING NOW!!!")}
                // to save power, stop scanning for other devices
                keepScanning = false
                disconnectButton.isEnabled = true
                
                // save a reference to the sensor tag
                self.blePeripheral = peripheral
                self.blePeripheral!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(self.blePeripheral!, options: nil)
            }
        }
    }
    
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if (debug) {print("DEBUG: SUCCESSFULLY CONNECTED TO MAGICLIGHT!!!")}
        
        messageLabel.font = UIFont(name: messageLabelFontName, size: messageLabelFontSizeMessage)
        messageLabel.text = "Connected"
        
        // Now that we've successfully connected to the blePeripheral, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        // peripheral.discoverServices(nil)
        let blePeripheralServiceUUID = CBUUID(string: Device.MagicLightServiceUUID)
        peripheral.discoverServices([blePeripheralServiceUUID])
    }
    
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if (debug) {print("ERROR: CONNECTION TO MAGICLIGHT FAILED!!!")}
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if (debug) {print("DEBUG: DISCONNECTED FROM MAGICLIGHT!!!")}
        circleView.isHidden = true
        messageLabel.font = UIFont(name: messageLabelFontName, size: messageLabelFontSizeMessage)
        messageLabel.text = "Tap to search"
        if error != nil {
            if (debug) {print("ERROR: DISCONNECTION DETAILS: \(error!.localizedDescription)")}
        }
        self.blePeripheral = nil
        // Todo
        // Save lastColor to defaults for next time to set the LED color automatically
    }
    
    
    //MARK: - CBPeripheralDelegate methods
    
    /*
     Invoked when you discover the peripheral’s available services.
     
     This method is invoked when your app calls the discoverServices: method.
     If the services of the peripheral are successfully discovered, you can access them
     through the peripheral’s services property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            if (debug) {print("ERROR: ERROR IN DISCOVERING SERVICES: \(error?.localizedDescription)")}
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                if (debug) {print("DEBUG: Discovered service \(service)")}
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
                if (service.uuid == CBUUID(string: Device.MagicLightServiceUUID))
                {
                    if (debug) {print("DEBUG: Discovering characteristics")}
                    let LEDColorCharUUIDs = [CBUUID(string: Device.LEDColorCharUUID)]
                    peripheral.discoverCharacteristics(LEDColorCharUUIDs, for: service)
                }
            }
        }
    }
    
    
    /*
     Invoked when you discover the characteristics of a specified service.
     
     If the characteristics of the specified service are successfully discovered, you can access
     them through the service's characteristics property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            if (debug) {print("ERROR: ERROR IN DISCOVERING CHARACTERISTICS: \(error?.localizedDescription)")}
            return
        }
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                if (debug) {print("DEBUG: Discovered characteristics \(characteristics)")}
                if characteristic.uuid == CBUUID(string: Device.LEDColorCharUUID) {
                    if (debug) {print("DEBUG: Discovered charecteristic \(characteristics)")}
                    ledcolorCharacteristic = characteristic
                    ledcolorPeripheral = peripheral
                    ledcolorDescriptor = characteristic.descriptors?[0]
                    peripheral.readValue(for: characteristic)
                    LEDConnected = true
                }
            }
        }
    }
    
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            if (debug) {print("ERROR: UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error?.localizedDescription)")}
            return
        }
        if (debug) {print("DEBUG: Characteristic \(characteristic) updated value")}
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: Device.LEDColorCharUUID) {
                circleDrawn = false
                displayColor(dataBytes)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            if (debug) {print("ERROR: UPDATING VALUE TO CHARACTERISTIC: \(characteristic) - \(error?.localizedDescription)")}
            return
        }
        circleDrawn = false
        updateLEDColorDisplay()
    }
}
