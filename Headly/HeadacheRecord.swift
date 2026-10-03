import Foundation
import Observation

struct HeadacheRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var startedAt: Date
    var endedAt: Date?
    var intensity: Int
    var location: String = "未选择"
    var symptoms: [String] = []
    var factors: [String] = []
    var relief: [String] = []
    var medication: String = ""
    var notes: String = ""
    var isDemo = false
    var createdAt = Date()
    var updatedAt = Date()
    var isOngoing: Bool { endedAt == nil }
    var intensityLabel: String { intensity <= 3 ? "轻度" : intensity <= 6 ? "中度" : "重度" }
    var title: String { location == "未选择" ? "头痛记录" : "\(location)头痛" }
    func duration(until now: Date = Date()) -> TimeInterval { max(0, (endedAt ?? now).timeIntervalSince(startedAt)) }
    func overlaps(_ interval: DateInterval, now: Date = Date()) -> Bool {
        startedAt < interval.end && (endedAt ?? now) > interval.start && (endedAt ?? now) >= startedAt
    }
}

enum RecordValidationError: LocalizedError {
    case intensity, futureStart, invalidEnd, ongoingExists, notesTooLong, locked, corrupt, schema
    var errorDescription: String? {
        switch self {
        case .intensity: return "请选择 1–10 的疼痛强度。"
        case .futureStart: return "开始时间不能晚于现在。"
        case .invalidEnd: return "结束时间需要晚于开始时间，且不能晚于现在。"
        case .ongoingExists: return "已有一条进行中的记录，请先结束它，或将这次记录设为已结束。"
        case .notesTooLong: return "备注最多 500 字，用药记录最多 200 字。"
        case .locked: return "记录暂时无法读取。为保护已有数据，目前不会覆盖文件。"
        case .corrupt: return "本地记录无法读取。原文件已保留，请勿卸载 App，可重启后再试。"
        case .schema: return "记录来自较新的版本，请更新 App 后再打开。"
        }
    }
}

extension HeadacheRecord {
    enum CodingKeys: String, CodingKey {
        case id, startedAt, endedAt, intensity, location, symptoms, factors, relief, medication, notes, isDemo, createdAt, updatedAt
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt)
        intensity = try c.decode(Int.self, forKey: .intensity)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? "未选择"
        symptoms = try c.decodeIfPresent([String].self, forKey: .symptoms) ?? []
        factors = try c.decodeIfPresent([String].self, forKey: .factors) ?? []
        relief = try c.decodeIfPresent([String].self, forKey: .relief) ?? []
        medication = try c.decodeIfPresent(String.self, forKey: .medication) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isDemo = try c.decodeIfPresent(Bool.self, forKey: .isDemo) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? startedAt
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

struct RecordStatistics {
    let included: [HeadacheRecord]
    let interval: DateInterval
    let calendar: Calendar
    let now: Date

    init(records: [HeadacheRecord], interval: DateInterval, calendar: Calendar = .current, now: Date = Date()) {
        included = records.filter { $0.overlaps(interval, now: now) }
        self.interval = interval
        self.calendar = calendar
        self.now = now
    }
    var averageIntensity: Double? { included.isEmpty ? nil : Double(included.map(\.intensity).reduce(0, +)) / Double(included.count) }
    var averageDuration: TimeInterval? {
        let completed = included.filter { !$0.isOngoing }
        return completed.isEmpty ? nil : completed.map { $0.duration() }.reduce(0, +) / Double(completed.count)
    }
    var recordedDays: Int {
        var result = 0
        var day = calendar.startOfDay(for: interval.start)
        while day < min(interval.end, now) {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            if included.contains(where: { $0.overlaps(DateInterval(start: day, end: next), now: now) }) { result += 1 }
            day = next
        }
        return result
    }
    var factorCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        for record in included { for factor in Set(record.factors) { counts[factor, default: 0] += 1 } }
        return counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.map { ($0.key, $0.value) }
    }
}

struct RecordFile: Codable { var schemaVersion = 1; var records: [HeadacheRecord] }

