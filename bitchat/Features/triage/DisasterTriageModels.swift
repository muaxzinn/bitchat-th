//
// DisasterTriageModels.swift
// bitchat
//
// Structured Emergency Triage Models for offline disaster response (e.g., floods, power outages).
// Supports granular questionnaire choices, Thai Citizen ID validation, and automated triage scoring.
//
// This is free and unencumbered software released into the public domain.
//

import Foundation

// MARK: - Thai Citizen ID Validation & Formatting

public enum ThaiCitizenIDValidator {
    /// Formats 13 digits into "x-xxxx-xxxxx-xx-x".
    public static func format(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        
        var result = ""
        let count = digits.count
        let chars = Array(digits)
        
        for i in 0..<min(count, 13) {
            if i == 1 || i == 5 || i == 10 || i == 12 {
                result.append("-")
            }
            result.append(chars[i])
        }
        return result
    }
    
    /// Validates Thai 13-digit National ID with the standard Modulo 11 check-digit algorithm.
    public static func isValid(_ raw: String) -> Bool {
        let digits = raw.filter { $0.isNumber }.compactMap { Int(String($0)) }
        guard digits.count == 13 else { return false }
        
        var sum = 0
        for i in 0..<12 {
            sum += digits[i] * (13 - i)
        }
        let checkDigit = (11 - (sum % 11)) % 10
        return checkDigit == digits[12]
    }
}

// MARK: - Granular Question Matrix Enums

public enum FloorPosition: String, Codable, CaseIterable, Identifiable {
    case ground = "ground"
    case secondFloor = "second_floor"
    case thirdFloorPlus = "third_floor_plus"
    case rooftop = "rooftop"
    case treeOrPole = "tree_or_pole"
    case inWater = "in_water"
    case trappedInVehicle = "in_vehicle"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .ground: return "ชั้น 1 (พื้นราบ)"
        case .secondFloor: return "ชั้น 2"
        case .thirdFloorPlus: return "ชั้น 3 ขึ้นไป"
        case .rooftop: return "ดาดฟ้า / หลังคา"
        case .treeOrPole: return "เกาะต้นไม้ / เสาไฟ"
        case .inWater: return "ลอยคอในกระแสน้ำ"
        case .trappedInVehicle: return "ติดในรถยนต์"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .ground: return "F1"
        case .secondFloor: return "F2"
        case .thirdFloorPlus: return "F3"
        case .rooftop: return "FR"
        case .treeOrPole: return "FT"
        case .inWater: return "FW"
        case .trappedInVehicle: return "FC"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .ground: return "house.fill"
        case .secondFloor: return "building.fill"
        case .thirdFloorPlus: return "building.2.fill"
        case .rooftop: return "triangle.fill"
        case .treeOrPole: return "arrow.up.and.line.horizontal.and.arrow.down"
        case .inWater: return "water.waves"
        case .trappedInVehicle: return "car.fill"
        }
    }
}

public enum WaterLevel: String, Codable, CaseIterable, Identifiable {
    case ankle = "ankle"
    case knee = "knee"
    case waist = "waist"
    case chest = "chest"
    case neck = "neck"
    case headHigh = "head_high"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .ankle: return "ข้อเท้า (10-30 ซม.)"
        case .knee: return "หัวเข่า (50 ซม.)"
        case .waist: return "ระดับเอว (1 ม.)"
        case .chest: return "ระดับอก (1.5 ม.)"
        case .neck: return "ระดับคอ (1.7 ม.)"
        case .headHigh: return "มิดหัว / ไหลเชี่ยว (> 2 ม.)"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .ankle: return "WL1"
        case .knee: return "WL2"
        case .waist: return "WL3"
        case .chest: return "WL4"
        case .neck: return "WL5"
        case .headHigh: return "WL6"
        }
    }
}

