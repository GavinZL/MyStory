import Foundation
import MultipeerConnectivity

/// 管理点对点迁移会话（基于 MultipeerConnectivity）
final class MigrationSessionManager: NSObject, ObservableObject {
    enum Role {
        case sender
        case receiver
    }

    enum State: Equatable {
        case idle
        case waitingForPeer
        case connected
        case pinWaitingInput
        case pinVerifying
        case readyToTransfer
        case transferring(Double)
        case completed
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    /// 新手机生成并展示的 PIN（仅 receiver 使用）
    @Published private(set) var pin: String?
    /// 发生错误时的人类可读错误信息
    @Published private(set) var errorMessage: String?
    
    /// 判断当前角色是否为发送端
    var isCurrentRoleSender: Bool {
        return currentRole == .sender
    }

    private let serviceType = "mystory-mig"
    private let peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var currentRole: Role?
    private var connectedPeer: MCPeerID?
    private var expectedPIN: String?
    private var pendingBackupURL: URL?
    private var progressObservation: NSKeyValueObservation?

    override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - 公共接口

    func reset() {
        stopSession()
        // 立即清空状态，避免竞态条件
        self.state = .idle
        self.pin = nil
        self.errorMessage = nil
        self.expectedPIN = nil
        self.pendingBackupURL = nil
    }

    /// 作为新手机，开始等待接收备份
    func startAsReceiver() {
        reset()
        currentRole = .receiver
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let advertiser = MCNearbyServiceAdvertiser(peer: peerID,
                                                   discoveryInfo: nil,
                                                   serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        let pin = String(format: "%06d", Int.random(in: 0..<1_000_000))
        
        // 确保在主线程同时设置 expectedPIN 和 pin，避免竞态条件
        DispatchQueue.main.async {
            self.expectedPIN = pin
            self.pin = pin
            self.state = .waitingForPeer
        }
    }

    /// 作为旧手机，准备发送指定备份文件
    /// 会自动搜索对端并在 PIN 验证通过后发送备份
    func startAsSender(with backupURL: URL) {
        reset()
        currentRole = .sender
        pendingBackupURL = backupURL

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser

        DispatchQueue.main.async {
            self.state = .waitingForPeer
        }
    }

    /// 旧手机在连接建立后，发送用户输入的 PIN 进行验证
    func sendPIN(_ input: String) {
        guard let session = session,
              let peer = connectedPeer,
              case .sender = currentRole else { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message: [String: Any] = [
            "type": "AuthPIN",
            "payload": ["pin": trimmed]
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            try session.send(data, toPeers: [peer], with: .reliable)
            state = .pinVerifying
        } catch {
            DispatchQueue.main.async {
                self.state = .failed("PIN 发送失败：\(error.localizedDescription)")
                self.errorMessage = "PIN 发送失败：\(error.localizedDescription)"
            }
        }
    }

    // MARK: - 内部工具

    private func stopSession() {
        progressObservation = nil
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        session?.disconnect()
        session = nil
        connectedPeer = nil
    }

    private func sendBackupIfReady() {
        print("📋 sendBackupIfReady called - role: \(String(describing: currentRole)), state: \(state)")
        guard case .sender = currentRole,
              case .readyToTransfer = state,
              let session = session,
              let peer = connectedPeer,
              let url = pendingBackupURL else {
            print("❌ sendBackupIfReady guard failed - role: \(String(describing: currentRole)), state: \(state), session: \(session != nil), peer: \(connectedPeer != nil), url: \(pendingBackupURL != nil)")
            return
        }

        print("✅ Starting backup transfer: \(url.lastPathComponent)")
        state = .transferring(0)
        let progress = session.sendResource(at: url, withName: url.lastPathComponent, toPeer: peer) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Backup send failed: \(error.localizedDescription)")
                    self?.state = .failed("发送失败：\(error.localizedDescription)")
                    self?.errorMessage = "发送失败：\(error.localizedDescription)"
                } else {
                    print("✅ Backup send completed")
                    self?.state = .completed
                }
            }
        }

        progressObservation = progress?.observe(\.fractionCompleted,
                                                options: [.new]) { [weak self] prog, _ in
            DispatchQueue.main.async {
                self?.state = .transferring(prog.fractionCompleted)
            }
        }
    }

    private func handleReceivedControlMessage(_ data: Data, from peer: MCPeerID) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = json as? [String: Any],
              let type = dict["type"] as? String else {
            return
        }

