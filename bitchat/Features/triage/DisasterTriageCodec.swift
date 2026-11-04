//
// DisasterTriageCodec.swift
// bitchat
//
// Dual-mode serialization: produces human-readable Thai emergency broadcast
// while embedding a structured Base64 payload for rich native card decoding.
//
// This is free and unencumbered software released into the public domain.
//

import Foundation

public enum DisasterTriageCodec {
    public static let payloadPrefix = "TH-SOS-V1:"
    
    // MARK: - Encode
    
    /// Encodes a DisasterTriageReport into a dual-mode message string:
    /// Line 1: Human-readable emergency announcement with Universal Shortcode
    /// Line 2: Structured Base64 payload for machine parsing
    public static func encode(_ report: DisasterTriageReport) -> String {
        let shortcode = report.universalShortCode
        let location = report.floorPosition.thaiTitle
        let water = report.waterLevel.thaiTitle
        let summary = report.victimSummaryDescription
        let supplies = report.supplies.map { $0.thaiTitle }.joined(separator: ", ")
        
        var header = "🚨 [รหัสฉุกเฉิน: \(shortcode)]\n"
        if let lat = report.latitude, let lon = report.longitude {
            header += String(format: "🌐 พิกัด GPS: %.5f, %.5f\n", lat, lon)
        }
        header += "📍 ตำแหน่ง: \(location) | น้ำ: \(water)\n"
        header += "👥 ผู้ประสบภัย: \(summary)\n"
        if !supplies.isEmpty {
            header += "📦 ต้องการด่วน: \(supplies)\n"
        }
        if !report.additionalNotes.isEmpty {
            header += "📝 เพิ่มเติม: \(report.additionalNotes)\n"
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        if let data = try? jsonEncoder.encode(report) {
            let base64 = data.base64EncodedString()
            return "\(header)\n\(payloadPrefix)\(base64)"
        }
        return header
    }
    
    // MARK: - Decode
    
    /// Parses a raw message string and extracts DisasterTriageReport if present.
    public static func decode(from text: String) -> DisasterTriageReport? {
        guard let range = text.range(of: payloadPrefix) else { return nil }
        let payloadSub = text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        // Extract up to the first space or newline
        let base64String = payloadSub.components(separatedBy: .whitespacesAndNewlines).first ?? payloadSub
        
        guard let data = Data(base64Encoded: base64String) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DisasterTriageReport.self, from: data)
    }
    
    /// Returns true if the message contains a disaster triage emergency payload.
    public static func isDisasterReport(_ text: String) -> Bool {
        text.contains(payloadPrefix)
    }
}

