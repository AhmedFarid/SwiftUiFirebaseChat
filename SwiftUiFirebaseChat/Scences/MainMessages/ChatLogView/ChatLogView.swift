//
//  ChatLogView.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 25/10/2022.
//

import SwiftUI
import Firebase

class ChatLogViewModel: ObservableObject {
  
  @Published var chatText = ""
  @Published var errorMessage = ""
  
  let chatUser: ChatUser?
  
  init(chatUser: ChatUser?) {
    self.chatUser = chatUser
  }
  
  func handelSend() {
    print(chatText)
    
    guard let fromId = FirebaseManger.shared.auth.currentUser?.uid else {return}
    guard let toId = chatUser?.uid else {return}
    
    let document = FirebaseManger.shared.fireStore
      .collection("messages")
      .document(fromId)
      .collection(toId)
      .document()
    
    let messageData = ["fromId": fromId, "toId": toId, "text": self.chatText, "timestamp": Timestamp()] as [String: Any]
    document.setData(messageData) { error in
      if let error = error {
        self.errorMessage = "Failed to save message into FireStore \(error)"
        return
      }
      
      print("Successfully saved current user sending message")
    }
    
    let recipientMessageDocument = FirebaseManger.shared.fireStore
      .collection("messages")
      .document(toId)
      .collection(fromId)
      .document()
    recipientMessageDocument.setData(messageData) { error in
      if let error = error {
        print(error)
        self.errorMessage = "Failed to save message into FireStore \(error)"
        return
      }
      
      print("Recipient saved message as well ")
      self.chatText = ""
    }
      
    
  }
}

struct ChatLogView: View {
  
  let chatUser: ChatUser?
  @ObservedObject var vm: ChatLogViewModel
  
  init(chatUser: ChatUser?) {
    self.chatUser = chatUser
    self.vm = .init(chatUser: chatUser)
  }
  
  
  
  var body: some View {
    
 //MARK: - MainView
    //MARK: - Chat Message
    ZStack {
      messageView
      Text(vm.errorMessage)
    }
    
    //MARK: - MAIN VIEW UI
    .navigationTitle(chatUser?.email ?? "")
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private var messageView: some View {
    VStack {
      ScrollView {
        ForEach(0..<20) {num in
          HStack {
            Spacer()
            HStack {
              Text("FakeMessageForNow")
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
          }
          .padding(.horizontal)
          .padding(.top,8)
        }
        HStack {
          Spacer()
        }
      }
      .background(Color(.init(white: 0.9, alpha: 1)))
      .safeAreaInset(edge: .bottom) {
        //MARK: - Chat Bottom Bar
        chatBottomBar
          .background(Color(.systemBackground).ignoresSafeArea())
      }
    }
    
  }
  
  private var chatBottomBar: some View {
    HStack {
      Image(systemName: "photo.on.rectangle")
        .font(.system(size: 24))
        .foregroundColor(Color(.darkGray))
      ZStack {
        //DescriptionPlaceholder()
        TextEditor(text: $vm.chatText)
          .opacity(vm.chatText.isEmpty ? 0.5 : 1)
      }
      .frame(height: 40)
      Button {
        vm.handelSend()
      } label: {
        Text("Send")
          .foregroundColor(.white)
      }
      .padding(.horizontal)
      .padding(.vertical, 8)
      .background(Color.blue)
      .cornerRadius(8)
      
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
  }
}

struct ChatLogView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      MainMessagesView()
    }
  }
}
