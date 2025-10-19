import Foundation
import Miniaudio
import CMiniaudio

// Simple test app to debug the data source issue
print("🎵 Starting simple playback test...")

// Find a test file
let testFiles = [
  "test.wav",
  "data/RE_SELECT02.wav",
  "data/16-44100-stereo.flac",
]

var testFile: String? = nil
for file in testFiles {
  if FileManager.default.fileExists(atPath: file) {
    testFile = file
    print("✅ Found test file: \(file)")
    break
  }
}

guard let file = testFile else {
  print("❌ No test file found!")
  exit(1)
}

do {
  print("📦 Creating Sound instance...")
  let sound = try Sound(contentsOfFile: file, spatial: false)
  print("✅ Sound created successfully")
  print("   Duration: \(sound.duration)s")
  
  print("▶️  Playing sound...")
  let playResult = sound.play()
  print("   Play result: \(playResult)")
  
  if playResult {
    print("⏳ Playing for 2 seconds...")
    Thread.sleep(forTimeInterval: 2.0)
    print("✅ Test completed successfully!")
  } else {
    print("❌ Failed to play sound")
    exit(1)
  }
} catch {
  print("❌ Error: \(error)")
  exit(1)
}

