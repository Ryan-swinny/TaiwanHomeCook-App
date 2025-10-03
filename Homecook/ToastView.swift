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
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
            .transition(.opacity.combined(with: .move(edge: .bottom))) // 增加淡入淡出和從底部移動的動畫
    }
}

// 視圖擴展：用於在任何視圖上輕鬆顯示快顯提示
extension View {
    
    // 讓任何 View 都能使用 .toast(message:isVisible:duration:)
    func toast(message: String, isVisible: Binding<Bool>, duration: Double = 2.0) -> some View {
        
        self.modifier(ToastModifier(message: message, isVisible: isVisible, duration: duration))
    }
}

// 核心修飾符：管理 Toast 視圖的顯示和隱藏
struct ToastModifier: ViewModifier {
    let message: String
    @Binding var isVisible: Bool
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            
            // 原始內容 (ContentView, DetailView 等)
            content
            
            // 只有當 isVisible 為 true 時才顯示 Toast
            if isVisible {
                ToastView(message: message)
                    .padding(.bottom, 80) // 讓它在螢幕底部上方顯示
                    
                    // 點餐成功動畫邏輯
                    .onAppear {
                        // 延遲 duration 秒後，將 isVisible 設為 false，隱藏提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isVisible = false
                            }
                        }
                    }
            }
        }
    }
}//
//  ToastView.swift
//  Homecook
//
//  Created by Ryan.L on 30/9/2025.
//

