import CMiniaudio
import Foundation

public typealias SoundCompletionHandler = () -> Void

// MARK: - Internal SoundInstance (pool entry)

internal final class SoundInstance {
  private var underlying: ma_sound
  // Allocate data source on the heap so the pointer remains valid
  private var dataSource: UnsafeMutablePointer<ma_resource_manager_data_source>
  private var isInitialized = false
  private weak var owner: Sound?
  private weak var engine: AudioEngine?

  public var volume: Float {
    get { isInitialized ? ma_sound_get_volume(&underlying) : 0.0 }
    set {
      guard isInitialized else { return }
      guard newValue >= 0.0 && newValue <= 1.0 else { return }
      ma_sound_set_volume(&underlying, newValue)
    }
  }

  public var isPlaying: Bool { isInitialized && (ma_sound_is_playing(&underlying) != 0) }

  public var loops: Bool {
    get { isInitialized && (ma_sound_is_looping(&underlying) != 0) }
    set {
      guard isInitialized else { return }
      ma_sound_set_looping(&underlying, newValue ? 1 : 0)
    }
  }

  public var position: (Float, Float, Float) {
    get {
      guard isInitialized else { return (0, 0, 0) }
      let p = ma_sound_get_position(&underlying)
      return (p.x, p.y, p.z)
    }
    set {
      guard isInitialized else { return }
      ma_sound_set_position(&underlying, newValue.0, newValue.1, newValue.2)
    }
  }

  public var currentTime: TimeInterval {
    get {
      guard isInitialized else { return 0 }
      var seconds: Float = 0
      if ma_sound_get_cursor_in_seconds(&underlying, &seconds) == MA_SUCCESS {
        return TimeInterval(seconds)
      }
      return 0
    }
    set {
      guard isInitialized else { return }
      _ = ma_sound_seek_to_second(&underlying, Float(newValue))
    }
  }

  public var duration: TimeInterval {
    guard isInitialized else { return 0 }
    var lengthInFrames: ma_uint64 = 0
    if ma_sound_get_length_in_pcm_frames(&underlying, &lengthInFrames) == MA_SUCCESS {
      let sr = ma_engine_get_sample_rate(ma_sound_get_engine(&underlying))
      if sr > 0 { return TimeInterval(Double(lengthInFrames) / Double(sr)) }
    }
    return 0
  }

  public var completionHandler: SoundCompletionHandler? {
    didSet { setupEndCallback() }
  }

  internal init(owner: Sound, engine: AudioEngine) throws {
    self.owner = owner
    self.engine = engine
    self.underlying = ma_sound()

    // Get engine pointer
    let enginePtr = engine.enginePointer

    // Get file path
    let path = owner.filePath ?? owner.url?.path ?? ""
    guard !path.isEmpty else {
      throw MiniaudioError.fileLoadFailed("unknown", code: MA_INVALID_ARGS)
    }

    // Create data source for this instance - resource manager handles reference counting
    // Use WAIT_INIT flag to ensure the data source is fully initialized before we use it
    // Allocate on the heap so the pointer remains valid for the lifetime of the sound
    self.dataSource = UnsafeMutablePointer<ma_resource_manager_data_source>.allocate(capacity: 1)
    self.dataSource.initialize(to: ma_resource_manager_data_source())
    
    let dataSourceFlags: ma_uint32 = UInt32(
      MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_DECODE.rawValue |
      MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_WAIT_INIT.rawValue
    )
    let initResult = ma_resource_manager_data_source_init(
      engine.resourceManagerPointer, path, dataSourceFlags, nil, self.dataSource)
    guard initResult == MA_SUCCESS else {
      self.dataSource.deinitialize(count: 1)
      self.dataSource.deallocate()
      throw MiniaudioError.fileLoadFailed(path, code: initResult)
    }

    // Verify the data source is actually ready (even with WAIT_INIT, double-check)
    let resultCheck = ma_resource_manager_data_source_result(self.dataSource)
    if resultCheck != MA_SUCCESS {
      // If still busy, wait a bit and check again
      if resultCheck == MA_BUSY {
        // This shouldn't happen with WAIT_INIT, but just in case
        Thread.sleep(forTimeInterval: 0.01)
        let retryCheck = ma_resource_manager_data_source_result(self.dataSource)
        guard retryCheck == MA_SUCCESS else {
          self.dataSource.pointee = ma_resource_manager_data_source()
          ma_resource_manager_data_source_uninit(self.dataSource)
          self.dataSource.deinitialize(count: 1)
          self.dataSource.deallocate()
          throw MiniaudioError.fileLoadFailed(path, code: retryCheck)
        }
      } else {
        self.dataSource.pointee = ma_resource_manager_data_source()
        ma_resource_manager_data_source_uninit(self.dataSource)
        self.dataSource.deinitialize(count: 1)
        self.dataSource.deallocate()
        throw MiniaudioError.fileLoadFailed(path, code: resultCheck)
      }
    }

    // Get pointer to the stored data source - now it's on the heap so the pointer is stable
    // ma_data_source is a typedef for void, so ma_data_source* is UnsafeMutableRawPointer
    // We can pass the pointer directly since ma_resource_manager_data_source starts with ma_data_source_base
    let dataSourcePtr = UnsafeMutableRawPointer(self.dataSource)
    
    // Initialize sound from data source
    var soundFlags: ma_uint32 = 0
    if !owner.spatial { soundFlags |= UInt32(MA_SOUND_FLAG_NO_SPATIALIZATION.rawValue) }

    let soundResult = ma_sound_init_from_data_source(enginePtr, dataSourcePtr, soundFlags, nil, &underlying)
    guard soundResult == MA_SUCCESS else {
      ma_resource_manager_data_source_uninit(self.dataSource)
      self.dataSource.deinitialize(count: 1)
      self.dataSource.deallocate()
      throw MiniaudioError.fileLoadFailed(owner.filePath ?? owner.url?.path ?? "unknown", code: soundResult)
    }

    isInitialized = true

    volume = owner.volume
    loops = owner.loops
    position = owner.position

    setupEndCallback()
  }

