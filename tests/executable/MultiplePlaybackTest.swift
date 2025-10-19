import Foundation
import Miniaudio
import CMiniaudio

// Test multiple simultaneous playbacks
print("🎵 Starting multiple playback test...")

let testFile = "test.wav"
guard FileManager.default.fileExists(atPath: testFile) else {
  print("❌ Test file not found: \(testFile)")
  exit(1)
}

do {
  print("📦 Creating 3 Sound instances...")
  let sound1 = try Sound(contentsOfFile: testFile, spatial: false)
  let sound2 = try Sound(contentsOfFile: testFile, spatial: false)
  let sound3 = try Sound(contentsOfFile: testFile, spatial: false)
  print("✅ All sounds created successfully")
  
  print("▶️  Playing all sounds simultaneously...")
  let result1 = sound1.play()
  Thread.sleep(forTimeInterval: 0.1)
  let result2 = sound2.play()
  Thread.sleep(forTimeInterval: 0.1)
  let result3 = sound3.play()
  
  print("   Sound 1: \(result1)")
  print("   Sound 2: \(result2)")
  print("   Sound 3: \(result3)")
  
  if result1 && result2 && result3 {
    print("⏳ Playing for 2 seconds...")
    Thread.sleep(forTimeInterval: 2.0)
    print("✅ Multiple playback test completed successfully!")
  } else {
    print("❌ Failed to play some sounds")
    exit(1)
  }
} catch {
  print("❌ Error: \(error)")
  exit(1)
}

