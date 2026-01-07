//
//  SettingsView.swift
//  MyStory
//
//  设置页面
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.managedObjectContext) private var context
    @StateObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var migrationSession = MigrationSessionManager()
    @State private var showLanguageSettings = false
    @State private var showThemeSettings = false
    @State private var isRunningBackup = false
    @State private var isRunningRestore = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var senderPINInput: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("settings.general".localized) {
                    Button {
                        showLanguageSettings = true
                    } label: {
                        HStack {
                            Label("settings.language".localized, systemImage: "globe")
                            Spacer()
                            Text(localizationManager.currentLanguage.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        showThemeSettings = true
                    } label: {
                        HStack {
                            Label("settings.theme".localized, systemImage: "paintbrush")
                            Spacer()
                            Text(themeManager.currentTheme.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section("数据迁移（测试）") {
                    Button {
                        runBackup()
                    } label: {
                        HStack {
                            Label("创建本地迁移备份", systemImage: "externaldrive.badge.plus")
                            if isRunningBackup {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRunningBackup || isRunningRestore)
                    
                    Button {
                        runRestore()
                    } label: {
                        HStack {
                            Label("从最新备份恢复", systemImage: "arrow.counterclockwise")
                            if isRunningRestore {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .tint(.red)
                    .disabled(isRunningBackup || isRunningRestore)
                }
                
                Section("点对点迁移（测试）") {
                    if let pin = migrationSession.pin {
                        HStack {
                            Text("本机 PIN：")
                            Text(pin)
                                .monospacedDigit()
                                .font(.title3.bold())
                        }
                    }
                    
                    // 显示当前状态
                    HStack {
                        Text("状态：")
                        Text(stateDescription(migrationSession.state))
                            .foregroundColor(.secondary)
                    }
                    
                    // 新手机按钮
                    Button {
                        startP2PReceiver()
                    } label: {
                        Label("作为新手机，等待接收", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .foregroundColor(.primary)
                    .disabled(isRunningBackup || isRunningRestore || migrationSession.state != .idle)
                    
                    // 旧手机：第一步，开始搜索并连接
                    Button {
                        startP2PSenderAndSendBackup()
                    } label: {
                        Label("作为旧手机，开始连接", systemImage: "wifi")
                    }
                    .foregroundColor(.primary)
                    .disabled(isRunningBackup || isRunningRestore || migrationSession.state != .idle)
                    
                    // 旧手机：第二步，连接成功后输入 PIN 验证
                    if migrationSession.state == .pinWaitingInput {
                        TextField("输入新手机的 PIN", text: $senderPINInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        Button {
                            migrationSession.sendPIN(senderPINInput)
                        } label: {
                            Label("发送 PIN 验证并传输", systemImage: "checkmark.seal")
                        }
                        .foregroundColor(.primary)
                        .disabled(senderPINInput.isEmpty)
                    }
                }
                
                Section("settings.about".localized) {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView()
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
            }
            .alert("提示", isPresented: $showAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                if let message = alertMessage {
                    Text(message)
                }
            }
        }
    }
    
    // MARK: - 迁移测试操作
    
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
                    alertMessage = "备份完成：\(url.lastPathComponent)"
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isRunningBackup = false
                    alertMessage = "备份失败：\(error.localizedDescription)"
                    showAlert = true
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
    
    private func runRestore() {
        isRunningRestore = true
        alertMessage = nil
        let password = "test-password" // 测试阶段使用固定密码
        guard let url = latestBackupURL() else {
            isRunningRestore = false
            alertMessage = "未找到任何备份文件"
            showAlert = true
            return
        }
        let service = MigrationRestoreService(context: context)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try service.restoreFromEncryptedBackup(encryptedURL: url, password: password) { _ in }
                DispatchQueue.main.async {
                    isRunningRestore = false
                    alertMessage = "恢复完成，请重启应用以确保状态刷新。"
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isRunningRestore = false
                    alertMessage = "恢复失败：\(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func startP2PReceiver() {
        migrationSession.startAsReceiver()
    }
    
    private func startP2PSenderAndSendBackup() {
        guard let url = latestBackupURL() else {
            alertMessage = "请先创建本地迁移备份"
            showAlert = true
            return
        }
        migrationSession.startAsSender(with: url)
    }
    
    // MARK: - 辅助方法
    
    private func stateDescription(_ state: MigrationSessionManager.State) -> String {
        switch state {
        case .idle:
            return "空闲"
        case .waitingForPeer:
            return "正在搜索设备..."
        case .connected:
            return "已连接"
        case .pinWaitingInput:
            return "等待输入 PIN"
        case .pinVerifying:
            return "验证中..."
        case .readyToTransfer:
            return "准备传输"
        case .transferring(let progress):
            return "传输中 \(Int(progress * 100))%"
        case .completed:
            return "完成"
        case .failed(let msg):
            return "失败：\(msg)"
        }
    }
}