import CMiniaudio
import Foundation

// MARK: - AudioEngine

public final class AudioEngine {
  public static let shared: AudioEngine = {
    do {
      return try AudioEngine()
    } catch {
      fatalError("Failed to initialize shared AudioEngine: \(error)")
    }
  }()

  private var engine: ma_engine
  private var resourceManager: ma_resource_manager
  private var device: ma_device?
  private var context: ma_context?
  private var isInitialized = false
  private var activeInstances: [SoundInstance] = []
  private let instancesLock = NSLock()

  public var volume: Float {
    get {
      guard isInitialized else { return 0.0 }
      return ma_engine_get_volume(&engine)
    }
    set {
      guard isInitialized else { return }
      guard newValue >= 0.0 && newValue <= 1.0 else {
        return  // Silently ignore invalid volume values
      }
      ma_engine_set_volume(&engine, newValue)
    }
  }

  public var isPlaying: Bool {
    guard isInitialized else { return false }
    instancesLock.lock()
    defer { instancesLock.unlock() }
    return activeInstances.contains { $0.isPlaying }
  }

  internal var resourceManagerPointer: UnsafeMutablePointer<ma_resource_manager> {
    return withUnsafeMutablePointer(to: &resourceManager) { $0 }
  }

  internal var enginePointer: UnsafeMutablePointer<ma_engine> {
    return withUnsafeMutablePointer(to: &engine) { $0 }
  }

  public init() throws {
    self.engine = ma_engine()
    self.resourceManager = ma_resource_manager()
    self.device = nil
    self.context = nil

    // Initialize resource manager first
    var resourceManagerConfig = ma_resource_manager_config_init()
    // Decode sounds into PCM at load time for efficiency
    resourceManagerConfig.flags = 0  // Use defaults for now
    let resourceManagerResult = ma_resource_manager_init(&resourceManagerConfig, &resourceManager)
    guard resourceManagerResult == MA_SUCCESS else {
      throw MiniaudioError.deviceInitializationFailed(code: resourceManagerResult)
    }

    // Initialize engine with resource manager (engine will create its own device)
    var engineConfig = ma_engine_config_init()
    engineConfig.pResourceManager = withUnsafeMutablePointer(to: &resourceManager) { $0 }

    let result = ma_engine_init(&engineConfig, &engine)
    guard result == MA_SUCCESS else {
      ma_resource_manager_uninit(&resourceManager)
      throw MiniaudioError.deviceInitializationFailed(code: result)
    }

    isInitialized = true
  }

  deinit {
    if isInitialized {
      // Uninitialize device if we created one
      if var device = device {
        ma_device_uninit(&device)
      }
      ma_engine_uninit(&engine)
      ma_resource_manager_uninit(&resourceManager)
      // Uninitialize context if we created one
      if var context = context {
        ma_context_uninit(&context)
      }
    }
  }

  // MARK: - Sound Management

  @discardableResult
  public func play(_ sound: Sound) -> Bool {
    guard isInitialized else { return false }
    do {
      let instance = try SoundInstance(owner: sound, engine: self)
      instancesLock.lock()
      activeInstances.append(instance)
      instancesLock.unlock()

      // Set up completion callback to remove from active instances
      instance.completionHandler = { [weak self, weak instance] in
        guard let self = self, let instance = instance else { return }
        self.instancesLock.lock()
        self.activeInstances.removeAll { $0 === instance }
        self.instancesLock.unlock()
      }

      return instance.play()
    } catch {
      return false
    }
  }

  public func playSound(contentsOfFile: String, spatial: Bool = true) {
    do {
      let sound = try Sound(contentsOfFile: contentsOfFile, spatial: spatial)
      _ = play(sound)
    } catch {
      // Silently ignore errors
    }
  }

  public func playSound(url: URL, spatial: Bool = true) {
    do {
      let sound = try Sound(contentsOf: url, spatial: spatial)
      _ = play(sound)
    } catch {
      // Silently ignore errors
    }
  }

  public func stopAllSounds() {
    guard isInitialized else { return }
    instancesLock.lock()
    let instances = activeInstances
    instancesLock.unlock()

    for instance in instances {
      instance.stop()
    }

    instancesLock.lock()
    activeInstances.removeAll()
    instancesLock.unlock()
  }

