import SwiftUI

struct TodayView: View {
    var store: HeadacheStore
    var onNew: () -> Void
    var onDetail: (HeadacheRecord) -> Void
    var onReview: () -> Void
    private let calendar = Calendar.current
    private var stats: RecordStatistics { RecordStatistics(records: store.records, interval: calendar.dateInterval(of: .month, for: Date())!) }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Date(), format: .dateTime.year().month(.wide).day().weekday(.wide)).font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
                Text("今天，慢一点。")
                    .font(.system(.largeTitle, design: .serif)).foregroundStyle(HeadlyTheme.ink).tracking(-1)
            }.padding(.top, 2)
            hero
            week
            HStack(spacing: 12) {
                metric("本月记录日", value: "\(stats.recordedDays)", unit: "天", icon: "calendar")
                metric("平均强度", value: stats.averageIntensity.map { String(format: "%.1f", $0) } ?? "—", unit: "/ 10", icon: "waveform.path")
            }
            VStack(spacing: 14) {
                HStack {
                    SectionHeading(title: "最近记录")
                    Button(action: onReview) { Text("查看全部").font(.system(.caption)).foregroundStyle(HeadlyTheme.muted).frame(minHeight: 44) }
                }
                if let recent = store.records.first {
                    Button { onDetail(recent) } label: { RecordRow(record: recent).paperCard(16) }.buttonStyle(.plain)
                } else {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("从一条记录开始").font(.system(.subheadline, weight: .medium)).foregroundStyle(HeadlyTheme.ink)
                        Text("不舒服时记一下，其他时间安心生活。")
                            .font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
                    }.frame(maxWidth: .infinity, alignment: .leading).paperCard()
                }
            }
            HStack(spacing: 6) { Image(systemName: "lock.shield"); Text("无需登录，记录只留在这台设备。") }
                .font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted).frame(maxWidth: .infinity).padding(.bottom, 8)
        }
    }
    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle().fill(HeadlyTheme.sage).frame(width: 5, height: 5)
                        Text(store.ongoing == nil ? "为自己留一份记录" : "头痛记录进行中").font(.system(.caption))
                    }.foregroundStyle(HeadlyTheme.sage)
                    if let ongoing = store.ongoing {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(ongoing.intensity)").font(.system(size: 52, weight: .regular, design: .serif))
                            Text("/ 10").font(.system(.subheadline)).foregroundStyle(HeadlyTheme.sage)
                        }
                        Text("\(ongoing.title) · \(durationText(ongoing.duration()))")
                            .font(.system(.caption)).foregroundStyle(HeadlyTheme.sage)
                    } else {
                        Text("让每次不适，\n都有迹可循。")
                            .font(.system(.title2, design: .serif)).lineSpacing(5)
                        Text("选一个强度，就能轻松记下。")
                            .font(.system(.caption)).foregroundStyle(HeadlyTheme.sage)
                    }
                }.foregroundStyle(HeadlyTheme.paper)
                Spacer(minLength: 0)
            }
            if let ongoing = store.ongoing {
                PrimaryButton(title: "查看并结束这次头痛", symbol: "checkmark", light: true) { onDetail(ongoing) }
            } else {
                PrimaryButton(title: "记录此刻的头痛", light: true, action: onNew)
            }
        }.padding(24)
            .background(alignment: .topTrailing) { OrbitArtwork().frame(width: 146, height: 148).offset(x: 38, y: 8) }
            .background(HeadlyTheme.forest, in: RoundedRectangle(cornerRadius: 28))
            .clipShape(RoundedRectangle(cornerRadius: 28))
    }
    private var week: some View {
        VStack(spacing: 16) {
            SectionHeading(title: "这一周", subtitle: "有记录的日子")
            HStack(spacing: 0) {
                ForEach(-6...0, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date()))!
                    let dayRecords = store.records.filter { $0.overlaps(calendar.dateInterval(of: .day, for: date)!) }
                    VStack(spacing: 8) {
                        Text(date, format: .dateTime.weekday(.narrow)).font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
                        Text("\(calendar.component(.day, from: date))").font(.system(.subheadline, weight: offset == 0 ? .semibold : .regular))
                            .frame(width: 32, height: 32).foregroundStyle(offset == 0 ? HeadlyTheme.paper : HeadlyTheme.ink)
                            .background(offset == 0 ? HeadlyTheme.forest : .clear, in: Circle())
                        Circle().fill(dayRecords.isEmpty ? HeadlyTheme.line : HeadlyTheme.painColor(dayRecords.map(\.intensity).max()!)).frame(width: 4, height: 4)
                    }.frame(maxWidth: .infinity)
                        .accessibilityLabel("\(calendar.component(.day, from: date)) 日，\(dayRecords.isEmpty ? "未记录" : "有头痛记录")")
                }
            }
        }.paperCard()
    }
    private func metric(_ title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text(title); Spacer(); Image(systemName: icon) }.font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value).font(.system(.largeTitle, design: .serif)).foregroundStyle(HeadlyTheme.ink)
                Text(unit).font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).paperCard(18)
    }
}

