import UIKit
import CoreBluetooth

class WearOSViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let wearOSLogoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Device Card
    private let deviceCardView = UIView()
    private let watchImageView = UIImageView()
    private let deviceNameLabel = UILabel()
    private let deviceModelLabel = UILabel()
    private let batteryLabel = UILabel()
    private let connectionStatusView = UIView()
    
    // Setup Progress
    private let setupCardView = UIView()
    private let setupProgressView = UIProgressView()
    private let setupStageLabel = UILabel()
    private let setupDetailLabel = UILabel()
    
    // Action Buttons
    private let scanButton = UIButton(type: .system)
    private let pairButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    
    // Device List
    private let devicesTableView = UITableView()
    private let devicesContainerView = UIView()
    
    // MARK: - Properties
    private let wearOSManager = WearOSBLEManager.shared
    private var discoveredDevices: [(peripheral: CBPeripheral, name: String, isWearOS: Bool)] = []
    private var connectedDevice: CBPeripheral?
    private var isScanning = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 WearOSViewController: viewDidLoad called")
        setupUI()
        setupWearOSCallbacks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 WearOSViewController: viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 WearOSViewController: viewDidAppear")
        
        // Force layout update
        view.layoutIfNeeded()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        print("🎨 Setting up WearOS UI...")
        
        // Set background color first
        view.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0) // Google Gray
        
        // Navigation
        title = "Wear OS"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Add Google-style navigation bar
        let googleBlue = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
        navigationController?.navigationBar.tintColor = googleBlue
        
        print("🎨 Setting up subviews...")
        setupScrollView()
        setupHeader()
        setupDeviceCard()
        setupSetupCard()
        setupActionButtons()
        setupDevicesList()
        
        print("🎨 Setting up constraints...")
        layoutConstraints()
        
        // Initial state
        print("🎨 Setting initial state...")
        showScanningState()
        
        print("✅ WearOS UI setup complete")
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.backgroundColor = .white
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        // WearOS Logo
        wearOSLogoImageView.image = UIImage(systemName: "applewatch.watchface")
        wearOSLogoImageView.tintColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
        wearOSLogoImageView.contentMode = .scaleAspectFit
        wearOSLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(wearOSLogoImageView)
        
        // Title
        titleLabel.text = "Wear OS by Google"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Connect your Samsung Galaxy Watch"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(subtitleLabel)
    }
    
    private func setupDeviceCard() {
        // Card styling
        deviceCardView.backgroundColor = .white
        deviceCardView.layer.cornerRadius = 16
        deviceCardView.layer.shadowColor = UIColor.black.cgColor
        deviceCardView.layer.shadowOpacity = 0.1
        deviceCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        deviceCardView.layer.shadowRadius = 8
        deviceCardView.isHidden = true
        deviceCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deviceCardView)
        
        // Watch image
        watchImageView.image = UIImage(systemName: "applewatch")
        watchImageView.tintColor = .black
        watchImageView.contentMode = .scaleAspectFit
        watchImageView.translatesAutoresizingMaskIntoConstraints = false
        deviceCardView.addSubview(watchImageView)
        
        // Device name
        deviceNameLabel.text = "Galaxy Watch6 Classic"
        deviceNameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceCardView.addSubview(deviceNameLabel)
        
        // Device model
        deviceModelLabel.text = "SM-R960"
        deviceModelLabel.font = .systemFont(ofSize: 14)
        deviceModelLabel.textColor = .systemGray
        deviceModelLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceCardView.addSubview(deviceModelLabel)
        
        // Battery
        batteryLabel.text = "🔋 Battery: --"
        batteryLabel.font = .systemFont(ofSize: 14)
        batteryLabel.textColor = .systemGray
        batteryLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceCardView.addSubview(batteryLabel)
        
        // Connection status
        connectionStatusView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        connectionStatusView.layer.cornerRadius = 4
        connectionStatusView.translatesAutoresizingMaskIntoConstraints = false
        deviceCardView.addSubview(connectionStatusView)
    }
    
    private func setupSetupCard() {
        // Card styling
        setupCardView.backgroundColor = .white
        setupCardView.layer.cornerRadius = 16
        setupCardView.layer.shadowColor = UIColor.black.cgColor
        setupCardView.layer.shadowOpacity = 0.1
        setupCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        setupCardView.layer.shadowRadius = 8
        setupCardView.isHidden = true
        setupCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(setupCardView)
        
        // Progress view
        setupProgressView.progressTintColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
        setupProgressView.trackTintColor = UIColor.systemGray5
        setupProgressView.translatesAutoresizingMaskIntoConstraints = false
        setupCardView.addSubview(setupProgressView)
        
        // Stage label
        setupStageLabel.text = "Connecting to Wear OS..."
        setupStageLabel.font = .systemFont(ofSize: 18, weight: .medium)
        setupStageLabel.translatesAutoresizingMaskIntoConstraints = false
        setupCardView.addSubview(setupStageLabel)
        
        // Detail label
        setupDetailLabel.text = "Please wait while we establish connection"
        setupDetailLabel.font = .systemFont(ofSize: 14)
        setupDetailLabel.textColor = .systemGray
        setupDetailLabel.numberOfLines = 0
        setupDetailLabel.translatesAutoresizingMaskIntoConstraints = false
        setupCardView.addSubview(setupDetailLabel)
    }
    
    private func setupActionButtons() {
        // Scan button - Google style
        scanButton.setTitle("Search for devices", for: .normal)
        scanButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        scanButton.backgroundColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 24
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        contentView.addSubview(scanButton)
        
        // Pair button
        pairButton.setTitle("Pair with Wear OS", for: .normal)
        pairButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        pairButton.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
        pairButton.setTitleColor(.white, for: .normal)
        pairButton.layer.cornerRadius = 24
        pairButton.isHidden = true
        pairButton.translatesAutoresizingMaskIntoConstraints = false
        pairButton.addTarget(self, action: #selector(pairButtonTapped), for: .touchUpInside)
        contentView.addSubview(pairButton)
        
        // Disconnect button
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 24
        disconnectButton.isHidden = true
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)
        contentView.addSubview(disconnectButton)
    }
    
    private func setupDevicesList() {
        // Container
        devicesContainerView.backgroundColor = .white
        devicesContainerView.layer.cornerRadius = 16
        devicesContainerView.layer.shadowColor = UIColor.black.cgColor
        devicesContainerView.layer.shadowOpacity = 0.1
        devicesContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        devicesContainerView.layer.shadowRadius = 8
        devicesContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(devicesContainerView)
        
        // Table view
        devicesTableView.delegate = self
        devicesTableView.dataSource = self
        devicesTableView.backgroundColor = .clear
        devicesTableView.separatorStyle = .none
        devicesTableView.register(WearOSDeviceCell.self, forCellReuseIdentifier: "WearOSDeviceCell")
        devicesTableView.translatesAutoresizingMaskIntoConstraints = false
        devicesContainerView.addSubview(devicesTableView)
    }
    
    private func layoutConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 140),
            
            wearOSLogoImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            wearOSLogoImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            wearOSLogoImageView.widthAnchor.constraint(equalToConstant: 40),
            wearOSLogoImageView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: wearOSLogoImageView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: wearOSLogoImageView.centerYAnchor),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            subtitleLabel.topAnchor.constraint(equalTo: wearOSLogoImageView.bottomAnchor, constant: 16),
            
            // Device Card
            deviceCardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            deviceCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            deviceCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            deviceCardView.heightAnchor.constraint(equalToConstant: 120),
            
            watchImageView.leadingAnchor.constraint(equalTo: deviceCardView.leadingAnchor, constant: 20),
            watchImageView.centerYAnchor.constraint(equalTo: deviceCardView.centerYAnchor),
            watchImageView.widthAnchor.constraint(equalToConstant: 60),
            watchImageView.heightAnchor.constraint(equalToConstant: 60),
            
            deviceNameLabel.leadingAnchor.constraint(equalTo: watchImageView.trailingAnchor, constant: 20),
            deviceNameLabel.topAnchor.constraint(equalTo: deviceCardView.topAnchor, constant: 20),
            
            deviceModelLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            deviceModelLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 4),
            
            batteryLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            batteryLabel.topAnchor.constraint(equalTo: deviceModelLabel.bottomAnchor, constant: 8),
            
            connectionStatusView.trailingAnchor.constraint(equalTo: deviceCardView.trailingAnchor, constant: -20),
            connectionStatusView.centerYAnchor.constraint(equalTo: deviceCardView.centerYAnchor),
            connectionStatusView.widthAnchor.constraint(equalToConstant: 8),
            connectionStatusView.heightAnchor.constraint(equalToConstant: 8),
            
            // Setup Card
            setupCardView.topAnchor.constraint(equalTo: deviceCardView.bottomAnchor, constant: 20),
            setupCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            setupCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            setupCardView.heightAnchor.constraint(equalToConstant: 100),
            
            setupProgressView.topAnchor.constraint(equalTo: setupCardView.topAnchor, constant: 20),
            setupProgressView.leadingAnchor.constraint(equalTo: setupCardView.leadingAnchor, constant: 20),
            setupProgressView.trailingAnchor.constraint(equalTo: setupCardView.trailingAnchor, constant: -20),
            setupProgressView.heightAnchor.constraint(equalToConstant: 4),
            
            setupStageLabel.leadingAnchor.constraint(equalTo: setupCardView.leadingAnchor, constant: 20),
            setupStageLabel.topAnchor.constraint(equalTo: setupProgressView.bottomAnchor, constant: 12),
            
            setupDetailLabel.leadingAnchor.constraint(equalTo: setupCardView.leadingAnchor, constant: 20),
            setupDetailLabel.trailingAnchor.constraint(equalTo: setupCardView.trailingAnchor, constant: -20),
            setupDetailLabel.topAnchor.constraint(equalTo: setupStageLabel.bottomAnchor, constant: 4),
            
            // Buttons
            scanButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            scanButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 200),
            scanButton.heightAnchor.constraint(equalToConstant: 48),
            
            pairButton.topAnchor.constraint(equalTo: setupCardView.bottomAnchor, constant: 20),
            pairButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pairButton.widthAnchor.constraint(equalToConstant: 200),
            pairButton.heightAnchor.constraint(equalToConstant: 48),
            
            disconnectButton.topAnchor.constraint(equalTo: deviceCardView.bottomAnchor, constant: 20),
            disconnectButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            disconnectButton.widthAnchor.constraint(equalToConstant: 200),
            disconnectButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Devices List
            devicesContainerView.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            devicesContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            devicesContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            devicesContainerView.heightAnchor.constraint(equalToConstant: 300),
            devicesContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            devicesTableView.topAnchor.constraint(equalTo: devicesContainerView.topAnchor, constant: 10),
            devicesTableView.leadingAnchor.constraint(equalTo: devicesContainerView.leadingAnchor),
            devicesTableView.trailingAnchor.constraint(equalTo: devicesContainerView.trailingAnchor),
            devicesTableView.bottomAnchor.constraint(equalTo: devicesContainerView.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - Callbacks
    private func setupWearOSCallbacks() {
        wearOSManager.onDeviceDiscovered = { [weak self] peripheral, name, isWearOS in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Check if already in list
                if !self.discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
                    self.discoveredDevices.append((peripheral, name, isWearOS))
                    self.devicesTableView.reloadData()
                }
            }
        }
        
        wearOSManager.onConnectionStatusChanged = { [weak self] isConnected, deviceName in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if isConnected {
                    self.showConnectedState(deviceName: deviceName ?? "Unknown Watch")
                } else {
                    self.showDisconnectedState()
                }
            }
        }
        
        wearOSManager.onSetupStageChanged = { [weak self] stage, progress in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.setupStageLabel.text = stage
                self.setupProgressView.setProgress(progress, animated: true)
                
                if progress >= 1.0 {
                    self.setupDetailLabel.text = "✅ Your watch is ready to use!"
                    
                    // Animate success
                    UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseInOut) {
                        self.setupCardView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
                    }
                }
            }
        }
        
        wearOSManager.onWearOSMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("📱 UI: Received message from watch: \(message)")
                
                // Update UI based on message
                if message.contains("battery") {
                    self.batteryLabel.text = "🔋 Battery: \(message)"
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
    
    @objc private func pairButtonTapped() {
        guard connectedDevice != nil else { return }
        
        showSetupState()
        wearOSManager.startWearOSPairing()
    }
    
    @objc private func disconnectButtonTapped() {
        wearOSManager.disconnect()
        showScanningState()
    }
    
    // MARK: - Private Methods
    private func startScanning() {
        isScanning = true
        discoveredDevices.removeAll()
        devicesTableView.reloadData()
        
        scanButton.setTitle("Searching...", for: .normal)
        scanButton.backgroundColor = .systemGray
        
        // Animate
        UIView.animate(withDuration: 0.3) {
            self.devicesContainerView.alpha = 1.0
        }
        
        wearOSManager.startWearOSScanning()
        
        // Stop after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.stopScanning()
        }
    }
    
    private func stopScanning() {
        isScanning = false
        wearOSManager.stopScanning()
        
        scanButton.setTitle("Search for devices", for: .normal)
        scanButton.backgroundColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
    }
    
    // MARK: - State Management
    private func showScanningState() {
        deviceCardView.isHidden = true
        setupCardView.isHidden = true
        scanButton.isHidden = false
        pairButton.isHidden = true
        disconnectButton.isHidden = true
        devicesContainerView.alpha = 0.5
    }
    
    private func showConnectedState(deviceName: String) {
        deviceCardView.isHidden = false
        setupCardView.isHidden = true
        scanButton.isHidden = true
        pairButton.isHidden = false
        disconnectButton.isHidden = true
        devicesContainerView.alpha = 0.3
        
        deviceNameLabel.text = deviceName
        
        // Detect model
        if deviceName.contains("Galaxy") {
            deviceModelLabel.text = "SM-R960"
        }
    }
    
    private func showSetupState() {
        setupCardView.isHidden = false
        pairButton.isHidden = true
        setupProgressView.progress = 0
        setupDetailLabel.text = "Establishing WearOS connection..."
    }
    
    private func showDisconnectedState() {
        showScanningState()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension WearOSViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WearOSDeviceCell", for: indexPath) as! WearOSDeviceCell
        
        let device = discoveredDevices[indexPath.row]
        cell.configure(name: device.name, isWearOS: device.isWearOS)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = discoveredDevices[indexPath.row]
        connectedDevice = device.peripheral
        
        stopScanning()
        wearOSManager.connectToWearOSDevice(device.peripheral)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - Custom Cell
class WearOSDeviceCell: UITableViewCell {
    
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let typeLabel = UILabel()
    private let wearOSBadge = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .black
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconImageView)
        
        // Name
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Type
        typeLabel.font = .systemFont(ofSize: 14)
        typeLabel.textColor = .systemGray
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(typeLabel)
        
        // WearOS Badge
        wearOSBadge.text = "Wear OS"
        wearOSBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        wearOSBadge.textColor = .white
        wearOSBadge.backgroundColor = UIColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0)
        wearOSBadge.layer.cornerRadius = 4
        wearOSBadge.layer.masksToBounds = true
        wearOSBadge.textAlignment = .center
        wearOSBadge.isHidden = true
        wearOSBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(wearOSBadge)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            typeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            wearOSBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            wearOSBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            wearOSBadge.widthAnchor.constraint(equalToConstant: 60),
            wearOSBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(name: String, isWearOS: Bool) {
        nameLabel.text = name
        
        if isWearOS {
            iconImageView.image = UIImage(systemName: "applewatch")
            typeLabel.text = "Smart Watch"
            wearOSBadge.isHidden = false
        } else {
            iconImageView.image = UIImage(systemName: "bluetooth")
            typeLabel.text = "Bluetooth Device"
            wearOSBadge.isHidden = true
        }
    }
}
