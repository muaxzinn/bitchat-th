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
    public static let payloadPrefix = "TH-V1:"
    public static let legacyPayloadPrefix = "TH-SOS-V1:"
    
    // MARK: - Encode
    
    /// Encodes a DisasterTriageReport into a pure code-only wire format without redundant "SOS":
    /// "<ShortCode>#TH-V1:<Base64Payload>"
    /// No long descriptive Thai text is transmitted over the air, minimizing BLE airtime & radio collision.
    public static func encode(_ report: DisasterTriageReport) -> String {
        let shortcode = report.universalShortCode
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        if let data = try? jsonEncoder.encode(report) {
            let base64 = data.base64EncodedString()
            return "\(shortcode)#\(payloadPrefix)\(base64)"
        }
        return shortcode
    }
    
    // MARK: - Decode
    
    /// Parses a raw message string and extracts DisasterTriageReport if present.
    /// Fully backward-compatible with pure code packets and legacy text blocks.
    public static func decode(from text: String) -> DisasterTriageReport? {
        let prefix: String
        if let range = text.range(of: payloadPrefix) {
            prefix = payloadPrefix
        } else if let range = text.range(of: legacyPayloadPrefix) {
            prefix = legacyPayloadPrefix
        } else {
            return nil
        }
        
        guard let range = text.range(of: prefix) else { return nil }
        let payloadSub = text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        let base64String = payloadSub.components(separatedBy: .whitespacesAndNewlines).first ?? payloadSub
        
        guard let data = Data(base64Encoded: base64String) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DisasterTriageReport.self, from: data)
    }
    
    /// Returns true if the message contains a disaster triage emergency payload.
    public static func isDisasterReport(_ text: String) -> Bool {
        text.contains(payloadPrefix) || text.contains(legacyPayloadPrefix)
    }
}

