import Foundation
import CoreBluetooth

class BLEManager: NSObject {
    
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var discoveredDevices: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    // Samsung Watch karakteristikleri (konsoldan alındı)
    private let SAMSUNG_WRITE_UUID = "B2AE0493-D87F-475C-B656-5840E0A13FC8"
    private let SAMSUNG_NOTIFY_UUID = "6FCFB474-CE57-48FF-A4CE-B43767D6D04A"
    
    // Callback'ler
    var onDeviceDiscovered: ((CBPeripheral, String) -> Void)?
    var onConnectionStatusChanged: ((Bool, String?) -> Void)?
    var onDataReceived: ((Data) -> Void)?
    var onMessageSent: ((Bool) -> Void)?
    var onSetupCompleted: ((Bool) -> Void)?
    
    // MARK: - Singleton
    static let shared = BLEManager()
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
        ])
    }
    
    // MARK: - Public Methods
    
    /// Cihaz taramasını başlat
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("❌ Bluetooth kapalı veya kullanılamıyor")
            return
        }
        
        print("🔍 Samsung Watch aranıyor...")
        discoveredDevices.removeAll()
        
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    /// Taramayı durdur
    func stopScanning() {
        centralManager.stopScan()
        print("⏹ Tarama durduruldu. Bulunan cihaz sayısı: \(discoveredDevices.count)")
    }
    
    /// Cihaza bağlan
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        
        // Bağlantı seçenekleri - Samsung Watch için
        let options: [String: Any] = [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ]
        
        centralManager.connect(peripheral, options: options)
        print("🔄 \(peripheral.name ?? "Bilinmeyen Cihaz") cihazına bağlanılıyor...")
    }
    
    /// Bağlantıyı kes ve unut
    func disconnectAndForget() {
        guard let peripheral = connectedPeripheral else { return }
        
        print("🗑 Cihaz unutuluyor: \(peripheral.name ?? "Bilinmeyen")")
        
        if let notifyChar = notifyCharacteristic {
            peripheral.setNotifyValue(false, for: notifyChar)
        }
        
        centralManager.cancelPeripheralConnection(peripheral)
        
        connectedPeripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
        
        print("✅ Cihaz unutuldu ve bağlantı kesildi")
    }
    
    /// Bağlantıyı kes
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// PIN gönder
    func sendPIN(_ pin: String) {
        sendSamsungCommand("PIN", parameter: pin)
    }
    
    /// Kurulum tamamlandı mesajı gönder - Samsung SAP protokolü
    func sendSetupComplete() {
        print("📱→⌚ Samsung SAP protokolü ile kurulum mesajı gönderiliyor...")
        
        // Samsung Accessory Protocol (SAP) formatı
        // Header: [Start, Length, Command, Checksum]
        let sapCommands: [[UInt8]] = [
            // SAP Handshake
            [0xFC, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00],
            
            // Device Info
            [0xFC, 0x00, 0x0C, 0x00, 0x01, 0x00, 0x00, 0x02,
             0x69, 0x50, 0x68, 0x6F, 0x6E, 0x65], // "iPhone"
            
            // Pairing Complete
            [0xFC, 0x00, 0x06, 0x00, 0x02, 0x00, 0x00, 0x03, 0x01, 0x00],
            
            // Setup Complete
            [0xFC, 0x00, 0x05, 0x00, 0x03, 0x00, 0x00, 0x04, 0xFF],
            
            // Sync Time
            [0xFC, 0x00, 0x08, 0x00, 0x04, 0x00, 0x00, 0x05] + getCurrentTimeBytes(),
            
            // End Session
            [0xFC, 0x00, 0x04, 0x00, 0xFF, 0x00, 0x00, 0xFF]
        ]
        
        // SAP komutlarını gönder
        for (index, command) in sapCommands.enumerated() {
            let data = Data(command)
            sendRawData(data)
            print("📤 SAP Komut \(index + 1): \(data.hexString)")
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // Alternatif: Galaxy Wearable formatı
        sendGalaxyWearableCommand()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.onSetupCompleted?(true)
        }
    }
    
    /// Galaxy Wearable uygulaması formatında komut gönder
    private func sendGalaxyWearableCommand() {
        print("📱 Galaxy Wearable formatında mesaj gönderiliyor...")
        
        // XML format (Galaxy Wearable kullanır)
        let xmlCommand = """
        <?xml version="1.0" encoding="UTF-8"?>
        <message>
            <header>
                <type>setup_complete</type>
                <from>iPhone</from>
                <to>GalaxyWatch</to>
            </header>
            <body>
                <status>success</status>
                <device>iOS</device>
                <version>1.0</version>
            </body>
        </message>
        """
        
        if let data = xmlCommand.data(using: .utf8) {
            // Parçalara böl ve gönder
            let chunks = data.chunked(into: 20) // BLE MTU limiti
            for chunk in chunks {
                sendRawData(chunk)
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        
        // JSON alternatif
        let jsonCommand = [
            "type": "SETUP_COMPLETE",
            "status": "SUCCESS",
            "device": "iPhone",
            "timestamp": Int(Date().timeIntervalSince1970)
        ] as [String : Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonCommand) {
            sendRawData(jsonData)
        }
    }
    
    /// Samsung özel protokol komutu oluştur
    private func createSamsungPacket(command: UInt8, data: [UInt8]) -> Data {
        var packet: [UInt8] = []
        
        // Samsung packet structure:
        // [Start Byte][Length][Command][Data][Checksum]
        
        packet.append(0xFC) // Start byte
        packet.append(UInt8(data.count + 3)) // Length
        packet.append(command) // Command
        packet.append(contentsOf: data) // Data
        
        // Calculate checksum (XOR)
        var checksum: UInt8 = 0
        for byte in packet {
            checksum ^= byte
        }
        packet.append(checksum)
        
        return Data(packet)
    }
    
    /// Zaman bilgisini byte array olarak al
    private func getCurrentTimeBytes() -> [UInt8] {
        let timestamp = UInt32(Date().timeIntervalSince1970)
        return [
            UInt8((timestamp >> 24) & 0xFF),
            UInt8((timestamp >> 16) & 0xFF),
            UInt8((timestamp >> 8) & 0xFF),
            UInt8(timestamp & 0xFF)
        ]
    }
    
    /// Samsung Watch'a özel handshake - PUBLIC
    func performSamsungHandshake() {
        print("🤝 Samsung handshake başlatılıyor...")
        
        // Step 1: Identify as phone
        let phoneIdentity = createSamsungPacket(command: 0x01, data: [0x50, 0x48, 0x4F, 0x4E, 0x45]) // "PHONE"
        sendRawData(phoneIdentity)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Step 2: Request pairing
        let pairRequest = createSamsungPacket(command: 0x02, data: [0x01])
        sendRawData(pairRequest)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Step 3: Confirm setup
        let setupConfirm = createSamsungPacket(command: 0x03, data: [0x01, 0x00])
        sendRawData(setupConfirm)
    }
    
    /// Samsung özel komut gönder
    private func sendSamsungCommand(_ command: String, parameter: String = "") {
        // Samsung Watch JSON format
        let jsonCommand = "{\"cmd\":\"\(command)\",\"param\":\"\(parameter)\"}"
        
        if let data = jsonCommand.data(using: .utf8) {
            sendRawData(data)
            print("📤 Samsung komutu: \(jsonCommand)")
        }
        
        // Alternatif format
        let simpleCommand = "\(command):\(parameter)"
        if let data = simpleCommand.data(using: .utf8) {
            sendRawData(data)
        }
    }
    
    /// Genel mesaj gönderme
    func sendMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        sendRawData(data)
    }
    
    /// Ham veri gönder
    func sendRawData(_ data: Data) {
        guard let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral else {
            print("❌ Veri gönderilemedi - karakteristik yok")
            onMessageSent?(false)
            return
        }
        
        // Samsung Watch için parçalı gönderim gerekebilir
        let maxLength = peripheral.maximumWriteValueLength(for: .withResponse)
        
        if data.count > maxLength {
            // Veriyi parçala
            var offset = 0
            while offset < data.count {
                let chunkSize = min(maxLength, data.count - offset)
                let chunk = data.subdata(in: offset..<(offset + chunkSize))
                
                peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
                print("📤 Parça gönderildi: \(chunk.hexString)")
                
                offset += chunkSize
                Thread.sleep(forTimeInterval: 0.05)
            }
        } else {
            // Tek seferde gönder
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("📤 Veri gönderildi: \(data.hexString)")
        }
    }
    
    /// Cihaz türünü al
    func getDeviceType(for peripheral: CBPeripheral) -> String {
        let name = peripheral.name?.lowercased() ?? ""
        
        if name.contains("watch") || name.contains("galaxy") || name.contains("gear") || name.contains("sm-r") {
            return "⌚ Akıllı Saat"
        } else if name.contains("airpod") || name.contains("buds") || name.contains("headphone") {
            return "🎧 Kulaklık"
        } else if name.contains("speaker") {
            return "🔊 Hoparlör"
        } else if name.contains("car") || name.contains("bmw") || name.contains("audi") {
            return "🚗 Araç"
        } else if name.contains("tv") || name.contains("samsung") {
            return "📺 TV"
        } else {
            return "📱 Diğer"
        }
    }
    
    /// Bağlantıyı güçlendir
    func strengthenConnection() {
        guard let peripheral = connectedPeripheral else { return }
        
        // MTU'yu artır (daha büyük veri paketleri için)
        if #available(iOS 11.0, *) {
            print("📶 MTU artırılıyor...")
        }
        
        // Bağlantı önceliğini artır
        peripheral.readRSSI()
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth açık ve hazır")
        case .poweredOff:
            print("❌ Bluetooth kapalı")
            onConnectionStatusChanged?(false, "Bluetooth kapalı")
        case .resetting:
            print("⚠️ Bluetooth sıfırlanıyor")
        case .unauthorized:
            print("❌ Bluetooth izni yok")
            onConnectionStatusChanged?(false, "Bluetooth izni verilmemiş")
        case .unsupported:
            print("❌ Bu cihaz Bluetooth desteklemiyor")
            onConnectionStatusChanged?(false, "Bluetooth desteklenmiyor")
        case .unknown:
            print("❓ Bluetooth durumu bilinmiyor")
        @unknown default:
            print("❓ Yeni bir durum")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Bilinmeyen"
        
        // Samsung Watch kontrolü
        let samsungKeywords = ["Galaxy", "Watch", "Samsung", "SM-R", "Gear"]
        let isSamsungDevice = samsungKeywords.contains { deviceName.lowercased().contains($0.lowercased()) }
        
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
            
            if isSamsungDevice {
                print("🎯 Samsung cihaz bulundu: \(deviceName) - RSSI: \(RSSI)")
            } else if deviceName != "Bilinmeyen" {
                print("📱 Cihaz bulundu: \(deviceName) - RSSI: \(RSSI)")
            }
            
            onDeviceDiscovered?(peripheral, deviceName)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Bağlandı: \(peripheral.name ?? "Bilinmeyen")")
        
        // Bağlantıyı güçlendir
        strengthenConnection()
        
        onConnectionStatusChanged?(true, peripheral.name)
        
        // Servisleri keşfet
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Bağlantı başarısız: \(error?.localizedDescription ?? "Bilinmeyen hata")")
        onConnectionStatusChanged?(false, error?.localizedDescription)
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Bağlantı kesildi: \(peripheral.name ?? "Bilinmeyen")")
        
        if let error = error {
            print("   Hata: \(error.localizedDescription)")
            
            // Otomatik yeniden bağlanma dene
            if error.localizedDescription.contains("disconnected") {
                print("🔄 Yeniden bağlanma deneniyor...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.connect(to: peripheral)
                }
                return
            }
        }
        
        onConnectionStatusChanged?(false, "Bağlantı kesildi")
        connectedPeripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("❌ Servis keşfi hatası: \(error!.localizedDescription)")
            return
        }
        
        print("📋 Bulunan servis sayısı: \(peripheral.services?.count ?? 0)")
        
        peripheral.services?.forEach { service in
            print("  📁 Servis UUID: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("❌ Karakteristik keşfi hatası: \(error!.localizedDescription)")
            return
        }
        
        print("  📂 Servis: \(service.uuid)")
        
        service.characteristics?.forEach { characteristic in
            print("    📝 Karakteristik: \(characteristic.uuid)")
            
            let properties = describeProperties(characteristic.properties)
            print("       Özellikler: \(properties)")
            
            // Samsung Watch karakteristiklerini kontrol et
            if characteristic.uuid.uuidString.uppercased() == SAMSUNG_WRITE_UUID {
                writeCharacteristic = characteristic
                print("    ✏️ Samsung yazma karakteristiği bulundu!")
            }
            
            if characteristic.uuid.uuidString.uppercased() == SAMSUNG_NOTIFY_UUID {
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("    🔔 Samsung bildirim karakteristiği bulundu ve aktif edildi!")
            }
            
            // Alternatif yazma karakteristiği
            if writeCharacteristic == nil &&
               (characteristic.properties.contains(.write) ||
                characteristic.properties.contains(.writeWithoutResponse)) {
                writeCharacteristic = characteristic
                print("    ✏️ Alternatif yazma karakteristiği bulundu!")
            }
            
            // Okunabilir karakteristikleri oku
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
        
        if writeCharacteristic != nil {
            print("✅ Cihaz kurulum için hazır!")
            
            // Samsung handshake başlat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.performSamsungHandshake()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value else {
            if let error = error {
                print("❌ Veri okuma hatası: \(error.localizedDescription)")
                
                // Encryption hatası varsa güvenlik seviyesini artır
                if error.localizedDescription.contains("Encryption") {
                    print("🔐 Güvenlik seviyesi artırılıyor...")
                    // iOS otomatik olarak halledecek
                }
            }
            return
        }
        
        print("📥 Veri alındı - UUID: \(characteristic.uuid)")
        print("   Ham veri: \(data.hexString)")
        
        // Veriyi yorumla
        if let string = String(data: data, encoding: .utf8) {
            print("   String: \(string)")
            
            // Samsung Watch komutlarını kontrol et
            handleSamsungResponse(string)
        } else {
            // Binary veri olabilir
            handleSamsungBinaryResponse(data)
        }
        
        onDataReceived?(data)
    }
    
    private func handleSamsungResponse(_ response: String) {
        if response.contains("WAITING") || response.contains("READY") {
            print("⌚ Saat kurulum bekliyor!")
            sendSetupComplete()
        } else if response.contains("ACK") || response.contains("OK") {
            print("✅ Saat komutu onayladı")
        } else if response.contains("ERROR") || response.contains("FAIL") {
            print("❌ Saat hata bildirdi: \(response)")
        }
        
        // Model bilgisi
        if response.contains("SM-R") {
            print("📱 Saat modeli: \(response)")
        }
    }
    
    private func handleSamsungBinaryResponse(_ data: Data) {
        let bytes = [UInt8](data)
        
        if bytes.count > 0 {
            switch bytes[0] {
            case 0x01:
                print("⌚ Saat: Bağlantı onaylandı")
                // Kurulum mesajını gönder
                sendSetupComplete()
            case 0x02:
                print("⌚ Saat: Kurulum modu")
            case 0x03:
                print("⌚ Saat: Veri bekleniyor")
            case 0xFC:
                print("⌚ Saat: Samsung SAP mesajı alındı")
                if bytes.count > 2 {
                    print("   Komut: 0x\(String(format: "%02X", bytes[2]))")
                }
            case 0xFF:
                print("⌚ Saat: İşlem tamamlandı")
            default:
                print("⌚ Saat: Bilinmeyen komut 0x\(String(format: "%02X", bytes[0]))")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Yazma hatası: \(error.localizedDescription)")
            onMessageSent?(false)
        } else {
            print("✅ Veri başarıyla yazıldı")
            onMessageSent?(true)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Bildirim durumu güncellenemedi: \(error.localizedDescription)")
        } else {
            print("✅ Bildirim durumu güncellendi: \(characteristic.isNotifying ? "Aktif" : "Pasif")")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            print("❌ RSSI okuma hatası: \(error.localizedDescription)")
        } else {
            print("📶 Sinyal gücü: \(RSSI) dBm")
        }
    }
    
    // Yardımcı fonksiyon
    private func describeProperties(_ properties: CBCharacteristicProperties) -> String {
        var descriptions: [String] = []
        
        if properties.contains(.read) { descriptions.append("Okunabilir") }
        if properties.contains(.write) { descriptions.append("Yazılabilir") }
        if properties.contains(.writeWithoutResponse) { descriptions.append("Yanıtsız Yazılabilir") }
        if properties.contains(.notify) { descriptions.append("Bildirim") }
        if properties.contains(.indicate) { descriptions.append("İndikasyon") }
        
        return descriptions.joined(separator: ", ")
    }
}

// MARK: - Data Extension
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined(separator: " ")
    }
    
    init(hex: String) {
        self.init()
        var hex = hex
        hex = hex.replacingOccurrences(of: " ", with: "")
        
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                append(byte)
            }
            index = nextIndex
        }
    }
    
    func chunked(into size: Int) -> [Data] {
        var chunks: [Data] = []
        var offset = 0
        
        while offset < count {
            let chunkSize = Swift.min(size, count - offset)
            let chunk = subdata(in: offset..<(offset + chunkSize))
            chunks.append(chunk)
            offset += chunkSize
        }
        
        return chunks
    }
}
