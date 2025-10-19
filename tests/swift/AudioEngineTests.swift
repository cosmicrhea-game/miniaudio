import Testing

@testable import Miniaudio

struct AudioEngineTests {

  @Test("AudioEngine initialization should work correctly")
  func testAudioEngineInitialization() throws {
    // Test that we can create an AudioEngine
    let engine = try AudioEngine()

    // Test basic properties
    _ = engine.volume
    _ = engine.isPlaying

    // Properties should be accessible without throwing
    #expect(throws: Never.self) {
      _ = engine.volume
      _ = engine.isPlaying
    }
  }

  @Test("Volume property should work correctly")
  func testVolumeProperty() throws {
    let engine = try AudioEngine()

    // Test volume setting and getting
    engine.volume = 0.5
    #expect(abs(engine.volume - 0.5) < 0.01)

    // Test volume range validation
    let originalVolume = engine.volume
    engine.volume = -1.0  // Should be ignored
    #expect(engine.volume == originalVolume)

    engine.volume = 2.0  // Should be ignored
    #expect(engine.volume == originalVolume)
  }

  @Test("Spatial audio methods should not crash")
  func testSpatialAudio() throws {
    let engine = try AudioEngine()

    // Test spatial audio methods don't crash
    #expect(throws: Never.self) {
      engine.setListenerPosition(x: 0, y: 0, z: 0)
      engine.setListenerDirection(forwardX: 0, forwardY: 0, forwardZ: -1, upX: 0, upY: 1, upZ: 0)
      engine.setListenerVelocity(x: 0, y: 0, z: 0)
    }
  }

  @Test("Effect methods should not crash")
  func testEffects() throws {
    let engine = try AudioEngine()

    // Test that effect methods don't crash
    #expect(throws: Never.self) {
      engine.setReverb(enabled: true)
      engine.setLowPassFilter(enabled: true)
      engine.setHighPassFilter(enabled: true)
      engine.setEcho(enabled: true)
    }
  }

  @Test("Stop all sounds should not crash")
  func testStopAllSounds() throws {
    let engine = try AudioEngine()

    // Test that stopAllSounds doesn't crash
    #expect(throws: Never.self) {
      engine.stopAllSounds()
    }
  }
}
