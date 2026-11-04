//
// DisasterBeaconMainView.swift
// bitchat
//
// A dedicated, tap-to-report offline disaster beacon and rescue radar dashboard.
// Replaces conversational chat with an ultra-granular button questionnaire and triage board.
//
// This is free and unencumbered software released into the public domain.
//

import SwiftUI
import BitFoundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct DisasterBeaconMainView: View {
    @EnvironmentObject private var conversationUIModel: ConversationUIModel
    @EnvironmentObject private var publicChatModel: PublicChatModel
    @ObservedObject private var gpsManager = DisasterGPSManager.shared
    
    // Tab Mode: 0 = Victim SOS Beacon, 1 = Rescuer Radar
    @State private var selectedTab = 0
    
    // Alert State
    @State private var showGPSRequiredAlert = false
    @State private var showSentSuccessAlert = false
    
    // MARK: - Form State for Questionnaire
    @State private var floorPosition: FloorPosition = .secondFloor
    @State private var waterLevel: WaterLevel = .waist
    @State private var waterTrend: WaterTrend = .slowlyRising
    @State private var selectedThreats: Set<EnvironmentalThreat> = []
    @State private var selectedVulnerabilities: Set<VulnerabilityFlag> = []
    @State private var totalPeople: Int = 1
    @State private var waterSupply: WaterSupplyRemaining = .lessThan1Day
    @State private var foodSupply: FoodSupplyRemaining = .oneToTwoMeals
    @State private var batteryStatus: BatteryPowerStatus = .medium
    @State private var primaryRequest: PrimaryRescueRequest = .boatEvac
    @State private var victims: [VictimRecord] = []
    @State private var additionalNotes: String = ""
    
    // Add Person Form State
    @State private var showAddPersonDialog = false
    @State private var tempPersonName = ""
    @State private var tempPersonCitizenID = ""
    @State private var tempPersonCategory: VictimCategory = .adult
    @State private var tempPersonNotes = ""
    
    // Beacon Broadcast State
    @State private var isBeaconActive = false
    @State private var lastBroadcastTimestamp: Date?
    @State private var showSuccessBanner = false
    
    public init() {}
    
    private var currentReport: DisasterTriageReport {
        var report = DisasterTriageReport(
            floorPosition: floorPosition,
            waterLevel: waterLevel,
            waterTrend: waterTrend,
            environmentalThreats: Array(selectedThreats),
            vulnerabilityFlags: Array(selectedVulnerabilities),
            waterSupply: waterSupply,
            foodSupply: foodSupply,
            batteryStatus: batteryStatus,
            primaryRequest: primaryRequest,
            supplies: [.water, .food],
            victims: victims,
            totalPeopleCount: totalPeople,
            additionalNotes: additionalNotes,
            districtName: "อำเภอเมือง",
            latitude: gpsManager.latitude,
            longitude: gpsManager.longitude,
            gpsAccuracyMeters: gpsManager.accuracyMeters
        )
        report.urgency = report.resolvedUrgency
        return report
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Navigation & Mode Switcher
            topHeaderBar
            
            // Main Content Area
            if selectedTab == 0 {
                victimQuestionnaireView
            } else {
                rescuerRadarView
            }
        }
        .background(windowBgColor)
    }
    
    private var windowBgColor: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    private var controlBgColor: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
    
    // MARK: - Top Header Bar
    
    private var topHeaderBar: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.righthalf.filled")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                    Text("ระบบกู้ภัยฉุกเฉินไร้สาย")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Spacer()
                
                if isBeaconActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("กำลังยิงสัญญาณ")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Tab Switcher
            Picker("โหมดการทำงาน", selection: $selectedTab) {
                Text("รายงานขอความช่วยเหลือ (SOS)").tag(0)
                Text("เรดาร์ตรวจหาสัญญาณ (RADAR)").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
        }
        .background(controlBgColor)
    }
    
    // MARK: - Tab 0: Victim Detailed Questionnaire
    
    private var victimQuestionnaireView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Live Triage Risk Banner
                triageAssessmentBanner
                
                // Group 1: Water & Position
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "1. สภาพน้ำและตำแหน่งในอาคาร", icon: "water.waves")
                    
                    Text("ตำแหน่งที่ติดอยู่:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    chipGrid(FloorPosition.allCases, selected: floorPosition) { floorPosition = $0 }
                    
                    Text("ระดับความสูงของน้ำ:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    chipGrid(WaterLevel.allCases, selected: waterLevel) { waterLevel = $0 }
                    
                    Text("แนวโน้มของน้ำ:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    chipGrid(WaterTrend.allCases, selected: waterTrend) { waterTrend = $0 }
                    
                    Text("อันตรายเฉพาะหน้า (เลือกได้หลายข้อ):")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    multiSelectChipGrid(EnvironmentalThreat.allCases, selectedSet: $selectedThreats)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
                
                // Group 2: Population & Vulnerabilities
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "2. การคัดกรองประชากรและกลุ่มเปราะบาง", icon: "person.2.fill")
                    
                    HStack {
                        Text("จำนวนผู้ประสบภัยทั้งหมด:")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { if totalPeople > 1 { totalPeople -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(totalPeople) คน")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                            
                            Button(action: { totalPeople += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Text("กลุ่มเปราะบางและอาการวิกฤต (แตะเลือกตามจริง):")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    multiSelectChipGrid(VulnerabilityFlag.allCases, selectedSet: $selectedVulnerabilities)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
                
                // Group 3: Resources & Supplies
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "3. เสบียงและพลังงานคงเหลือ", icon: "battery.50")
                    
                    Text("น้ำดื่มสะอาดคงเหลือ:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    chipGrid(WaterSupplyRemaining.allCases, selected: waterSupply) { waterSupply = $0 }
                    
                    Text("อาหารคงเหลือ:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    chipGrid(FoodSupplyRemaining.allCases, selected: foodSupply) { foodSupply = $0 }
                    
                    Text("แบตเตอรี่โทรศัพท์:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    chipGrid(BatteryPowerStatus.allCases, selected: batteryStatus) { batteryStatus = $0 }
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
                
                // Group 4: Primary Rescue Request
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "4. ความช่วยเหลือที่ต้องการด่วนที่สุด (อันดับ 1)", icon: "star.fill")
                    
                    chipGrid(PrimaryRescueRequest.allCases, selected: primaryRequest) { primaryRequest = $0 }
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
                
                // Group 5: Citizen IDs & Per-Person Details
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionHeader(title: "5. รายชื่อและเลขบัตรประชาชน 13 หลัก", icon: "person.crop.rectangle.fill")
                        Spacer()
                        Text("(\(victims.count) คน)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(victims) { victim in
                        HStack(spacing: 8) {
                            Image(systemName: victim.category.systemIcon)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(victim.fullName.isEmpty ? "ผู้ประสบภัย" : victim.fullName)
                                    .font(.system(size: 13, weight: .semibold))
                                if !victim.citizenID.isEmpty {
                                    Text("เลข ปชช: \(victim.formattedCitizenID)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button(action: { victims.removeAll { $0.id == victim.id } }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(6)
                    }
                    
                    Button(action: { showAddPersonDialog = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("เพิ่มข้อมูลบุคคล / เลขบัตรประชาชน")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
                
                // Group 6: Additional Notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("จุดสังเกตเพิ่มเติม:")
                        .font(.system(size: 12, weight: .bold))
                    TextField("เช่น บ้านทาสีชมพู หลังคาปั้นหยา มีเสาอากาศ", text: $additionalNotes)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                
                // Group 7: Mandatory GPS Acquisition (Battery-Conscious One-Shot Fix)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location.north.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(gpsManager.hasValidGPSFix ? .green : .orange)
                            Text("พิกัดดาวเทียม GPS (จำเป็นต้องมีเพื่อส่งกู้ภัย)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Spacer()
                        if gpsManager.hasValidGPSFix {
                            Text("พร้อมส่ง")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("ยังไม่มีพิกัด")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if let lat = gpsManager.latitude, let lon = gpsManager.longitude {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "ละติจูด (Lat): %.5f", lat))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text(String(format: "ลองจิจูด (Lon): %.5f", lon))
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                            Spacer()
                            if let acc = gpsManager.accuracyMeters {
                                Text(String(format: "ความแม่นยำ ±%.0f ม.", acc))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                    } else if gpsManager.isLocating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("กำลังเปิดรับสัญญาณดาวเทียม GPS ชั่วคราว...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Text("⚠️ จำเป็นต้องเปิด GPS ชั่วคราวเพื่อให้เรือกู้ภัยนำทางมาหาคุณได้ เมื่อส่งสำเร็จระบบจะแจ้งให้ปิด GPS ได้ทันทีเพื่อประหยัดแบตเตอรี่")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        gpsManager.requestTemporaryGPSFix()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                            Text(gpsManager.hasValidGPSFix ? "กดจับพิกัด GPS ใหม่อีกครั้ง" : "กดเปิดรับพิกัด GPS ชั่วคราว (One-Shot)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(gpsManager.hasValidGPSFix ? .secondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(gpsManager.hasValidGPSFix ? Color.secondary.opacity(0.15) : Color.blue)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(gpsManager.isLocating)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
                
                // Big Action: Broadcast SOS Beacon
                Button(action: broadcastEmergencyBeacon) {
                    HStack(spacing: 8) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 18, weight: .bold))
                        Text(isBeaconActive ? "อัปเดตและยิงสัญญาณขอความช่วยเหลือ (SOS)" : "เปิดสัญญาณขอความช่วยเหลือ (ACTIVATE SOS)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(gpsManager.hasValidGPSFix ? Color.red : Color.gray)
                    .cornerRadius(12)
                    .shadow(color: gpsManager.hasValidGPSFix ? Color.red.opacity(0.4) : Color.clear, radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding()
        }
        .sheet(isPresented: $showAddPersonDialog) {
            addPersonSheet
        }
        .alert("จำเป็นต้องเปิด GPS", isPresented: $showGPSRequiredAlert) {
            Button("เปิดรับพิกัด GPS ทันที") {
                gpsManager.requestTemporaryGPSFix()
            }
            Button("ยกเลิก", role: .cancel) {}
        } message: {
            Text("ระบบกู้ภัยจำเป็นต้องมีพิกัดดาวเทียม ละติจูด/ลองจิจูด เพื่อให้เรือกู้ภัยและโดรนสามารถแล่นตรงมาถึงจุดที่คุณติดค้างอยู่ได้ถูกต้อง\n\nระบบจะเปิด GPS เพียงชั่วครู่เพื่อจับพิกัด จากนั้นจะตัดสัญญาณ GPS ให้อัตโนมัติ")
        }
        .alert("ส่งสัญญาณกู้ภัยเรียบร้อยแล้ว!", isPresented: $showSentSuccessAlert) {
            Button("ไปที่การตั้งค่าเพื่อปิด GPS") {
                SystemSettings.location.open()
            }
            Button("รับทราบ (ปิดหน้าต่าง)", role: .cancel) {}
        } message: {
            Text("พิกัดดาวเทียม: \(gpsManager.formattedCoordinates)\nถูกบันทึกลงในแพ็กเก็ตนำทางและยิงออกสู่อากาศเรียบร้อยแล้ว\n\n💡 คำแนะนำเพื่อประหยัดแบตเตอรี่สูงสุด:\nท่านสามารถปิดระบบ GPS บนอุปกรณ์ของท่านได้เลยในตอนนี้ เนื่องจากระบบได้บันทึกพิกัดไว้แล้ว เพื่อให้โทรศัพท์มีแบตเตอรี่ใช้งานได้ยาวนานที่สุด")
        }
    }
    
    // MARK: - Live Triage Assessment Banner
    
    private var triageAssessmentBanner: some View {
        let report = currentReport
        let score = report.calculatedTriageScore
        let urgency = report.resolvedUrgency
        
        let bannerColor: Color = {
            switch urgency {
            case .critical: return .red
            case .urgent: return .orange
            case .stable: return .green
            }
        }()
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 12))
                    Text(urgency.thaiTitle)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(bannerColor)
                .cornerRadius(6)
                
                Spacer()
                
                Text(String(format: "คะแนนวิกฤต: %.1f / 10", score))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(bannerColor)
            }
            
            HStack {
                Text("รหัสสากล (สำหรับวิทยุ/พ่นหลังคา):")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(report.universalShortCode)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(12)
        .background(bannerColor.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(bannerColor.opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Tab 1: Rescuer Radar View
    
    private var rescuerRadarView: some View {
        let messages = publicChatModel.messages
        let reports = messages.compactMap { msg -> (BitchatMessage, DisasterTriageReport)? in
            if let report = DisasterTriageCodec.decode(from: msg.content) {
                return (msg, report)
            }
            return nil
        }
        .sorted { $0.1.calculatedTriageScore > $1.1.calculatedTriageScore }
        
        return VStack(spacing: 0) {
            HStack {
                Text("เรดาร์ตรวจจับสัญญาณผู้ประสบภัยในรัศมี BLE")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("พบ \(reports.count) จุด")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.06))
            
            if reports.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("กำลังสแกนค้นหาสัญญาณ Beacon ในอากาศ...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("เมื่อเรือกู้ภัยเข้าใกล้บ้านที่มีการส่ง SOS ข้อมูลจะเด้งขึ้นมาทันที")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(reports, id: \.0.id) { pair in
                            let report = pair.1
                            DisasterTriageCardView(report: report)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func broadcastEmergencyBeacon() {
        guard gpsManager.hasValidGPSFix else {
            showGPSRequiredAlert = true
            return
        }
        let encoded = DisasterTriageCodec.encode(currentReport)
        conversationUIModel.sendMessage(encoded)
        isBeaconActive = true
        lastBroadcastTimestamp = Date()
        
        // Immediately stop GPS hardware updates to conserve vital battery power!
        gpsManager.stopGPS()
        
        // Prompt user with notification that coordinates are sent and they can turn off GPS
        showSentSuccessAlert = true
    }
    
    // MARK: - Reusable UI Helper Components
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.red)
            Text(title)
                .font(.system(size: 14, weight: .bold))
        }
    }
    
    private func chipGrid<T: CaseIterable & Identifiable & RawRepresentable>(
        _ items: [T],
        selected: T,
        onSelect: @escaping (T) -> Void
    ) -> some View where T.RawValue == String, T: Hashable {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(items) { item in
                let isChosen = (selected == item)
                Button(action: { onSelect(item) }) {
                    Text(titleForEnum(item))
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(isChosen ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.08))
                        .foregroundColor(isChosen ? .blue : .primary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isChosen ? Color.blue : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func multiSelectChipGrid<T: CaseIterable & Identifiable & Hashable>(
        _ items: [T],
        selectedSet: Binding<Set<T>>
    ) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(items) { item in
                let isChosen = selectedSet.wrappedValue.contains(item)
                Button(action: {
                    if isChosen {
                        selectedSet.wrappedValue.remove(item)
                    } else {
                        selectedSet.wrappedValue.insert(item)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isChosen ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 11))
                            .foregroundColor(isChosen ? .orange : .secondary)
                        Text(titleForMulti(item))
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(isChosen ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.08))
                    .foregroundColor(isChosen ? .orange : .primary)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isChosen ? Color.orange : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func titleForEnum<T>(_ item: T) -> String {
        if let x = item as? FloorPosition { return x.thaiTitle }
        if let x = item as? WaterLevel { return x.thaiTitle }
        if let x = item as? WaterTrend { return x.thaiTitle }
        if let x = item as? WaterSupplyRemaining { return x.thaiTitle }
        if let x = item as? FoodSupplyRemaining { return x.thaiTitle }
        if let x = item as? BatteryPowerStatus { return x.thaiTitle }
        if let x = item as? PrimaryRescueRequest { return x.thaiTitle }
        return ""
    }
    
    private func titleForMulti<T>(_ item: T) -> String {
        if let x = item as? EnvironmentalThreat { return x.thaiTitle }
        if let x = item as? VulnerabilityFlag { return x.thaiTitle }
        return ""
    }
    
    // MARK: - Add Person Sheet
    
    private var addPersonSheet: some View {
        NavigationStack {
            Form {
                Section("ข้อมูลบุคคล") {
                    TextField("ชื่อ-นามสกุล หรือชื่อเล่น", text: $tempPersonName)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("เลขบัตรประชาชน 13 หลัก", text: $tempPersonCitizenID)
                            .onChange(of: tempPersonCitizenID) { val in
                                let digits = val.filter { $0.isNumber }
                                tempPersonCitizenID = String(digits.prefix(13))
                            }
                        
                        if !tempPersonCitizenID.isEmpty {
                            let formatted = ThaiCitizenIDValidator.format(tempPersonCitizenID)
                            let isValid = ThaiCitizenIDValidator.isValid(tempPersonCitizenID)
                            HStack(spacing: 4) {
                                Text(formatted).font(.system(size: 11, design: .monospaced))
                                Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundColor(isValid ? .green : .orange)
                                Text(isValid ? "เลขบัตรถูกต้อง" : "ยังไม่ครบ 13 หลัก")
                                    .font(.system(size: 10))
                                    .foregroundColor(isValid ? .green : .secondary)
                            }
                        }
                    }
                    
                    Picker("ประเภทบุคคล", selection: $tempPersonCategory) {
                        ForEach(VictimCategory.allCases) { cat in
                            Text(cat.thaiTitle).tag(cat)
                        }
                    }
                    
                    TextField("โรคประจำตัว / ยาที่ต้องใช้", text: $tempPersonNotes)
                }
            }
            .navigationTitle("เพิ่มผู้ประสบภัย")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ยกเลิก") { showAddPersonDialog = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("บันทึก") {
                        let record = VictimRecord(
                            fullName: tempPersonName.trimmingCharacters(in: .whitespaces),
                            citizenID: tempPersonCitizenID,
                            category: tempPersonCategory,
                            medicalNotes: tempPersonNotes.trimmingCharacters(in: .whitespaces)
                        )
                        victims.append(record)
                        tempPersonName = ""
                        tempPersonCitizenID = ""
                        tempPersonCategory = .adult
                        tempPersonNotes = ""
                        showAddPersonDialog = false
                    }
                    .disabled(tempPersonName.isEmpty && tempPersonCitizenID.isEmpty)
                }
            }
        }
    }
}