public enum WaterTrend: String, Codable, CaseIterable, Identifiable {
    case stable = "stable"
    case slowlyRising = "slowly_rising"
    case rapidRising = "rapid_rising"
    case receding = "receding"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .stable: return "น้ำนิ่ง / ทรงตัว"
        case .slowlyRising: return "น้ำค่อยๆ เพิ่มขึ้น"
        case .rapidRising: return "น้ำขึ้นเร็ว / เชี่ยวจัด"
        case .receding: return "น้ำเริ่มลดลง"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .stable: return "equal"
        case .slowlyRising: return "arrow.up.right"
        case .rapidRising: return "arrow.up"
        case .receding: return "arrow.down"
        }
    }
}

public enum EnvironmentalThreat: String, Codable, CaseIterable, Identifiable {
    case electricityLeak = "electricity_leak"
    case landslide = "landslide"
    case gasLeak = "gas_leak"
    case venomousAnimals = "venomous_animals"
    case buildingCracking = "building_cracking"
    case trappedNoExit = "trapped_no_exit"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .electricityLeak: return "ไฟฟ้ารั่ว / เสาไฟล้ม"
        case .landslide: return "ดินสไลด์ / โคลนถล่ม"
        case .gasLeak: return "กลิ่นแก๊สรั่ว"
        case .venomousAnimals: return "สัตว์มีพิษ / งู"
        case .buildingCracking: return "อาคารทรุด / มีเสียงลั่น"
        case .trappedNoExit: return "ประตูปิดตาย / ไม่มีทางออก"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .electricityLeak: return "bolt.trianglebadge.exclamationmark.fill"
        case .landslide: return "mountain.2.fill"
        case .gasLeak: return "flame.fill"
        case .venomousAnimals: return "allergens"
        case .buildingCracking: return "exclamationmark.triangle.fill"
        case .trappedNoExit: return "lock.fill"
        }
    }
}

public enum VulnerabilityFlag: String, Codable, CaseIterable, Identifiable {
    case pregnant = "pregnant"
    case infant = "infant"
    case child = "child"
    case elderly = "elderly"
    case bedridden = "bedridden"
    case dialysis = "dialysis"
    case oxygen = "oxygen"
    case chronicDisease = "chronic_disease"
    case severeInjury = "severe_injury"
    case unconscious = "unconscious"
    case deceased = "deceased"
    case pets = "pets"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .pregnant: return "หญิงตั้งครรภ์ / ใกล้คลอด"
        case .infant: return "ทารก / เด็กแรกเกิด"
        case .child: return "เด็กเล็ก (< 10 ปี)"
        case .elderly: return "ผู้สูงอายุ (> 65 ปี)"
        case .bedridden: return "ผู้ป่วยติดเตียง"
        case .dialysis: return "ผู้ป่วยฟอกไต (ต้องไป รพ.)"
        case .oxygen: return "ผู้ป่วยใช้ออกซิเจน"
        case .chronicDisease: return "โรคหัวใจ / เบาหวาน / ความดัน"
        case .severeInjury: return "บาดเจ็บ แผลฉกรรจ์ / กระดูกหัก"
        case .unconscious: return "หมดสติ / ไม่รู้สึกตัว"
        case .deceased: return "มีผู้เสียชีวิต"
        case .pets: return "มีสัตว์เลี้ยง (สุนัข/แมว)"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .pregnant: return "G"
        case .infant: return "B"
        case .child: return "C"
        case .elderly: return "E"
        case .bedridden: return "M"
        case .dialysis: return "D"
        case .oxygen: return "O"
        case .chronicDisease: return "H"
        case .severeInjury: return "I"
        case .unconscious: return "U"
        case .deceased: return "X"
        case .pets: return "P"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .pregnant: return "figure.stand"
        case .infant: return "figure.child"
        case .child: return "figure.child"
        case .elderly: return "figure.cane"
        case .bedridden: return "bed.double.fill"
        case .dialysis: return "cross.case.fill"
        case .oxygen: return "lungs.fill"
        case .chronicDisease: return "heart.fill"
        case .severeInjury: return "bandage.fill"
        case .unconscious: return "waveform.path.ecg"
        case .deceased: return "heart.slash.fill"
        case .pets: return "pawprint.fill"
        }
    }
    
    /// Score weight for automated emergency priority calculation
    public var riskWeight: Double {
        switch self {
        case .unconscious: return 5.0
        case .dialysis: return 4.5
        case .oxygen: return 4.5
        case .severeInjury: return 4.0
        case .bedridden: return 3.5
        case .pregnant: return 3.0
        case .infant: return 3.0
        case .elderly: return 2.0
        case .child: return 1.5
        case .chronicDisease: return 1.5
        case .deceased: return 1.0
        case .pets: return 0.5
        }
    }
}

