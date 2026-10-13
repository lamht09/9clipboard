import ClipCore
import SwiftUI

/// Cửa sổ Settings 4 tab (DESIGN §6.4) + tab Giới thiệu.
struct SettingsView: View {
    var model: SettingsModel

    var body: some View {
        TabView {
            GeneralTab(model: model)
                .tabItem { Label("Chung", systemImage: "gearshape") }
            PrivacyTab(model: model)
                .tabItem { Label("Riêng tư", systemImage: "hand.raised") }
            PinboardTab(model: model)
                .tabItem { Label("Pinboard", systemImage: "pin") }
            PermissionTab(model: model)
                .tabItem { Label("Quyền", systemImage: "lock.shield") }
            AboutTab()
                .tabItem { Label("Giới thiệu", systemImage: "info.circle") }
        }
        .frame(width: 540, height: 480)
    }
}

private struct Caption: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Chung

private struct GeneralTab: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Phím tắt mở panel") {
                    HStack {
                        ShortcutRecorder(model: model).fixedSize()
                        if model.shortcut != .default {
                            Button("Mặc định") { model.resetShortcut() }
                        }
                    }
                }
                if let message = model.shortcutMessage { Caption(message) }

                Toggle("Chạy khi đăng nhập", isOn: $model.launchAtLogin)
                if model.loginStatus == .requiresApproval {
                    HStack {
                        Caption("Cần cho phép 9clipboard trong System Settings › Mục đăng nhập.")
                        Button("Mở") { model.openLoginItemsSettings() }
                    }
                }
                if let error = model.loginError { Caption(error) }

                Toggle(isOn: $model.autoPaste) {
                    Text("Tự dán vào app đang dùng")
                    Text("Tắt thì chỉ copy, bạn tự bấm ⌘V.")
                }
            }

            Section("Lịch sử") {
                Picker(selection: $model.historyLimit) {
                    ForEach(SettingsModel.historyLimits, id: \.self) { Text("\($0) mục").tag($0) }
                } label: {
                    Text("Giới hạn lịch sử")
                    Text("Không tính mục đã ghim. Giảm giới hạn thì mục cũ nhất bị xoá ở lần copy tiếp theo.")
                }
                Picker("Ảnh lớn nhất", selection: $model.maxImageMB) {
                    ForEach(SettingsModel.imageLimits, id: \.self) { Text("\($0) MB").tag($0) }
                }
            }

            Section("Dữ liệu") {
                LabeledContent("Thư mục") {
                    HStack {
                        Text((model.dataDirectory.path as NSString).abbreviatingWithTildeInPath)
                            .lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                        Button("Hiện trong Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([model.dataDirectory])
                        }
                    }
                }
                LabeledContent("Dung lượng đang dùng") {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(model.diskUsage), countStyle: .file))
                }
                HStack {
                    Spacer()
                    Button("Xoá lịch sử…", role: .destructive) { model.clearHistory() }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Riêng tư

private struct PrivacyTab: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $model.detectPasswords) {
                    Text("Nhận diện mật khẩu và tự xoá")
                    Text("Mật khẩu copy từ 1Password, Passwords… vẫn hiện (🔒) nhưng tự xoá nếu không bấm “Giữ lại” hoặc ghim.")
                }
                Picker("Tự xoá mật khẩu sau", selection: $model.passwordLifetimeMinutes) {
                    ForEach(SettingsModel.passwordLifetimes, id: \.self) { Text("\($0) phút").tag($0) }
                }
                .disabled(!model.detectPasswords)
            }

            Section {
                if model.excludedApps.isEmpty {
                    Caption("Chưa có app nào.")
                }
                ForEach(model.excludedApps) { app in
                    HStack {
                        AppIcon(image: app.icon)
                        Text(app.name)
                        Spacer()
                        Button { model.removeExcludedApp(app) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                            .help("Bỏ loại trừ")
                    }
                }
                HStack {
                    Spacer()
                    Button("Thêm app…") { model.addExcludedApp() }
                }
            } header: {
                Text("App bị loại trừ")
            } footer: {
                Caption("Copy từ các app này không bao giờ được ghi vào lịch sử.")
            }

            Section("Xoá lịch sử theo app") {
                if model.sourceApps.isEmpty {
                    Caption("Lịch sử đang trống.")
                }
                ForEach(model.sourceApps) { source in
                    HStack {
                        AppIcon(image: SettingsModel.AppInfo(bundleID: source.bundleID).icon)
                        Text(source.name)
                        Spacer()
                        Text("\(source.count) mục").foregroundStyle(.secondary).monospacedDigit()
                        Button("Xoá…") { model.clearHistory(fromApp: source) }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct AppIcon: View {
    var image: NSImage?
    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable()
            } else {
                Image(systemName: "app.dashed").resizable().foregroundStyle(.secondary)
            }
        }
        .frame(width: 18, height: 18)
    }
}

// MARK: - Pinboard

private struct PinboardTab: View {
    @Bindable var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            List {
                ForEach(model.app.pinboards) { board in
                    PinboardRow(model: model, board: board)
                }
                .onMove { model.movePinboards(from: $0, to: $1) }
            }
            .overlay {
                if model.app.pinboards.isEmpty {
                    Caption("Chưa có bảng nào. Bấm 📌 trên thẻ hoặc ⌘P trong panel để ghim.")
                }
            }
            HStack {
                Caption("Kéo để sắp xếp lại. Xoá bảng thì các mục được bỏ ghim, không bị xoá.")
                Spacer()
                Button("Bảng mới") { model.createPinboard() }
            }
        }
        .padding()
    }
}

