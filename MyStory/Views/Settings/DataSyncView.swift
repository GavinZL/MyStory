//
//  DataSyncView.swift
//  MyStory
//
//  数据同步页面 - 支持点对点数据迁移
//

import SwiftUI

struct DataSyncView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var migrationSession = MigrationSessionManager()
    @State private var isRunningBackup = false
    @State private var isRunningRestore = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var senderPINInput: String = ""
    @State private var toastMessage: ToastMessage?
    @State private var isResetting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 当前状态显示
                statusSection
                
                // 发送端功能区
                senderSection
                
                // 接收端功能区
                receiverSection
                
                // 操作说明
                instructionsSection
            }
            .padding()
        }
        .navigationTitle("dataSync.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .alert("common.confirm".localized, isPresented: $showAlert) {
            Button("common.confirm".localized, role: .cancel) { }
        } message: {
            if let message = alertMessage {
                Text(message)
            }
        }
        .onChange(of: migrationSession.state) { newValue in
            handleStateChange(newValue)
        }
        .overlay(
            // 重置时的遮罩层
            Group {
                if isResetting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("dataSync.alert.resetting".localized)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 20)
                        )
                    }
                }
            }
        )
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("dataSync.status.title".localized)
                    .font(.headline)
                Text(stateDescription(migrationSession.state))
                    .foregroundColor(.secondary)
            }
            
            // 显示传输进度
            if case .transferring(let progress) = migrationSession.state {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Sender Section
    
    private var senderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("dataSync.sender.title".localized)
                .font(.headline)
            
            VStack(spacing: 12) {
                // 创建备份按钮
                Button {
                    runBackup()
                } label: {
                    HStack {
                        Label("dataSync.sender.createBackup".localized, systemImage: "externaldrive.badge.plus")
                        Spacer()
                        if isRunningBackup {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isRunningBackup || migrationSession.state != .idle)
                
                // 开始连接按钮
                Button {
                    startP2PSenderAndSendBackup()
                } label: {
                    HStack {
                        Label("dataSync.sender.startConnection".localized, systemImage: "Øwifi")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isRunningBackup || migrationSession.state != .idle)
                
                // PIN 输入区域（连接成功后显示）
                if migrationSession.state == .pinWaitingInput {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("dataSync.sender.inputPIN".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("dataSync.sender.inputPIN".localized, text: $senderPINInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                        
                        Button {
                            migrationSession.sendPIN(senderPINInput)
                        } label: {
                            Label("dataSync.sender.sendPIN".localized, systemImage: "checkmark.seal")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(senderPINInput.isEmpty)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Receiver Section
    
    private var receiverSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("dataSync.receiver.title".localized)
                .font(.headline)
            
            VStack(spacing: 12) {
                // 等待接收按钮
                Button {
                    startP2PReceiver()
                } label: {
                    HStack {
                        Label("dataSync.receiver.waitForData".localized, systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .tint(.green)
                .disabled(isRunningBackup || isRunningRestore || migrationSession.state != .idle)
                
                // 显示PIN码（接收模式下）
                if let pin = migrationSession.pin {
                    VStack(spacing: 8) {
                        Text("dataSync.receiver.yourPIN".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(pin)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .tracking(8)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                } else if migrationSession.state == .waitingForPeer && migrationSession.pin == nil {
                    Text("dataSync.receiver.showPINHint".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // 恢复数据按钮（传输完成后显示）
                if migrationSession.state == .completed {
                    Button {
                        runRestore()
                    } label: {
                        HStack {
                            Label("dataSync.receiver.restoreData".localized, systemImage: "arrow.counterclockwise")
                            Spacer()
                            if isRunningRestore {
                                ProgressView()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tint(.orange)
                    .disabled(isRunningRestore)
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("dataSync.instructions.title".localized)
                .font(.headline)
            
            // 接收端说明
            VStack(alignment: .leading, spacing: 8) {
                Text("dataSync.instructions.receiver.title".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("dataSync.instructions.receiver.step1".localized)
                    Text("dataSync.instructions.receiver.step2".localized)
                    Text("dataSync.instructions.receiver.step3".localized)
                    Text("dataSync.instructions.receiver.step4".localized)
                    Text("dataSync.instructions.receiver.step5".localized)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 发送端说明
            VStack(alignment: .leading, spacing: 8) {
                Text("dataSync.instructions.sender.title".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("dataSync.instructions.sender.step1".localized)
                    Text("dataSync.instructions.sender.step2".localized)
                    Text("dataSync.instructions.sender.step3".localized)
                    Text("dataSync.instructions.sender.step4".localized)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 注意事项
            VStack(alignment: .leading, spacing: 8) {
                Text("dataSync.instructions.notes.title".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("dataSync.instructions.notes.note1".localized)
                    Text("dataSync.instructions.notes.note2".localized)
                    Text("dataSync.instructions.notes.note3".localized)
                    Text("dataSync.instructions.notes.note4".localized)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func stateDescription(_ state: MigrationSessionManager.State) -> String {
        switch state {
        case .idle:
            return "dataSync.status.idle".localized
        case .waitingForPeer:
            return "dataSync.status.waitingForPeer".localized
        case .connected:
            return "dataSync.status.connected".localized
        case .pinWaitingInput:
            return "dataSync.status.pinWaitingInput".localized
        case .pinVerifying:
            return "dataSync.status.pinVerifying".localized
        case .readyToTransfer:
            return "dataSync.status.readyToTransfer".localized
        case .transferring(let progress):
            return String(format: "dataSync.status.transferring".localized, Int(progress * 100))
        case .completed:
            return "dataSync.status.completed".localized
        case .failed(let msg):
            return String(format: "dataSync.status.failed".localized, msg)
        }
    }
    
    private func handleStateChange(_ newState: MigrationSessionManager.State) {
        switch newState {
        case .completed:
            // 传输完成
            toastMessage = ToastMessage(
                type: .success,
                message: "dataSync.alert.transferComplete".localized,
                duration: 5.0
            )
            
            // 如果是发送端，传输完成后清理备份文件
            if migrationSession.isCurrentRoleSender {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cleanupMigrationBackups()
                }
            }
        case .failed(let msg):
            // 分析错误类型并显示友好的错误信息
            let errorMessage = parseErrorMessage(msg)
            
            // 使用Toast显示错误，5秒后自动重置
            toastMessage = ToastMessage(
                type: .error,
                message: errorMessage,
                duration: 5.0
            )
            
            // 5秒后自动重置到初始状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                resetToInitialState()
            }
        default:
            break
        }
    }
    
    /// 解析错误信息，返回用户友好的提示
    private func parseErrorMessage(_ errorMsg: String) -> String {
        let lowercased = errorMsg.lowercased()
        
        // 检查是否包含特定关键词
        if lowercased.contains("network") || lowercased.contains("网络") {
            return "dataSync.error.networkIssue".localized
        } else if lowercased.contains("timeout") || lowercased.contains("超时") {
            return "dataSync.error.connectionTimeout".localized
        } else if lowercased.contains("pin") || lowercased.contains("验证") {
            return "dataSync.error.pinVerificationFailed".localized
        } else if lowercased.contains("disconnect") || lowercased.contains("断开") {
            return "dataSync.error.connectionLost".localized
        } else if lowercased.contains("transfer") || lowercased.contains("传输") {
            return "dataSync.error.transferFailed".localized
        } else {
            // 如果无法识别错误类型，返回原始错误信息
            return errorMsg.isEmpty ? "dataSync.error.unknown".localized : errorMsg
        }
    }
    
    /// 重置到初始状态
    private func resetToInitialState() {
        guard !isResetting else { return }
        
        isResetting = true
        
        // 清空所有状态
        senderPINInput = ""
        isRunningBackup = false
        isRunningRestore = false
        alertMessage = nil
        
        // 重置MigrationSession
        migrationSession.reset()
        
        // 延迟一小段时间，让用户看到重置动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isResetting = false
        }
    }
    
    // MARK: - Migration Operations
    
    private func runBackup() {
        isRunningBackup = true
        alertMessage = nil
        let password = "test-password" // 测试阶段使用固定密码
        let service = MigrationBackupService(context: context)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = try service.createEncryptedBackup(password: password) { _ in }
                DispatchQueue.main.async {
                    isRunningBackup = false
                    let message = String(format: "dataSync.alert.backupComplete".localized, url.lastPathComponent)
                    // 使用Toast显示成功消息
                    toastMessage = ToastMessage(
                        type: .success,
                        message: message,
                        duration: 3.0
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    isRunningBackup = false
                    let message = String(format: "dataSync.alert.backupFailed".localized, error.localizedDescription)
                    // 使用Toast显示错误消息
                    toastMessage = ToastMessage(
                        type: .error,
                        message: message,
                        duration: 5.0
                    )
                }
            }
        }
    }
    
    private func latestBackupURL() -> URL? {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupsRoot = docs.appendingPathComponent("MigrationBackups", isDirectory: true)
        guard let files = try? fileManager.contentsOfDirectory(at: backupsRoot,
                                                               includingPropertiesForKeys: [.creationDateKey],
                                                               options: [.skipsHiddenFiles]) else {
            return nil
        }
        let encFiles = files.filter { $0.pathExtension == "enc" }
        guard !encFiles.isEmpty else { return nil }
        let sorted = encFiles.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let rDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return lDate < rDate
        }
        return sorted.last
    }
    
    private func startP2PReceiver() {
        migrationSession.startAsReceiver()
    }
    
    private func startP2PSenderAndSendBackup() {
        guard let url = latestBackupURL() else {
            // 使用Toast显示错误
            toastMessage = ToastMessage(
                type: .warning,
                message: "dataSync.sender.noBackup".localized,
                duration: 3.0
            )
            return
        }
        migrationSession.startAsSender(with: url)
    }
    
    private func runRestore() {
        isRunningRestore = true
        alertMessage = nil
        let password = "test-password" // 测试阶段使用固定密码
        guard let url = latestBackupURL() else {
            isRunningRestore = false
            // 使用Toast显示错误
            toastMessage = ToastMessage(
                type: .error,
                message: "dataSync.alert.noBackupFound".localized,
                duration: 3.0
            )
            return
        }
        let service = MigrationRestoreService(context: context)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try service.restoreFromEncryptedBackup(encryptedURL: url, password: password) { _ in }
                DispatchQueue.main.async {
                    isRunningRestore = false
                    // 使用Toast显示成功消息
                    toastMessage = ToastMessage(
                        type: .success,
                        message: "dataSync.alert.restoreComplete".localized,
                        duration: 5.0
                    )
                    
                    // 恢复成功后清理备份文件
                    cleanupMigrationBackups()
                    
                    // 恢复完成后2秒重置会话
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        resetToInitialState()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isRunningRestore = false
                    let message = String(format: "dataSync.alert.restoreFailed".localized, error.localizedDescription)
                    // 使用Toast显示错误消息
                    toastMessage = ToastMessage(
                        type: .error,
                        message: message,
                        duration: 5.0
                    )
                    // 5秒后自动重置
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        resetToInitialState()
                    }
                }
            }
        }
    }
    
    /// 清理 MigrationBackups 目录下的所有备份文件
    private func cleanupMigrationBackups() {
        DispatchQueue.global(qos: .utility).async {
            let fileManager = FileManager.default
            let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let backupsRoot = docs.appendingPathComponent("MigrationBackups", isDirectory: true)
            
            guard fileManager.fileExists(atPath: backupsRoot.path) else {
                return
            }
            
            do {
                // 删除整个 MigrationBackups 目录及其内容
                try fileManager.removeItem(at: backupsRoot)
                print("✅ 成功清理 MigrationBackups 目录")
            } catch {
                print("⚠️ 清理 MigrationBackups 失败: \(error.localizedDescription)")
            }
        }
    }
}

//#Preview {
//    DataSyncView()
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
