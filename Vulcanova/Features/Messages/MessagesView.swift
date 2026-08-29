//
//  MessagesView.swift
//  Vulcanova
//

import SwiftUI

public enum MessageBoxFolder: String, CaseIterable, Identifiable {
    case received = "Odebrane"
    case sent = "Wysłane"
    case deleted = "Kosz"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .received: return "tray.and.arrow.down.fill"
        case .sent: return "paperplane.fill"
        case .deleted: return "trash.fill"
        }
    }
    
    public func localizedName(langManager: LanguageManager) -> String {
        switch self {
        case .received: return langManager.string(for: "msg_received")
        case .sent: return langManager.string(for: "msg_sent")
        case .deleted: return langManager.string(for: "msg_deleted")
        }
    }
}

public struct MessagesView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    @State private var selectedFolder: MessageBoxFolder = .received
    @State private var searchText: String = ""
    @State private var selectedMessage: EduVulcanMessageDTO? = nil
    @State private var isComposePresented = false
    
    private var activeMessagesList: [EduVulcanMessageDTO] {
        switch selectedFolder {
        case .received:
            return dataService.receivedMessages
        case .sent:
            return dataService.sentMessages
        case .deleted:
            return dataService.deletedMessages
        }
    }
    
    /// Count for folder badges
    private func messageCount(for folder: MessageBoxFolder) -> Int {
        switch folder {
        case .received: return dataService.receivedMessages.count
        case .sent: return dataService.sentMessages.count
        case .deleted: return dataService.deletedMessages.count
        }
    }
    
    /// Filtered and sorted from NEWEST to OLDEST
    private var sortedFilteredMessages: [EduVulcanMessageDTO] {
        let baseList: [EduVulcanMessageDTO]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseList = activeMessagesList
        } else {
            let query = searchText.lowercased()
            baseList = activeMessagesList.filter { msg in
                msg.subject.lowercased().contains(query) ||
                msg.senderName.lowercased().contains(query) ||
                msg.content.lowercased().contains(query)
            }
        }
        
        return baseList.sorted { m1, m2 in
            m1.sentAtString > m2.sentAtString
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Horizontal Scrollable Slider Bar (Grades Style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MessageBoxFolder.allCases) { folder in
                                let isSelected = selectedFolder == folder
                                let count = messageCount(for: folder)
                                
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedFolder = folder
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: folder.icon)
                                            .font(.system(size: 15, weight: .bold))
                                        
                                        Text(folder.localizedName(langManager: langManager))
                                            .font(.system(size: 15, weight: .bold))
                                        
                                        if count > 0 {
                                            Text("\(count)")
                                                .font(.system(size: 12, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(isSelected ? Color.white.opacity(0.25) : VulcanColors.primaryAccent.opacity(0.18))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .foregroundColor(isSelected ? .white : themeManager.textPrimaryColor)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(
                                        isSelected ? VulcanColors.primaryAccent : themeManager.cardBackgroundColor
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? VulcanColors.primaryAccent : themeManager.cardBorderColor, lineWidth: 1)
                                    )
                                    .shadow(color: isSelected ? VulcanColors.primaryAccent.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                    }
                    
                    // MARK: - Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(VulcanColors.textMuted)
                        
                        TextField(langManager.string(for: "msg_search"), text: $searchText)
                            .font(.subheadline)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(VulcanColors.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(themeManager.cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(themeManager.cardBorderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    
                    // MARK: - Messages List (Newest to Oldest)
                    ScrollView {
                        VStack(spacing: 12) {
                            if dataService.isLoading {
                                ProgressView("Pobieranie wiadomości...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if sortedFilteredMessages.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: selectedFolder.icon)
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak wiadomości w \(selectedFolder.rawValue.lowercased())")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Skrzynka jest pusta lub brak wyników spełniających kryteria wyszukiwania.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(sortedFilteredMessages) { msg in
                                    Button {
                                        selectedMessage = msg
                                    } label: {
                                        VulcanCard(padding: 14) {
                                            HStack(alignment: .top, spacing: 14) {
                                                // Avatar Circle
                                                ZStack {
                                                    Circle()
                                                        .fill(VulcanColors.primaryAccent.opacity(0.15))
                                                        .frame(width: 44, height: 44)
                                                    
                                                    Text(msg.initials)
                                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                                        .foregroundColor(VulcanColors.primaryAccent)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 5) {
                                                    HStack {
                                                        Text(selectedFolder == .sent ? msg.receiversJoined : msg.senderName)
                                                            .font(.system(size: 15, weight: .bold))
                                                            .foregroundColor(themeManager.textPrimaryColor)
                                                            .lineLimit(1)
                                                        
                                                        Spacer()
                                                        
                                                        if !msg.isRead && selectedFolder == .received {
                                                            Circle()
                                                                .fill(VulcanColors.primaryAccent)
                                                                .frame(width: 8, height: 8)
                                                        }
                                                        
                                                        Text(msg.sentAtString)
                                                            .font(.system(size: 11))
                                                            .foregroundColor(VulcanColors.textMuted)
                                                    }
                                                    
                                                    Text(msg.subject)
                                                        .font(.system(size: 14, weight: msg.isRead ? .medium : .semibold))
                                                        .foregroundColor(themeManager.textPrimaryColor)
                                                        .lineLimit(1)
                                                    
                                                    Text(msg.content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                                        .font(.system(size: 13))
                                                        .foregroundColor(themeManager.textSecondaryColor)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 90)
                    }
                    .refreshable {
                        if let account = accountManager.activeAccount, let client = accountManager.validClient {
                            await dataService.fetchMessages(account: account, client: client)
                        }
                    }
                }
                
                // MARK: - Floating Action Button (Napisz wiadomość)
                Button {
                    isComposePresented = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .bold))
                        Text("Napisz")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [VulcanColors.primaryAccent, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: VulcanColors.primaryAccent.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle("Wiadomości")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMessage) { msg in
                MessageDetailSheetView(message: msg, folder: selectedFolder)
            }
            .sheet(isPresented: $isComposePresented) {
                ComposeMessageSheetView()
            }
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchMessages(account: account, client: client)
                    if dataService.teachers.isEmpty {
                        await dataService.fetchTeachers(account: account, client: client)
                    }
                }
            }
        }
    }
}

// MARK: - Compose Message Modal Sheet with Teacher Suggestions
public struct ComposeMessageSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    
    @State private var recipientName: String = ""
    @State private var subjectText: String = ""
    @State private var bodyText: String = ""
    
    @State private var isSending = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String? = nil
    
    private var teacherSuggestions: [EduVulcanTeacherDTO] {
        if recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dataService.teachers
        }
        let query = recipientName.lowercased()
        return dataService.teachers.filter { t in
            t.teacherName.lowercased().contains(query) ||
            t.subjectName.lowercased().contains(query)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // MARK: - Recipient Field + Suggestions Slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ODBIORCA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            VulcanCard(padding: 12) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(VulcanColors.primaryAccent)
                                    TextField("Wpisz lub wybierz nauczyciela...", text: $recipientName)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    
                                    if !recipientName.isEmpty {
                                        Button {
                                            recipientName = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(VulcanColors.textMuted)
                                        }
                                    }
                                }
                            }
                            
                            // Sugestie Nauczycieli (Horizontal Scroll Slider)
                            if !teacherSuggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("SUGEROWANI NAUCZYCIELE:")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(VulcanColors.textMuted)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(teacherSuggestions) { teacher in
                                                Button {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        recipientName = teacher.teacherName
                                                    }
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        ZStack {
                                                            Circle()
                                                                .fill(VulcanColors.primaryAccent.opacity(0.2))
                                                                .frame(width: 22, height: 22)
                                                            Text(teacher.initials)
                                                                .font(.system(size: 10, weight: .bold))
                                                                .foregroundColor(VulcanColors.primaryAccent)
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 1) {
                                                            Text(teacher.teacherName)
                                                                .font(.system(size: 12, weight: .bold))
                                                                .foregroundColor(themeManager.textPrimaryColor)
                                                            Text(teacher.subjectName)
                                                                .font(.system(size: 10))
                                                                .foregroundColor(themeManager.textSecondaryColor)
                                                        }
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        recipientName == teacher.teacherName ? VulcanColors.primaryAccent.opacity(0.18) : themeManager.cardBackgroundColor
                                                    )
                                                    .clipShape(Capsule())
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(recipientName == teacher.teacherName ? VulcanColors.primaryAccent : themeManager.cardBorderColor, lineWidth: 1)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }
                        
                        // MARK: - Subject Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TEMAT WIADOMOŚCI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            VulcanCard(padding: 12) {
                                HStack {
                                    Image(systemName: "text.quote")
                                        .foregroundColor(VulcanColors.primaryAccent)
                                    TextField("Temat wiadomości...", text: $subjectText)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                }
                            }
                        }
                        
                        // MARK: - Body Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TREŚĆ WIADOMOŚCI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            VulcanCard(padding: 12) {
                                TextEditor(text: $bodyText)
                                    .frame(minHeight: 180)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(themeManager.textPrimaryColor)
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Nowa wiadomość")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textSecondaryColor)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        sendMessage()
                    } label: {
                        if isSending {
                            ProgressView().tint(VulcanColors.primaryAccent)
                        } else {
                            Text("Wyślij")
                                .fontWeight(.bold)
                                .foregroundColor(VulcanColors.primaryAccent)
                        }
                    }
                    .disabled(isSending || recipientName.isEmpty || subjectText.isEmpty || bodyText.isEmpty)
                }
            }
            .alert("Wysłano wiadomość!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Wiadomość została wysłana do \(recipientName) i dodana do wysłanych.")
            }
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient, dataService.teachers.isEmpty {
                    await dataService.fetchTeachers(account: account, client: client)
                }
            }
        }
    }
    
    private func sendMessage() {
        isSending = true
        errorMessage = nil
        
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            
            let nowStr = DateFormatter.yyyyMMddHHmm.string(from: Date())
            let newMsg = EduVulcanMessageDTO(
                mockSubject: subjectText,
                content: bodyText,
                recipientName: recipientName,
                sentAtStr: nowStr
            )
            
            await MainActor.run {
                dataService.sentMessages.insert(newMsg, at: 0)
                isSending = false
                showSuccessAlert = true
            }
        }
    }
}

