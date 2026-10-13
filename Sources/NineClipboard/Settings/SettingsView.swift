import ClipCore
import SwiftUI

/// Cửa sổ Settings 4 tab + tab Giới thiệu.
struct SettingsView: View {
    var model: SettingsModel

    var body: some View {
        TabView {
            GeneralTab(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }
            PrivacyTab(model: model)
                .tabItem { Label("Privacy", systemImage: "hand.raised") }
            PinboardTab(model: model)
                .tabItem { Label("Pinboard", systemImage: "pin") }
            PermissionTab(model: model)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 540, height: 480)
    }
}

private struct Caption: View {
    var text: Text
    /// Chuỗi viết thẳng trong code được dịch; chuỗi đã có sẵn (lỗi, tên…) thì hiện nguyên văn — giống `Text`.
    init(_ key: LocalizedStringKey) { text = Text(key) }
    @_disfavoredOverload
    init(_ string: some StringProtocol) { text = Text(string) }
    var body: some View {
        text.font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Chung

private struct GeneralTab: View {
    @Bindable var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Picker("Language", selection: $model.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }
                LabeledContent("Open Panel Shortcut") {
                    HStack {
                        ShortcutRecorder(model: model).fixedSize()
                        if model.shortcut != .default {
                            Button("Default") { model.resetShortcut() }
                        }
                    }
                }
                if let message = model.shortcutMessage { Caption(message) }

                Toggle("Launch at Login", isOn: $model.launchAtLogin)
                if model.loginStatus == .requiresApproval {
                    HStack {
                        Caption("Allow 9clipboard in System Settings › Login Items.")
                        Button("Open") { model.openLoginItemsSettings() }
                    }
                }
                if let error = model.loginError { Caption(error) }

                Toggle(isOn: $model.autoPaste) {
                    Text("Paste into the Active App")
                    Text("When off, items are only copied and you press ⌘V yourself.")
                }
            }

            Section("History") {
                Picker(selection: $model.historyLimit) {
                    ForEach(SettingsModel.historyLimits, id: \.self) { Text("\($0) items").tag($0) }
                } label: {
                    Text("History Limit")
                    Text("Pinned items don’t count. Lowering the limit deletes the oldest items on your next copy.")
                }
                Picker("Largest Image", selection: $model.maxImageMB) {
                    ForEach(SettingsModel.imageLimits, id: \.self) { Text("\($0) MB").tag($0) }
                }
            }

            Section("Data") {
                LabeledContent("Folder") {
                    HStack {
                        Text((model.dataDirectory.path as NSString).abbreviatingWithTildeInPath)
                            .lineLimit(1).truncationMode(.middle).textSelection(.enabled)
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([model.dataDirectory])
                        }
                    }
                }
                LabeledContent("Disk Usage") {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(model.diskUsage), countStyle: .file))
                }
                HStack {
                    Spacer()
                    Button("Clear History…", role: .destructive) { model.clearHistory() }
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
                    Text("Detect and Auto-Delete Passwords")
                    Text("Passwords copied from 1Password, Passwords… still appear (🔒) but are deleted unless you click “Keep” or pin them.")
                }
                Picker("Delete Passwords After", selection: $model.passwordLifetimeMinutes) {
                    ForEach(SettingsModel.passwordLifetimes, id: \.self) { Text("\($0) min").tag($0) }
                }
                .disabled(!model.detectPasswords)
            }

            Section {
                if model.excludedApps.isEmpty {
                    Caption("No apps yet.")
                }
                ForEach(model.excludedApps) { app in
                    HStack {
                        AppIcon(image: app.icon)
                        Text(app.name)
                        Spacer()
                        Button { model.removeExcludedApp(app) } label: { Image(systemName: "minus.circle") }
                            .buttonStyle(.borderless)
                            .help("Stop Excluding")
                    }
                }
                HStack {
                    Spacer()
                    Button("Add App…") { model.addExcludedApp() }
                }
            } header: {
                Text("Excluded Apps")
            } footer: {
                Caption("Anything copied from these apps is never saved to history.")
            }

            Section("Clear History by App") {
                if model.sourceApps.isEmpty {
                    Caption("History is empty.")
                }
                ForEach(model.sourceApps) { source in
                    HStack {
                        AppIcon(image: SettingsModel.AppInfo(bundleID: source.bundleID).icon)
                        Text(source.name)
                        Spacer()
                        Text("\(source.count) items").foregroundStyle(.secondary).monospacedDigit()
                        Button("Delete…") { model.clearHistory(fromApp: source) }
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
                    Caption("No boards yet. Click 📌 on a card or press ⌘P in the panel to pin.")
                }
            }
            HStack {
                Caption("Drag to reorder. Deleting a board unpins its items without deleting them.")
                Spacer()
                Button("New Board") { model.createPinboard() }
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
            .help("Change Color")

            TextField("Board Name", text: name)
                .textFieldStyle(.plain)
                .onSubmit { model.commitName(of: board) }

            Button { model.delete(board) } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .help("Delete Board")
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
                        Text(model.isTrusted ? "Accessibility Access Granted" : "Accessibility Access Not Granted")
                            .font(.headline)
                        if model.isTrusted {
                            Caption("9clipboard pastes by sending ⌘V to the active app.")
                        } else {
                            Caption("Without access, 9clipboard only copies and you press ⌘V to paste.")
                        }
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button("Open System Settings") { model.openAccessibilitySettings() }
                }
            } footer: {
                Caption("This access is only used to send ⌘V. 9clipboard needs no network and never sends your data anywhere.")
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
            Text("Version \(About.version)").foregroundStyle(.secondary).textSelection(.enabled)
            Text("Developed by \(About.author)").font(.headline).padding(.top, 8)
            Link(About.repositoryLabel, destination: About.repositoryURL)
            Spacer()
            Caption(About.copyright)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
