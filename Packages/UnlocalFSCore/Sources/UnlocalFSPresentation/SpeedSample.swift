import Foundation
import UnlocalFSDomain

public struct SpeedSample: Equatable, Sendable {
    public let date: Date
    public let upload: Double
    public let download: Double

    init(_ activity: [FileActivity], at date: Date) {
        self.date = date.secondAligned
        upload = activity.bytesPerSecond(.uploading)
        download = activity.bytesPerSecond(.downloading)
    }

    init(_ status: MountStatus, at date: Date) {
        self.date = date.secondAligned
        upload = status.uploadSpeed
        download = status.downloadSpeed
    }
}

private extension Date {
    var secondAligned: Date { Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate.rounded(.down)) }
}

public extension [SpeedSample] {
    var fastestUpload: Double { map(\.upload).max() ?? 0 }
    var fastestDownload: Double { map(\.download).max() ?? 0 }
    var axisLimit: Double { Swift.max(fastestUpload, fastestDownload, 100_000) * 1.1 }

    func nearest(to date: Date) -> SpeedSample? {
        self.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
