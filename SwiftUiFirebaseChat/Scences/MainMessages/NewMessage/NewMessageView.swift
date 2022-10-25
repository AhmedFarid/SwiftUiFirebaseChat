//
//  NewMessageView.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 20/10/2022.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
  
  @Published var users = [ChatUser]()
  @Published var errorMessage = ""
  init() {
    fetchAllUser()
  }
  
  private func fetchAllUser() {
    FirebaseManger.shared.fireStore.collection("users")
      .getDocuments { documentSnapshot, error in
        if let error = error {
          self.errorMessage = "Failed to fetch all users: \(error)"
          print("Failed to fetch all users: \(error)")
          return
        }
        
        documentSnapshot?.documents.forEach({ snapshot in
          let data = snapshot.data()
          let user = ChatUser(data: data)
          if user.uid != FirebaseManger.shared.auth.currentUser?.uid {
            self.users.append(.init(data: data))
          }
          
        })
      }
  }
}

struct NewMessageView: View {
  
  let didSelectNewUser: (ChatUser) -> ()
  
  // for dismiss view cancel button
  @Environment(\.presentationMode) var presentationMode
  
  @ObservedObject var vm = CreateNewMessageViewModel()
  
  var body: some View {
    
    //MARK: - Navigation View
    NavigationView {
      
      //MARK: - Scroll View
      ScrollView {
        
        Text(vm.errorMessage)
        
        ForEach(vm.users) { user in
          Button {
            presentationMode.wrappedValue.dismiss()
            didSelectNewUser(user)
          } label: {
            HStack(spacing: 16) {
              WebImage(url: URL(string: user.profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 50)
                  .stroke(Color(.label),
                          lineWidth: 1)
                )
              Text(user.email)
                .foregroundColor(Color(.label))
              Spacer()
            }.padding(.horizontal)
          }
          Divider()
            .padding(.vertical, 8)
        }
        
      }.navigationTitle("New Message")
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
              presentationMode.wrappedValue
                .dismiss()
            } label: {
              Text("Cancel")
            }
          }
        }
    }
  }
}

struct NewMessageView_Previews: PreviewProvider {
  static var previews: some View {
    //NewMessageView()
    MainMessagesView()
  }
}