public enum WaterSupplyRemaining: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case lessThan1Day = "1_day"
    case twoToThreeDays = "2_3_days"
    case sufficient = "sufficient"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .none: return "น้ำหมดแล้ว (ไม่มีดื่ม)"
        case .lessThan1Day: return "เหลือไม่เกิน 1 วัน"
        case .twoToThreeDays: return "เหลือ 2-3 วัน"
        case .sufficient: return "มีเพียงพอ"
        }
    }
}

public enum FoodSupplyRemaining: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case oneToTwoMeals = "1_2_meals"
    case twoToThreeDays = "2_3_days"
    case sufficient = "sufficient"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .none: return "อาหารหมดแล้ว (อดอาหาร)"
        case .oneToTwoMeals: return "เหลือ 1-2 มื้อ"
        case .twoToThreeDays: return "เหลือ 2-3 วัน"
        case .sufficient: return "มีเพียงพอ"
        }
    }
}

public enum BatteryPowerStatus: String, Codable, CaseIterable, Identifiable {
    case critical = "critical"
    case medium = "medium"
    case sufficient = "sufficient"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .critical: return "แบตเตอรี่วิกฤต (< 10%)"
        case .medium: return "แบตเตอรี่ 10-40%"
        case .sufficient: return "มีพาวเวอร์แบงก์ / > 50%"
        }
    }
}

public enum PrimaryRescueRequest: String, Codable, CaseIterable, Identifiable {
    case boatEvac = "boat_evac"
    case helicopter = "helicopter"
    case emergencyMedical = "emergency_medical"
    case supplyRations = "supply_rations"
    case lifejacketRope = "lifejacket_rope"
    case powerCutoff = "power_cutoff"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .boatEvac: return "ขอเรือท้องแบนอพยพด่วน"
        case .helicopter: return "ขอเฮลิคอปเตอร์ (น้ำเชี่ยว/เรือเข้าไม่ถึง)"
        case .emergencyMedical: return "ขอทีมกู้ชีพ / ยาฉุกเฉิน / ออกซิเจน"
        case .supplyRations: return "ขอถุงยังชีพ / น้ำดื่ม (ยังไม่อพยพ)"
        case .lifejacketRope: return "ขอชูชีพ / เชือกกู้ภัย"
        case .powerCutoff: return "ขอตัดกระแสไฟฟ้าด่วน"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .boatEvac: return "BOAT"
        case .helicopter: return "HELI"
        case .emergencyMedical: return "MED"
        case .supplyRations: return "RATION"
        case .lifejacketRope: return "ROPE"
        case .powerCutoff: return "ELEC"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .boatEvac: return "ferry.fill"
        case .helicopter: return "airplane"
        case .emergencyMedical: return "cross.case.fill"
        case .supplyRations: return "shippingbox.fill"
        case .lifejacketRope: return "shield.fill"
        case .powerCutoff: return "bolt.slash.fill"
        }
    }
}

