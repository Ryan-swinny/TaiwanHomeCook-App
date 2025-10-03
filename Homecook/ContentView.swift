import SwiftUI
import CoreLocation

struct ContentView: View {
    
    // 觀察定位管理器
    @StateObject var locationManager = LocationManager()
    
    // 🐞 修正：重新引入 OrderManager，子視圖和 Preview 必須要它在環境中
    @EnvironmentObject var orderManager: OrderManager
    
    // 獲取所有私廚據點（目前使用範例數據）
    let allCookSpots = CookSpot.sampleCookSpots
    
    // 根據定位結果，篩選出附近的私廚
    var nearbyCookSpots: [CookSpot] {
        locationManager.filterCookSpots(allSpots: allCookSpots)
    }
    
    var body: some View {
        
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
                // 🐞 移除：這裡不再需要購物車彈出邏輯
            
            if locationManager.authorizationStatus == .authorizedWhenInUse,
               let userLocation = locationManager.location
            {
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
                            Text("試試調整模擬器位置，或擴大搜尋半徑！")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)

                    } else {
                        // 使用 NavigationLink 包裹 CookSpotRow，點擊時進入詳情頁
                        ForEach(nearbyCookSpots, id: \.identifiableId) { spot in
                            NavigationLink {
                                // 🐞 傳遞 OrderManager 給 CookSpotDetailView
                                CookSpotDetailView(spot: spot)
                                    .environmentObject(orderManager)
                            } label: {
                                CookSpotRow(spot: spot, userLocation: userLocation)
                            }
                        }
                    }
                }
                .listStyle(.plain)

            } else {
                Spacer()
                locationStatusView // 顯示定位狀態的輔助視圖
                Spacer()
            }
        }
    }
    
    // MARK: - Map View Tab
    
    var mapTabView: some View {
        
        if let userLocation = locationManager.location, locationManager.authorizationStatus == .authorizedWhenInUse {
            
            return AnyView(
                CookSpotMapView(
                    nearbyCookSpots: nearbyCookSpots,
                    userLocation: userLocation
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
    
    // 將定位狀態視圖拆分成獨立的計算屬性，保持 body 簡潔
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
    
    // 頂部標題視圖 (已移除購物車按鈕)
    var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("🏠 回家吃飯")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(locationManager.location != nil ? "目前定位成功！" : "請允許定位以搜尋附近美食")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // 🐞 移除：這裡不再顯示購物車按鈕
        }
        .padding(.horizontal)
    }
}

// 獨立的視圖：用於顯示單個私廚的資訊行 (CookSpotRow)
struct CookSpotRow: View {
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
                // 注意：這裡顯示的是 CookSpot 的 description，而非菜單項目的 description
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

// 擴展 CLAuthorizationStatus，讓它可以直接輸出中文描述
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
    // 預覽時必須提供 OrderManager
    let previewOrderManager = OrderManager()
    
    return ContentView()
        .environmentObject(previewOrderManager)
}
