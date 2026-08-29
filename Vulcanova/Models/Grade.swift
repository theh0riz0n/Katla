//
//  Grade.swift
//  Vulcanova
//

import Foundation

public struct Grade: Identifiable, Hashable {
    public let id: UUID
    public let subjectName: String
    public let content: String
    public let value: Double
    public let displayText: String
    public let weight: Int
    public let categoryName: String
    public let dateCreated: Date
    public let teacher: String
    
    public init(
        id: UUID = UUID(),
        subjectName: String,
        content: String,
        value: Double,
        displayText: String,
        weight: Int,
        categoryName: String,
        dateCreated: Date = Date(),
        teacher: String
    ) {
        self.id = id
        self.subjectName = subjectName
        self.content = content
        self.value = value
        self.displayText = displayText
        self.weight = weight
        self.categoryName = categoryName
        self.dateCreated = dateCreated
        self.teacher = teacher
    }
}

// MARK: - Mock Data
extension Grade {
    public static let sampleGrades: [Grade] = [
        Grade(subjectName: "Język polski", content: "Sprawdzian z 'Dziadów'", value: 5.0, displayText: "5", weight: 3, categoryName: "Sprawdzian", teacher: "Marta Kowalska"),
        Grade(subjectName: "Matematyka", content: "Kartkówka - pochodne", value: 4.5, displayText: "5-", weight: 2, categoryName: "Kartkówka", teacher: "Jan Nowak"),
        Grade(subjectName: "Matematyka", content: "Praca klasowa: Funkcje", value: 4.0, displayText: "4", weight: 3, categoryName: "Sprawdzian", teacher: "Jan Nowak"),
        Grade(subjectName: "Język angielski", content: "Essay: Technology", value: 6.0, displayText: "6", weight: 2, categoryName: "Praca domowa", teacher: "Anna Smith"),
        Grade(subjectName: "Informatyka", content: "Projekt algorytmy w C#", value: 5.5, displayText: "5+", weight: 3, categoryName: "Projekt", teacher: "Piotr Wiśniewski"),
        Grade(subjectName: "Fizyka", content: "Kartkówka: Dynamika", value: 3.0, displayText: "3", weight: 1, categoryName: "Kartkówka", teacher: "Adam Zieliński")
    ]
}
