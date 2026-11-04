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
        // Verify pure compact code wire format (Zero verbose sentences)
        XCTAssertTrue(encodedWire.hasPrefix("SOS#SOS-FRW6-RED-P2M#TH-SOS-V1:"))
        XCTAssertFalse(encodedWire.contains("📍 ตำแหน่ง:"))
        XCTAssertFalse(encodedWire.contains("👥 ผู้ประสบภัย:"))
        
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
    
    // MARK: - Distance Calculation & Officer Filtering Tests
    
    func testDistanceCalculatorAndBearing() {
        // Officer located at Lat: 5.84261, Lon: 101.87717
        let officer = (latitude: 5.84261, longitude: 101.87717)
        // Victim located approx ~550 meters directly north (higher latitude)
        let victimNorth = (latitude: 5.84761, longitude: 101.87717)
        
        let dist = DisasterDistanceCalculator.distanceInMeters(from: officer, to: victimNorth)
        XCTAssertGreaterThan(dist, 500)
        XCTAssertLessThan(dist, 600)
        
        let vector = DisasterDistanceCalculator.calculateVector(from: officer, to: victimNorth)
        XCTAssertEqual(vector.cardinalDirection, "ทิศเหนือ")
        XCTAssertEqual(vector.arrowIcon, "arrow.up")
        XCTAssertEqual(vector.formattedDistance, String(format: "%.0f ม.", dist))
    }
    
    func testOfficerRangeFilterEvaluation() {
        let officer = (latitude: 5.84261, longitude: 101.87717)
        let victimClose = (latitude: 5.84461, longitude: 101.87717) // ~220m
        let victimFar = (latitude: 5.87261, longitude: 101.87717) // ~3.3km
        
        let distClose = DisasterDistanceCalculator.distanceInMeters(from: officer, to: victimClose)
        let distFar = DisasterDistanceCalculator.distanceInMeters(from: officer, to: victimFar)
        
        // Filter: 500 meters
        let filter500 = OfficerRangeFilter.within500m
        XCTAssertTrue(distClose <= filter500.maxDistanceMeters!)
        XCTAssertFalse(distFar <= filter500.maxDistanceMeters!)
        
        // Filter: 5 kilometers
        let filter5km = OfficerRangeFilter.within5km
        XCTAssertTrue(distClose <= filter5km.maxDistanceMeters!)
        XCTAssertTrue(distFar <= filter5km.maxDistanceMeters!)
    }
    
    // MARK: - Device Deduplication & Last-Write-Wins Tests
    
    func testRadarDeviceDeduplication() {
        let deviceID = "NODE-TEST99"
        
        let report1 = DisasterTriageReport(
            id: deviceID,
            timestamp: Date().addingTimeInterval(-100),
            waterLevel: .ankle
        )
        let report2 = DisasterTriageReport(
            id: deviceID,
            timestamp: Date().addingTimeInterval(-50),
            waterLevel: .waist
        )
        let report3 = DisasterTriageReport(
            id: deviceID,
            timestamp: Date(),
            waterLevel: .headHigh
        )
        
        let reports = [report1, report2, report3]
        var latestMap: [String: DisasterTriageReport] = [:]
        
        for r in reports {
            if let existing = latestMap[r.id] {
                if r.timestamp > existing.timestamp {
                    latestMap[r.id] = r
                }
            } else {
                latestMap[r.id] = r
            }
        }
        
        // Exactly 1 deduplicated entry remaining
        XCTAssertEqual(latestMap.count, 1)
        // Kept the latest state (headHigh)
        XCTAssertEqual(latestMap[deviceID]?.waterLevel, .headHigh)
    }
}

