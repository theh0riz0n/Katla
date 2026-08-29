//
//  Lesson.swift
//  Vulcanova
//

import Foundation

public struct Lesson: Identifiable, Hashable {
    public let id: UUID
    public let number: Int
    public let subjectName: String
    public let teacherName: String
    public let classroom: String
    public let timeStart: String
    public let timeEnd: String
    public let dateString: String
    public let isCancelled: Bool
    public let isSubstitution: Bool
    
    public var timeString: String {
        "\(timeStart) - \(timeEnd)"
    }
    
    public init(
        id: UUID = UUID(),
        number: Int,
        subjectName: String,
        teacherName: String,
        classroom: String,
        timeStart: String,
        timeEnd: String,
        dateString: String = "",
        isCancelled: Bool = false,
        isSubstitution: Bool = false
    ) {
        self.id = id
        self.number = number
        self.subjectName = subjectName
        self.teacherName = teacherName
        self.classroom = classroom
        self.timeStart = timeStart
        self.timeEnd = timeEnd
        self.dateString = dateString
        self.isCancelled = isCancelled
        self.isSubstitution = isSubstitution
    }
}

// MARK: - Mock Data
extension Lesson {
    public static let sampleLessons: [Lesson] = [
        Lesson(number: 1, subjectName: "Język angielski", teacherName: "A. Smith", classroom: "204", timeStart: "08:00", timeEnd: "08:45", dateString: "2026-09-02"),
        Lesson(number: 2, subjectName: "Matematyka", teacherName: "J. Nowak", classroom: "112", timeStart: "08:55", timeEnd: "09:40", dateString: "2026-09-02"),
        Lesson(number: 3, subjectName: "Matematyka", teacherName: "J. Nowak", classroom: "112", timeStart: "09:50", timeEnd: "10:35", dateString: "2026-09-02"),
        Lesson(number: 4, subjectName: "Informatyka", teacherName: "P. Wiśniewski", classroom: "Lab 3", timeStart: "10:45", timeEnd: "11:30", dateString: "2026-09-02"),
        Lesson(number: 5, subjectName: "Fizyka", teacherName: "A. Zieliński", classroom: "301", timeStart: "11:45", timeEnd: "12:30", dateString: "2026-09-02", isSubstitution: true),
        Lesson(number: 6, subjectName: "Język polski", teacherName: "M. Kowalska", classroom: "105", timeStart: "12:45", timeEnd: "13:30", dateString: "2026-09-02", isCancelled: true)
    ]
}