public enum EmergencyUrgency: String, Codable, CaseIterable, Identifiable {
    case critical = "critical"
    case urgent = "urgent"
    case stable = "stable"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .critical: return "วิกฤตสีแดง (ลำดับ 1: กู้ชีพทันที)"
        case .urgent: return "เร่งด่วนสีส้ม (ลำดับ 2: น้ำขึ้น/เสบียงหมด)"
        case .stable: return "เฝ้าระวังสีเขียว (ลำดับ 3: ปลอดภัย รออพยพ)"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .critical: return "RED"
        case .urgent: return "ORG"
        case .stable: return "GRN"
        }
    }
}

// MARK: - Legacy Compatibility Enums

public enum VictimCategory: String, Codable, CaseIterable, Identifiable {
    case adult = "adult"
    case child = "child"
    case elderly = "elderly"
    case bedridden = "bedridden"
    case injured = "injured"
    case deceased = "deceased"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .adult: return "ผู้ใหญ่"
        case .child: return "เด็ก / ทารก"
        case .elderly: return "ผู้สูงอายุ"
        case .bedridden: return "ผู้ป่วยติดเตียง"
        case .injured: return "ผู้บาดเจ็บ"
        case .deceased: return "ผู้เสียชีวิต"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .adult: return "A"
        case .child: return "C"
        case .elderly: return "E"
        case .bedridden: return "M"
        case .injured: return "I"
        case .deceased: return "D"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .adult: return "person.fill"
        case .child: return "figure.child"
        case .elderly: return "figure.cane"
        case .bedridden: return "bed.double.fill"
        case .injured: return "cross.case.fill"
        case .deceased: return "heart.slash.fill"
        }
    }
}

public enum SupplyNeed: String, Codable, CaseIterable, Identifiable {
    case water = "water"
    case food = "food"
    case medicines = "medicines"
    case evacuationBoat = "boat"
    case powerBank = "power"
    case lifejacket = "lifejacket"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .water: return "น้ำดื่มสะอาด"
        case .food: return "อาหาร / นมผง"
        case .medicines: return "ยารักษาโรค"
        case .evacuationBoat: return "เรืออพยพด่วน"
        case .powerBank: return "ไฟฉาย / แบตเตอรี่"
        case .lifejacket: return "ชูชีพ / เชือก"
        }
    }
    
    public var shortCode: String {
        switch self {
        case .water: return "W"
        case .food: return "F"
        case .medicines: return "M"
        case .evacuationBoat: return "B"
        case .powerBank: return "P"
        case .lifejacket: return "J"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .water: return "drop.fill"
        case .food: return "fork.knife"
        case .medicines: return "cross.case.fill"
        case .evacuationBoat: return "ferry.fill"
        case .powerBank: return "bolt.fill"
        case .lifejacket: return "shield.fill"
        }
    }
}

// MARK: - Individual Person Model

public struct VictimRecord: Identifiable, Codable, Equatable {
    public var id: String
    public var fullName: String
    public var citizenID: String
    public var category: VictimCategory
    public var medicalNotes: String
    public var address: String
    public var isHeadOfHousehold: Bool
    
    public init(
        id: String = UUID().uuidString.prefix(6).uppercased(),
        fullName: String = "",
        citizenID: String = "",
        category: VictimCategory = .adult,
        medicalNotes: String = "",
        address: String = "",
        isHeadOfHousehold: Bool = false
    ) {
        self.id = id
        self.fullName = fullName
        self.citizenID = citizenID
        self.category = category
        self.medicalNotes = medicalNotes
        self.address = address
        self.isHeadOfHousehold = isHeadOfHousehold
    }
    
    public var formattedCitizenID: String {
        ThaiCitizenIDValidator.format(citizenID)
    }
    
    /// Protected masked Citizen ID (e.g. "1-1005-•••••-••-6") to preserve privacy and prevent identity theft
    public var maskedCitizenID: String {
        let digits = citizenID.filter { $0.isNumber }
        guard digits.count == 13 else {
            return citizenID.isEmpty ? "ไม่ระบุ" : "•••••••••••••"
        }
        let chars = Array(digits)
        return "\(chars[0])-\(chars[1])\(chars[2])\(chars[3])\(chars[4])-•••••-••-\(chars[12])"
    }
    
