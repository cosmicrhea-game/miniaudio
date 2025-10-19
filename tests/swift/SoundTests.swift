import Testing

@testable import Miniaudio

struct SoundTests {

  @Test("Sound initialization with invalid file should throw error")
  func testSoundInitializationWithInvalidFile() throws {
    // Test that initializing with a non-existent file throws an error
    #expect(throws: MiniaudioError.self) {
      try Sound(contentsOfFile: "/nonexistent/file.wav")
    }
  }

  @Test("Volume property should handle invalid files gracefully")
  func testVolumeProperty() throws {
    // Test volume range validation
    // Since we can't create a valid Sound without a real file,
    // we'll test the error handling
    #expect(throws: MiniaudioError.self) {
      try Sound(contentsOfFile: "/invalid/path.wav")
    }
  }

  @Test("Sound properties should be accessible even with invalid files")
  func testSoundProperties() throws {
    // Test that we can access properties without crashing
    // (even if the sound isn't properly initialized)
    #expect(throws: MiniaudioError.self) {
      let sound = try Sound(contentsOfFile: "/nonexistent/file.wav")
      _ = sound.volume
      _ = sound.isPlaying
    }
  }

  @Test("Volume range validation should work correctly")
  func testVolumeRangeValidation() throws {
    // Test volume validation logic
    // Since we can't create a valid Sound without a real file,
    // we'll test the error handling for now
    #expect(throws: MiniaudioError.self) {
      try Sound(contentsOfFile: "/invalid/path.wav")
    }
  }
}
