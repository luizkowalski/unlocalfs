func statusBatch(cache: String, queue: String = #"{"queue":[]}"#, stats: String = "{}", transferred: String? = nil) -> String {
    #"{"results":[{"diskCache":{\#(cache)}},\#(queue),\#(stats)\#(transferred.map { ",\($0)" } ?? "")]}"#
}
