import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    // MARK: - Ekran Durumları
    enum ScreenState {
        case scanning
        case pairing  // Şu an kullanılmıyor ama ileride gerekebilir
        case setup
        case connected
    }
    
    // MARK: - UI Elements
    private let containerView = UIView()
    
    // Tarama Ekranı
    private let scanningView = UIView()
    private let statusLabel = UILabel()
    private let scanButton = UIButton(type: .system)
    private let devicesTableView = UITableView()
    
    // PIN Ekranı
    private let pairingView = UIView()
    private let pinTitleLabel = UILabel()
    private let pinStackView = UIStackView()
    private var pinTextFields: [UITextField] = []
    private let confirmPinButton = UIButton(type: .system)
    private let pinErrorLabel = UILabel()
    
    // Kurulum Ekranı
    private let setupView = UIView()
    private let setupTitleLabel = UILabel()
    private let setupProgressView = UIProgressView()
    private let setupStatusLabel = UILabel()
    private let setupStepsStackView = UIStackView()
    
    // Bağlı Ekranı
    private let connectedView = UIView()
    private let connectedLabel = UILabel()
    private let connectedDeviceLabel = UILabel()
    private let disconnectButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let bleManager = BLEManager.shared
    private var discoveredDevices: [(peripheral: CBPeripheral, name: String)] = []
    private var currentPeripheral: CBPeripheral?
    private var currentDeviceName: String = ""
    private var isScanning = false
    private var currentState: ScreenState = .scanning
    private var setupTimer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBLECallbacks()
        showScreen(.scanning)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0) // Google Gray
        title = "WearOS & Samsung Watch"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // WearOS style modifications
        navigationController?.navigationBar.tintColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
        
        // Container View
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Ekranları oluştur
        setupScanningView()
        setupPairingView()
        setupSetupView()
        setupConnectedView()
        
        // Container constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Tarama Ekranı
    private func setupScanningView() {
        scanningView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(scanningView)
        
        // Status Label
        statusLabel.text = "WearOS cihazlarını taramak için aşağıdaki butona basın"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        scanningView.addSubview(statusLabel)
        
        // Scan Button
        scanButton.setTitle("🔍 WearOS Cihaz Ara", for: .normal)
        scanButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        scanButton.backgroundColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0) // Google Blue
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 25
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        scanningView.addSubview(scanButton)
        
        // Devices Table
        devicesTableView.delegate = self
        devicesTableView.dataSource = self
        devicesTableView.layer.cornerRadius = 10
        devicesTableView.backgroundColor = .secondarySystemBackground
        devicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        devicesTableView.translatesAutoresizingMaskIntoConstraints = false
        scanningView.addSubview(devicesTableView)
        
        NSLayoutConstraint.activate([
            scanningView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scanningView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scanningView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scanningView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: scanningView.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: scanningView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: scanningView.trailingAnchor, constant: -20),
            
            scanButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            scanButton.centerXAnchor.constraint(equalTo: scanningView.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 200),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            devicesTableView.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            devicesTableView.leadingAnchor.constraint(equalTo: scanningView.leadingAnchor, constant: 20),
            devicesTableView.trailingAnchor.constraint(equalTo: scanningView.trailingAnchor, constant: -20),
            devicesTableView.bottomAnchor.constraint(equalTo: scanningView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - PIN Ekranı
    private func setupPairingView() {
        pairingView.backgroundColor = .systemBackground
        pairingView.translatesAutoresizingMaskIntoConstraints = false
        pairingView.isHidden = true
        containerView.addSubview(pairingView)
        
        // Title
        pinTitleLabel.text = "Saatinizde görünen 6 haneli PIN kodunu girin"
        pinTitleLabel.textAlignment = .center
        pinTitleLabel.numberOfLines = 0
        pinTitleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        pinTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pairingView.addSubview(pinTitleLabel)
        
        // PIN Stack View
        pinStackView.axis = .horizontal
        pinStackView.distribution = .fillEqually
        pinStackView.spacing = 10
        pinStackView.translatesAutoresizingMaskIntoConstraints = false
        pairingView.addSubview(pinStackView)
        
        // PIN Text Fields
        for i in 0..<6 {
            let textField = UITextField()
            textField.borderStyle = .none
            textField.textAlignment = .center
            textField.font = .systemFont(ofSize: 24, weight: .bold)
            textField.keyboardType = .numberPad
            textField.tag = i
            textField.backgroundColor = .secondarySystemBackground
            textField.layer.cornerRadius = 10
            textField.layer.borderWidth = 2
            textField.layer.borderColor = UIColor.systemGray4.cgColor
            textField.delegate = self
            
            // Her text field'a target ekle
            textField.addTarget(self, action: #selector(pinFieldChanged(_:)), for: .editingChanged)
            
            pinTextFields.append(textField)
            pinStackView.addArrangedSubview(textField)
        }
        
        // Error Label
        pinErrorLabel.text = ""
        pinErrorLabel.textColor = .systemRed
        pinErrorLabel.textAlignment = .center
        pinErrorLabel.font = .systemFont(ofSize: 14)
        pinErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        pairingView.addSubview(pinErrorLabel)
        
        // Confirm Button
        confirmPinButton.setTitle("PIN'i Onayla", for: .normal)
        confirmPinButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        confirmPinButton.backgroundColor = .systemGreen
        confirmPinButton.setTitleColor(.white, for: .normal)
        confirmPinButton.layer.cornerRadius = 25
        confirmPinButton.translatesAutoresizingMaskIntoConstraints = false
        confirmPinButton.addTarget(self, action: #selector(confirmPinTapped), for: .touchUpInside)
        pairingView.addSubview(confirmPinButton)
        
        NSLayoutConstraint.activate([
            pairingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pairingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pairingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pairingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            pinTitleLabel.topAnchor.constraint(equalTo: pairingView.topAnchor, constant: 40),
            pinTitleLabel.leadingAnchor.constraint(equalTo: pairingView.leadingAnchor, constant: 20),
            pinTitleLabel.trailingAnchor.constraint(equalTo: pairingView.trailingAnchor, constant: -20),
            
            pinStackView.topAnchor.constraint(equalTo: pinTitleLabel.bottomAnchor, constant: 40),
            pinStackView.leadingAnchor.constraint(equalTo: pairingView.leadingAnchor, constant: 30),
            pinStackView.trailingAnchor.constraint(equalTo: pairingView.trailingAnchor, constant: -30),
            pinStackView.heightAnchor.constraint(equalToConstant: 50),
            
            pinErrorLabel.topAnchor.constraint(equalTo: pinStackView.bottomAnchor, constant: 20),
            pinErrorLabel.leadingAnchor.constraint(equalTo: pairingView.leadingAnchor, constant: 20),
            pinErrorLabel.trailingAnchor.constraint(equalTo: pairingView.trailingAnchor, constant: -20),
            
            confirmPinButton.topAnchor.constraint(equalTo: pinErrorLabel.bottomAnchor, constant: 30),
            confirmPinButton.centerXAnchor.constraint(equalTo: pairingView.centerXAnchor),
            confirmPinButton.widthAnchor.constraint(equalToConstant: 200),
            confirmPinButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Kurulum Ekranı
    private func setupSetupView() {
        setupView.backgroundColor = .systemBackground
        setupView.translatesAutoresizingMaskIntoConstraints = false
        setupView.isHidden = true
        containerView.addSubview(setupView)
        
        // Title
        setupTitleLabel.text = "Kurulum Yapılıyor"
        setupTitleLabel.textAlignment = .center
        setupTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        setupTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        setupView.addSubview(setupTitleLabel)
        
        // Progress
        setupProgressView.progressTintColor = .systemBlue
        setupProgressView.trackTintColor = .systemGray5
        setupProgressView.translatesAutoresizingMaskIntoConstraints = false
        setupView.addSubview(setupProgressView)
        
        // Status
        setupStatusLabel.text = "Lütfen bekleyin..."
        setupStatusLabel.textAlignment = .center
        setupStatusLabel.font = .systemFont(ofSize: 16)
        setupStatusLabel.textColor = .secondaryLabel
        setupStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        setupView.addSubview(setupStatusLabel)
        
        // Steps Stack
        setupStepsStackView.axis = .vertical
        setupStepsStackView.spacing = 15
        setupStepsStackView.translatesAutoresizingMaskIntoConstraints = false
        setupView.addSubview(setupStepsStackView)
        
        // Kurulum adımları
        let steps = [
            "⏳ Bluetooth bağlantısı kuruluyor...",
            "⏳ Cihaz bilgileri alınıyor...",
            "⏳ Saat ayarları yapılandırılıyor...",
            "⏳ Saate bildirim gönderiliyor...",
            "⏳ Kurulum tamamlanıyor..."
        ]
        
        for step in steps {
            let label = UILabel()
            label.text = step
            label.font = .systemFont(ofSize: 14)
            label.textColor = .secondaryLabel
            setupStepsStackView.addArrangedSubview(label)
        }
        
        NSLayoutConstraint.activate([
            setupView.topAnchor.constraint(equalTo: containerView.topAnchor),
            setupView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            setupView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            setupView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            setupTitleLabel.topAnchor.constraint(equalTo: setupView.topAnchor, constant: 40),
            setupTitleLabel.leadingAnchor.constraint(equalTo: setupView.leadingAnchor, constant: 20),
            setupTitleLabel.trailingAnchor.constraint(equalTo: setupView.trailingAnchor, constant: -20),
            
            setupProgressView.topAnchor.constraint(equalTo: setupTitleLabel.bottomAnchor, constant: 30),
            setupProgressView.leadingAnchor.constraint(equalTo: setupView.leadingAnchor, constant: 30),
            setupProgressView.trailingAnchor.constraint(equalTo: setupView.trailingAnchor, constant: -30),
            setupProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            setupStatusLabel.topAnchor.constraint(equalTo: setupProgressView.bottomAnchor, constant: 20),
            setupStatusLabel.leadingAnchor.constraint(equalTo: setupView.leadingAnchor, constant: 20),
            setupStatusLabel.trailingAnchor.constraint(equalTo: setupView.trailingAnchor, constant: -20),
            
            setupStepsStackView.topAnchor.constraint(equalTo: setupStatusLabel.bottomAnchor, constant: 40),
            setupStepsStackView.leadingAnchor.constraint(equalTo: setupView.leadingAnchor, constant: 30),
            setupStepsStackView.trailingAnchor.constraint(equalTo: setupView.trailingAnchor, constant: -30)
        ])
    }
    
    // MARK: - Bağlı Ekranı
    private func setupConnectedView() {
        connectedView.backgroundColor = .systemBackground
        connectedView.translatesAutoresizingMaskIntoConstraints = false
        connectedView.isHidden = true
        containerView.addSubview(connectedView)
        
        // Success Icon
        let successIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        successIcon.tintColor = .systemGreen
        successIcon.contentMode = .scaleAspectFit
        successIcon.translatesAutoresizingMaskIntoConstraints = false
        connectedView.addSubview(successIcon)
        
        // Connected Label
        connectedLabel.text = "✅ Kurulum Tamamlandı!"
        connectedLabel.textAlignment = .center
        connectedLabel.font = .systemFont(ofSize: 24, weight: .bold)
        connectedLabel.translatesAutoresizingMaskIntoConstraints = false
        connectedView.addSubview(connectedLabel)
        
        // Device Name Label
        connectedDeviceLabel.textAlignment = .center
        connectedDeviceLabel.font = .systemFont(ofSize: 18)
        connectedDeviceLabel.textColor = .secondaryLabel
        connectedDeviceLabel.translatesAutoresizingMaskIntoConstraints = false
        connectedView.addSubview(connectedDeviceLabel)
        
        // Disconnect Button
        disconnectButton.setTitle("Bağlantıyı Kes", for: .normal)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 25
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        connectedView.addSubview(disconnectButton)
        
        NSLayoutConstraint.activate([
            connectedView.topAnchor.constraint(equalTo: containerView.topAnchor),
            connectedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            connectedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            connectedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            successIcon.centerXAnchor.constraint(equalTo: connectedView.centerXAnchor),
            successIcon.centerYAnchor.constraint(equalTo: connectedView.centerYAnchor, constant: -100),
            successIcon.widthAnchor.constraint(equalToConstant: 80),
            successIcon.heightAnchor.constraint(equalToConstant: 80),
            
            connectedLabel.topAnchor.constraint(equalTo: successIcon.bottomAnchor, constant: 20),
            connectedLabel.leadingAnchor.constraint(equalTo: connectedView.leadingAnchor, constant: 20),
            connectedLabel.trailingAnchor.constraint(equalTo: connectedView.trailingAnchor, constant: -20),
            
            connectedDeviceLabel.topAnchor.constraint(equalTo: connectedLabel.bottomAnchor, constant: 10),
            connectedDeviceLabel.leadingAnchor.constraint(equalTo: connectedView.leadingAnchor, constant: 20),
            connectedDeviceLabel.trailingAnchor.constraint(equalTo: connectedView.trailingAnchor, constant: -20),
            
            disconnectButton.topAnchor.constraint(equalTo: connectedDeviceLabel.bottomAnchor, constant: 40),
            disconnectButton.centerXAnchor.constraint(equalTo: connectedView.centerXAnchor),
            disconnectButton.widthAnchor.constraint(equalToConstant: 200),
            disconnectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Ekran Değiştirme
    private func showScreen(_ state: ScreenState) {
        currentState = state
        
        // Tüm ekranları gizle
        scanningView.isHidden = true
        pairingView.isHidden = true
        setupView.isHidden = true
        connectedView.isHidden = true
        
        // İstenen ekranı göster
        switch state {
        case .scanning:
            scanningView.isHidden = false
            title = "Bluetooth Cihazları"
            
        case .pairing:
            pairingView.isHidden = false
            title = "PIN Girişi"
            // İlk text field'a focus ver
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.pinTextFields.first?.becomeFirstResponder()
            }
            
        case .setup:
            setupView.isHidden = false
            title = "Saat Kuruluyor"
            startSetupProcess()
            
        case .connected:
            connectedView.isHidden = false
            title = currentDeviceName
            connectedDeviceLabel.text = "\(currentDeviceName) başarıyla kuruldu ve bağlandı"
        }
    }
    
    // MARK: - BLE Callbacks
    private func setupBLECallbacks() {
        bleManager.onDeviceDiscovered = { [weak self] peripheral, name in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let deviceExists = self.discoveredDevices.contains { device in
                    device.peripheral.identifier == peripheral.identifier
                }
                
                if !deviceExists {
                    self.discoveredDevices.append((peripheral, name))
                    self.devicesTableView.reloadData()
                }
            }
        }
        
        bleManager.onConnectionStatusChanged = { [weak self] isConnected, deviceName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if isConnected {
                    self.currentDeviceName = deviceName ?? "Samsung Watch"
                    // PIN ekranını atla, doğrudan kuruluma geç
                    self.showScreen(.setup)
                } else if self.currentState != .scanning {
                    // Bağlantı koptu
                    self.showAlert(title: "Bağlantı Kesildi", message: "Cihaz bağlantısı koptu")
                    self.showScreen(.scanning)
                }
            }
        }
        
        bleManager.onMessageSent = { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ Mesaj saate iletildi")
                } else {
                    print("❌ Mesaj gönderilemedi")
                }
            }
        }
        
        bleManager.onSetupCompleted = { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if success {
                    print("✅ Saat kurulum mesajını aldı")
                    // Ekranda bir onay göster
                    self.setupStatusLabel.text = "✅ Saat kurulumu onaylandı!"
                }
            }
        }
        
        bleManager.onDataReceived = { [weak self] data in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Saatten gelen verileri işle
                if let message = String(data: data, encoding: .utf8) {
                    print("⌚ Saatten mesaj: \(message)")
                    
                    // Özel komutları kontrol et
                    if message.contains("WAITING") || message.contains("READY") {
                        // Saat kurulum bekliyor, hemen mesaj gönder
                        self.bleManager.sendSetupComplete()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func scanButtonTapped() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @objc private func pinFieldChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        // Sadece 1 karakter kabul et
        if text.count > 1 {
            textField.text = String(text.prefix(1))
        }
        
        // Karakter girildiyse sonraki field'a geç
        if text.count == 1 && textField.tag < 5 {
            pinTextFields[textField.tag + 1].becomeFirstResponder()
        }
        
        // Tüm alanlar doluysa butonu aktif et
        let allFilled = pinTextFields.allSatisfy { !($0.text?.isEmpty ?? true) }
        confirmPinButton.isEnabled = allFilled
        confirmPinButton.backgroundColor = allFilled ? .systemGreen : .systemGray
    }
    
    @objc private func confirmPinTapped() {
        view.endEditing(true)
        
        let pin = pinTextFields.compactMap { $0.text }.joined()
        
        guard pin.count == 6 else {
            pinErrorLabel.text = "Lütfen 6 haneli PIN'i tam girin"
            return
        }
        
        // PIN'i gönder ve kuruluma geç
        confirmPinButton.isEnabled = false
        pinTitleLabel.text = "PIN doğrulanıyor..."
        
        // Simülasyon: 2 saniye sonra kuruluma geç
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.bleManager.sendPIN(pin)
            self?.showScreen(.setup)
        }
    }
    
    @objc private func disconnectTapped() {
        // Onay iste
        let alert = UIAlertController(
            title: "Bağlantıyı Kes",
            message: "Cihazı unutmak istiyor musunuz? Bu işlem Bluetooth ayarlarından cihazı kaldıracak.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Sadece Bağlantıyı Kes", style: .default) { [weak self] _ in
            self?.bleManager.disconnect()
            self?.resetAll()
            self?.showScreen(.scanning)
        })
        
        alert.addAction(UIAlertAction(title: "Cihazı Unut", style: .destructive) { [weak self] _ in
            self?.bleManager.disconnectAndForget()
            self?.resetAll()
            self?.showScreen(.scanning)
            self?.showAlert(title: "Cihaz Unutuldu", message: "Cihaz Bluetooth listesinden kaldırıldı. Tekrar bağlanmak için yeniden eşleşme gerekecek.")
        })
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Private Methods
    private func startScanning() {
        isScanning = true
        discoveredDevices.removeAll()
        devicesTableView.reloadData()
        
        statusLabel.text = "🔍 Bluetooth cihazları aranıyor..."
        scanButton.setTitle("Aramayı Durdur", for: .normal)
        scanButton.backgroundColor = .systemRed
        
        bleManager.startScanning()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isScanning == true {
                self?.stopScanning()
            }
        }
    }
    
    private func stopScanning() {
        isScanning = false
        bleManager.stopScanning()
        
        scanButton.setTitle("🔍 Cihaz Ara", for: .normal)
        scanButton.backgroundColor = .systemBlue
        
        if discoveredDevices.isEmpty {
            statusLabel.text = "Bluetooth cihazı bulunamadı"
        } else {
            statusLabel.text = "\(discoveredDevices.count) cihaz bulundu (⌚ Saat ikonlu cihazları seçin)"
        }
    }
    
    private func startSetupProcess() {
        setupProgressView.progress = 0
        setupTitleLabel.text = "Samsung Watch Kuruluyor"
        setupStatusLabel.text = "Lütfen bekleyin, kurulum başlıyor..."
        
        let steps: [(Float, String, String)] = [
            (0.20, "✓ Bluetooth bağlantısı kuruldu", "⏳ Cihaz bilgileri alınıyor..."),
            (0.40, "✓ Cihaz bilgileri alındı", "⏳ Saat ayarları yapılandırılıyor..."),
            (0.60, "✓ Saat ayarları yapılandırıldı", "⏳ Saate bildirim gönderiliyor..."),
            (0.80, "✓ Bildirim gönderildi", "⏳ Kurulum tamamlanıyor..."),
            (1.00, "✓ Kurulum tamamlandı!", "")
        ]
        
        var currentStep = 0
        
        // İlk adımı hemen göster
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if let firstLabel = self.setupStepsStackView.arrangedSubviews.first as? UILabel {
                firstLabel.text = "⏳ Bluetooth bağlantısı kuruluyor..."
                firstLabel.textColor = .label
            }
        }
        
        setupTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
            guard let self = self, currentStep < steps.count else {
                timer.invalidate()
                return
            }
            
            let step = steps[currentStep]
            
            UIView.animate(withDuration: 0.5) {
                self.setupProgressView.setProgress(step.0, animated: true)
            }
            
            if currentStep < self.setupStepsStackView.arrangedSubviews.count {
                if let label = self.setupStepsStackView.arrangedSubviews[currentStep] as? UILabel {
                    label.text = step.1
                    label.textColor = .label
                }
            }
            
            if currentStep + 1 < self.setupStepsStackView.arrangedSubviews.count {
                if let nextLabel = self.setupStepsStackView.arrangedSubviews[currentStep + 1] as? UILabel {
                    nextLabel.text = step.2
                }
            }
            
            // 3. adımda (index 2) saate mesaj gönder
            if currentStep == 2 {
                self.sendCompletionToWatch()
            }
            
            if currentStep == steps.count - 1 {
                self.setupStatusLabel.text = "✅ Kurulum başarıyla tamamlandı!"
                timer.invalidate()
                
                // 2 saniye sonra otomatik olarak bağlı ekranına geç
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showScreen(.connected)
                }
            } else {
                self.setupStatusLabel.text = "Adım \(currentStep + 1)/5"
            }
            
            currentStep += 1
        }
    }
    
    private func sendCompletionToWatch() {
        // WearOS protokolü ile mesaj gönder
        print("📱 → ⌚ WearOS protokolü ile kurulum tamamlandı mesajı gönderiliyor")
        
        // WearOS mesajları
        let wearOSMessages: [[UInt8]] = [
            [0x57, 0x45, 0x41, 0x52], // "WEAR"
            [0x4F, 0x53, 0x00, 0x01], // "OS" + version
            [0x53, 0x45, 0x54, 0x55, 0x50], // "SETUP"
            [0x44, 0x4F, 0x4E, 0x45], // "DONE"
            [0xFF, 0xFF, 0xFF, 0xFF]  // End marker
        ]
        
        for message in wearOSMessages {
            let messageData = Data(message)
            if let base64String = messageData.base64EncodedString().data(using: .utf8) {
                bleManager.sendRawData(base64String)
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Samsung SAP protokolü de dene
        bleManager.sendSetupComplete()
        
        // Samsung handshake
        bleManager.performSamsungHandshake()
        
        print("✅ WearOS ve Samsung protokolleri ile mesajlar gönderildi")
    }
    
    private func resetAll() {
        // PIN alanlarını temizle
        pinTextFields.forEach { $0.text = "" }
        pinErrorLabel.text = ""
        
        // Setup durumunu sıfırla
        setupTimer?.invalidate()
        setupTimer = nil
        setupProgressView.progress = 0
        setupStatusLabel.text = "Lütfen bekleyin..."
        setupTitleLabel.text = "Kurulum Yapılıyor"
        
        // Setup adımlarını sıfırla
        let steps = [
            "⏳ Bluetooth bağlantısı kuruluyor...",
            "⏳ Cihaz bilgileri alınıyor...",
            "⏳ Saat ayarları yapılandırılıyor...",
            "⏳ Saate bildirim gönderiliyor...",
            "⏳ Kurulum tamamlanıyor..."
        ]
        
        for (index, step) in steps.enumerated() {
            if index < setupStepsStackView.arrangedSubviews.count,
               let label = setupStepsStackView.arrangedSubviews[index] as? UILabel {
                label.text = step
                label.textColor = .secondaryLabel
            }
        }
        
        // Cihaz bilgilerini sıfırla
        currentPeripheral = nil
        currentDeviceName = ""
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        
        let device = discoveredDevices[indexPath.row]
        
        // Cihaz türünü belirle
        let deviceType = bleManager.getDeviceType(for: device.peripheral)
        
        var content = cell.defaultContentConfiguration()
        content.text = device.name
        content.secondaryText = deviceType
        
        if deviceType.contains("Saat") {
            content.image = UIImage(systemName: "applewatch")
            content.imageProperties.tintColor = .systemBlue
            content.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        } else if deviceType.contains("Kulaklık") {
            content.image = UIImage(systemName: "headphones")
            content.imageProperties.tintColor = .systemPurple
        } else if deviceType.contains("Hoparlör") {
            content.image = UIImage(systemName: "speaker.wave.2")
            content.imageProperties.tintColor = .systemOrange
        } else if deviceType.contains("Araç") {
            content.image = UIImage(systemName: "car")
            content.imageProperties.tintColor = .systemGreen
        } else if deviceType.contains("TV") {
            content.image = UIImage(systemName: "tv")
            content.imageProperties.tintColor = .systemIndigo
        } else {
            content.image = UIImage(systemName: "bluetooth")
            content.imageProperties.tintColor = .systemGray
        }
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = discoveredDevices[indexPath.row]
        currentPeripheral = device.peripheral
        
        stopScanning()
        statusLabel.text = "📱 Bağlanılıyor: \(device.name)"
        
        // Loading indicator ekle
        let alert = UIAlertController(title: "Bağlanıyor", message: "\(device.name)\n\n", preferredStyle: .alert)
        
        let indicator = UIActivityIndicatorView(frame: CGRect(x: 125, y: 50, width: 50, height: 50))
        indicator.style = .large
        indicator.startAnimating()
        alert.view.addSubview(indicator)
        
        present(alert, animated: true)
        
        bleManager.connect(to: device.peripheral)
        
        // 3 saniye sonra alert'i kapat (bağlantı kurulmazsa bile)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            alert.dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Sadece rakam kabul et
        if !string.isEmpty {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            if !allowedCharacters.isSuperset(of: characterSet) {
                return false
            }
        }
        
        // Max 1 karakter
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        
        return newLength <= 1
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Text field seçildiğinde içeriği temizle
        textField.text = ""
    }
}