  deinit {
    if isInitialized {
      ma_sound_uninit(&underlying)
    }
    // Uninit the data source and deallocate
    // Check if initialized by checking if the data source has been initialized
    // We can check by trying to uninit - it's safe to call even if not initialized
    ma_resource_manager_data_source_uninit(dataSource)
    dataSource.deinitialize(count: 1)
    dataSource.deallocate()
  }

  private func setupEndCallback() {
    guard isInitialized else { return }
    if completionHandler != nil {
      let callback:
        @convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<ma_sound>?) -> Void = {
          userData, _ in
          let instance = Unmanaged<SoundInstance>.fromOpaque(userData!).takeUnretainedValue()
          instance.completionHandler?()
          // Engine manages instances now, no need to remove from owner
        }
      let selfPtr = Unmanaged.passUnretained(self).toOpaque()
      ma_sound_set_end_callback(&underlying, callback, selfPtr)
    } else {
      ma_sound_set_end_callback(&underlying, nil, nil)
    }
  }

  @discardableResult
  public func play() -> Bool {
    guard isInitialized else { return false }
    return ma_sound_start(&underlying) == MA_SUCCESS
  }

  @discardableResult
  public func pause() -> Bool {
    guard isInitialized else { return false }
    ma_sound_stop(&underlying)
    return true
  }

  @discardableResult
  public func resume() -> Bool {
    guard isInitialized else { return false }
    return ma_sound_start(&underlying) == MA_SUCCESS
  }

  @discardableResult
  public func stop() -> Bool {
    guard isInitialized else { return false }
    ma_sound_stop(&underlying)
    _ = ma_sound_seek_to_pcm_frame(&underlying, 0)
    return true
  }
}

// MARK: - Public Sound (pool-backed)

public final class Sound {
  internal let filePath: String?
  internal let url: URL?
  internal let spatial: Bool

  // Defaults applied to new instances and propagated to active ones when changed.
  public var volume: Float = 1.0
  public var position: (Float, Float, Float) = (0, 0, 0)
  public var loops: Bool = false

  // Cached metadata
  public private(set) var metadata: AudioMetadata?
  public var duration: TimeInterval { metadata?.duration ?? 0 }

  public var isPlaying: Bool {
    // Check if any instances are playing via the engine
    return AudioEngine.shared.isPlaying
  }

  public var currentTime: TimeInterval {
    get { 0 }  // TODO: Track current time from active instances
    set { }  // TODO: Seek active instances
  }

  public init(contentsOf url: URL, spatial: Bool = true) throws {
    self.filePath = nil
    self.url = url
    self.spatial = spatial
    try loadMetadata()
  }

  public init(contentsOfFile path: String, spatial: Bool = true) throws {
    self.filePath = path
    self.url = nil
    self.spatial = spatial
    try loadMetadata()
  }

  @discardableResult
  public func play() -> Bool {
    return AudioEngine.shared.play(self)
  }

  @discardableResult
  public func pause() -> Bool {
    // TODO: Track instances and pause them
    return false
  }

  @discardableResult
  public func resume() -> Bool {
    // TODO: Track instances and resume them
    return false
  }

  @discardableResult
  public func stop() -> Bool {
    // TODO: Track instances and stop them
    return false
  }

  private func loadMetadata() throws {
    // Create a temporary data source to query metadata
    let path = filePath ?? url?.path ?? ""
    guard !path.isEmpty else {
      throw MiniaudioError.fileLoadFailed("unknown", code: MA_INVALID_ARGS)
    }

    let engine = AudioEngine.shared
    var tempDataSource = ma_resource_manager_data_source()
    let flags: ma_uint32 = UInt32(MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_DECODE.rawValue)
    let initResult = ma_resource_manager_data_source_init(
      engine.resourceManagerPointer, path, flags, nil, &tempDataSource)
    guard initResult == MA_SUCCESS else {
      throw MiniaudioError.fileLoadFailed(path, code: initResult)
    }

    defer {
      ma_resource_manager_data_source_uninit(&tempDataSource)
    }

    // Query metadata from the data source
    var fmt = ma_format_unknown
    var ch: ma_uint32 = 0
    var sr: ma_uint32 = 0
    let dataSourcePtr = withUnsafePointer(to: &tempDataSource) {
      UnsafeMutablePointer(mutating: $0)
    }
    _ = ma_data_source_get_data_format(
      dataSourcePtr, &fmt, &ch, &sr, nil, 0)

    let bitDepth: UInt32
    switch fmt {
    case ma_format_u8: bitDepth = 8
    case ma_format_s16: bitDepth = 16
    case ma_format_s24: bitDepth = 24
    case ma_format_s32: bitDepth = 32
    case ma_format_f32: bitDepth = 32
    default: bitDepth = 0
    }

    let metaFormat: AudioFormat = {
      if let p = filePath { return AudioFormat.detect(from: p) }
      if let u = url { return AudioFormat.detect(from: u) }
      return .unknown
    }()

    var lenFrames: ma_uint64 = 0
    var duration: TimeInterval = 0
    if ma_data_source_get_length_in_pcm_frames(dataSourcePtr, &lenFrames) == MA_SUCCESS {
      if sr > 0 {
        duration = TimeInterval(Double(lenFrames) / Double(sr))
      }
    }

    self.metadata = AudioMetadata(
      format: metaFormat,
      duration: duration,
      sampleRate: sr,
      channels: ch,
      bitDepth: bitDepth
    )
  }
}
