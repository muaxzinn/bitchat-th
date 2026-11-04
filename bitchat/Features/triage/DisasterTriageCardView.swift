//
// DisasterTriageCardView.swift
// bitchat
//
// High-visibility, accessible emergency triage card rendered directly in the chat timeline.
// Displays location, water level, needed supplies, and individual victims with Thai Citizen IDs.
//
// This is free and unencumbered software released into the public domain.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct DisasterTriageCardView: View {
    public let report: DisasterTriageReport
    public let officerLocation: (latitude: Double, longitude: Double)?
    public let isSelfDevice: Bool
    
    @State private var isVictimsExpanded = true
    @State private var copiedCitizenID: String?
    @State private var isShortCodeCopied = false
    @State private var isAcknowledged = false
    @State private var showFullscreenBeacon = false
    
    public init(
        report: DisasterTriageReport,
        officerLocation: (latitude: Double, longitude: Double)? = nil,
        isSelfDevice: Bool = false
    ) {
        self.report = report
        self.officerLocation = officerLocation
        self.isSelfDevice = isSelfDevice
    }
    
    private var urgencyColor: Color {
        switch report.urgency {
        case .critical: return Color.red
        case .urgent: return Color.orange
        case .stable: return Color.green
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Emergency Banner & Universal Shortcode
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(report.universalShortCode)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(urgencyColor)
                .cornerRadius(6)
                
                Text(report.urgency.thaiTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(urgencyColor)
                    .lineLimit(1)
                
                if isSelfDevice {
                    HStack(spacing: 3) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 10))
                        Text("เครื่องนี้")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(report.universalShortCode)
                    isShortCodeCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isShortCodeCopied = false
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isShortCodeCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(isShortCodeCopied ? "คัดลอกแล้ว" : "คัดลอกรหัส")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            
            // Location and Water Level Indicators
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: report.floorPosition.systemIcon)
                        .font(.system(size: 11))
                    Text(report.floorPosition.thaiTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(6)
                
                HStack(spacing: 4) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 11))
                    Text(report.waterLevel.thaiTitle)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.15))
                .foregroundColor(.cyan)
                .cornerRadius(6)
            }
            
            // GPS Satellite Coordinates & Officer Relative Vector
            if let lat = report.latitude, let lon = report.longitude {
                VStack(alignment: .leading, spacing: 6) {
                    if let officerLoc = officerLocation {
                        let vector = DisasterDistanceCalculator.calculateVector(from: officerLoc, to: (lat, lon))
                        HStack(spacing: 6) {
                            Image(systemName: vector.arrowIcon)
                                .font(.system(size: 11, weight: .bold))
                            Text("ห่างจากเจ้าหน้าที่ \(vector.formattedDistance) (\(vector.cardinalDirection))")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(6)
                    }
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.north.circle.fill")
                                .font(.system(size: 11))
                            Text(String(format: "GPS: %.5f, %.5f", lat, lon))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                        
                        Button(action: {
                            let coordStr = String(format: "%.5f, %.5f", lat, lon)
                            copyToClipboard(coordStr)
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 9))
                                Text("คัดลอกพิกัด")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        
                        #if os(macOS)
                        Button(action: {
                            if let url = URL(string: "https://maps.apple.com/?q=\(lat),\(lon)") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 9))
                                Text("เปิดแผนที่")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        #elseif os(iOS)
                        Button(action: {
                            if let url = URL(string: "https://maps.apple.com/?q=\(lat),\(lon)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 9))
                                Text("เปิดแผนที่")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                }
            } else if officerLocation != nil {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("ไม่มีพิกัดดาวเทียม (ไม่สามารถคำนวณระยะทางและคัดกรองพื้นที่ได้)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(6)
            }
            
            // Needed Supplies Chips
            if !report.supplies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ต้องการความช่วยเหลือด่วน:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(report.supplies) { supply in
                                HStack(spacing: 4) {
                                    Image(systemName: supply.systemIcon)
                                        .font(.system(size: 10))
                                    Text(supply.thaiTitle)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            // Victims & Citizen ID Section (Highlight Feature)
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isVictimsExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text(report.victimSummaryDescription)
                            .font(.system(size: 12, weight: .bold))
                        
                        Spacer()
                        
                        Image(systemName: isVictimsExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                if isVictimsExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        if report.victims.isEmpty {
                            Text("ไม่ระบุรายบุคคล (ยอดรวม 1 คน)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        } else {
                            ForEach(report.victims) { victim in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: victim.category.systemIcon)
                                        .font(.system(size: 13))
                                        .foregroundColor(urgencyColor)
                                        .frame(width: 16)
                                        .padding(.top, 2)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(victim.fullName.isEmpty ? "ผู้ประสบภัย" : victim.fullName)
                                                .font(.system(size: 12, weight: .semibold))
                                            
                                            Text(victim.category.thaiTitle)
                                                .font(.system(size: 10, weight: .medium))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1)
                                                .background(Color.secondary.opacity(0.15))
                                                .cornerRadius(3)
                                        }
                                        
                                        // Thai National Citizen ID with 1-Tap Copy
                                        if !victim.citizenID.isEmpty {
                                            HStack(spacing: 6) {
                                                Text("เลข ปชช: \(victim.formattedCitizenID)")
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                                
                                                Button(action: {
                                                    let cleanID = victim.citizenID.filter { $0.isNumber }
                                                    copyToClipboard(cleanID)
                                                    copiedCitizenID = victim.id
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                        if copiedCitizenID == victim.id {
                                                            copiedCitizenID = nil
                                                        }
                                                    }
                                                }) {
                                                    HStack(spacing: 2) {
                                                        Image(systemName: copiedCitizenID == victim.id ? "checkmark" : "doc.on.doc")
                                                            .font(.system(size: 9))
                                                        Text(copiedCitizenID == victim.id ? "คัดลอกแล้ว" : "คัดลอก")
                                                            .font(.system(size: 9, weight: .medium))
                                                    }
                                                    .foregroundColor(.blue)
                                                }
                                                .buttonStyle(.plain)
                                                
                                                if victim.isCitizenIDValid {
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        }
                                        
                                        if !victim.medicalNotes.isEmpty {
                                            Text("อาการ/โรค: \(victim.medicalNotes)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.red.opacity(0.85))
                                        }
                                    }
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.08))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            // Additional Notes
            if !report.additionalNotes.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(report.additionalNotes)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Rescuer & Beacon Actions
            HStack(spacing: 8) {
                Button(action: {
                    isAcknowledged.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isAcknowledged ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isAcknowledged ? .green : .secondary)
                        Text(isAcknowledged ? "รับเรื่องช่วยเหลือแล้ว" : "กู้ภัยกดรับเรื่อง")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    showFullscreenBeacon = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text("เปิดไฟส่งสัญญาณ")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgencyColor.opacity(0.8), lineWidth: 1.5)
        )
        .sheet(isPresented: $showFullscreenBeacon) {
            FullscreenEmergencyBeaconView(report: report)
        }
    }
    
    private var cardBackgroundColor: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Fullscreen Emergency Beacon View

public struct FullscreenEmergencyBeaconView: View {
    public let report: DisasterTriageReport
    @Environment(\.dismiss) private var dismiss
    @State private var isFlashing = false
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text(report.universalShortCode)
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .foregroundColor(isFlashing ? .red : .yellow)
                        .multilineTextAlignment(.center)
                    
                    Text(report.floorPosition.thaiTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(report.victimSummaryDescription)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("น้ำ: \(report.waterLevel.thaiTitle)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                .padding()
                
                Spacer()
                
                Text("แสดงหน้าจอนี้ไปทางเรือกู้ภัยหรือเฮลิคอปเตอร์")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isFlashing = true
            }
        }
    }
}