    public var isCitizenIDValid: Bool {
        ThaiCitizenIDValidator.isValid(citizenID)
    }
}

// MARK: - Comprehensive Disaster Triage Report

public struct DisasterTriageReport: Identifiable, Codable, Equatable {
    public var id: String
    public var timestamp: Date
    public var floorPosition: FloorPosition
    public var waterLevel: WaterLevel
    public var waterTrend: WaterTrend
    public var environmentalThreats: [EnvironmentalThreat]
    public var vulnerabilityFlags: [VulnerabilityFlag]
    public var waterSupply: WaterSupplyRemaining
    public var foodSupply: FoodSupplyRemaining
    public var batteryStatus: BatteryPowerStatus
    public var primaryRequest: PrimaryRescueRequest
    public var urgency: EmergencyUrgency
    public var supplies: [SupplyNeed]
    public var victims: [VictimRecord]
    public var totalPeopleCount: Int
    public var houseAddress: String
    public var additionalNotes: String
    public var districtName: String
    public var geohash: String
    public var latitude: Double?
    public var longitude: Double?
    public var gpsAccuracyMeters: Double?
    
    public init(
        id: String = String(UUID().uuidString.prefix(8).uppercased()),
        timestamp: Date = Date(),
        floorPosition: FloorPosition = .secondFloor,
        waterLevel: WaterLevel = .waist,
        waterTrend: WaterTrend = .slowlyRising,
        environmentalThreats: [EnvironmentalThreat] = [],
        vulnerabilityFlags: [VulnerabilityFlag] = [],
        waterSupply: WaterSupplyRemaining = .lessThan1Day,
        foodSupply: FoodSupplyRemaining = .oneToTwoMeals,
        batteryStatus: BatteryPowerStatus = .medium,
        primaryRequest: PrimaryRescueRequest = .boatEvac,
        urgency: EmergencyUrgency = .urgent,
        supplies: [SupplyNeed] = [.water, .food],
        victims: [VictimRecord] = [],
        totalPeopleCount: Int = 1,
        houseAddress: String = "",
        additionalNotes: String = "",
        districtName: String = "อำเภอเมือง",
        geohash: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        gpsAccuracyMeters: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.floorPosition = floorPosition
        self.waterLevel = waterLevel
        self.waterTrend = waterTrend
        self.environmentalThreats = environmentalThreats
        self.vulnerabilityFlags = vulnerabilityFlags
        self.waterSupply = waterSupply
        self.foodSupply = foodSupply
        self.batteryStatus = batteryStatus
        self.primaryRequest = primaryRequest
        self.urgency = urgency
        self.supplies = supplies
        self.victims = victims
        self.totalPeopleCount = max(totalPeopleCount, max(victims.count, 1))
        self.houseAddress = houseAddress
        self.additionalNotes = additionalNotes
        self.districtName = districtName
        self.geohash = geohash
        self.latitude = latitude
        self.longitude = longitude
        self.gpsAccuracyMeters = gpsAccuracyMeters
    }
    
    /// Automated Triage Score (0.0 to 10.0) based on disaster medical logistics
    public var calculatedTriageScore: Double {
        var score: Double = 0.0
        
        // Water Level Risk
        switch waterLevel {
        case .ankle: score += 1.0
        case .knee: score += 2.0
        case .waist: score += 3.5
        case .chest: score += 5.0
        case .neck: score += 7.0
        case .headHigh: score += 8.5
        }
        
        // Floor Position
        if floorPosition == .inWater { score += 5.0 }
        if floorPosition == .rooftop { score += 2.0 }
        if floorPosition == .treeOrPole { score += 4.0 }
        if floorPosition == .trappedInVehicle { score += 4.5 }
        
        // Water Trend
        if waterTrend == .rapidRising { score += 2.5 }
        
        // Environmental Threats
        if environmentalThreats.contains(.electricityLeak) { score += 4.0 }
        if environmentalThreats.contains(.landslide) { score += 4.0 }
        if environmentalThreats.contains(.buildingCracking) { score += 3.0 }
        if environmentalThreats.contains(.trappedNoExit) { score += 3.0 }
        
        // Vulnerabilities
        for flag in vulnerabilityFlags {
            score += flag.riskWeight
        }
        
        // Food/Water Depletion
        if waterSupply == .none { score += 3.0 }
        if foodSupply == .none { score += 2.0 }
        
        return min(score, 10.0)
    }
    
