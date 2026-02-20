import Foundation
import CoreLocation

// MARK: - Location Fetch State

/// 位置获取状态枚举
enum LocationFetchState {
    case idle                           // 空闲
    case fetching(accuracy: Double?)    // 获取中（可选：当前精度）
    case success(LocationInfo)          // 成功
    case failed(LocationError)          // 失败
}

/// 位置错误类型
public enum LocationError: Error, LocalizedError {
    case notAuthorized           // 未授权
    case timeout                 // 超时
    case locationUnknown         // 位置未知
    case networkError            // 网络错误（地理编码）
    case cancelled               // 已取消
    case other(Error)            // 其他错误
    
    public var errorDescription: String? {
        switch self {
        case .notAuthorized: return "location.error.notAuthorized".localized
        case .timeout: return "location.error.timeout".localized
        case .locationUnknown: return "location.error.unknown".localized
        case .networkError: return "location.error.network".localized
        case .cancelled: return "location.error.cancelled".localized
        case .other(let error): return error.localizedDescription
        }
    }
}

// MARK: - Location Service

final class LocationService: NSObject, ObservableObject {
    
    // MARK: - Configuration
    
    /// 位置缓存有效期（秒）
    private let cacheValidityDuration: TimeInterval = 30
    
    /// 超时时间（秒）
    private let timeoutDuration: TimeInterval = 5
    
    /// 目标精度（米）- 达到此精度后立即返回
    private let targetAccuracy: CLLocationAccuracy = 50
    
    /// 最大精度等待时间（秒）- 超过此时间返回当前最佳结果
    private let maxAccuracyWaitTime: TimeInterval = 3
    
    // MARK: - Properties
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    /// 当前位置获取回调
    private var locationHandler: ((LocationInfo?) -> Void)?
    
    /// 缓存的位置信息
    private var cachedLocation: LocationInfo?
    private var cacheTimestamp: Date?
    
    /// 超时计时器
    private var timeoutTimer: Timer?
    
    /// 精度提升计时器
    private var accuracyTimer: Timer?
    
    /// 当前获取到的最佳位置
    private var bestLocation: CLLocation?
    
    /// 是否正在获取位置
    private var isFetching = false
    
    /// 发布的状态（供UI绑定）
    @Published private(set) var fetchState: LocationFetchState = .idle
    
    // MARK: - Init
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    // MARK: - Public API
    
    /// 请求当前位置（优化版本）
    /// - Parameter completion: 完成回调，返回位置信息或nil
    func requestCurrentLocation(_ completion: @escaping (LocationInfo?) -> Void) {
        // 1. 检查缓存
        if let cached = getCachedLocationIfValid() {
            completion(cached)
            return
        }
        
        // 2. 防止重复请求
        if isFetching {
            // 已有请求进行中，追加回调
            let existingHandler = locationHandler
            locationHandler = { info in
                existingHandler?(info)
                completion(info)
            }
            return
        }
        
        // 3. 开始新的位置请求
        startLocationFetch(completion: completion)
    }
    
    /// 取消当前位置请求
    func cancelLocationRequest() {
        guard isFetching else { return }
        
        cleanup()
        fetchState = .failed(.cancelled)
        locationHandler?(nil)
        locationHandler = nil
    }
    
    /// 清除缓存
    func clearCache() {
        cachedLocation = nil
        cacheTimestamp = nil
    }
    
    // MARK: - Private Methods
    
    private func startLocationFetch(completion: @escaping (LocationInfo?) -> Void) {
        isFetching = true
        bestLocation = nil
        locationHandler = completion
        fetchState = .fetching(accuracy: nil)
        
        // 检查授权状态
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finishWithError(.notAuthorized)
            return
        default:
            break
        }
        
        // 配置精度策略：先使用较低精度快速获取，然后提升
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
        
        // 开始持续更新位置（而非单次请求）
        manager.startUpdatingLocation()
        
        // 设置超时计时器
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutDuration, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
        
        // 设置精度提升计时器 - 一段时间后提升精度要求
        accuracyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.upgradeAccuracy()
        }
    }
    
    private func upgradeAccuracy() {
        guard isFetching else { return }
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    private func handleTimeout() {
        guard isFetching else { return }
        
        // 超时但有最佳位置，使用它
        if let best = bestLocation {
            processLocation(best)
        } else {
            finishWithError(.timeout)
        }
    }
    
    private func processLocation(_ location: CLLocation) {
        // 停止位置更新
        manager.stopUpdatingLocation()
        
        // 先返回不含地址的位置信息（快速响应）
        let quickInfo = LocationInfo(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            name: nil,
            address: nil,
            city: nil,
            country: nil
        )
        
        // 更新状态
        fetchState = .success(quickInfo)
        
        // 异步进行反向地理编码
        reverseGeocodeAsync(location) { [weak self] info in
            guard let self = self else { return }
            
            let finalInfo = info ?? quickInfo
            
            // 更新缓存
            self.cachedLocation = finalInfo
            self.cacheTimestamp = Date()
            
            // 完成回调
            self.cleanup()
            self.fetchState = .success(finalInfo)
            self.locationHandler?(finalInfo)
            self.locationHandler = nil
        }
    }
    
    private func reverseGeocodeAsync(_ location: CLLocation, completion: @escaping (LocationInfo?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[LocationService] Geocoding error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                let placemark = placemarks?.first
                let info = LocationInfo(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    horizontalAccuracy: location.horizontalAccuracy,
                    verticalAccuracy: location.verticalAccuracy,
                    name: placemark?.name,
                    address: [
                        placemark?.administrativeArea,
                        placemark?.locality,
                        placemark?.subLocality,
                        placemark?.thoroughfare
                    ].compactMap { $0 }.joined(),
                    city: placemark?.locality,
                    country: placemark?.country
                )
                completion(info)
            }
        }
    }
    
    private func finishWithError(_ error: LocationError) {
        cleanup()
        fetchState = .failed(error)
        locationHandler?(nil)
        locationHandler = nil
    }
    
    private func cleanup() {
        isFetching = false
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        accuracyTimer?.invalidate()
        accuracyTimer = nil
        manager.stopUpdatingLocation()
    }
    
    private func getCachedLocationIfValid() -> LocationInfo? {
        guard let cached = cachedLocation,
              let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return nil
        }
        return cached
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isFetching, let location = locations.last else { return }
        
        // 更新状态显示当前精度
        fetchState = .fetching(accuracy: location.horizontalAccuracy)
        
        // 保存最佳位置（精度最高的）
        if bestLocation == nil || location.horizontalAccuracy < (bestLocation?.horizontalAccuracy ?? .infinity) {
            bestLocation = location
        }
        
        // 检查是否达到目标精度
        if location.horizontalAccuracy <= targetAccuracy {
            // 达到目标精度，立即处理
            processLocation(location)
        }
        // 否则继续等待更好的位置，直到超时
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isFetching else { return }
        
        let clError = error as? CLError
        
        // 某些错误可以忽略继续等待
        if clError?.code == .locationUnknown {
            // 位置暂时未知，继续等待
            return
        }
        
        // 如果有最佳位置，使用它
        if let best = bestLocation {
            processLocation(best)
            return
        }
        
        // 真正的错误
        let locationError: LocationError
        switch clError?.code {
        case .denied:
            locationError = .notAuthorized
        case .network:
            locationError = .networkError
        default:
            locationError = .other(error)
        }
        
        finishWithError(locationError)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isFetching else { return }
        
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 授权成功，开始获取位置
            manager.startUpdatingLocation()
        case .denied, .restricted:
            finishWithError(.notAuthorized)
        default:
            break
        }
    }
}
