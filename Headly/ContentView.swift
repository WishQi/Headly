//
//  ContentView.swift
//  Headly
//
//  Created by Maoqi on 2026/5/13.
//

import SwiftUI

struct ContentView: View {
    var store: HeadacheStore
    @State private var tab = 0
    @State private var sheet: Sheet?
    @State private var pendingEdit: HeadacheRecord?
    @State private var toast: Toast?

    private enum Sheet: Identifiable {
        case editor(HeadacheRecord?, Date?)
        case detail(HeadacheRecord)
        case privacy

        var id: String {
            switch self {
            case .editor: return "editor"
            case .detail(let record): return record.id.uuidString
            case .privacy: return "privacy"
            }
        }
    }
    private struct Toast: Identifiable {
        let id = UUID()
        let message: String
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "circle.lefthalf.filled").font(.system(size: 20, weight: .light)).rotationEffect(.degrees(-35))
                Text("Headly").font(.system(size: 25, weight: .medium, design: .serif)).tracking(-1)
                Text("轻记").font(.system(.caption)).foregroundStyle(HeadlyTheme.muted).padding(.leading, 3)
                Spacer()
                Button { sheet = .privacy } label: { Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .regular)).frame(width: 44, height: 44) }
                    .buttonStyle(.plain).accessibilityLabel("记录与隐私")
            }.foregroundStyle(HeadlyTheme.forest).padding(.horizontal, 24).padding(.top, 5).padding(.bottom, 12)
            if store.records.contains(where: \.isDemo) {
                Text("正在浏览虚构演示记录").font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted).padding(.bottom, 8)
            }
            ScrollView {
                if tab == 0 {
                    TodayView(store: store, onNew: { openEditor() }, onDetail: { sheet = .detail($0) }, onReview: { tab = 1 })
                        .padding(.horizontal, 24).padding(.bottom, 20)
                } else {
                    ReviewView(store: store, onNew: { openEditor(date: $0) }, onDetail: { sheet = .detail($0) })
                        .padding(.horizontal, 24).padding(.bottom, 20)
                }
            }.scrollIndicators(.hidden)
        }.background(HeadlyTheme.background)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            .sheet(item: $sheet, onDismiss: presentPendingEdit) { destination in
                Group {
                    switch destination {
                    case .editor(let record, let date):
                        RecordEditor(store: store, existing: record, initialDate: date, onSaved: { notify("记录已保存") })
                    case .detail(let record):
                        RecordDetail(store: store, record: record, onEdit: {
                            pendingEdit = $0
                            sheet = nil
                        }, onChanged: notify)
                    case .privacy:
                        PrivacySettings(store: store, onChanged: notify)
                    }
                }.presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast.message).font(.system(.subheadline)).foregroundStyle(.white).padding(.horizontal, 22).padding(.vertical, 13)
                        .background(HeadlyTheme.forest, in: Capsule()).padding(.bottom, 85).transition(.opacity)
                        .accessibilityLabel(toast.message)
                }
            }
            .task(id: toast?.id) {
                guard toast != nil else { return }
                do { try await Task.sleep(for: .seconds(2)) } catch { return }
                withAnimation { toast = nil }
            }
            .alert("记录暂时无法读取", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("知道了") { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
            .task {
                let arguments = ProcessInfo.processInfo.arguments
                if arguments.contains("--demo") { do { try store.addDemo() } catch { store.errorMessage = error.localizedDescription } }
                if arguments.contains("--review") { tab = 1 }
                if arguments.contains("--record") { openEditor() }
            }
    }
    private var bottomBar: some View {
        HStack(spacing: 0) {
            navItem("今日", icon: "circle.grid.2x2", index: 0)
            Button { openEditor() } label: {
                Image(systemName: "plus").font(.system(size: 23, weight: .light)).foregroundStyle(HeadlyTheme.paper)
                    .frame(width: 52, height: 52).background(HeadlyTheme.forest, in: Circle())
            }.buttonStyle(.plain).accessibilityLabel("新建头痛记录").padding(.horizontal, 28)
            navItem("回顾", icon: "chart.xyaxis.line", index: 1)
        }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 8)
            .background(HeadlyTheme.paper)
            .overlay(alignment: .top) { Rectangle().fill(HeadlyTheme.line.opacity(0.6)).frame(height: 0.5) }
    }
    private func navItem(_ title: String, icon: String, index: Int) -> some View {
        Button { tab = index } label: {
            VStack(spacing: 5) { Image(systemName: icon).font(.system(size: 18, weight: .regular)); Text(title).font(.system(.caption2, weight: tab == index ? .semibold : .regular)) }
                .frame(maxWidth: .infinity).frame(minHeight: 48).foregroundStyle(tab == index ? HeadlyTheme.forest : HeadlyTheme.muted)
        }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : [])
    }
    private func openEditor(record: HeadacheRecord? = nil, date: Date? = nil) {
        sheet = .editor(record, date)
    }
    private func presentPendingEdit() {
        guard let record = pendingEdit else { return }
        pendingEdit = nil
        openEditor(record: record)
    }
    private func notify(_ message: String) {
        withAnimation { toast = Toast(message: message) }
    }
}

#Preview {
    ContentView(store: HeadacheStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("headly-preview.json")))
}