        switch type {
        case "AuthPIN":
            // 新手机（receiver）接收 PIN 验证
            guard case .receiver = currentRole,
                  let payload = dict["payload"] as? [String: Any],
                  let pin = payload["pin"] as? String,
                  let expected = expectedPIN else { return }
            if pin == expected {
                DispatchQueue.main.async {
                    self.state = .readyToTransfer
                }
                // 发送成功回复给旧手机
                sendPINSuccessReply(to: peer)
            } else {
                DispatchQueue.main.async {
                    self.state = .failed("PIN 验证失败")
                    self.errorMessage = "PIN 验证失败"
                    self.stopSession()
                }
            }
        case "AuthPINSuccess":
            // 旧手机（sender）接收验证成功回复
            guard case .sender = currentRole else {
                print("❌ Received AuthPINSuccess but not in sender role")
                return
            }
            print("✅ Received AuthPINSuccess, preparing to send backup")
            DispatchQueue.main.async {
                self.state = .readyToTransfer
            }
            // 确保状态更新后再调用发送
            DispatchQueue.main.async {
                print("📤 Calling sendBackupIfReady()")
                self.sendBackupIfReady()
            }
        default:
            break
        }
    }
    
    private func sendPINSuccessReply(to peer: MCPeerID) {
        guard let session = session else { return }
        let message: [String: Any] = ["type": "AuthPINSuccess"]
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Failed to send PIN success reply: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate

extension MigrationSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                // 只有在之前已经连接过的情况下才视为失败
                if self.connectedPeer != nil {
                    self.state = .failed("连接已断开")
                }
                // 否则忽略，这是初始状态
            case .connecting:
                self.state = .waitingForPeer
            case .connected:
                self.connectedPeer = peerID
                // sender 需要等待输入 PIN，receiver 等待接收 PIN
                switch self.currentRole {
                case .sender?:
                    self.state = .pinWaitingInput
                case .receiver?:
                    self.state = .waitingForPeer
                default:
                    self.state = .connected
                }
            @unknown default:
                self.state = .failed("未知连接状态")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handleReceivedControlMessage(data, from: peerID)
    }

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        DispatchQueue.main.async {
            self.state = .transferring(0)
        }
        progressObservation = progress.observe(\.fractionCompleted,
                                              options: [.new]) { [weak self] prog, _ in
            DispatchQueue.main.async {
                self?.state = .transferring(prog.fractionCompleted)
            }
        }
    }

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
        progressObservation = nil
        DispatchQueue.main.async {
            if let error = error {
                self.state = .failed("接收失败：\(error.localizedDescription)")
                self.errorMessage = "接收失败：\(error.localizedDescription)"
            } else if let localURL = localURL {
                // 将接收到的文件移动到 MigrationBackups 目录
                let fileManager = FileManager.default
                let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let backupsRoot = docs.appendingPathComponent("MigrationBackups", isDirectory: true)
                try? fileManager.createDirectory(at: backupsRoot, withIntermediateDirectories: true)
                let targetURL = backupsRoot.appendingPathComponent(resourceName)
                try? fileManager.removeItem(at: targetURL)
                do {
                    try fileManager.moveItem(at: localURL, to: targetURL)
                    self.state = .completed
                } catch {
                    self.state = .failed("保存备份文件失败：\(error.localizedDescription)")
                    self.errorMessage = "保存备份文件失败：\(error.localizedDescription)"
                }
            } else {
                self.state = .failed("接收失败：未知错误")
                self.errorMessage = "接收失败：未知错误"
            }
        }
    }

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        // 不使用流
    }

    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        // 直接接受
        certificateHandler(true)
    }
}

// MARK: - 广播 & 浏览委托

extension MigrationSessionManager: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    // Receiver 侧：收到邀请时直接接受
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let session = session, case .receiver = currentRole else {
            invitationHandler(false, nil)
            return
        }
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.state = .failed("无法开始广播：\(error.localizedDescription)")
            self.errorMessage = "无法开始广播：\(error.localizedDescription)"
        }
    }

    // Sender 侧：发现对端后直接发起连接
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let session = session, case .sender = currentRole else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // 忽略
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.state = .failed("无法开始搜索设备：\(error.localizedDescription)")
            self.errorMessage = "无法开始搜索设备：\(error.localizedDescription)"
        }
    }
}
