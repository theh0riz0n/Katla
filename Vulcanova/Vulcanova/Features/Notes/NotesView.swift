//
//  NotesView.swift
//  Vulcanova
//

import SwiftUI

public enum NotesFilterMode: String, CaseIterable, Identifiable {
    case all = "Wszystkie"
    case praise = "Pochwały"
    case remarks = "Uwagi"
    
    public var id: String { rawValue }
}

public struct NotesView: View {
    @Bindable private var themeManager = ThemeManager.shared
    @State private var dataService = EduVulcanDataService.shared
    @State private var accountManager = AccountManager.shared
    @State private var filterMode: NotesFilterMode = .all
    @State private var selectedNote: EduVulcanNoteDTO? = nil
    
    private var filteredNotes: [EduVulcanNoteDTO] {
        switch filterMode {
        case .all:
            return dataService.notes
        case .praise:
            return dataService.notes.filter { $0.positive }
        case .remarks:
            return dataService.notes.filter { !$0.positive }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Filter Segmented Control
                    Picker("Filtruj wpisy", selection: $filterMode) {
                        ForEach(NotesFilterMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    
                    ScrollView {
                        VStack(spacing: 14) {
                            if dataService.isLoading {
                                ProgressView("Pobieranie uwag i pochwał...")
                                    .tint(VulcanColors.primaryAccent)
                                    .padding(.top, 40)
                            } else if filteredNotes.isEmpty {
                                VStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.bubble")
                                        .font(.system(size: 44))
                                        .foregroundColor(VulcanColors.textMuted)
                                    Text("Brak wpisów w kategorii \(filterMode.rawValue)")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textPrimaryColor)
                                    Text("Nauczyciele nie wpisali uwag ani pochwał w tym okresie. Przesuń palcem w lewo/prawo, aby zmienić filtr.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.textSecondaryColor)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.top, 50)
                            } else {
                                ForEach(filteredNotes) { note in
                                    Button {
                                        selectedNote = note
                                    } label: {
                                        VulcanCard(padding: 16) {
                                            VStack(alignment: .leading, spacing: 10) {
                                                HStack {
                                                    // Positive / Negative Badge Icon
                                                    Image(systemName: note.positive ? "hand.thumbsup.fill" : "exclamationmark.triangle.fill")
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(note.positive ? .green : .red)
                                                        .frame(width: 32, height: 32)
                                                        .background((note.positive ? Color.green : Color.red).opacity(0.15))
                                                        .clipShape(Circle())
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(note.category?.name ?? (note.positive ? "Pochwała" : "Uwaga"))
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(themeManager.textPrimaryColor)
                                                        
                                                        if let creator = note.creator?.displayName {
                                                            Text("Wpisujący: \(creator)")
                                                                .font(.caption)
                                                                .foregroundColor(themeManager.textSecondaryColor)
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if let pts = note.points, pts != 0 {
                                                        Text(pts > 0 ? "+\(pts) pkt" : "\(pts) pkt")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(pts > 0 ? .green : .red)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background((pts > 0 ? Color.green : Color.red).opacity(0.12))
                                                            .clipShape(Capsule())
                                                    }
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(VulcanColors.textMuted)
                                                }
                                                
                                                Text(note.content)
                                                    .font(.subheadline)
                                                    .foregroundColor(themeManager.textPrimaryColor)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, minHeight: 300)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                                .onEnded { value in
                                    let modes = NotesFilterMode.allCases
                                    guard let currentIndex = modes.firstIndex(of: filterMode) else { return }
                                    
                                    if value.translation.width < -50 {
                                        // Swipe Left -> Next Filter Mode
                                        if currentIndex + 1 < modes.count {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                filterMode = modes[currentIndex + 1]
                                            }
                                        }
                                    } else if value.translation.width > 50 {
                                        // Swipe Right -> Previous Filter Mode
                                        if currentIndex > 0 {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                filterMode = modes[currentIndex - 1]
                                            }
                                        }
                                    }
                                }
                        )
                    }
                    .refreshable {
                        if let account = accountManager.activeAccount, let client = accountManager.validClient {
                            await dataService.fetchNotes(account: account, client: client)
                        }
                    }
                }
            }
            .navigationTitle("Uwagi i Pochwały")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedNote) { note in
                NoteDetailSheetView(note: note)
            }
            .task {
                if let account = accountManager.activeAccount, let client = accountManager.validClient {
                    await dataService.fetchNotes(account: account, client: client)
                }
            }
        }
    }
}

// MARK: - Dedicated Note Detail Modal Sheet
public struct NoteDetailSheetView: View {
    public let note: EduVulcanNoteDTO
    @Environment(\.dismiss) private var dismiss
    @Bindable private var themeManager = ThemeManager.shared
    
    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header Status Badge
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill((note.positive ? Color.green : Color.red).opacity(0.15))
                                    .frame(width: 72, height: 72)
                                Image(systemName: note.positive ? "hand.thumbsup.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(note.positive ? .green : .red)
                            }
                            
                            Text(note.positive ? "POCHWAŁA" : "UWAGA")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(note.positive ? .green : .red)
                                .tracking(1.4)
                            
                            Text(note.category?.name ?? "Wpis zachowania")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.textPrimaryColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        Divider()
                            .overlay(themeManager.cardBorderColor)
                        
                        // MARK: - Full Content Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TREŚĆ WPISU")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            Text(note.content)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.textPrimaryColor)
                                .lineSpacing(4)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.cardBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(themeManager.cardBorderColor, lineWidth: 1)
                        )
                        
                        // MARK: - Meta Details Card (Teacher, Points, Date)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SZCZEGÓŁY WPISU")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(VulcanColors.textMuted)
                                .tracking(1.2)
                            
                            if let creator = note.creator?.displayName {
                                HDetailRow(title: "Nauczyciel wpisujący", value: creator)
                            }
                            
                            if let pts = note.points, pts != 0 {
                                HDetailRow(title: "Wpływ punktowy", value: pts > 0 ? "+\(pts) pkt" : "\(pts) pkt")
                            }
                            
                            if !note.dateValidString.isEmpty {
                                HDetailRow(title: "Data wpisu", value: note.dateValidString)
                            }
                        }
                        .padding(18)
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
            .navigationTitle("Szczegóły wpisu")
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
    NotesView()
}
