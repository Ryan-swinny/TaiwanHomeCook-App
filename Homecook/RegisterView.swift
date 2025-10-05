//
//  RegisterView.swift
//  Homecook
//
//  Created by Ryan.L on 5/10/2025.
//

import SwiftUI

// 假設你在 LoginView.swift 中定義了 UserRole
// 確保這個 enum 可以在 RegisterView 存取到
/*
enum UserRole: String, CaseIterable, Identifiable {
    case user = "我是顧客"
    case cooker = "我是私廚"
    // ... (其他屬性)
}
*/

struct RegisterView: View {
    
    // ⭐ 注入 AuthService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    // 從 LoginView 傳入的註冊身份
    let role: UserRole
    
    // 追蹤輸入狀態：必填欄位
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // 追蹤 Cooker 專屬欄位：當身份為私廚時才需要
    @State private var cookerName = ""
    @State private var cookerCuisine = ""
    
    // ⭐ 追蹤 UI 狀態
    @State private var isLoading = false
    @State private var registrationError: String?
    @State private var isRegistrationSuccessful = false
    
    // 驗證表單是否有效 (簡化版：確保必填欄位不為空且密碼相符)
    var isFormValid: Bool {
        // 1. 基礎檢查：Email/Password/確認密碼不可為空
        guard !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty else { return false }
        
        // 2. 密碼檢查：密碼必須相符
        guard password == confirmPassword else { return false }
        
        // 3. Cooker 額外檢查：私廚名稱和菜系不可為空
        if role == .cooker {
            guard !cookerName.isEmpty && !cookerCuisine.isEmpty else { return false }
        }
        
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: - 1. 帳號資訊 (通用欄位)
                Section(header: Text("帳號與密碼")) {
                    TextField("電子郵件 (必填)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("密碼 (至少 6 位)", text: $password)
                    SecureField("確認密碼", text: $confirmPassword)
                    
                    // 密碼不符提示
                    if password != confirmPassword && (!password.isEmpty || !confirmPassword.isEmpty) {
                        Text("⚠️ 兩次密碼輸入不相符")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // MARK: - 2. 私廚專屬資訊 (動態顯示)
                if role == .cooker {
                    cookerFields
                }
                
                // ⭐ 錯誤訊息顯示
                if let error = registrationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("註冊成為 \(role.rawValue)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            
            // 底部註冊按鈕
            VStack {
                Button {
                    registerUser()
                } label: {
                    if isLoading {
                        ProgressView() // 載入中動畫
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("確認註冊")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                // ⭐ 根據載入狀態顯示 ProgressView
                .background(isFormValid && !isLoading ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                // 禁用條件：如果表單無效或正在載入，則禁用
                .disabled(!isFormValid || isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // ⭐ 註冊成功後的提示
            .alert("註冊成功！", isPresented: $isRegistrationSuccessful) {
                Button("回到登錄頁") {
                    // 點擊後關閉整個模態視圖，回到 LoginView
                    dismiss()
                }
            } message: {
                Text("您的 \(role.rawValue) 帳號已建立，請返回登錄。")
            }
        }
    }
    
    // MARK: - 私廚專屬欄位輔助 View (保持不變)
    var cookerFields: some View {
        Section(header: Text("私廚資訊 (必填)")) {
            // 建議：私廚註冊需要更細緻的資訊
            TextField("私廚名稱", text: $cookerName)
            
            Picker("拿手菜系", selection: $cookerCuisine) {
                Text("台式傳統").tag("台式傳統")
                Text("川菜").tag("川菜")
                Text("養生輕食").tag("養生輕食")
                Text("其他").tag("其他")
            }
            .onAppear {
                // 設定 Picker 初始值
                if cookerCuisine.isEmpty {
                    cookerCuisine = "台式傳統"
                }
            }
        }
    }
    
    // MARK: - 註冊邏輯 (實作 Firebase 呼叫)
    func registerUser() {
        isLoading = true
        registrationError = nil
        
        // 1. 收集額外資料 (如果是私廚)
        var extraData: [String: Any] = [:]
        if role == .cooker {
            extraData = [
                "cookerName": cookerName,
                "cuisine": cookerCuisine
            ]
        }
        
        // 2. 呼叫 AuthService 進行註冊
        authService.register(
            role: role,
            email: email,
            password: password,
            extraData: extraData
        ) { result in
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    // 註冊成功，觸發 Alert
                    self.isRegistrationSuccessful = true
                    
                case .failure(let error):
                    // 註冊失敗，顯示 Firebase 錯誤訊息
                    self.registrationError = error.localizedDescription
                    print("註冊失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 預覽

#Preview {
    // 預覽私廚註冊頁
    RegisterView(role: .cooker)
        // 必須注入 AuthService 讓預覽可以運作
        .environmentObject(AuthService())
}

#Preview {
    // 預覽顧客註冊頁
    RegisterView(role: .user)
        .environmentObject(AuthService())
}
