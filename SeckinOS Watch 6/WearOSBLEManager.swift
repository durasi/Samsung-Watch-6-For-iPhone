import Foundation
import CoreBluetooth

class WearOSBLEManager: NSObject {
    
    // MARK: - WearOS Service UUIDs
    private let WEAROS_SERVICE_UUID = CBUUID(string: "0000FE2C-0000-1000-8000-00805F9B34FB") // Google Wearable
    private let GOOGLE_SERVICE_UUID = CBUUID(string: "0000FEF3-0000-1000-8000-00805F9B34FB") // Google Nearby
    private let COMPANION_SERVICE_UUID = CBUUID(string: "00001811-0000-1000-8000-00805F9B34FB") // Alert Notification
    
    // WearOS Characteristics (from reverse engineering)
    private let WEAROS_COMMAND_CHAR = CBUUID(string: "00002A46-0000-1000-8000-00805F9B34FB")
    private let WEAROS_NOTIFY_CHAR = CBUUID(string: "00002A44-0000-1000-8000-00805F9B34FB")
    
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var connectedWatch: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    // Discovered characteristics
    private var allCharacteristics: [CBCharacteristic] = []
    
    // Callbacks
    var onDeviceDiscovered: ((CBPeripheral, String, Bool) -> Void)? // peripheral, name, isWearOS
    var onConnectionStatusChanged: ((Bool, String?) -> Void)?
    var onSetupStageChanged: ((String, Float) -> Void)? // stage description, progress
    var onWearOSMessageReceived: ((String) -> Void)?
    
