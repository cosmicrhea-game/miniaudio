import Testing

@testable import Miniaudio

struct AudioDeviceTests {

  @Test("Output devices enumeration should work correctly")
  func testOutputDevicesEnumeration() throws {
    // Test that we can enumerate output devices without crashing
    let devices = try AudioDevice.outputDevices

    // We should have at least one device (the default)
    #expect(!devices.isEmpty, "Should have at least one output device")

    // Check that device properties are accessible
    for device in devices {
      #expect(!device.name.isEmpty, "Device name should not be empty")
      #expect(!device.id.isEmpty, "Device ID should not be empty")
    }

    // Check that at least one device is marked as default
    let hasDefault = devices.contains { $0.isDefault }
    #expect(hasDefault, "Should have at least one default device")
  }

  @Test("Device properties should be accessible")
  func testDeviceProperties() throws {
    let devices = try AudioDevice.outputDevices
    let firstDevice = devices.first!

    // Test property access
    _ = firstDevice.name
    _ = firstDevice.id
    _ = firstDevice.isDefault

    // Properties should be accessible without throwing
    #expect(throws: Never.self) {
      _ = firstDevice.name
      _ = firstDevice.id
      _ = firstDevice.isDefault
    }
  }
}
