import CMiniaudio
import Foundation

// MARK: - AudioDevice

public final class AudioDevice {
  public let id: String
  public let name: String
  public let isDefault: Bool

  internal let deviceInfo: ma_device_info

  internal init(deviceInfo: ma_device_info) {
    self.deviceInfo = deviceInfo

    // Create a cross-platform device ID using a hash of the device info
    // This ensures uniqueness while being platform-agnostic
    let deviceInfoHash = withUnsafeBytes(of: deviceInfo) { bytes in
      bytes.reduce(0) { $0 ^ UInt($1) }
    }
    self.id = "device_\(deviceInfoHash)"

    // Convert C string to Swift String using withUnsafeBytes
    self.name = withUnsafeBytes(of: deviceInfo.name) { bytes in
      let buffer = bytes.bindMemory(to: CChar.self)
      let length = strnlen(buffer.baseAddress!, Int(MA_MAX_DEVICE_NAME_LENGTH))
      let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
      return String(decoding: uint8Buffer[0..<length], as: UTF8.self)
    }

    self.isDefault = deviceInfo.isDefault != 0
  }

  public static var outputDevices: [AudioDevice] {
    get throws {
      var context = ma_context()
      let result = ma_context_init(nil, 0, nil, &context)
      guard result == MA_SUCCESS else {
        throw MiniaudioError.contextInitializationFailed(code: result)
      }
      defer { ma_context_uninit(&context) }

      var playbackDeviceInfos: UnsafeMutablePointer<ma_device_info>?
      var playbackDeviceCount: ma_uint32 = 0
      var captureDeviceInfos: UnsafeMutablePointer<ma_device_info>?
      var captureDeviceCount: ma_uint32 = 0

      let enumResult = ma_context_get_devices(
        &context, &playbackDeviceInfos, &playbackDeviceCount, &captureDeviceInfos,
        &captureDeviceCount)
      guard enumResult == MA_SUCCESS else {
        throw MiniaudioError.deviceEnumerationFailed(code: enumResult)
      }

      var devices: [AudioDevice] = []
      for i in 0..<Int(playbackDeviceCount) {
        let deviceInfo = playbackDeviceInfos![i]
        devices.append(AudioDevice(deviceInfo: deviceInfo))
      }

      return devices
    }
  }
}
