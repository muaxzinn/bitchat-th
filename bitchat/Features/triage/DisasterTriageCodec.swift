//
// DisasterTriageCodec.swift
// bitchat
//
// Pure compact code serialization for offline emergency radio & BLE mesh broadcasts.
// Transmits zero verbose human sentences over the air to save critical radio bandwidth
// while encoding the Universal Shortcode and structured Base64 payload.
//
// This is free and unencumbered software released into the public domain.
//

import Foundation

public enum DisasterTriageCodec {
    public static let payloadPrefix = "TH-SOS-V1:"
    
    // MARK: - Encode
    
    /// Encodes a DisasterTriageReport into a pure code-only wire format:
    /// "SOS#<ShortCode>#TH-SOS-V1:<Base64Payload>"
    /// No long descriptive Thai text is transmitted over the air, minimizing BLE airtime & radio collision.
    public static func encode(_ report: DisasterTriageReport) -> String {
        let shortcode = report.universalShortCode
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        if let data = try? jsonEncoder.encode(report) {
            let base64 = data.base64EncodedString()
            return "SOS#\(shortcode)#\(payloadPrefix)\(base64)"
        }
        return "SOS#\(shortcode)"
    }
    
    // MARK: - Decode
    
    /// Parses a raw message string and extracts DisasterTriageReport if present.
    /// Fully backward-compatible with pure code packets and legacy text blocks.
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