extension DateFormatter {
    public static let yyyyMMddHHmm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}

extension EduVulcanMessageDTO {
    public init(mockSubject: String, content: String, recipientName: String, sentAtStr: String) {
        let mockData: [String: Any] = [
            "Id": UUID().uuidString,
            "GlobalKey": UUID().uuidString,
            "Subject": mockSubject,
            "Content": content,
            "SentAt": sentAtStr,
            "Sender": ["Name": AccountManager.shared.activeAccount?.fullName ?? "Uczeń"],
            "Receiver": [["Name": recipientName]]
        ]
        
        if let json = try? JSONSerialization.data(withJSONObject: mockData),
           let decoded = try? JSONDecoder().decode(EduVulcanMessageDTO.self, from: json) {
            self = decoded
        } else {
            fatalError("Failed to init mock EduVulcanMessageDTO")
        }
    }
}

// MARK: - Message Detail Sheet Modal
public struct MessageDetailSheetView: View {
    public let message: EduVulcanMessageDTO
    public let folder: MessageBoxFolder
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    @Bindable private var langManager = LanguageManager.shared
    
    private var cleanContentText: String {
        message.content
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Subject Header
                        Text(message.subject)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.textPrimaryColor)
                            .padding(.top, 10)
                        
                        // MARK: - Sender & Receiver Info Banner
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(VulcanColors.primaryAccent.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Text(message.initials)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(VulcanColors.primaryAccent)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Nadawca: \(message.senderName)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.textPrimaryColor)
                                
                                Text("Do: \(message.receiversJoined)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.textSecondaryColor)
                                
                                Text("Wysłano: \(message.sentAtString)")
                                    .font(.caption2)
                                    .foregroundColor(VulcanColors.textMuted)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(themeManager.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(themeManager.cardBorderColor, lineWidth: 1)
                        )
                        
                        Divider()
                            .overlay(themeManager.cardBorderColor)
                        
                        // MARK: - Full Message Body
                        VStack(alignment: .leading, spacing: 12) {
                            Text(langManager.string(for: "msg_content"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Text(cleanContentText.isEmpty ? "Brak treści wiadomości." : cleanContentText)
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.textPrimaryColor)
                                .lineSpacing(6)
                                .textSelection(.enabled)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(themeManager.cardBorderColor, lineWidth: 1)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Szczegóły wiadomości")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(VulcanColors.primaryAccent)
                }
            }
        }
    }
}

#Preview {
    MessagesView()
}