private struct PinboardRow: View {
    @Bindable var model: SettingsModel
    var board: Pinboard

    private var name: Binding<String> {
        Binding(
            get: { board.id.flatMap { model.nameDrafts[$0] } ?? board.name },
            set: { if let id = board.id { model.nameDrafts[id] = $0 } })
    }

    var body: some View {
        HStack {
            Menu {
                ForEach(ClipboardStore.pinboardPalette, id: \.self) { hex in
                    Button { model.setColor(hex, for: board) } label: {
                        Label(hex == board.color ? "✓" : " ", systemImage: "circle.fill")
                            .foregroundStyle(Color(hex: hex))
                    }
                }
            } label: {
                Circle().fill(Color(hex: board.color)).frame(width: 12, height: 12)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Đổi màu")

            TextField("Tên bảng", text: name)
                .textFieldStyle(.plain)
                .onSubmit { model.commitName(of: board) }

            Button { model.delete(board) } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .help("Xoá bảng")
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Quyền

private struct PermissionTab: View {
    var model: SettingsModel

    var body: some View {
        Form {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: model.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(model.isTrusted ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.isTrusted ? "Đã cấp quyền Trợ năng" : "Chưa cấp quyền Trợ năng")
                            .font(.headline)
                        Caption(
                            model.isTrusted
                                ? "9clipboard tự dán bằng cách gửi ⌘V vào app đang dùng."
                                : "Không có quyền thì 9clipboard chỉ copy, bạn tự bấm ⌘V để dán.")
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button("Mở System Settings") { model.openAccessibilitySettings() }
                }
            } footer: {
                Caption("Quyền này chỉ dùng để gửi phím ⌘V. 9clipboard không cần mạng và không gửi dữ liệu đi đâu.")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Giới thiệu

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("9clipboard").font(.title.bold())
            Text("Phiên bản \(About.version)").foregroundStyle(.secondary).textSelection(.enabled)
            Text("Phát triển bởi \(About.author)").font(.headline).padding(.top, 8)
            Link(About.repositoryLabel, destination: About.repositoryURL)
            Spacer()
            Caption(About.copyright)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