  // MARK: - Output Device Selection

  public func setOutputDevice(_ audioDevice: AudioDevice?) throws {
    guard isInitialized else {
      throw MiniaudioError.deviceInitializationFailed(code: MA_INVALID_OPERATION)
    }

    // Stop all sounds before reinitializing
    stopAllSounds()

    // Uninitialize current device if we created one
    if var currentDevice = device {
      ma_device_uninit(&currentDevice)
      self.device = nil
    }

    // Uninitialize current engine
    ma_engine_uninit(&engine)

    // Initialize context if we don't have one
    if context == nil {
      var newContext = ma_context()
      let contextResult = ma_context_init(nil, 0, nil, &newContext)
      guard contextResult == MA_SUCCESS else {
        throw MiniaudioError.contextInitializationFailed(code: contextResult)
      }
      self.context = newContext
    }

    // Create device if a specific device is requested
    var newDevice: ma_device?
    if let audioDevice = audioDevice {
      var deviceConfig = ma_device_config_init(ma_device_type_playback)
      var deviceId = audioDevice.deviceInfo.id
      deviceConfig.playback.pDeviceID = withUnsafePointer(to: &deviceId) { $0 }
      // Use engine's resource manager format if available
      // For now, use defaults and let the engine handle it

      var createdDevice = ma_device()
      let contextPtr = withUnsafeMutablePointer(to: &context!) { $0 }
      let deviceResult = ma_device_init(contextPtr, &deviceConfig, &createdDevice)
      guard deviceResult == MA_SUCCESS else {
        throw MiniaudioError.deviceInitializationFailed(code: deviceResult)
      }
      newDevice = createdDevice
      self.device = createdDevice
    }

    // Reinitialize engine with new device
    var engineConfig = ma_engine_config_init()
    engineConfig.pResourceManager = withUnsafeMutablePointer(to: &resourceManager) { $0 }
    if var device = newDevice {
      engineConfig.pDevice = withUnsafeMutablePointer(to: &device) { $0 }
    }

    let result = ma_engine_init(&engineConfig, &engine)
    guard result == MA_SUCCESS else {
      // Clean up device if engine init failed
      if var device = newDevice {
        ma_device_uninit(&device)
        self.device = nil
      }
      throw MiniaudioError.deviceInitializationFailed(code: result)
    }
  }

  // MARK: - Effects

  public func setReverb(
    enabled: Bool, roomSize: Float = 0.5, damping: Float = 0.5, width: Float = 1.0,
    wetLevel: Float = 0.3
  ) {
    guard isInitialized else { return }
    // TODO: Implement reverb effect using ma_effect_chain
    // This would require setting up effect nodes in the engine's node graph
  }

  public func setLowPassFilter(enabled: Bool, cutoffFrequency: Float = 1000.0) {
    guard isInitialized else { return }
    // TODO: Implement low-pass filter effect
  }

  public func setHighPassFilter(enabled: Bool, cutoffFrequency: Float = 1000.0) {
    guard isInitialized else { return }
    // TODO: Implement high-pass filter effect
  }

  public func setEcho(enabled: Bool, delay: Float = 0.1, decay: Float = 0.5) {
    guard isInitialized else { return }
    // TODO: Implement echo effect
  }

  // MARK: - Spatial Audio

  public func setListenerPosition(x: Float, y: Float, z: Float) {
    guard isInitialized else { return }
    ma_engine_listener_set_position(&engine, 0, x, y, z)  // listenerIndex = 0 for default listener
  }

  public func setListenerDirection(
    forwardX: Float, forwardY: Float, forwardZ: Float, upX: Float, upY: Float, upZ: Float
  ) {
    guard isInitialized else { return }
    ma_engine_listener_set_direction(&engine, 0, forwardX, forwardY, forwardZ)  // listenerIndex = 0
  }

  public func setListenerVelocity(x: Float, y: Float, z: Float) {
    guard isInitialized else { return }
    ma_engine_listener_set_velocity(&engine, 0, x, y, z)  // listenerIndex = 0
  }
}
