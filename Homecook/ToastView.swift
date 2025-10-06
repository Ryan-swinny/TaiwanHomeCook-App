//
//  ToastView.swift
//  Homecook
//
//  Created by Ryan.L on 30/9/2025.
//

import SwiftUI

// 輕量級的快顯提示視圖
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(
                Capsule() // 優化：膠囊形狀
                    .fill(Color.black.opacity(0.85)) // 增加不透明度
            )
            .padding(.bottom, 80) // 讓它在螢幕底部上方顯示
            .shadow(radius: 5) // 增加陰影，讓它有浮動感
    }
}

// MARK: - 視圖擴展：用於在任何視圖上輕鬆顯示快顯提示

extension View {
    
    // 讓任何 View 都能使用 .toast(message:isVisible:duration:)
    func toast(message: String, isVisible: Binding<Bool>, duration: Double = 2.0) -> some View {
        
        // 使用 ZStack 覆蓋層級，確保它能在 TabView 上方顯示。
        ZStack(alignment: .bottom) {
            
            // 原始內容 (ContentView, DetailView 等)
            self
            
            // 只有當 isVisible 為 true 時才顯示 Toast
            if isVisible.wrappedValue {
                ToastView(message: message)
                    // 優化：顯式添加動畫
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                    .onAppear {
                        // 延遲 duration 秒後，將 isVisible 設為 false，隱藏提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            // 優化：確保消失時也有動畫效果
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isVisible.wrappedValue = false
                            }
                        }
                    }
            }
        }
    }
}
//
//  Created by Ryan.L on 30/9/2025.
//

