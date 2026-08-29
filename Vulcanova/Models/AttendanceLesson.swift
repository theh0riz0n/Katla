//
//  AttendanceLesson.swift
//  Vulcanova
//

import SwiftUI

public struct AttendanceLesson: Identifiable, Hashable {
    public let id: UUID
    public let lessonNumber: Int
    public let subjectName: String
    public let teacherName: String
    public let topic: String
    public let timeStart: String
    public let timeEnd: String
    public let dateString: String
    public let presenceSymbol: String
    public let presenceName: String
    public let isPresence: Bool
    public let isAbsence: Bool
    public let isAbsenceJustified: Bool
    public let isLate: Bool
    public let isLateJustified: Bool
    public let isLegalAbsence: Bool
    public let isSchoolAbsence: Bool
    
    public var statusBadgeColor: Color {
        if isPresence {
            return .green
        } else if isSchoolAbsence {
            return Color(red: 0.0, green: 0.75, blue: 0.85) // Teal ZS
        } else if isAbsenceJustified {
            return .blue // NU
        } else if isAbsence {
            return .red // ✕
        } else if isLateJustified {
            return Color(red: 1.0, green: 0.7, blue: 0.0) // Amber SU
        } else if isLate {
            return .orange // S
        } else if isLegalAbsence {
            return .purple // ZW
        } else {
            return VulcanColors.textMuted
        }
    }
    
    public var shortSymbol: String {
        if isPresence {
            return "✓"
        } else if isSchoolAbsence {
            return "ZS"
        } else if isAbsenceJustified {
            return "NU"
        } else if isAbsence {
            return "✕"
        } else if isLateJustified {
            return "SU"
        } else if isLate {
            return "S"
        } else if isLegalAbsence {
            return "ZW"
        } else {
            return presenceSymbol.isEmpty ? "•" : presenceSymbol.uppercased()
        }
    }
    
    public init(
        id: UUID = UUID(),
        lessonNumber: Int,
        subjectName: String,
        teacherName: String,
        topic: String,
        timeStart: String,
        timeEnd: String,
        dateString: String,
        presenceSymbol: String,
        presenceName: String,
        isPresence: Bool,
        isAbsence: Bool,
        isAbsenceJustified: Bool,
        isLate: Bool,
        isLateJustified: Bool = false,
        isLegalAbsence: Bool = false,
        isSchoolAbsence: Bool = false
    ) {
        self.id = id
        self.lessonNumber = lessonNumber
        self.subjectName = subjectName
        self.teacherName = teacherName
        self.topic = topic
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.dateString = dateString
        self.presenceSymbol = presenceSymbol
        self.presenceName = presenceName
        self.isPresence = isPresence
        self.isAbsence = isAbsence
        self.isAbsenceJustified = isAbsenceJustified
        self.isLate = isLate
        self.isLateJustified = isLateJustified
        self.isLegalAbsence = isLegalAbsence
        self.isSchoolAbsence = isSchoolAbsence
    }
}
