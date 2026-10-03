import Foundation

/// Keeps the form's editable record and its original snapshot together.
struct RecordDraft {
    var record: HeadacheRecord
    var end: Date
    var ongoing: Bool
    let isEditing: Bool
    private let original: HeadacheRecord

    init(existing: HeadacheRecord? = nil, initialDate: Date? = nil, now: Date = Date(), calendar: Calendar = .current) {
        var record = existing ?? HeadacheRecord(startedAt: now, intensity: 0)
        if existing == nil, let initialDate, !calendar.isDate(initialDate, inSameDayAs: now) {
            record.startedAt = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: initialDate)!
            record.endedAt = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: initialDate)!
        }
        self.record = record
        end = record.endedAt ?? now
        ongoing = record.isOngoing
        isEditing = existing != nil
        original = record
    }

    var value: HeadacheRecord {
        var value = record
        value.endedAt = ongoing ? nil : end
        return value
    }
    var hasChanges: Bool { value != original }
}
