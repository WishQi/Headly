import Foundation

@main
struct ModelChecks {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("headly-model-checks-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ name: String) {
            if !condition() { print("FAIL \(name)"); exit(1) }
            passed += 1; print("PASS \(name)")
        }
        func mustThrow(_ name: String, _ action: () throws -> Void) {
            do { try action(); print("FAIL \(name): did not throw"); exit(1) }
            catch { passed += 1; print("PASS \(name)") }
        }
        let iso = ISO8601DateFormatter()
        func date(_ value: String) -> Date { iso.date(from: value)! }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        let now = date("2026-10-03T20:00:00+08:00")
        let url = directory.appendingPathComponent("records.json")
        let store = HeadacheStore(fileURL: url)
        check(store.records.isEmpty && !store.isReadOnly, "first launch is empty")
        var first = HeadacheRecord(startedAt: date("2026-10-03T18:00:00+08:00"), intensity: 4, location: "左侧", notes: "第一行，中文\n第二行")
        try store.save(first, now: now)
        let reopened = HeadacheStore(fileURL: url)
        check(reopened.records.count == 1 && reopened.ongoing?.id == first.id, "save and reload retains ongoing identity")
        var second = HeadacheRecord(startedAt: date("2026-10-03T19:00:00+08:00"), intensity: 6)
        mustThrow("second ongoing rejected") { try store.save(second, now: now) }
        check(store.records.count == 1, "invalid save leaves records unchanged")
        second.endedAt = date("2026-10-03T19:30:00+08:00")
        try store.save(second, now: now)
        check(store.records.count == 2, "completed overlapping backfill allowed")
        try store.finish(first, at: now)
        check(store.ongoing == nil && store.records.first(where: {$0.id == first.id})?.duration() == 7200, "finish updates same record with exact duration")
        first.endedAt = now; first.notes = "=SUM(1,2)\n中文，\"引号\""; first.intensity = 5
        let originalCreated = first.createdAt
        try store.save(first, now: now)
        let edited = HeadacheStore(fileURL: url).records.first(where: { $0.id == first.id })!
        check(edited.notes == first.notes && edited.createdAt == originalCreated && edited.intensity == 5, "editing retains identity creation time and multiline text")
        let export = try store.exportCSV(directory: directory)
        let csv = try String(contentsOf: export, encoding: .utf8)
        let csvBytes = try Data(contentsOf: export)
        check(csvBytes.starts(with: [0xEF, 0xBB, 0xBF]) && csv.contains("'="), "CSV UTF8 BOM and formula prefix neutralization")
        check(csv.contains("\"\"引号\"\"") && csv.contains("中文"), "CSV quotes and Chinese text retained")
        try? FileManager.default.removeItem(at: export)
        var invalid = first; invalid.intensity = 0
        mustThrow("zero intensity rejected") { try store.save(invalid, now: now) }
        invalid = first; invalid.startedAt = now.addingTimeInterval(60)
        mustThrow("future start rejected") { try store.save(invalid, now: now) }
        invalid = first; invalid.endedAt = first.startedAt
        mustThrow("zero or negative duration rejected") { try store.save(invalid, now: now) }
        invalid = first; invalid.endedAt = now.addingTimeInterval(60)
        mustThrow("future end rejected") { try store.save(invalid, now: now) }
        invalid = first; invalid.notes = String(repeating: "记", count: 501)
        mustThrow("notes length validated") { try store.save(invalid, now: now) }
        let cross = HeadacheRecord(startedAt: date("2026-09-30T23:30:00+08:00"), endedAt: date("2026-10-01T00:30:00+08:00"), intensity: 6, factors: ["压力", "压力"])
        let midnight = HeadacheRecord(startedAt: date("2026-10-01T23:00:00+08:00"), endedAt: date("2026-10-02T00:00:00+08:00"), intensity: 2)
        let sameDay = HeadacheRecord(startedAt: date("2026-10-01T14:00:00+08:00"), endedAt: date("2026-10-01T15:00:00+08:00"), intensity: 4)
        let october = DateInterval(start: date("2026-10-01T00:00:00+08:00"), end: date("2026-11-01T00:00:00+08:00"))
        let stats = RecordStatistics(records: [cross, midnight, sameDay], interval: october, calendar: calendar, now: now)
        check(stats.included.count == 3 && stats.recordedDays == 1, "cross month overlap midnight exclusion and day deduplication")
        check(stats.averageIntensity == 4 && stats.averageDuration == 3600, "unweighted intensity and full completed duration")
        check(stats.factorCounts.first?.1 == 1, "factors deduplicated within a record")
        let pending = HeadacheRecord(startedAt: date("2026-10-02T12:00:00+08:00"), intensity: 8)
        let pendingStats = RecordStatistics(records: [pending], interval: october, calendar: calendar, now: now)
        check(pendingStats.averageDuration == nil && pendingStats.recordedDays == 2, "ongoing excluded from average duration includes covered dates")
        let emptyStats = RecordStatistics(records: [], interval: october, calendar: calendar, now: now)
        check(emptyStats.recordedDays == 0 && emptyStats.averageIntensity == nil && emptyStats.averageDuration == nil, "empty samples use unknown values")
        try store.delete(first)
        check(HeadacheStore(fileURL: url).records.count == 1, "delete persists across reload")
        try store.clear()
        check(HeadacheStore(fileURL: url).records.isEmpty, "clear persists empty state")
        try store.addDemo(now: now, calendar: calendar)
        check(store.records.count == 5 && store.records.allSatisfy(\.isDemo), "demo explicit and labeled")
        try store.addDemo(now: now, calendar: calendar)
        check(store.records.count == 5, "demo cannot overwrite or duplicate existing records")
        let corruptURL = directory.appendingPathComponent("corrupt.json")
        let corruptBytes = Data("broken JSON".utf8)
        try corruptBytes.write(to: corruptURL)
        let corruptStore = HeadacheStore(fileURL: corruptURL)
        check(corruptStore.isReadOnly && corruptStore.errorMessage != nil, "corrupt file enters protected state")
        mustThrow("corrupt store refuses write") { try corruptStore.clear() }
        let retainedBytes = try Data(contentsOf: corruptURL)
        check(retainedBytes == corruptBytes, "corrupt original bytes preserved")
        let schemaURL = directory.appendingPathComponent("future.json")
        try Data("{\"schemaVersion\":2,\"records\":[]}".utf8).write(to: schemaURL)
        check(HeadacheStore(fileURL: schemaURL).isReadOnly, "unknown schema protected")
        let unavailable = HeadacheStore(fileURL: URL(fileURLWithPath: "/dev/null/headly-records.json"))
        mustThrow("filesystem write failure surfaced") { try unavailable.save(second, now: now) }
        check(unavailable.records.isEmpty, "write failure does not change memory")
        var draft = RecordDraft(now: now, calendar: calendar)
        check(!draft.hasChanges && draft.record.intensity == 0 && draft.value.isOngoing, "new draft starts clean without a preselected intensity")
        draft.end = now.addingTimeInterval(-60)
        check(!draft.hasChanges, "hidden end time does not dirty an ongoing draft")
        draft.ongoing = false
        check(draft.hasChanges, "completed state dirties the draft")
        draft.ongoing = true
        check(!draft.hasChanges, "restoring the original state clears draft changes")
        var editing = RecordDraft(existing: first, now: now, calendar: calendar)
        check(!editing.hasChanges && editing.value == first && editing.isEditing, "editing initializes every field and identity from the original")
        editing.record.notes = "修改后的备注"
        check(editing.hasChanges && editing.value.id == first.id && editing.value.createdAt == first.createdAt, "editing detects changes without changing identity")
        editing.record.notes = first.notes
        check(!editing.hasChanges, "restoring edited text returns to a clean draft")
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        let dstDay = date("2026-03-08T00:00:00-05:00")
        let nextDay = date("2026-03-09T18:00:00-04:00")
        let backfill = RecordDraft(initialDate: dstDay, now: nextDay, calendar: ny)
        check(ny.component(.hour, from: backfill.value.startedAt) == 12 && ny.component(.hour, from: backfill.value.endedAt!) == 13 && !backfill.hasChanges, "DST backfill uses local noon and 13:00")
        let demoStore = HeadacheStore(fileURL: directory.appendingPathComponent("dst-demo.json"))
        try demoStore.addDemo(now: nextDay, calendar: ny)
        check(demoStore.records.allSatisfy { ny.component(.hour, from: $0.startedAt) == 14 }, "demo times remain at 14:00 across DST")
        print("RESULT \(passed) checks passed")
    }
}
