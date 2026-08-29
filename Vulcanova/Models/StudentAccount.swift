//
//  StudentAccount.swift
//  Vulcanova
//

import Foundation

public struct StudentPeriod: Codable, Identifiable, Equatable {
    public let id: Int
    public let number: Int
    public let current: Bool
    
    public init(id: Int, number: Int, current: Bool) {
        self.id = id
        self.number = number
        self.current = current
    }
}

public struct StudentAccount: Codable, Identifiable, Equatable {
    public let id: Int
    public let firstName: String
    public let lastName: String
    public let schoolName: String
    public let symbol: String
    public let restUrl: String
    public let keyFingerprint: String
    public let privateKeyBase64: String
    public let periodId: Int
    public let unitId: Int
    public let periods: [StudentPeriod]
    public let messageBoxKey: String
    
    public var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var semester1PeriodId: Int {
        periods.first(where: { $0.number == 1 })?.id ?? periodId
    }
    
    public var semester2PeriodId: Int {
        periods.first(where: { $0.number == 2 })?.id ?? periodId
    }
    
    public init(
        id: Int,
        firstName: String,
        lastName: String,
        schoolName: String,
        symbol: String,
        restUrl: String,
        keyFingerprint: String,
        privateKeyBase64: String,
        periodId: Int,
        unitId: Int,
        periods: [StudentPeriod] = [],
        messageBoxKey: String = ""
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.schoolName = schoolName
        self.symbol = symbol
        self.restUrl = restUrl
        self.keyFingerprint = keyFingerprint
        self.privateKeyBase64 = privateKeyBase64
        self.periodId = periodId
        self.unitId = unitId
        self.periods = periods
        self.messageBoxKey = messageBoxKey
    }
}
