import Foundation

public protocol RandomSource {
    mutating func nextInt(upperBound: Int) -> Int
}

public struct SeededRandom: RandomSource, Codable, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    public mutating func nextInt(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27
        return Int((state &* 0x2545F4914F6CDD1D) % UInt64(upperBound))
    }
}
