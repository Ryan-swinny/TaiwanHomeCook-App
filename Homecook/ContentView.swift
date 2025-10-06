//
//  ContentView.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    
    // ⭐ 修正點 1：使用 @EnvironmentObject 來存取 LocationManager
    @EnvironmentObject var locationManager: LocationManager
    
    // 🐞 修正：OrderManager 保持不變
    @EnvironmentObject var orderManager: OrderManager
    
    // 獲取所有私廚據點（目前使用範例數據）
    let allCookSpots = CookSpot.sampleCookSpots
    
    // 根據定位結果，篩選出附近的私廚
    var nearbyCookSpots: [CookSpot] {
        locationManager.filterCookSpots(allSpots: allCookSpots)
    }
    
    var body: some View {
        
        // 檢查定位授權狀態，優先處理「拒絕」和「未決定」的狀態
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            // 狀態一：定位被拒絕或受限，顯示錯誤頁面
            return AnyView(permissionDeniedView)
            
        case .notDetermined, .authorizedAlways, .authorizedWhenInUse, .none:
            // 狀態二：定位狀態正常或正在等待，顯示 TabView 內容
            return AnyView(mainTabView)

        @unknown default:
            return AnyView(Text("未知狀態，請檢查 App 設定。"))
        }
    }
    
    // MARK: - Main Tab View (已授權或等待中)
    var mainTabView: some View {
        NavigationView {
            
            // 使用 TabView 讓使用者可以在「列表」和「地圖」之間切換
            TabView {
                
                // 標籤一：列表視圖
                listTabView
                    .tabItem {
                        Label("列表", systemImage: "list.bullet.clipboard.fill")
                    }
                
                // 標籤二：地圖視圖
                mapTabView
                    .tabItem {
                        Label("地圖", systemImage: "map.fill")
                    }
            }
            .navigationTitle("台灣 Home Cook")
            .navigationBarTitleDisplayMode(.inline) // 確保標題位置一致
        }
    }
    
    // MARK: - List View Tab
    var listTabView: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.bottom)
            
            // 檢查是否已取得位置
            if let userLocation = locationManager.location {
                // 如果已定位，則顯示列表
                List {
                    Text("附近 \(locationManager.searchRadius / 1000, specifier: "%.0f") 公里內的美食：")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .listRowSeparator(.hidden)
                        .padding(.top)
                    
                    if nearbyCookSpots.isEmpty {
                        VStack(alignment: .center) {
                            Text("抱歉！您的附近目前沒有私房菜上線。")
                            Text("試試調整搜尋半徑！")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        
                    } else {
                        // 使用 NavigationLink 包裹 CookSpotRow，點擊時進入詳情頁
                        ForEach(nearbyCookSpots, id: \.identifiableId) { spot in
                            NavigationLink {
                                CookSpotDetailView(spot: spot)
                                    .environmentObject(orderManager)
                            } label: { // ⭐ 這裡的 label: { 是正確的
                                CookSpotRow(spot: spot, userLocation: userLocation)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                
            } else {
                Spacer()
                // 顯示等待定位的狀態
                locationStatusView
                Spacer()
            }
        }
    }
    
    // MARK: - Map View Tab
    var mapTabView: some View {
        // 地圖只需要用戶位置和權限
        if let userLocation = locationManager.location {
            return AnyView(
                // 修正：刪除重複的 CookSpotMapView 呼叫，並使用參數標籤和 .coordinate
                CookSpotMapView(
                    nearbyCookSpots: nearbyCookSpots, // L123: 缺少參數標籤
                    userLocation: userLocation.coordinate // L125: 修正類型錯誤
                )
            )
        } else {
            return AnyView(
                VStack {
                    Spacer()
                    Text("地圖載入中...")
                    locationStatusView
                    Spacer()
                }
            )
        }
    }
    
    // MARK: - Helper Views
    
    // 輔助視圖：定位權限被拒絕時的畫面
    var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
            
            Text("無法存取您的位置")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("請前往設定開啟定位權限，才能找到附近的私房菜！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // ⭐ Call-to-Action 按鈕：引導用戶
            Button("重新請求權限") {
                locationManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
    
    // 輔助視圖：等待定位的狀態
    var locationStatusView: some View {
        VStack {
            Text("正在等待您的 GPS 位置...")
                .foregroundColor(.gray)
            // 顯示授權狀態
            Text("定位授權狀態：\(locationManager.authorizationStatus.map { String($0.statusDescription) } ?? "等待中")")
                .font(.subheadline)
                .foregroundColor(locationManager.authorizationStatus == .authorizedWhenInUse ? .green : .red)
                .padding(.top, 5)
        }
    }
    
    // 頂部標題視圖
    var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("🏠 回家吃飯")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 修正：更精確地反映當前狀態
                Text(locationManager.location != nil ? "已在 \(locationManager.searchRadius / 1000, specifier: "%.0f") 公里內搜尋" : "請允許定位以搜尋附近美食")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

// 獨立的視圖：用於顯示單個私廚的資訊行 (CookSpotRow)
struct CookSpotRow: View {
    // 保持不變...
    let spot: CookSpot
    let userLocation: CLLocation
    
    // 計算使用者到私廚的距離
    var distance: String {
        let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        
        // 格式化距離：如果大於 1000 公尺顯示為「公里」，否則顯示為「公尺」
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        
        return formatter.string(fromValue: distanceInMeters, unit: .meter)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "house.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(spot.name)
                    .font(.headline)
                Text("\(spot.cuisine) • \(spot.description)")
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(spot.rating, specifier: "%.1f")")
                        .font(.caption)
                    Text("•")
                    Text(spot.priceRange)
                        .font(.caption)
                }
            }
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(distance)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                Text("距離")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 擴展 CLAuthorizationStatus，讓它可以直接輸出中文描述 (保持不變)
extension CLAuthorizationStatus {
    var statusDescription: String {
        switch self {
        case .authorizedWhenInUse: return "已授權 (App 使用期間)"
        case .denied: return "已拒絕"
        case .notDetermined: return "尚未決定"
        case .restricted: return "受限"
        case .authorizedAlways: return "永遠允許"
        @unknown default: return "未知狀態"
        }
    }
}

#Preview {
    // 預覽時必須提供 OrderManager 和 LocationManager
    let previewOrderManager = OrderManager()
    let previewLocationManager = LocationManager()
    
    return ContentView()
        .environmentObject(previewOrderManager)
        .environmentObject(previewLocationManager)
}
