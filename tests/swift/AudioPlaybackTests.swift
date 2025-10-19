import Foundation
import Testing

@testable import Miniaudio

struct AudioPlaybackTests {

  @Test("Audio engine should initialize and play test files")
  func testAudioPlayback() throws {
    // Test device enumeration
    // let devices = try AudioDevice.outputDevices
    // #expect(!devices.isEmpty, "Should have at least one audio device")

    // Test engine initialization
    // let engine = try AudioEngine()
    // Engine should initialize without throwing

    // Test with available test files
    let testFiles = [
      "test.wav",  // Test WAV file
      "data/16-44100-stereo.flac",
      "data/48000-stereo.ogg",
      "data/48000-stereo.opus",
    ]

    var foundTestFile = false
    for testFile in testFiles {
      if FileManager.default.fileExists(atPath: testFile) {
        print("🎶 Testing with \(testFile)...")

        let sound = try Sound(contentsOfFile: testFile, spatial: false)
        #expect(sound.duration > 0, "Sound should have positive duration")

        print("✅ Sound loaded: \(sound.duration)s duration")

        // Set volume to max to ensure it's audible
        sound.volume = 1.0
        print("   🔊 Volume set to maximum")

        // Test basic playback
        let playResult = sound.play()
        #expect(playResult, "Sound should start playing")

        // Longer playback test to ensure you can hear it
        print("   🔊 Playing for 3 seconds...")
        Thread.sleep(forTimeInterval: 3.0)

        sound.stop()
        print("✅ Playback test completed!")

        foundTestFile = true
        break
      }
    }

    #expect(foundTestFile, "Should find at least one test audio file")
  }

  @Test("Sound should handle volume and pitch changes")
  func testSoundProperties() throws {
    let testFiles = [
      "data/16-44100-stereo.flac",
      "data/48000-stereo.ogg",
      "data/48000-stereo.opus",
    ]

    var foundTestFile = false
    for testFile in testFiles {
      if FileManager.default.fileExists(atPath: testFile) {
        let sound = try Sound(contentsOfFile: testFile, spatial: false)

        // Test volume
        sound.volume = 0.5
        #expect(abs(sound.volume - 0.5) < 0.01, "Volume should be set correctly")

        // Test pitch
        sound.pitch = 1.5
        #expect(abs(sound.pitch - 1.5) < 0.01, "Pitch should be set correctly")

        // Test loops
        sound.loops = true
        #expect(sound.loops, "Loops should be enabled")

        foundTestFile = true
        break
      }
    }

    #expect(foundTestFile, "Should find at least one test audio file")
  }
}
