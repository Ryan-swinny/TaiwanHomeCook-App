//
//  LocationManager.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import Foundation
import CoreLocation
import Combine

/// 處理所有 Core Location 相關操作的服務層，並遵循 ObservableObject 協議。
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // ⭐ 修正點 1：將搜尋半徑設為 5000 公尺，並設為 @Published 以便在 UI 中調整。
    @Published var searchRadius: Double = 5000.0 // 單位：公尺 (5公里)
    
    private let locationManager = CLLocationManager()
    
    // @Published 變數，當位置或授權狀態改變時，會通知 SwiftUI 視圖更新。
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 設置為最佳準確度
        
        // ⭐ 修正點 2：只在 init() 中請求權限，避免立即開始追蹤 (StartUpdatingLocation)
        locationManager.requestWhenInUseAuthorization()
        
        // 初始檢查並開始追蹤 (如果 App 已經有權限，這裡會立即執行)
        checkInitialAuthorization()
    }
    
    /// 檢查並開始位置更新，避免在未授權時浪費資源。
    private func checkInitialAuthorization() {
        // 使用 CLLocationManager 的靜態方法獲取當前狀態
        let status = locationManager.authorizationStatus
        authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    /// 公開方法：用於在使用者點擊按鈕時重新請求定位權限。
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// 根據用戶當前位置和設定的半徑篩選附近的私廚據點。
    func filterCookSpots(allSpots: [CookSpot]) -> [CookSpot] {
        
        // 1. 確保我們已經成功獲取到使用者的位置
        guard let userLocation = location else {
            // 如果沒有位置，則返回空列表
            return []
        }
        
        // 2. 篩選列表
        return allSpots.compactMap { spot -> CookSpot? in
            
            let cookSpotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
            
            // CLLocation 內建的 distance(from:) 方法會計算兩點間的距離（單位：公尺）
            let distanceInMeters = userLocation.distance(from: cookSpotLocation)
            
            // 使用可配置的 searchRadius 進行篩選
            if distanceInMeters <= searchRadius {
                return spot
            } else {
                return nil
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate 代理方法
    
    /// 代理方法：當授權狀態改變時呼叫
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        print("定位授權狀態已變更為: \(status.rawValue)")
        
        // ⭐ 修正點 3：只在獲得授權時才開始追蹤，這是更高效的資源管理。
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
        }
    }
    
    /// 代理方法：當接收到新的位置資料時呼叫
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        location = latestLocation
        
        // 為了節省電量，在獲取到第一次準確位置後，可以考慮停止連續追蹤
        // manager.stopUpdatingLocation()
    }
    
    /// 代理方法：定位失敗時呼叫
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失敗: \(error.localizedDescription)")
    }
}
