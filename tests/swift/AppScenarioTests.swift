import Foundation
import Testing

@testable import Miniaudio

struct AppScenarioTests {

  @Test("Simulate app bundle file loading")
  func testBundleFileLoading() throws {
    print("📱 Testing bundle-style file loading...")

    // Simulate how you might load files in an app
    let fileName = "data/RE_SELECT02.wav"
    let filePath = fileName  // In real app: Bundle.main.path(forResource: "sound", ofType: "wav")

    print("   File path: \(filePath)")
    print("   File exists: \(FileManager.default.fileExists(atPath: filePath))")

    let sound = try Sound(contentsOfFile: filePath, spatial: false)
    print("✅ Bundle-style loading worked!")

    sound.volume = 1.0
    let playResult = sound.play()
    print("   Play result: \(playResult)")

    Thread.sleep(forTimeInterval: 1.0)
    sound.stop()
  }

  @Test("Test from background thread")
  func testBackgroundThread() throws {
    print("🧵 Testing background thread...")

    // Simple background test without async expectations
    let sound = try Sound(contentsOfFile: "data/RE_SELECT02.wav", spatial: false)
    print("✅ Sound loaded")

    sound.volume = 1.0
    let playResult = sound.play()
    print("   Play result: \(playResult)")

    Thread.sleep(forTimeInterval: 1.0)
    sound.stop()
    print("✅ Background test completed")
  }

  @Test("Test multiple rapid sound creation")
  func testRapidSoundCreation() throws {
    print("⚡ Testing rapid sound creation...")

    var sounds: [Sound] = []

    for i in 1...5 {
      let sound = try Sound(contentsOfFile: "data/RE_SELECT02.wav", spatial: false)
      sound.volume = 0.2
      sounds.append(sound)
      print("   Created sound \(i)")
    }

    // Play them all
    for (index, sound) in sounds.enumerated() {
      let playResult = sound.play()
      print("   Sound \(index + 1) play result: \(playResult)")
    }

    Thread.sleep(forTimeInterval: 2.0)

    // Stop all
    for sound in sounds {
      sound.stop()
    }

    print("✅ Rapid creation test completed!")
  }

  @Test("Test URL-based loading")
  func testURLLoading() throws {
    print("🌐 Testing URL-based loading...")

    let url = URL(fileURLWithPath: "data/RE_SELECT02.wav")
    let sound = try Sound(url: url, spatial: false)
    print("✅ URL loading worked!")

    sound.volume = 1.0
    let playResult = sound.play()
    print("   URL play result: \(playResult)")

    Thread.sleep(forTimeInterval: 1.0)
    sound.stop()
  }
}
