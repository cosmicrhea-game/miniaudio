import CMiniaudio
import Foundation

// MARK: - AudioFormat

public enum AudioFormat: String, CaseIterable {
  case wav = "wav"
  case flac = "flac"
  case mp3 = "mp3"
  case vorbis = "ogg"  // Vorbis codec in OGG container
  case unknown = "unknown"

  public static func detect(from url: URL) -> AudioFormat {
    let pathExtension = url.pathExtension.lowercased()
    return AudioFormat(rawValue: pathExtension) ?? .unknown
  }

  public static func detect(from filePath: String) -> AudioFormat {
    let url = URL(fileURLWithPath: filePath)
    return detect(from: url)
  }
}

// MARK: - AudioMetadata

public struct AudioMetadata {
  public let format: AudioFormat
  public let duration: TimeInterval
  public let sampleRate: UInt32
  public let channels: UInt32
  public let bitDepth: UInt32

  public init(
    format: AudioFormat, duration: TimeInterval, sampleRate: UInt32, channels: UInt32,
    bitDepth: UInt32
  ) {
    self.format = format
    self.duration = duration
    self.sampleRate = sampleRate
    self.channels = channels
    self.bitDepth = bitDepth
  }
}
