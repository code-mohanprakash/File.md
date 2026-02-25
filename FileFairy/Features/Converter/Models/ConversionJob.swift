// ConversionJob.swift
// FileFairy

import SwiftData
import Foundation

@Model
final class ConversionJob {
    var id: UUID
    var inputFileName: String
    var outputFileName: String?
    var conversionType: String
    var status: String  // pending, processing, complete, failed
    var createdAt: Date
    var inputSize: Int64
    var outputSize: Int64
    var outputPath: String?

    init(
        inputFileName: String,
        conversionType: ConversionType,
        inputSize: Int64 = 0
    ) {
        self.id = UUID()
        self.inputFileName = inputFileName
        self.conversionType = conversionType.rawValue
        self.status = "pending"
        self.createdAt = Date()
        self.inputSize = inputSize
        self.outputSize = 0
    }
}
