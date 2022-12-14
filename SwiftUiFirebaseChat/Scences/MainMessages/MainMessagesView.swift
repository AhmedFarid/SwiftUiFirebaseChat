//
//  MainMessagesView.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 19/10/2022.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

class MainMessagesViewModel: ObservableObject {
  
  @Published var errorMessage = ""
  @Published var chatUser: ChatUser?
  
  // handle sign out
  @Published var isUserCurrentlyLoggedOut = false

  init() {
    
    DispatchQueue.main.async {
      self.isUserCurrentlyLoggedOut = FirebaseManger.shared.auth.currentUser?.uid == nil
    }
    
    fetchCurrentUser()
    fetchRecentMessages()
  }
  
  @Published var recentMessages = [RecentMessage]()
  
  private func fetchRecentMessages() {
    guard let uid = FirebaseManger.shared.auth.currentUser?.uid else {return}
    
    FirebaseManger.shared.fireStore
      .collection("recent_messages")
      .document(uid)
      .collection("messages")
      .order(by: "timestamp")
      .addSnapshotListener { querySnapshot, error in
        if let error = error {
          self.errorMessage = "Failed to listen for recent message: \(error)"
          print(error)
          return
        }
        
        querySnapshot?.documentChanges.forEach({ change  in
            let docId = change.document.documentID
          if let index = self.recentMessages.firstIndex(where: { rm in
            return rm.documentId == docId
          }) {
            self.recentMessages.remove(at: index)
          }
          self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
        })
      }
    
  }
  
  func fetchCurrentUser() {
    guard let uid = FirebaseManger.shared.auth.currentUser?.uid else {
      self.errorMessage = "Could not find firebase uid"
      return
    }
    FirebaseManger.shared.fireStore.collection("users").document(uid).getDocument { snapshot, error in
      if let error = error {
        self.errorMessage = "Failed to fetch current user: \(error)"
        return
      }
      guard let data = snapshot?.data() else {
        self.errorMessage = "No Data found"
        return
      }
      
      self.chatUser = .init(data: data)
    }
  }
  
  func handleSignOut() {
    try? FirebaseManger.shared.auth.signOut()
    isUserCurrentlyLoggedOut.toggle()
  }
  
}

struct MainMessagesView: View {
  
  @State var shouldShowLogOutOptions = false
  @ObservedObject var vm = MainMessagesViewModel()
  @State var shouldNavigateToChatLogView = false
  @State var chatUser: ChatUser?
  
  //handle New Message
  @State var shouldShowNewMessageScreen = false
   
  // MARK: - MainBody
  var body: some View {
    NavigationView {
      VStack {
        customNavBar
        messagesView
        NavigationLink("",isActive: $shouldNavigateToChatLogView) {
          ChatLogView(chatUser: self.chatUser)
        }
      }
      .overlay(
        newMessageButton, alignment: .bottom)
      .navigationBarHidden(true)
    }
  }
  
  // MARK: - customNavBar
  private var customNavBar: some View {
    HStack(spacing: 16) {
      
      WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
        .resizable()
        .scaledToFill()
        .frame(width: 50,height: 50)
        .clipped()
        .cornerRadius(50)
        .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label),lineWidth: 1))
        .shadow(radius: 5)
       
      VStack(alignment: .leading, spacing: 4) {
        let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
        Text(email)
          .font(.system(size: 24, weight: .bold))
        HStack {
          Circle()
            .foregroundColor(.green)
            .frame(width: 14,height: 14)
          Text("Online")
            .font(.system(size: 14))
            .foregroundColor(Color(.lightGray))
        }
      }
      Spacer()
      Button {
        shouldShowLogOutOptions.toggle()
      } label: {
        Image(systemName: "gear")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(Color(.label))
      }
    }
    .padding()
    .actionSheet(isPresented: $shouldShowLogOutOptions) {
      .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
        .destructive(Text("Sign Out"), action: {
          vm.handleSignOut()
        }),
        .cancel()
      ])
    }
    .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut,onDismiss: nil) {
      AuthView(didCompleteLoginProcess:  {
        self.vm.isUserCurrentlyLoggedOut = false
        self.vm.fetchCurrentUser()
      })
    }
  }
  
  // MARK: - MessagesView
  private var messagesView: some View {
    ScrollView {
      ForEach(vm.recentMessages) { recentMessage in
        VStack {
          NavigationLink {
            Text("Destination")
          } label: {
            HStack(spacing: 16) {
              WebImage(url: URL(string: recentMessage.profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipped()
                .cornerRadius(64)
                .overlay(RoundedRectangle(cornerRadius: 44)
                  .stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)
              VStack(alignment: .leading, spacing: 8) {
                Text(recentMessage.email)
                  .font(.system(size: 16, weight: .bold))
                  .foregroundColor(Color(.label))
                  
                Text(recentMessage.text)
                  .font(.system(size: 14))
                  .foregroundColor(Color(.darkGray))
                  .multilineTextAlignment(.leading)
              }
              Spacer()
              Text("22d")
                .font(.system(size: 14,weight: .semibold))
            }
          }
          Divider()
            .padding(.vertical, 8)
        }.padding(.horizontal)
      }
    }.padding(.bottom, 50)
  }
  
  // MARK: - newMessageButton
  private var newMessageButton: some View {
    
    Button {
     shouldShowNewMessageScreen.toggle()
    } label: {
      HStack {
        Spacer()
        Text("+ New Message")
          .font(.system(size:  16, weight: .bold))
        Spacer()
      }
      .foregroundColor(.white)
      .padding(.vertical)
      .background(Color.blue)
      .cornerRadius(32)
      .padding(.horizontal)
      .shadow(radius: 15)
    }
    .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
      NewMessageView(didSelectNewUser: { user in
        self.shouldNavigateToChatLogView.toggle()
        self.chatUser = user
      })
    }
  }
}




struct MainMessagesView_Previews: PreviewProvider {
  static var previews: some View {
    MainMessagesView()
      .preferredColorScheme(.dark)
    MainMessagesView()
  }
}
