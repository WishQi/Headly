import SwiftUI

struct RecordDetail: View {
    var store: HeadacheStore
    var record: HeadacheRecord
    var onEdit: (HeadacheRecord) -> Void
    var onChanged: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var error: String?
    private var current: HeadacheRecord { store.records.first { $0.id == record.id } ?? record }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 13) {
                        Text(current.isOngoing ? "进行中" : "已结束").font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
                        HStack(alignment: .firstTextBaseline, spacing: 7) {
                            Text("\(current.intensity)").font(.system(size: 64, weight: .regular, design: .serif))
                            Text("/ 10").foregroundStyle(HeadlyTheme.muted); Spacer()
                            Text(current.intensityLabel).font(.system(.subheadline)).foregroundStyle(HeadlyTheme.painColor(current.intensity))
                        }
                        Text(current.title).font(.system(.title2, design: .serif))
                    }.frame(maxWidth: .infinity, alignment: .leading).paperCard()
                    VStack(spacing: 15) {
                        detailRow("开始", value: current.startedAt.formatted(.dateTime.year().month().day().hour().minute()))
                        detailRow("结束", value: current.endedAt?.formatted(.dateTime.year().month().day().hour().minute()) ?? "仍在头痛")
                        detailRow("时长", value: durationText(current.duration()))
                    }.paperCard()
                    if !current.symptoms.isEmpty { section("伴随症状", value: current.symptoms.joined(separator: "、")) }
                    if !current.factors.isEmpty { section("可能相关因素", value: current.factors.joined(separator: "、")) }
                    if !current.relief.isEmpty { section("尝试过的缓解方式", value: current.relief.joined(separator: "、")) }
                    if !current.medication.isEmpty { section("用药记录", value: current.medication) }
                    if !current.notes.isEmpty { section("备注", value: current.notes) }
                    if let error { Text(error).font(.system(.subheadline)).foregroundStyle(HeadlyTheme.rose) }
                    if current.isOngoing {
                        PrimaryButton(title: "现在结束这次头痛", symbol: "checkmark") {
                            do { try store.finish(current); onChanged("已结束，辛苦了。"); dismiss() }
                            catch { self.error = error.localizedDescription }
                        }
                    }
                    Button { onEdit(current) } label: {
                        Label("编辑这条记录", systemImage: "pencil").font(.system(.subheadline)).frame(maxWidth: .infinity).frame(minHeight: 48)
                    }.tint(HeadlyTheme.forest)
                    Button("删除这条记录", role: .destructive) { confirmDelete = true }
                        .font(.system(.caption)).frame(maxWidth: .infinity).frame(minHeight: 44)
                }.padding(24)
            }.background(HeadlyTheme.background).foregroundStyle(HeadlyTheme.ink)
                .navigationTitle("记录详情").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() }.tint(HeadlyTheme.forest) } }
                .confirmationDialog("删除这条记录？此操作无法撤销。", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("删除记录", role: .destructive) {
                        do { try store.delete(current); onChanged("记录已删除"); dismiss() } catch { self.error = error.localizedDescription }
                    }; Button("取消", role: .cancel) { }
                }
        }
    }
    private func detailRow(_ label: String, value: String) -> some View {
        HStack { Text(label).foregroundStyle(HeadlyTheme.muted); Spacer(); Text(value).multilineTextAlignment(.trailing) }.font(.system(.subheadline))
    }
    private func section(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) { SectionHeading(title: title); Text(value).font(.system(.subheadline)).lineSpacing(5) }
            .frame(maxWidth: .infinity, alignment: .leading).paperCard()
    }
}

struct PrivacySettings: View {
    var store: HeadacheStore
    var onChanged: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showClear = false
    @State private var showDemo = false
    @State private var exportURL: URL?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Image(systemName: "lock.shield").font(.system(size: 32, weight: .light))
                        Text("你的记录，\n由你保管。").font(.system(.title, design: .serif)).lineSpacing(5)
                        Text("无需账号，不上传记录。数据保存在这台设备，卸载 App、清除数据或更换设备后不会自动恢复。重要记录请先导出。")
                            .font(.system(.subheadline)).foregroundStyle(HeadlyTheme.muted).lineSpacing(5)
                    }.paperCard()
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "导出记录", subtitle: "CSV")
                        Text("导出文件含有你的健康记录，请自行选择保存或分享的对象。")
                            .font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
                        if let exportURL {
                            ShareLink(item: exportURL) { Label("保存或分享 CSV", systemImage: "square.and.arrow.up").frame(minHeight: 44) }.tint(HeadlyTheme.forest)
                        } else {
                            Button { do { exportURL = try store.exportCSV() } catch { self.error = error.localizedDescription } } label: {
                                Label("生成导出文件", systemImage: "square.and.arrow.up").frame(minHeight: 44)
                            }.tint(HeadlyTheme.forest).disabled(store.records.isEmpty)
                        }
                    }.paperCard()
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "关于健康记录")
                        Text("Headly 帮你记录与回顾，不提供诊断或用药建议。记录里的强度分组用于浏览，不是医学分级。")
                            .font(.system(.subheadline)).foregroundStyle(HeadlyTheme.muted).lineSpacing(5)
                        Text("如果突然出现剧烈头痛，或伴随肢体无力、言语或视力异常，请立即寻求当地医疗帮助。")
                            .font(.system(.caption)).foregroundStyle(HeadlyTheme.muted).lineSpacing(4)
                    }.paperCard()
                    if store.records.isEmpty {
                        Button("加载演示记录") { showDemo = true }.font(.system(.subheadline)).tint(HeadlyTheme.forest).frame(minHeight: 44)
                    }
                    Button("清除所有记录", role: .destructive) { showClear = true }
                        .font(.system(.subheadline)).frame(minHeight: 44).disabled(store.records.isEmpty || store.isReadOnly)
                    if let error { Text(error).font(.system(.subheadline)).foregroundStyle(HeadlyTheme.rose) }
                    Text("Headly 轻记 · 产品原型 1.0").font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
                }.padding(24)
            }.background(HeadlyTheme.background).foregroundStyle(HeadlyTheme.ink)
                .navigationTitle("记录与隐私").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() }.tint(HeadlyTheme.forest) } }
                .confirmationDialog("清除全部 \(store.records.count) 条记录？此操作无法撤销，请先导出。", isPresented: $showClear, titleVisibility: .visible) {
                    Button("清除全部记录", role: .destructive) {
                        do { try store.clear(); onChanged("记录已清除"); dismiss() } catch { self.error = error.localizedDescription }
                    }; Button("取消", role: .cancel) { }
                }
                .confirmationDialog("加载 5 条虚构记录，用于体验界面。", isPresented: $showDemo, titleVisibility: .visible) {
                    Button("加载演示数据") {
                        do { try store.addDemo(); onChanged("已加载演示记录"); dismiss() } catch { self.error = error.localizedDescription }
                    }; Button("取消", role: .cancel) { }
                }
        }
    }
}
