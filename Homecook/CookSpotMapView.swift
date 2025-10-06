// CookSpotMapView.swift 最終乾淨版 (請用此取代舊內容)

import SwiftUI
import MapKit
import CoreLocation

// MARK: - 0. 解決 Equatable 協定不符問題
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - 1. 主地圖視圖
struct CookSpotMapView: View {
    
    // 這裡的 CookSpot 必須指向主專案的定義
    let nearbyCookSpots: [CookSpot]
    
    let userLocation: CLLocationCoordinate2D
    
    @State private var cameraPosition: MapCameraPosition
    
    @State private var selectedSpot: CookSpot?
    
    init(nearbyCookSpots: [CookSpot], userLocation: CLLocationCoordinate2D) {
        self.nearbyCookSpots = nearbyCookSpots
        self.userLocation = userLocation
        
        let initialRegion = MapCameraPosition.region(
            MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )
        )
        _cameraPosition = State(initialValue: initialRegion)
    }
    
    var body: some View {
        // ... (body 內容保持不變，因為邏輯是正確的)
        Map(position: $cameraPosition) {
            
            UserAnnotation()
            
            ForEach(nearbyCookSpots, id: \.identifiableId) { spot in
                
                Annotation(spot.name, coordinate: spot.coordinate) {
                    
                    VStack(spacing: 4) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                        
                        Text(spot.name)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .onTapGesture {
                        self.selectedSpot = spot
                    }
                    .offset(y: -20)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onChange(of: userLocation) { oldLocation, newLocation in
            let oldLoc = CLLocation(latitude: oldLocation.latitude, longitude: oldLocation.longitude)
            let newLoc = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
            
            if oldLoc.distance(from: newLoc) > 100 {
                withAnimation(.easeInOut) {
                    cameraPosition = .region(MKCoordinateRegion(center: newLocation, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)))
                }
            }
        }
        .sheet(item: $selectedSpot) { spot in
            // 這裡直接引用主專案的 CookSpotDetailView
            CookSpotDetailView(spot: spot)
        }
    }
}


// MARK: - 預覽區塊 (直接使用主專案的 CookSpot)
#if DEBUG
#Preview {
    // 假設 CookSpot.sampleCookSpots 存在且可見
    let mockSpots = CookSpot.sampleCookSpots
    let mockUserLocation = CLLocationCoordinate2D(latitude: 25.033964, longitude: 121.564468)
    
    // 預覽 CookSpotMapView
    return CookSpotMapView(
        nearbyCookSpots: mockSpots,
        userLocation: mockUserLocation
    )
}
#endif // DEBUG
