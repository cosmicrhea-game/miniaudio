import Testing
@testable import Miniaudio
import Foundation

struct MultipleSoundsTests {
    
    @Test("Multiple sounds should not conflict")
    func testMultipleSounds() throws {
        print("🎵 Testing multiple sounds...")
        
        // Test with WAV file
        let sound1 = try Sound(contentsOfFile: "test.wav", spatial: false)
        print("✅ Sound 1 loaded: \(sound1.duration)s")
        
        // Try to create another sound
        let sound2 = try Sound(contentsOfFile: "test.wav", spatial: false)
        print("✅ Sound 2 loaded: \(sound2.duration)s")
        
        // Test playing both
        sound1.volume = 0.5
        sound2.volume = 0.5
        
        print("🔊 Playing sound 1...")
        let play1 = sound1.play()
        #expect(play1, "Sound 1 should play")
        
        Thread.sleep(forTimeInterval: 1.0)
        
        print("🔊 Playing sound 2...")
        let play2 = sound2.play()
        #expect(play2, "Sound 2 should play")
        
        Thread.sleep(forTimeInterval: 1.0)
        
        sound1.stop()
        sound2.stop()
        print("✅ Multiple sounds test completed!")
    }
    
    @Test("AudioEngine should manage sounds better")
    func testAudioEngineManagement() throws {
        print("🎵 Testing AudioEngine sound management...")
        
        let engine = try AudioEngine()
        print("✅ AudioEngine initialized")
        
        // Use AudioEngine to play sounds
        let sound1 = try engine.playSound(contentsOfFile: "test.wav", spatial: false)
        print("✅ Sound 1 played via engine")
        
        Thread.sleep(forTimeInterval: 1.0)
        
        let sound2 = try engine.playSound(contentsOfFile: "test.wav", spatial: false)
        print("✅ Sound 2 played via engine")
        
        Thread.sleep(forTimeInterval: 1.0)
        
        engine.stopAllSounds()
        print("✅ All sounds stopped via engine")
    }
}
