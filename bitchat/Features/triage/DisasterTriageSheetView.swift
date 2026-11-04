//
// DisasterTriageSheetView.swift
// bitchat
//
// Modern, accessible disaster triage sheet for composing structured SOS beacons.
// Fully wired with Thai language, Citizen ID validation, and interactive victim lists.
//
// This is free and unencumbered software released into the public domain.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public struct DisasterTriageSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Form State
    @State private var floorPosition: FloorPosition = .secondFloor
    @State private var waterLevel: WaterLevel = .waist
    @State private var urgency: EmergencyUrgency = .urgent
    @State private var selectedSupplies: Set<SupplyNeed> = [.water, .food]
    @State private var victims: [VictimRecord] = []
    @State private var additionalNotes: String = ""
    @State private var districtName: String = "อำเภอเมือง"
    
    // New Victim Input State
    @State private var newVictimName: String = ""
    @State private var newVictimCitizenID: String = ""
    @State private var newVictimCategory: VictimCategory = .adult
    @State private var newVictimNotes: String = ""
    @State private var showAddVictimForm = false
    
    // Callback when SOS is triggered
    public let onSendSOS: (String) -> Void
    
    public init(onSendSOS: @escaping (String) -> Void) {
        self.onSendSOS = onSendSOS
    }
    
    private var currentReport: DisasterTriageReport {
        DisasterTriageReport(
            floorPosition: floorPosition,
            waterLevel: waterLevel,
            urgency: urgency,
            supplies: Array(selectedSupplies),
            victims: victims,
            additionalNotes: additionalNotes,
            districtName: districtName
        )
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Banner with Live Shortcode
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "shield.righthalf.filled")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            Text("ระบบส่งสัญญาณกู้ภัยฉุกเฉิน (Disaster SOS)")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        
                        Text("ข้อมูลจะถูกบีบอัดเป็นรหัสย่อสากล และยิงผ่านโครงข่ายวิทยุ BLE โดยไม่ต้องใช้อินเทอร์เน็ต")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("รหัสย่อสากล:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(currentReport.universalShortCode)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(4)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                    
                    // Section 1: Urgency & Situation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. ระดับความเร่งด่วน (Triage Level)")
                            .font(.system(size: 14, weight: .bold))
                        
                        Picker("ความเร่งด่วน", selection: $urgency) {
                            ForEach(EmergencyUrgency.allCases) { u in
                                Text(u.thaiTitle).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Section 2: Location and Water Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("2. ตำแหน่งที่อยู่และระดับน้ำ")
                            .font(.system(size: 14, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ตำแหน่งที่ติดอยู่:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(FloorPosition.allCases) { pos in
                                    Button(action: { floorPosition = pos }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: pos.systemIcon)
                                                .font(.system(size: 12))
                                            Text(pos.thaiTitle)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(floorPosition == pos ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.08))
                                        .foregroundColor(floorPosition == pos ? .blue : .primary)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(floorPosition == pos ? Color.blue : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ระดับความสูงของน้ำ:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Picker("ระดับน้ำ", selection: $waterLevel) {
                                ForEach(WaterLevel.allCases) { wl in
                                    Text(wl.thaiTitle).tag(wl)
                                }
                            }
                            #if os(macOS)
                            .pickerStyle(.menu)
                            #else
                            .pickerStyle(.menu)
                            #endif
                            .padding(.vertical, 2)
                        }
                    }
                    
                    // Section 3: Needed Supplies
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. สิ่งของหรือความช่วยเหลือที่ต้องการด่วน")
                            .font(.system(size: 14, weight: .bold))
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(SupplyNeed.allCases) { need in
                                let isSelected = selectedSupplies.contains(need)
                                Button(action: {
                                    if isSelected {
                                        selectedSupplies.remove(need)
                                    } else {
                                        selectedSupplies.insert(need)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : need.systemIcon)
                                            .font(.system(size: 12))
                                            .foregroundColor(isSelected ? .orange : .secondary)
                                        Text(need.thaiTitle)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.orange.opacity(0.18) : Color.secondary.opacity(0.08))
                                    .foregroundColor(isSelected ? .orange : .primary)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Section 4: Individual Victims & Citizen ID
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("4. รายชื่อและเลขบัตรประชาชนผู้ประสบภัย")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text("(\(victims.count) คน)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("กู้ภัยและแพทย์จะใช้เลขบัตรประชาชนในการค้นหาประวัติการรักษาและติดต่อญาติ")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        // List of already added victims
                        ForEach(victims) { victim in
                            HStack(spacing: 8) {
                                Image(systemName: victim.category.systemIcon)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(victim.fullName.isEmpty ? "ผู้ประสบภัย" : victim.fullName)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("(\(victim.category.thaiTitle))")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    if !victim.citizenID.isEmpty {
                                        Text("เลข ปชช: \(victim.formattedCitizenID)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    if !victim.medicalNotes.isEmpty {
                                        Text("โรค/ยา: \(victim.medicalNotes)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    victims.removeAll { $0.id == victim.id }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.06))
                            .cornerRadius(8)
                        }
                        
                        // Add Victim Form Trigger
                        if !showAddVictimForm {
                            Button(action: { showAddVictimForm = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("เพิ่มรายชื่อบุคคล / สมาชิกในบ้าน")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Inline Add Victim Card
                            VStack(alignment: .leading, spacing: 10) {
                                Text("เพิ่มข้อมูลบุคคล:")
                                    .font(.system(size: 12, weight: .bold))
                                
                                TextField("ชื่อ-นามสกุล หรือชื่อเล่น", text: $newVictimName)
                                    .textFieldStyle(.roundedBorder)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    TextField("เลขประจำตัวประชาชน 13 หลัก", text: $newVictimCitizenID)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: newVictimCitizenID) { newValue in
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count <= 13 {
                                                newVictimCitizenID = filtered
                                            } else {
                                                newVictimCitizenID = String(filtered.prefix(13))
                                            }
                                        }
                                    
                                    if !newVictimCitizenID.isEmpty {
                                        let formatted = ThaiCitizenIDValidator.format(newVictimCitizenID)
                                        let isValid = ThaiCitizenIDValidator.isValid(newVictimCitizenID)
                                        HStack(spacing: 4) {
                                            Text(formatted)
                                                .font(.system(size: 10, design: .monospaced))
                                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle")
                                                .font(.system(size: 10))
                                                .foregroundColor(isValid ? .green : .orange)
                                            Text(isValid ? "เลขบัตรถูกต้อง" : "(ยังไม่ครบ 13 หลัก หรือเลขไม่ตรง)")
                                                .font(.system(size: 10))
                                                .foregroundColor(isValid ? .green : .secondary)
                                        }
                                    }
                                }
                                
                                Picker("กลุ่มบุคคล", selection: $newVictimCategory) {
                                    ForEach(VictimCategory.allCases) { cat in
                                        Text(cat.thaiTitle).tag(cat)
                                    }
                                }
                                
                                TextField("โรคประจำตัว / ยาที่ต้องใช้ (ถ้ามี)", text: $newVictimNotes)
                                    .textFieldStyle(.roundedBorder)
                                
                                HStack(spacing: 12) {
                                    Button("ยกเลิก") {
                                        showAddVictimForm = false
                                        resetNewVictimFields()
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Spacer()
                                    
                                    Button("บันทึกบุคคลนี้") {
                                        let newRecord = VictimRecord(
                                            fullName: newVictimName.trimmingCharacters(in: .whitespaces),
                                            citizenID: newVictimCitizenID,
                                            category: newVictimCategory,
                                            medicalNotes: newVictimNotes.trimmingCharacters(in: .whitespaces)
                                        )
                                        victims.append(newRecord)
                                        showAddVictimForm = false
                                        resetNewVictimFields()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.top, 4)
                            }
                            .padding(12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Section 5: Additional Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("5. จุดสังเกตหรือข้อมูลเพิ่มเติม")
                            .font(.system(size: 14, weight: .bold))
                        
                        TextField("เช่น บ้านหลังคาสีฟ้า, ติดอยู่รวมกับเพื่อนบ้าน ฯลฯ", text: $additionalNotes)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Submit Button
                    Button(action: {
                        let encoded = DisasterTriageCodec.encode(currentReport)
                        onSendSOS(encoded)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.system(size: 16, weight: .bold))
                            Text("ยิงสัญญาณขอความช่วยเหลือ (Broadcast SOS)")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(color: Color.red.opacity(0.4), radius: 5, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("แจ้งเหตุฉุกเฉิน / กู้ภัยน้ำท่วม")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ปิด") { dismiss() }
                }
            }
        }
    }
    
    private func resetNewVictimFields() {
        newVictimName = ""
        newVictimCitizenID = ""
        newVictimCategory = .adult
        newVictimNotes = ""
    }
}