@Observable
final class HeadacheStore {
    private(set) var records: [HeadacheRecord] = []
    private(set) var isReadOnly = false
    var errorMessage: String?
    let fileURL: URL
    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? base.appendingPathComponent("Headly", isDirectory: true).appendingPathComponent("records-v1.json")
        do {
            if FileManager.default.fileExists(atPath: self.fileURL.path) {
                let decoded = try JSONDecoder().decode(RecordFile.self, from: Data(contentsOf: self.fileURL))
                guard decoded.schemaVersion == 1 else { throw RecordValidationError.schema }
                guard decoded.records.allSatisfy({ (1...10).contains($0.intensity) && ($0.endedAt == nil || $0.endedAt! > $0.startedAt) }), Set(decoded.records.map(\.id)).count == decoded.records.count, decoded.records.filter(\.isOngoing).count <= 1 else { throw RecordValidationError.corrupt }
                records = decoded.records.sorted { $0.startedAt > $1.startedAt }
            }
        } catch {
            isReadOnly = true
            errorMessage = (error as? RecordValidationError)?.errorDescription ?? RecordValidationError.corrupt.errorDescription
        }
    }
    var ongoing: HeadacheRecord? { records.first(where: \.isOngoing) }
    func save(_ record: HeadacheRecord, now: Date = Date()) throws {
        guard !isReadOnly else { throw RecordValidationError.locked }
        guard (1...10).contains(record.intensity) else { throw RecordValidationError.intensity }
        guard record.startedAt <= now else { throw RecordValidationError.futureStart }
        if let end = record.endedAt, end <= record.startedAt || end > now { throw RecordValidationError.invalidEnd }
        guard !record.isOngoing || !records.contains(where: { $0.id != record.id && $0.isOngoing }) else { throw RecordValidationError.ongoingExists }
        guard record.notes.count <= 500, record.medication.count <= 200 else { throw RecordValidationError.notesTooLong }
        var updated = record; updated.updatedAt = now
        var next = records.filter { $0.id != record.id }; next.append(updated)
        try persist(next)
    }
    func finish(_ record: HeadacheRecord, at end: Date = Date()) throws {
        var updated = record; updated.endedAt = end
        try save(updated, now: end)
    }
    func delete(_ record: HeadacheRecord) throws { try persist(records.filter { $0.id != record.id }) }
    func clear() throws { try persist([]) }
    private func persist(_ next: [HeadacheRecord]) throws {
        guard !isReadOnly else { throw RecordValidationError.locked }
        var directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var attributes = URLResourceValues(); attributes.isExcludedFromBackup = true
        try directory.setResourceValues(attributes)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(RecordFile(records: next)).write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        records = next.sorted { $0.startedAt > $1.startedAt }
    }
    func addDemo(now: Date = Date(), calendar: Calendar = .current) throws {
        guard records.isEmpty else { return }
        let base = calendar.startOfDay(for: now)
        let days = [-1, -4, -7, -11, -17], scores = [4, 6, 3, 5, 2], positions = ["左侧", "额头", "右侧", "双侧", "后脑"]
        let demo = days.enumerated().map { index, day in
            let date = calendar.date(byAdding: .day, value: day, to: base)!
            let start = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)!
            return HeadacheRecord(startedAt: start, endedAt: start.addingTimeInterval(Double([90, 150, 45, 120, 60][index]) * 60), intensity: scores[index], location: positions[index], symptoms: index == 1 ? ["畏光"] : [], factors: index % 2 == 0 ? ["睡眠不足"] : ["压力", "久看屏幕"], relief: ["休息"], notes: index == 0 ? "午后工作时开始，休息后缓解。" : "", isDemo: true)
        }
        try persist(demo)
    }
    func exportCSV(directory: URL? = nil) throws -> URL {
        let formatter = ISO8601DateFormatter()
        func cell(_ value: String) -> String {
            var safe = value
            if let first = value.trimmingCharacters(in: .whitespacesAndNewlines).first, "=+-@".contains(first) { safe = "'" + value }
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        var lines = ["ID,开始时间,结束时间,状态,疼痛强度,部位,症状,可能相关因素,缓解方式,用药记录,备注"]
        for record in records {
            let values = [record.id.uuidString, formatter.string(from: record.startedAt), record.endedAt.map { formatter.string(from: $0) } ?? "", record.isOngoing ? "进行中" : "已结束", String(record.intensity), record.location, record.symptoms.joined(separator: "；"), record.factors.joined(separator: "；"), record.relief.joined(separator: "；"), record.medication, record.notes]
            lines.append(values.map(cell).joined(separator: ","))
        }
        let url = (directory ?? FileManager.default.temporaryDirectory).appendingPathComponent("Headly-记录.csv")
        try ("\u{FEFF}" + lines.joined(separator: "\r\n")).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

func durationText(_ seconds: TimeInterval) -> String {
    let minutes = max(1, Int(seconds / 60))
    if minutes < 60 { return "\(minutes) 分钟" }
    let hours = minutes / 60, remainder = minutes % 60
    return remainder == 0 ? "\(hours) 小时" : "\(hours) 小时 \(remainder) 分"
}
