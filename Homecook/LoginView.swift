//
//  LoginView.swift
//  Homecook
//
//  Created by [你的名字] on [今天的日期].
//

import SwiftUI

// MARK: - User Role Enum
// 定義一個列舉 (Enum) 來表示使用者或私廚的身份
enum UserRole: String, CaseIterable, Identifiable {
    case user = "我是顧客" // User - 點餐者
    case cooker = "我是私廚" // Cooker - 供餐者
    
    var id: String { self.rawValue }
    
    // 雖然這裡定義了 iconName，但我們在 Picker 中只使用文字標籤
    var iconName: String {
        switch self {
        case .user:
            return "person.crop.circle.fill" // 顧客圖標
        case .cooker:
            return "stove.fill" // 私廚圖標
        }
    }
}

// MARK: - 主登錄視圖

struct LoginView: View {
    
    // ⭐ 注入 AuthService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedRole: UserRole = .user
    @State private var email = ""
    @State private var password = ""
    @State private var isRegisterPresented = false
    
    // 追蹤 UI 狀態
    @State private var isLoading = false
    @State private var loginError: String?
    
    // 檢查登錄表單是否有效
    var isLoginValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                // MARK: - 標題
                Text("歡迎回到 Home Cook")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                // MARK: - 身份選擇器 (分段控制 SegmentedPicker)
                roleSelector
                
                // MARK: - 輸入表單 (Email / Password)
                Form {
                    TextField("電子郵件", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("密碼", text: $password)
                }
                .frame(height: 150)
                .scrollDisabled(true)
                
                // MARK: - 錯誤訊息顯示
                if let error = loginError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.vertical, 5)
                }
                
                // MARK: - 登錄按鈕
                Button {
                    login()
                } label: {
                    if isLoading {
                        ProgressView() // 載入中動畫
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("登錄")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoginValid ? Color.orange : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                // 禁用條件：如果無效或正在載入，則禁用
                .disabled(!isLoginValid || isLoading)
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                // MARK: - 註冊連結
                VStack(spacing: 5) {
                    Text("還沒有帳號嗎？")
                        .foregroundColor(.secondary)
                    
                    Button("立即註冊成為 \(selectedRole.rawValue)") {
                        isRegisterPresented = true
                    }
                }
                .padding(.bottom, 30)
                
            }
            .padding()
            .navigationBarHidden(true)
        }
        // 處理跳轉到註冊頁面 (彈出 RegisterView)
        .sheet(isPresented: $isRegisterPresented) {
            // 傳遞當前選定的身份 (selectedRole) 給 RegisterView
            RegisterView(role: selectedRole)
                .environmentObject(authService) // 必須注入 AuthService
        }
    }
    
    // MARK: - 輔助視圖：身份選擇器 (已移除頭像)
    var roleSelector: some View {
        Picker("選擇身份", selection: $selectedRole) {
            ForEach(UserRole.allCases) { role in
                // ⭐ 修正點：只保留 Text
                Text(role.rawValue)
                    .tag(role)
            }
        }
        .pickerStyle(.segmented) // 使用分段控制樣式
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - 登錄函數
    func login() {
        isLoading = true
        loginError = nil
        
        // 呼叫 AuthService 提供的登錄方法
        authService.login(email: email, password: password) { result in
            
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // 登錄成功：App 會自動透過 HomecookApp.swift 偵測狀態變化而跳轉
                    print("登錄成功，App 流程已接管。")
                    
                case .failure(let error):
                    // 登錄失敗：顯示錯誤訊息
                    self.loginError = error.localizedDescription
                    print("登錄失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 預覽

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
