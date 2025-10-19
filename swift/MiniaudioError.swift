import CMiniaudio
import Foundation

// MARK: - Error Types

public enum MiniaudioError: Error {
  case contextInitializationFailed(code: ma_result)
  case deviceEnumerationFailed(code: ma_result)
  case deviceInitializationFailed(code: ma_result)
  case fileLoadFailed(String, code: ma_result)
  case playbackFailed(code: ma_result)
  case invalidVolume
}
