import Foundation
import UnlocalFSDomain

public struct SpeedSample: Equatable, Sendable {
    public let date: Date
    public let upload: Double
    public let download: Double

    init(_ activity: [FileActivity], at date: Date) {
        self.date = date
        upload = activity.bytesPerSecond(.uploading)
        download = activity.bytesPerSecond(.downloading)
    }

    init(_ status: MountStatus, at date: Date) {
        self.date = date
        upload = status.uploadSpeed
        download = status.downloadSpeed
    }
}
