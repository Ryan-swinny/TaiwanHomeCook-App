import Foundation
import CoreLocation
import Combine

// LocationManager 是 Core Location 的主要類別，用於獲取位置。
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let searchRadius: Double = 2000.0 // 單位：公尺 (5000公尺 = 5公里)
    
    private let locationManager = CLLocationManager()
    
    // @Published 變數，當位置或授權狀態改變時，會通知 SwiftUI 視圖更新。
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init() {
        super.init()
        // 設定代理，讓這個類別接收定位事件
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 要求 App 使用期間的定位權限
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func filterCookSpots(allSpots: [CookSpot]) -> [CookSpot] {
        
        // 1. 確保我們已經成功獲取到使用者的位置
        guard let userLocation = location else {
            // 如果沒有位置，則返回空列表
            return []
        }
        
        // 2. 篩選列表
        let nearbySpots = allSpots.compactMap { spot -> CookSpot? in
            
            // 創建一個 CLLocation 物件來表示私廚的位置
            let cookSpotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
            
            // CLLocation 內建的 distance(from:) 方法會計算兩點間的距離（單位：公尺）
            let distanceInMeters = userLocation.distance(from: cookSpotLocation)
            
            // 如果距離在我們設定的半徑內 (5000 公尺)
            if distanceInMeters <= searchRadius {
                // 這個私廚符合條件，將其加入列表
                return spot
            } else {
                // 太遠了，不加入
                return nil
            }
        }
        
        return nearbySpots
    }
    
    // 代理方法：當授權狀態改變時呼叫
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        print("定位授權狀態已變更為: \(status.rawValue)")
    }
    
    // 代理方法：當接收到新的位置資料時呼叫
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        location = latestLocation
    }
    
    // 代理方法：定位失敗時呼叫
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失敗: \(error.localizedDescription)")
    }
}
