//
//  ContentView.swift
//  SwiftUiFirebaseChat
//
//  Created by macbook on 11/10/2022.
//

import SwiftUI

struct AuthView: View {
  
  let didCompleteLoginProcess: () -> ()
  
  var authMethod = ["Login", "Create Account"]
  
  @State private var isLoginMode = "Login"
  @State private var email = ""
  @State private var password = ""
  @State private var loginStatusMessage = ""
  
  @State private var shouldShowImagePicker = false
  
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
              shouldShowImagePicker.toggle()
            } label: {
              VStack {
                if let image = self.image {
                  Image(uiImage: image)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .scaledToFill()
                    .cornerRadius(64)
                }else {
                  Image(systemName: "person.fill")
                    .font(.system(size: 64))
                    .padding()
                    .foregroundColor(Color(.label))
                }
              }
              .overlay(RoundedRectangle(cornerRadius: 64)
                .stroke(Color.black, lineWidth: 3)
              )
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
      .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
        ImagePicker(image: $image)
      }
  }
  
  @State var image: UIImage?
  
  
  private func handleAction() {
    if isLoginMode == "Login"  {
      loginUser()
    }else {
      createNewAccount()
    }
  }
  
  private func createNewAccount() {
    
    if self.image == nil {
      self.loginStatusMessage = "You must select an avatar image"
      return 
    }
    
    FirebaseManger.shared.auth.createUser(withEmail: email, password: password) { result, error in
      if let error = error {
        self.loginStatusMessage = "error in create account \(error.localizedDescription)"
        return
      }
      self.loginStatusMessage = "Success To Create User \(result?.user.uid ?? "")"
      self.persistImageToStorage()
    }
  }
  
  private func loginUser() {
    FirebaseManger.shared.auth.signIn(withEmail: email, password: password) {result, error in
      if let error = error {
        self.loginStatusMessage = "error in login to account \(error.localizedDescription)"
        return
      }
      self.loginStatusMessage = "Success To login user id: \(result?.user.uid ?? "")"
      self.didCompleteLoginProcess()
    }
  }
  
  private func persistImageToStorage() {
//    let fileName = UUID().uuidString
    guard let uid = FirebaseManger.shared.auth.currentUser?.uid else {return}
    let ref = FirebaseManger.shared.storage.reference(withPath: uid)
    guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
    ref.putData(imageData) { metadata, error in
      if let error = error {
        self.loginStatusMessage = "Failed to push image to storage: \(error)"
        return
      }
      ref.downloadURL { url, error in
        if let error = error {
          self.loginStatusMessage = "Failed to retrieve downloadedURL: \(error)"
          return
        }
        self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
        print(url?.absoluteString ?? "")
        
        guard let url = url else { return }
        storeUserInformation(imageProfileUrl: url)
      }
    }
  }
  
  private func storeUserInformation(imageProfileUrl: URL) {
    guard let uid = FirebaseManger.shared.auth.currentUser?.uid else { return }
    let userData = ["email": self.email, "uid": uid,"profileImageUrl": imageProfileUrl.absoluteString]
    FirebaseManger.shared.fireStore.collection("users")
      .document(uid).setData(userData) { error in
        if let error = error {
          print(error)
          self.loginStatusMessage = "\(error)"
          return
        }
        
        print("Success")
        
        self.didCompleteLoginProcess()
      }
  }
}



struct AuthView_Previews: PreviewProvider {
  static var previews: some View {
    AuthView(didCompleteLoginProcess: {
      
    })
  }
}
