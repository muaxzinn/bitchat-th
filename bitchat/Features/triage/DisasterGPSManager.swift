//
// DisasterGPSManager.swift
// bitchat
//
// Battery-conscious one-shot GPS manager for emergency disaster response.
// Enforces precise satellite coordinate acquisition, then immediately puts the GPS hardware to sleep.
//
// This is free and unencumbered software released into the public domain.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
public final class DisasterGPSManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = DisasterGPSManager()
    
    @Published public private(set) var latitude: Double?
    @Published public private(set) var longitude: Double?
    @Published public private(set) var accuracyMeters: Double?
    @Published public private(set) var isLocating: Bool = false
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var errorMessage: String?
    
    private let manager = CLLocationManager()
    private var completionHandler: ((CLLocationCoordinate2D?, Double?) -> Void)?
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    public var hasValidGPSFix: Bool {
        latitude != nil && longitude != nil
    }
    
    public var formattedCoordinates: String {
        guard let lat = latitude, let lon = longitude else { return "ยังไม่มีพิกัด GPS" }
        return String(format: "%.5f, %.5f", lat, lon)
    }
    
    public var isAuthorized: Bool {
        #if os(macOS)
        return manager.authorizationStatus == .authorizedAlways
        #else
        return manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        #endif
    }
    
    /// Requests a temporary high-accuracy GPS fix, then IMMEDIATELY stops tracking to preserve battery.
    public func requestTemporaryGPSFix(completion: ((CLLocationCoordinate2D?, Double?) -> Void)? = nil) {
        self.completionHandler = completion
        self.errorMessage = nil
        self.isLocating = true
        
        let status = manager.authorizationStatus
        if status == .notDetermined {
            #if os(macOS)
            manager.requestAlwaysAuthorization()
            #else
            manager.requestWhenInUseAuthorization()
            #endif
        } else if status == .denied || status == .restricted {
            isLocating = false
            errorMessage = "กรุณาเปิดการอนุญาตตำแหน่ง (Location Services) ในการตั้งค่า"
            completion?(nil, nil)
            return
        }
        
        manager.startUpdatingLocation()
    }
    
    public func stopGPS() {
        manager.stopUpdatingLocation()
        isLocating = false
    }
    
    public func setManualCoordinatesForTesting(lat: Double, lon: Double) {
        self.latitude = lat
        self.longitude = lon
        self.accuracyMeters = 5.0
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        
        Task { @MainActor in
            // As soon as a fix is acquired, save and immediately stop the GPS radio!
            self.latitude = loc.coordinate.latitude
            self.longitude = loc.coordinate.longitude
            self.accuracyMeters = loc.horizontalAccuracy
            self.isLocating = false
            self.manager.stopUpdatingLocation()
            
            self.completionHandler?(loc.coordinate, loc.horizontalAccuracy)
            self.completionHandler = nil
        }
    }
    
    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            self.manager.stopUpdatingLocation()
            self.errorMessage = error.localizedDescription
            self.completionHandler?(nil, nil)
            self.completionHandler = nil
        }
    }
    
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if self.isAuthorized {
                if self.isLocating {
                    self.manager.startUpdatingLocation()
                }
            }
        }
    }
}
