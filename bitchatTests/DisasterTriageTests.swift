//
// DisasterTriageTests.swift
// bitchatTests
//
// Automated verification tests for Thai Citizen ID validation and Disaster Triage codec.
//

import XCTest
@testable import bitchat

final class DisasterTriageTests: XCTestCase {
    
    // MARK: - Thai Citizen ID Validation
    
    func testThaiCitizenIDValidation() {
        // Known valid Thai IDs (Mod 11 test vectors)
        let validID1 = "1100500123456" // Test sample
        XCTAssertEqual(ThaiCitizenIDValidator.format(validID1), "1-1005-00123-45-6")
        
        // Invalid IDs (wrong length / wrong check digit)
        XCTAssertFalse(ThaiCitizenIDValidator.isValid("12345"))
        XCTAssertFalse(ThaiCitizenIDValidator.isValid("1111111111111"))
    }
    
    // MARK: - Disaster Triage Serialization & Deserialization
    
    func testDisasterTriageRoundtrip() {
        let victims = [
            VictimRecord(
                fullName: "สมชาย ใจดี",
                citizenID: "1100500123456",
                category: .adult,
                medicalNotes: "แขนหัก"
            ),
            VictimRecord(
                fullName: "ยายสมศรี",
                citizenID: "3100500987654",
                category: .bedridden,
                medicalNotes: "ขาดออกซิเจน"
            )
        ]
        
        let originalReport = DisasterTriageReport(
            floorPosition: .rooftop,
            waterLevel: .headHigh,
            vulnerabilityFlags: [.bedridden],
            urgency: .critical,
            supplies: [.water, .food, .evacuationBoat, .medicines],
            victims: victims,
            additionalNotes: "บ้านหลังคาสีฟ้าติดริมคลอง",
            districtName: "อำเภอเมือง"
        )
        
        let encodedWire = DisasterTriageCodec.encode(originalReport)
        XCTAssertTrue(DisasterTriageCodec.isDisasterReport(encodedWire))
        XCTAssertTrue(encodedWire.contains("🚨 [รหัสฉุกเฉิน: SOS-FRW6-RED-P2M]"))
        
        guard let decodedReport = DisasterTriageCodec.decode(from: encodedWire) else {
            XCTFail("Failed to decode disaster triage report from wire text")
            return
        }
        
        XCTAssertEqual(decodedReport.floorPosition, .rooftop)
        XCTAssertEqual(decodedReport.waterLevel, .headHigh)
        XCTAssertEqual(decodedReport.urgency, .critical)
        XCTAssertEqual(decodedReport.victims.count, 2)
        XCTAssertEqual(decodedReport.victims[0].fullName, "สมชาย ใจดี")
        XCTAssertEqual(decodedReport.victims[1].category, .bedridden)
        XCTAssertEqual(decodedReport.additionalNotes, "บ้านหลังคาสีฟ้าติดริมคลอง")
    }
    
    func testUniversalShortCodeGeneration() {
        let report = DisasterTriageReport(
            floorPosition: .secondFloor,
            waterLevel: .waist,
            vulnerabilityFlags: [.child, .elderly],
            urgency: .urgent,
            supplies: [.water],
            victims: [
                VictimRecord(fullName: "เด็กชายพีท", category: .child),
                VictimRecord(fullName: "คุณยายพร", category: .elderly)
            ]
        )
        
        // F2 + W3 + RED (Score 7.0) + P2 + CE (Child & Elderly)
        XCTAssertEqual(report.universalShortCode, "SOS-F2W3-RED-P2CE")
    }
}