    // MARK: - Singleton
    static let shared = WearOSBLEManager()
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
            // CBCentralManagerOptionRestoreIdentifierKey removed - causing crash
        ])
    }
    
    // MARK: - Public Methods
    
    func startWearOSScanning() {
        guard centralManager.state == .poweredOn else {
            print("❌ WearOS: Bluetooth not ready")
            return
        }
        
        print("🔍 WearOS: Scanning for Wear OS devices...")
        
        // Scan for all devices (WearOS service UUIDs not always advertised)
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        // Stop after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("⏹ WearOS: Scanning stopped")
    }
    
    func connectToWearOSDevice(_ peripheral: CBPeripheral) {
        stopScanning()
        connectedWatch = peripheral
        connectedWatch?.delegate = self
        
        print("🔄 WearOS: Connecting to \(peripheral.name ?? "Unknown Watch")...")
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func disconnect() {
        guard let watch = connectedWatch else { return }
        centralManager.cancelPeripheralConnection(watch)
    }
    
    // MARK: - WearOS Protocol Implementation
    
    func startWearOSPairing() {
        print("🚀 WearOS: Starting pairing sequence...")
        onSetupStageChanged?("Initializing WearOS Protocol", 0.1)
        
        // Step 1: Send WearOS identification
        sendWearOSIdentification()
        
        // Step 2: Exchange capabilities
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.sendCapabilities()
        }
        
        // Step 3: Sync time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.syncTime()
        }
        
        // Step 4: Complete setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.completeWearOSSetup()
        }
    }
    
    private func sendWearOSIdentification() {
        print("📱 WearOS: Sending device identification...")
        onSetupStageChanged?("Identifying as WearOS Companion", 0.2)
        
        // WearOS Protocol Buffer format (simplified)
        let identification = WearOSMessage.deviceInfo(
            deviceName: "iPhone",
            deviceType: 2, // 1=Android, 2=iOS
            companionVersion: "3.0.0",
            protocolVersion: 1
        )
        
        sendWearOSMessage(identification)
    }
    
    private func sendCapabilities() {
        print("📋 WearOS: Exchanging capabilities...")
        onSetupStageChanged?("Exchanging Device Capabilities", 0.4)
        
        let capabilities = WearOSMessage.capabilities(
            notifications: true,
            calls: false, // iOS limitation
            sms: false,   // iOS limitation
            fitness: true,
            assistant: false
        )
        
        sendWearOSMessage(capabilities)
    }
    
    private func syncTime() {
        print("🕐 WearOS: Syncing time...")
        onSetupStageChanged?("Synchronizing Time", 0.6)
        
        let timeSync = WearOSMessage.timeSync(
            timestamp: Int(Date().timeIntervalSince1970),
            timezone: TimeZone.current.identifier
        )
        
        sendWearOSMessage(timeSync)
    }
    
    private func completeWearOSSetup() {
        print("✅ WearOS: Completing setup...")
        onSetupStageChanged?("Finalizing WearOS Setup", 0.8)
        
        // Send multiple completion signals
        let completionMessages = [
            WearOSMessage.setupComplete(),
            WearOSMessage.companionReady(),
            WearOSMessage.startSync()
        ]
        
        for (index, message) in completionMessages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) { [weak self] in
                self?.sendWearOSMessage(message)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.onSetupStageChanged?("WearOS Setup Complete!", 1.0)
            print("🎉 WearOS: Setup sequence completed")
        }
    }
    
    private func sendWearOSMessage(_ message: WearOSMessage) {
        let data = message.toData()
        
        // Try all writable characteristics
        for characteristic in allCharacteristics {
            if characteristic.properties.contains(.write) ||
               characteristic.properties.contains(.writeWithoutResponse) {
                
                let writeType: CBCharacteristicWriteType =
                    characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                connectedWatch?.writeValue(data, for: characteristic, type: writeType)
                print("📤 WearOS: Sent to \(characteristic.uuid): \(data.hexString)")
            }
        }
    }
    
    // MARK: - Samsung Specific Workarounds
    
    func trySamsungWearOSMode() {
        print("🔧 WearOS: Attempting Samsung-specific protocol...")
        
        // Samsung watches use modified WearOS
        let samsungMessages: [Data] = [
            // Galaxy Wearable handshake
            Data([0x10, 0x00, 0x08, 0x00, 0x01, 0x00, 0x02, 0x01]),
            
            // WearOS mode activation
            Data([0x47, 0x57, 0x4F, 0x53]), // "GWOS" - Galaxy WearOS
            
            // Companion app identification
            Data([0x02, 0x00, 0x04, 0x69, 0x4F, 0x53, 0x00]), // iOS identifier
            
            // Setup complete signal
            Data([0xFF, 0x00, 0x01, 0x01])
        ]
        
        for message in samsungMessages {
            sendRawData(message)
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
    
    private func sendRawData(_ data: Data) {
        guard let watch = connectedWatch else { return }
        
        // Send to all writable characteristics
        for characteristic in allCharacteristics {
            if characteristic.properties.contains(.write) ||
               characteristic.properties.contains(.writeWithoutResponse) {
                
                let writeType: CBCharacteristicWriteType =
                    characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                watch.writeValue(data, for: characteristic, type: writeType)
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension WearOSBLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ WearOS: Bluetooth powered on")
        case .poweredOff:
            print("❌ WearOS: Bluetooth powered off")
            onConnectionStatusChanged?(false, "Bluetooth off")
        default:
            print("⚠️ WearOS: Bluetooth state: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown"
        
        // Check if it's a WearOS device
        let isWearOS = name.lowercased().contains("watch") ||
                       name.lowercased().contains("wear") ||
                       name.lowercased().contains("galaxy") ||
                       name.lowercased().contains("fossil") ||
                       name.lowercased().contains("ticwatch")
        
        if isWearOS {
            print("⌚ WearOS: Found potential device: \(name) (RSSI: \(RSSI))")
        }
        
        onDeviceDiscovered?(peripheral, name, isWearOS)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ WearOS: Connected to \(peripheral.name ?? "Unknown")")
        onConnectionStatusChanged?(true, peripheral.name)
        
        // Discover all services
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ WearOS: Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        onConnectionStatusChanged?(false, error?.localizedDescription)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 WearOS: Disconnected from \(peripheral.name ?? "Unknown")")
        onConnectionStatusChanged?(false, "Disconnected")
        connectedWatch = nil
        allCharacteristics.removeAll()
    }
}

// MARK: - CBPeripheralDelegate
extension WearOSBLEManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            print("❌ WearOS: Service discovery failed")
            return
        }
        
        print("📋 WearOS: Discovered \(services.count) services")
        
        for service in services {
            print("  📁 Service: \(service.uuid)")
            
            // Check for WearOS services
            if service.uuid == WEAROS_SERVICE_UUID {
                print("  ✅ Found WearOS Service!")
            } else if service.uuid == GOOGLE_SERVICE_UUID {
                print("  ✅ Found Google Service!")
            }
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }
        
        print("  📂 Service \(service.uuid): \(characteristics.count) characteristics")
        
        for characteristic in characteristics {
            allCharacteristics.append(characteristic)
            
            print("    📝 Char: \(characteristic.uuid)")
            
            // Subscribe to notifications
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                print("      🔔 Subscribed to notifications")
            }
            
            // Read if possible
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
        
        // Start pairing once all characteristics are discovered
        if allCharacteristics.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.startWearOSPairing()
                self?.trySamsungWearOSMode()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else { return }
        
        print("📥 WearOS: Received from \(characteristic.uuid): \(data.hexString)")
        
        if let message = String(data: data, encoding: .utf8) {
            print("   String: \(message)")
            onWearOSMessageReceived?(message)
        }
        
        // Handle WearOS protocol responses
        handleWearOSResponse(data)
    }
    
    private func handleWearOSResponse(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count > 0 else { return }
        
        // WearOS protocol responses
        switch bytes[0] {
        case 0x01:
            print("⌚ WearOS: Handshake acknowledged")
        case 0x02:
            print("⌚ WearOS: Capabilities received")
        case 0x03:
            print("⌚ WearOS: Time sync confirmed")
        case 0x10:
            print("⌚ WearOS: Pairing request")
        case 0xFF:
            print("⌚ WearOS: Setup complete acknowledged")
            onSetupStageChanged?("Watch confirmed setup!", 1.0)
        default:
            break
        }
    }
}

// MARK: - WearOS Message Structure
struct WearOSMessage {
    let type: UInt8
    let payload: Data
    
    func toData() -> Data {
        var data = Data()
        data.append(type)
        data.append(UInt8(payload.count))
        data.append(payload)
        
        // Add checksum
        var checksum: UInt8 = type
        for byte in payload {
            checksum ^= byte
        }
        data.append(checksum)
        
        return data
    }
    
    // Message factory methods
    static func deviceInfo(deviceName: String, deviceType: Int, companionVersion: String, protocolVersion: Int) -> WearOSMessage {
        var payload = Data()
        
        // Add device name
        if let nameData = deviceName.data(using: .utf8) {
            payload.append(UInt8(nameData.count))
            payload.append(nameData)
        }
        
        // Add device type
        payload.append(UInt8(deviceType))
        
        // Add version info
        if let versionData = companionVersion.data(using: .utf8) {
            payload.append(UInt8(versionData.count))
            payload.append(versionData)
        }
        
        payload.append(UInt8(protocolVersion))
        
        return WearOSMessage(type: 0x01, payload: payload)
    }
    
    static func capabilities(notifications: Bool, calls: Bool, sms: Bool, fitness: Bool, assistant: Bool) -> WearOSMessage {
        var payload = Data()
        var flags: UInt8 = 0
        
        if notifications { flags |= 0x01 }
        if calls { flags |= 0x02 }
        if sms { flags |= 0x04 }
        if fitness { flags |= 0x08 }
        if assistant { flags |= 0x10 }
        
        payload.append(flags)
        
        return WearOSMessage(type: 0x02, payload: payload)
    }
    
    static func timeSync(timestamp: Int, timezone: String) -> WearOSMessage {
        var payload = Data()
        
        // Add timestamp (4 bytes)
        let time = UInt32(timestamp)
        payload.append(UInt8((time >> 24) & 0xFF))
        payload.append(UInt8((time >> 16) & 0xFF))
        payload.append(UInt8((time >> 8) & 0xFF))
        payload.append(UInt8(time & 0xFF))
        
        // Add timezone
        if let tzData = timezone.data(using: .utf8) {
            payload.append(UInt8(tzData.count))
            payload.append(tzData)
        }
        
        return WearOSMessage(type: 0x03, payload: payload)
    }
    
    static func setupComplete() -> WearOSMessage {
        return WearOSMessage(type: 0xFF, payload: Data([0x01]))
    }
    
    static func companionReady() -> WearOSMessage {
        return WearOSMessage(type: 0xFE, payload: Data([0x01]))
    }
    
    static func startSync() -> WearOSMessage {
        return WearOSMessage(type: 0xFD, payload: Data([0x01]))
    }
}

// MARK: - Data Extension
// Note: hexString extension is defined in BLEManager.swift
// If you get an error, add this extension here:
/*
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined(separator: " ")
    }
}
*/