    /// Recommended Urgency Classification
    public var resolvedUrgency: EmergencyUrgency {
        let score = calculatedTriageScore
        if score >= 6.5 || waterLevel == .headHigh || floorPosition == .inWater || vulnerabilityFlags.contains(.dialysis) || vulnerabilityFlags.contains(.oxygen) || vulnerabilityFlags.contains(.unconscious) {
            return .critical
        } else if score >= 3.5 || waterTrend == .rapidRising || waterSupply == .none {
            return .urgent
        } else {
            return .stable
        }
    }
    
    /// Ultra-Granular Alphanumeric Triage Code without redundant "SOS" prefix.
    /// Format: [Floor + Water + Trend + Threats]-[Urgency]-[People + Vulnerabilities]-[Request]-[Supplies]
    /// e.g. "F2W3SR-RED-P3EMO-BOAT-W0F0" or "FRW6RR+EL-RED-P4BEM-BOAT-W0F0"
    public var universalShortCode: String {
        let floorCode = floorPosition.shortCode
        let waterCode = waterLevel.shortCode.replacingOccurrences(of: "L", with: "")
        
        let trendCode: String = {
            switch waterTrend {
            case .rapidRising: return "RR"
            case .slowlyRising: return "SR"
            case .stable: return "ST"
            case .receding: return "RC"
            }
        }()
        
        var threatStr = ""
        if !environmentalThreats.isEmpty {
            let threatCodes = environmentalThreats.compactMap { threat -> String? in
                switch threat {
                case .electricityLeak: return "EL"
                case .landslide: return "LS"
                case .gasLeak: return "GS"
                case .venomousAnimals: return "SN"
                case .buildingCracking: return "CR"
                case .trappedNoExit: return "TR"
                }
            }
            if !threatCodes.isEmpty {
                threatStr = "+" + threatCodes.joined(separator: "")
            }
        }
        
        let urgencyCode = resolvedUrgency.shortCode
        let count = max(totalPeopleCount, max(victims.count, 1))
        
        var flagStr = ""
        for flag in vulnerabilityFlags.prefix(5) {
            flagStr += flag.shortCode
        }
        
        let reqCode = primaryRequest.shortCode
        
        var shortageStr = ""
        if waterSupply == .none { shortageStr += "W0" }
        else if waterSupply == .lessThan1Day { shortageStr += "W1" }
        
        if foodSupply == .none { shortageStr += "F0" }
        else if foodSupply == .oneToTwoMeals { shortageStr += "F1" }
        
        if batteryStatus == .critical { shortageStr += "B0" }
        
        var components = [
            "\(floorCode)\(waterCode)\(trendCode)\(threatStr)",
            urgencyCode,
            "P\(count)\(flagStr)",
            reqCode
        ]
        if !shortageStr.isEmpty {
            components.append(shortageStr)
        }
        
        return components.joined(separator: "-")
    }
    
    public var victimSummaryDescription: String {
        var parts: [String] = ["ยอดรวม \(totalPeopleCount) คน"]
        let flagTitles = vulnerabilityFlags.map { $0.thaiTitle }
        if !flagTitles.isEmpty {
            parts.append(flagTitles.joined(separator: ", "))
        }
        return parts.joined(separator: " | ")
    }
}
