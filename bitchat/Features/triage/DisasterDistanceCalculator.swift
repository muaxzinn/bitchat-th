//
// DisasterDistanceCalculator.swift
// bitchat
//
// Geodesic distance calculation and relative bearing estimation between
// rescue officers and victims in offline flood/disaster environments.
//
// This is free and unencumbered software released into the public domain.
//

import Foundation
import CoreLocation

public struct RelativeVector: Equatable {
    public let distanceMeters: Double
    public let bearingDegrees: Double
    public let cardinalDirection: String
    public let arrowIcon: String
    
    public var formattedDistance: String {
        if distanceMeters < 1000 {
            return String(format: "%.0f ม.", distanceMeters)
        } else {
            return String(format: "%.1f กม.", distanceMeters / 1000.0)
        }
    }
}

public enum OfficerRangeFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case within500m = "500m"
    case within1km = "1km"
    case within3km = "3km"
    case within5km = "5km"
    case within10km = "10km"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .all: return "ทั้งหมด"
        case .within500m: return "500 ม."
        case .within1km: return "1 กม."
        case .within3km: return "3 กม."
        case .within5km: return "5 กม."
        case .within10km: return "10 กม."
        }
    }
    
    public var maxDistanceMeters: Double? {
        switch self {
        case .all: return nil
        case .within500m: return 500
        case .within1km: return 1000
        case .within3km: return 3000
        case .within5km: return 5000
        case .within10km: return 10000
        }
    }
}

public enum OfficerSortOrder: String, CaseIterable, Identifiable {
    case urgencyFirst = "urgency"
    case nearestFirst = "nearest"
    
    public var id: String { rawValue }
    
    public var thaiTitle: String {
        switch self {
        case .urgencyFirst: return "วิกฤตสูงสุดก่อน"
        case .nearestFirst: return "ใกล้ที่สุดก่อน"
        }
    }
    
    public var systemIcon: String {
        switch self {
        case .urgencyFirst: return "exclamationmark.triangle.fill"
        case .nearestFirst: return "location.fill"
        }
    }
}

public enum DisasterDistanceCalculator {
    /// Computes the WGS-84 geodesic distance in meters between two lat/lon coordinates.
    public static func distanceInMeters(
        from source: (latitude: Double, longitude: Double),
        to target: (latitude: Double, longitude: Double)
    ) -> Double {
        let loc1 = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let loc2 = CLLocation(latitude: target.latitude, longitude: target.longitude)
        return loc1.distance(from: loc2)
    }
    
    /// Calculates relative vector including distance and bearing from source to target.
    public static func calculateVector(
        from source: (latitude: Double, longitude: Double),
        to target: (latitude: Double, longitude: Double)
    ) -> RelativeVector {
        let dist = distanceInMeters(from: source, to: target)
        
        let lat1 = source.latitude * .pi / 180.0
        let lon1 = source.longitude * .pi / 180.0
        let lat2 = target.latitude * .pi / 180.0
        let lon2 = target.longitude * .pi / 180.0
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        var degrees = radiansBearing * 180.0 / .pi
        if degrees < 0 { degrees += 360 }
        
        let (cardinal, icon) = cardinalDirectionAndIcon(for: degrees)
        return RelativeVector(
            distanceMeters: dist,
            bearingDegrees: degrees,
            cardinalDirection: cardinal,
            arrowIcon: icon
        )
    }
    
    public static func cardinalDirectionAndIcon(for degrees: Double) -> (String, String) {
        let normalized = degrees.truncatingRemainder(dividingBy: 360.0)
        let positive = normalized < 0 ? normalized + 360.0 : normalized
        
        switch positive {
        case 22.5..<67.5:
            return ("ทิศตะวันออกเฉียงเหนือ", "arrow.up.right")
        case 67.5..<112.5:
            return ("ทิศตะวันออก", "arrow.right")
        case 112.5..<157.5:
            return ("ทิศตะวันออกเฉียงใต้", "arrow.down.right")
        case 157.5..<202.5:
            return ("ทิศใต้", "arrow.down")
        case 202.5..<247.5:
            return ("ทิศตะวันตกเฉียงใต้", "arrow.down.left")
        case 247.5..<292.5:
            return ("ทิศตะวันตก", "arrow.left")
        case 292.5..<337.5:
            return ("ทิศตะวันตกเฉียงเหนือ", "arrow.up.left")
        default: // 337.5...360 or 0..<22.5
            return ("ทิศเหนือ", "arrow.up")
        }
    }
}

