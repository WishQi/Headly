import SwiftUI

struct RecordEditor: View {
    let store: HeadacheStore
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: RecordDraft
    @State private var expanded: Bool
    @State private var error: String?
    @State private var discard = false

    init(store: HeadacheStore, existing: HeadacheRecord? = nil, initialDate: Date? = nil, onSaved: @escaping () -> Void) {
        self.store = store
        self.onSaved = onSaved
        let draft = RecordDraft(existing: existing, initialDate: initialDate)
        _draft = State(initialValue: draft)
        let record = draft.record
        _expanded = State(initialValue: !record.symptoms.isEmpty || !record.factors.isEmpty || !record.relief.isEmpty || !record.notes.isEmpty || !record.medication.isEmpty)
    }

    private var location: Binding<[String]> {
        Binding(get: { draft.record.location == "未选择" ? [] : [draft.record.location] },
                set: { draft.record.location = $0.first ?? "未选择" })
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(!draft.isEditing ? "记录一次头痛" : "编辑这次记录").font(.system(.title2, design: .serif))
                    Text("先记下来，细节可以以后补充。")
                        .font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
                }
                Spacer()
                Button { if draft.hasChanges { discard = true } else { dismiss() } } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .medium)).frame(width: 44, height: 44)
                        .background(HeadlyTheme.line.opacity(0.6), in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("关闭记录")
            }.padding(24)
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    intensityPicker
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "哪里不舒服", subtitle: "选填")
                        ChipGroup(options: ["左侧", "右侧", "双侧", "额头", "后脑", "整个头部"], selected: location, single: true)
                    }
                    VStack(spacing: 14) {
                        DatePicker("开始时间", selection: $draft.record.startedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .font(.system(.subheadline)).tint(HeadlyTheme.forest)
                        Divider().overlay(HeadlyTheme.line)
                        Toggle("仍在头痛", isOn: $draft.ongoing).font(.system(.subheadline)).tint(HeadlyTheme.forest)
                        if !draft.ongoing {
                            DatePicker("结束时间", selection: $draft.end, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                .font(.system(.subheadline)).tint(HeadlyTheme.forest)
                        }
                    }.paperCard(18)
                    Button { withAnimation { expanded.toggle() } } label: {
                        HStack {
                            Image(systemName: "text.alignleft")
                            Text(expanded ? "收起更多细节" : "补充更多细节")
                            Spacer(); Text("选填").font(.system(.caption)); Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        }.font(.system(.subheadline)).foregroundStyle(HeadlyTheme.muted).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                    if expanded {
                        extra(title: "伴随症状", options: ["畏光", "怕声音", "恶心", "眩晕", "视觉异常", "其他"], selection: $draft.record.symptoms)
                        extra(title: "可能相关因素", options: ["睡眠不足", "压力", "久看屏幕", "饮食变化", "生理期", "不确定"], selection: $draft.record.factors)
                        extra(title: "尝试过的缓解方式", options: ["休息", "喝水", "冷敷", "用药", "其他"], selection: $draft.record.relief)
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeading(title: "用药记录", subtitle: "选填")
                            TextField("药名、剂量及服用时间", text: $draft.record.medication, axis: .vertical)
                                .font(.system(.subheadline)).lineLimit(2...4).padding(16).background(HeadlyTheme.paper, in: RoundedRectangle(cornerRadius: 14))
                            Text("仅记录已使用的药物，不提供用药建议。")
                                .font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeading(title: "想补充的话", subtitle: "\(draft.record.notes.count) / 500")
                            TextField("当时在做什么，有什么感受……", text: $draft.record.notes, axis: .vertical)
                                .font(.system(.subheadline)).lineLimit(3...6).padding(16).background(HeadlyTheme.paper, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    if let error { Text(error).font(.system(.subheadline)).foregroundStyle(HeadlyTheme.rose).accessibilityLabel("保存失败：\(error)") }
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: "info.circle")
                        Text("突然出现的剧烈头痛，或伴随无力、言语或视力异常，请及时寻求医疗帮助。")
                    }.font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted).lineSpacing(3)
                }.padding(.horizontal, 24).padding(.bottom, 20)
            }.scrollDismissesKeyboard(.interactively)
        }.foregroundStyle(HeadlyTheme.ink).background(HeadlyTheme.background)
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: !draft.isEditing ? "保存这次记录" : "保存修改", symbol: "checkmark", disabled: draft.record.intensity == 0 || store.isReadOnly) { save() }
                    .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8).background(HeadlyTheme.background)
            }
            .interactiveDismissDisabled(draft.hasChanges)
            .confirmationDialog("放弃这次修改？", isPresented: $discard, titleVisibility: .visible) {
                Button("放弃修改", role: .destructive) { dismiss() }; Button("继续编辑", role: .cancel) { }
            }
    }
    private var intensityPicker: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading(title: "疼痛有多强", subtitle: "必填")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(draft.record.intensity == 0 ? "—" : "\(draft.record.intensity)").font(.system(size: 64, weight: .regular, design: .serif))
                Text("/ 10").font(.system(.subheadline)).foregroundStyle(HeadlyTheme.muted)
                Spacer()
                Text(draft.record.intensity == 0 ? "请选择强度" : draft.record.intensity <= 3 ? "轻度 · 可以正常活动" : draft.record.intensity <= 6 ? "中度 · 影响日常活动" : "重度 · 难以正常活动")
                    .font(.system(.caption)).foregroundStyle(HeadlyTheme.muted).multilineTextAlignment(.trailing)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 5), spacing: 8) {
                ForEach(1...10, id: \.self) { value in
                    Button { draft.record.intensity = value } label: {
                        Text("\(value)").font(.system(.body, weight: draft.record.intensity == value ? .semibold : .regular))
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .foregroundStyle(draft.record.intensity == value ? HeadlyTheme.paper : HeadlyTheme.ink)
                            .background(draft.record.intensity == value ? HeadlyTheme.forest : HeadlyTheme.paper, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(draft.record.intensity == value ? .clear : HeadlyTheme.line, lineWidth: 1))
                    }.buttonStyle(.plain).accessibilityLabel("疼痛强度 \(value) / 10").accessibilityAddTraits(draft.record.intensity == value ? .isSelected : [])
                }
            }
            HStack { Text("1 轻微"); Spacer(); Text("10 最强") }.font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
        }
    }
    private func extra(title: String, options: [String], selection: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 12) { SectionHeading(title: title, subtitle: "可多选"); ChipGroup(options: options, selected: selection) }
    }
    private func save() {
        do { try store.save(draft.value); onSaved(); dismiss() }
        catch { self.error = error.localizedDescription }
    }
}
