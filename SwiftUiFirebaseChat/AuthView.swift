//
//  ContentView.swift
//  SwiftUiFirebaseChat
//
//  Created by macbook on 11/10/2022.
//

import SwiftUI
import Firebase

class FirebaseManger: NSObject {
  let auth: Auth
  
  static let shared = FirebaseManger()
  
  override init() {
    FirebaseApp.configure()
    self.auth = Auth.auth()
    super.init()
  }
}

struct AuthView: View {
  var authMethod = ["Login", "Create Account"]
  
  @State private var isLoginMode = "Login"
  @State private var email = ""
  @State private var password = ""
  @State private var loginStatusMessage = ""
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 12) {
          
          // picker view
          Picker(selection: $isLoginMode) {
            ForEach(authMethod, id: \.self) {
              Text($0)
            }
          } label: {
            Text("Picker here")
          }.pickerStyle(.segmented)
          
          
          // image button
          if isLoginMode != "Login"  {
            Button {
              
            } label: {
              Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 100))
                .padding()
                .foregroundColor(.black)
            }
          }
          
          // text field
          Group {
            TextField("Email", text: $email)
              .keyboardType(.emailAddress)
              .autocapitalization(.none)
            SecureField("Password", text: $password)
          }.background(Color.white)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(height: 45)
          
          
          // create account
          Button {
            handleAction()
          } label: {
            HStack {
              Spacer()
              Text(isLoginMode == "Login" ? "Log In" :  "Create Account")
                .foregroundColor(.white)
                .font(.system(size: 14 ,weight: .semibold))
                .padding(.vertical, 12)
              Spacer()
            }.background(Color.blue)
              .cornerRadius(8)
          }
          Text(self.loginStatusMessage)
            .foregroundColor(Color.red)
        }.padding()
        
        // navigation title
      }.navigationTitle(isLoginMode == "Login" ? "Log In" :  "Create Account")
        .background(Color(.init(white: 0, alpha: 0.05))
          .ignoresSafeArea())
    }.navigationViewStyle(StackNavigationViewStyle())
  }
  
  private func handleAction() {
    if isLoginMode == "Login"  {
      loginUser()
    }else {
      createNewAccount()
    }
  }
  
  private func createNewAccount() {
    FirebaseManger.shared.auth.createUser(withEmail: email, password: password) { result, error in
      if let error = error {
        self.loginStatusMessage = "error in create account \(error.localizedDescription)"
        return
      }
      self.loginStatusMessage = "Success To Create User \(result?.user.uid ?? "")"
    }
  }
  
  private func loginUser() {
    FirebaseManger.shared.auth.signIn(withEmail: email, password: password) {result, error in
      if let error = error {
        self.loginStatusMessage = "error in login to account \(error.localizedDescription)"
        return
      }
      self.loginStatusMessage = "Success To login user id: \(result?.user.uid ?? "")"
    }
  }
}



struct AuthView_Previews: PreviewProvider {
  static var previews: some View {
    AuthView()
  }
}
