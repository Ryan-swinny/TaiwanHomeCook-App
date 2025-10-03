import SwiftUI

struct OrderConfirmationView: View {
    
    // 讓這個 View 能夠 dismiss 掉整個 Checkout 模態視圖
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("訂單已成功送出！")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("您的私房菜訂單已發送給老闆，請耐心等待美味餐點。")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack {
                Text("訂單編號: #20250930-A1B2")
                    .font(.caption)
                Text("預計送達時間：約 45 分鐘")
                    .font(.caption)
            }
            .padding()

            Spacer()
            
            // 返回主頁面按鈕
            Button("回到首頁") {
                // 點擊後關閉整個模態視圖
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        // 隱藏頂部的 Navigation Bar，讓頁面更簡潔
        .navigationBarHidden(true)
    }
}

#Preview {
    OrderConfirmationView()
}//
//  OrderConfirmationView.swift
//  Homecook
//
//  Created by Ryan.L on 3/10/2025.
//