struct ReviewView: View {
    var store: HeadacheStore
    var onNew: (Date?) -> Void
    var onDetail: (HeadacheRecord) -> Void
    @State private var month = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @State private var selectedDay: Date?
    private let calendar = Calendar.current
    private var interval: DateInterval { calendar.dateInterval(of: .month, for: month)! }
    private var stats: RecordStatistics { RecordStatistics(records: store.records, interval: interval) }
    private var visible: [HeadacheRecord] {
        guard let selectedDay else { return stats.included }
        return stats.included.filter { $0.overlaps(calendar.dateInterval(of: .day, for: selectedDay)!) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR PERSONAL PATTERNS").font(.system(.caption2)).tracking(2).foregroundStyle(HeadlyTheme.muted)
                Text("看见自己的节奏").font(.system(.largeTitle, design: .serif)).foregroundStyle(HeadlyTheme.ink).tracking(-1)
            }.padding(.top, 2)
            calendarCard
            HStack(alignment: .top, spacing: 0) {
                summary(value: "\(stats.recordedDays)", label: "记录日", unit: "天")
                summary(value: stats.averageIntensity.map { String(format: "%.1f", $0) } ?? "—", label: "平均强度", unit: "/10")
                summary(value: stats.averageDuration.map { String(format: "%.1f", $0 / 3600) } ?? "—", label: "平均时长", unit: "小时")
            }.paperCard(18)
            Text("仅基于已记录数据；平均时长只统计已结束记录。")
                .font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted).padding(.top, -12)
            VStack(spacing: 10) {
                HStack {
                    SectionHeading(title: selectedDay.map { "\(calendar.component(.day, from: $0)) 日记录" } ?? "本月记录", subtitle: "\(visible.count) 条")
                    if selectedDay != nil { Button("全部") { selectedDay = nil }.font(.system(.caption)).tint(HeadlyTheme.forest).frame(minHeight: 44) }
                }
                if visible.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "leaf").font(.system(size: 25, weight: .light)).foregroundStyle(HeadlyTheme.muted)
                        Text("这里还没有记录").font(.system(.subheadline, weight: .medium))
                        Text("未记录的日子，不代表没有头痛。")
                            .font(.system(.caption)).foregroundStyle(HeadlyTheme.muted)
                        Button("补记一次头痛") { onNew(selectedDay) }.font(.system(.subheadline, weight: .medium)).tint(HeadlyTheme.forest).frame(minHeight: 44)
                    }.frame(maxWidth: .infinity).paperCard()
                } else {
                    VStack(spacing: 0) {
                        ForEach(visible) { record in
                            Button { onDetail(record) } label: { RecordRow(record: record).padding(.vertical, 10) }.buttonStyle(.plain)
                            if record.id != visible.last?.id { Divider().overlay(HeadlyTheme.line) }
                        }
                    }.paperCard(16)
                }
            }
            if !stats.factorCounts.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading(title: "你提到的相关因素", subtitle: "记录次数")
                    ForEach(stats.factorCounts.prefix(3), id: \.0) { factor, count in
                        HStack { Text(factor); Spacer(); Text("\(count) 次").foregroundStyle(HeadlyTheme.muted) }.font(.system(.subheadline))
                    }
                    Text("这些是你的主观记录，不代表因果关系。")
                        .font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
                }.paperCard()
            }
        }
    }
    private var calendarCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(month, format: .dateTime.year().month(.wide)).font(.system(.headline)).foregroundStyle(HeadlyTheme.ink)
                Spacer()
                Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("上个月")
                Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel("下个月")
                    .disabled(calendar.isDate(month, equalTo: Date(), toGranularity: .month))
            }.tint(HeadlyTheme.forest)
            let firstOffset = (calendar.component(.weekday, from: month) + 5) % 7
            let days = calendar.range(of: .day, in: .month, for: month)!.count
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 4) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { Text($0).font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted).frame(height: 24) }
                ForEach(0..<(firstOffset + days), id: \.self) { cell in
                    if cell < firstOffset { Color.clear.frame(height: 44) }
                    else {
                        let date = calendar.date(byAdding: .day, value: cell - firstOffset, to: month)!
                        let dayRecords = store.records.filter { $0.overlaps(calendar.dateInterval(of: .day, for: date)!) }
                        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                        Button { selectedDay = isSelected ? nil : date } label: {
                            VStack(spacing: 3) {
                                Text("\(cell - firstOffset + 1)").font(.system(.subheadline))
                                Circle().fill(dayRecords.isEmpty ? Color.clear : (isSelected ? HeadlyTheme.paper : HeadlyTheme.painColor(dayRecords.map(\.intensity).max()!))).frame(width: 4, height: 4)
                            }.frame(maxWidth: .infinity).frame(height: 44)
                                .foregroundStyle(date > Date() ? HeadlyTheme.line : (isSelected ? HeadlyTheme.paper : HeadlyTheme.ink))
                                .background(isSelected ? HeadlyTheme.forest : dayRecords.isEmpty ? .clear : HeadlyTheme.sage.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(calendar.isDateInToday(date) && !isSelected ? HeadlyTheme.forest.opacity(0.5) : .clear, lineWidth: 1))
                        }.buttonStyle(.plain).disabled(date > Date())
                            .accessibilityLabel("\(cell - firstOffset + 1) 日，\(dayRecords.isEmpty ? "未记录" : "有头痛记录")")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            HStack(spacing: 7) {
                Circle().fill(HeadlyTheme.forest).frame(width: 5, height: 5); Text("有头痛记录")
                Spacer(); Text("空白日期为未记录")
            }.font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
        }.paperCard(18)
    }
    private func move(_ direction: Int) { month = calendar.date(byAdding: .month, value: direction, to: month)!; selectedDay = nil }
    private func summary(value: String, label: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.system(.title, design: .serif)); Text(unit).font(.system(.caption2)).foregroundStyle(HeadlyTheme.muted)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(HeadlyTheme.ink)
    }
}
