//
//  ChatLogView.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 25/10/2022.
//

import SwiftUI
import Firebase

struct FirebaseConstants {
  static let fromId = "fromId"
  static let toId = "toId"
  static let text = "text"
  static let timeStamp = "timestamp"
  static let profileImageUrl = "profileImageUrl"
  static let email = "email"
}

struct ChatMessage: Identifiable{
  var id: String {documentId}
  let documentId: String
  let fromId, toId, text: String
  
  init(documentId: String ,data: [String: Any]) {
    self.documentId = documentId
    self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
    self.toId = data[FirebaseConstants.toId] as? String ?? ""
    self.text = data[FirebaseConstants.text] as? String ?? ""
  }
}

class ChatLogViewModel: ObservableObject {
  
  @Published var chatText = ""
  @Published var errorMessage = ""
  
  @Published var chatMessages = [ChatMessage]()
  
  let chatUser: ChatUser?
  
  init(chatUser: ChatUser?) {
    self.chatUser = chatUser
    
    fetchMessages()
  }
  
  private func fetchMessages() {
    guard let fromId = FirebaseManger.shared.auth.currentUser?.uid else {return}
    guard let toId = chatUser?.uid else {return}
    
    
    FirebaseManger.shared.fireStore
      .collection("messages")
      .document(fromId)
      .collection(toId)
      .order(by: "timestamp")
      .addSnapshotListener { querySnapshot, error in
        if let error = error {
          self.errorMessage = "Failed to listen for messages: \(error)"
          print(error)
          return
        }
        querySnapshot?.documentChanges.forEach({ change in
          if change.type == .added {
            let data = change.document.data()
            self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
          }
        })
        DispatchQueue.main.async {
          self.count += 1
        }
      }
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
    
    let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, "timestamp": Timestamp()] as [String: Any]
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
      
      self.persistRecentMessage()
      
      self.chatText = ""
      self.count += 1
    }
  }
  
  private func persistRecentMessage() {
    
    guard let uid = FirebaseManger.shared.auth.currentUser?.uid else {return}
    guard let toId = self.chatUser?.uid else {return}
    
    let document = FirebaseManger.shared.fireStore
      .collection("recent_messages")
      .document(uid)
      .collection("messages")
      .document(toId)
    let data = [
      FirebaseConstants.timeStamp: Timestamp(),
      FirebaseConstants.text: self.chatText,
      FirebaseConstants.fromId: uid,
      FirebaseConstants.toId: toId,
      FirebaseConstants.profileImageUrl: chatUser?.profileImageUrl ?? "",
      FirebaseConstants.email: chatUser?.email ?? ""
    ] as [String: Any]
    
    // you'll need to save another very similar dictionary for the recipient of this message 
    
    document.setData(data) {error in
      if let error = error {
        self.errorMessage = "Failed to save recent message: \(error)"
        print("Failed to save recent message: \(error)")
        return
      }
      
    }
  }
  
  @Published var count = 0
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
  
  static let emptyScrollToString = "Empty"
  
  private var messageView: some View {
    VStack {
      ScrollView {
        ScrollViewReader { scrollViewProxy in
          VStack {
            ForEach(vm.chatMessages) {message in
              MessageView(message: message)
            }
            HStack {
              Spacer()
            }
            .id(ChatLogView.emptyScrollToString)
          }
          .onReceive(vm.$count) { _  in
            withAnimation(.easeOut(duration: 0.5)) {
              scrollViewProxy.scrollTo(ChatLogView.emptyScrollToString, anchor: .bottom)
            }
          }
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
        DescriptionPlaceholder()
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

struct MessageView: View {
  
  let message: ChatMessage
  
  var body: some View {
    VStack {
      if message.fromId == FirebaseManger.shared.auth.currentUser?.uid {
        HStack {
          Spacer()
          HStack {
            Text(message.text)
              .foregroundColor(.white)
          }
          .padding()
          .background(Color.blue)
          .cornerRadius(8)
        }
      }else {
        HStack {
          
          HStack {
            Text(message.text)
              .foregroundColor(.black)
          }
          .padding()
          .background(Color.white)
          .cornerRadius(8)
          Spacer()
        }
      }
    }
    .padding(.horizontal)
    .padding(.top,8)
  }
}

private struct DescriptionPlaceholder: View {
  var body: some View {
    HStack {
      Text("Description")
        .foregroundColor(Color(.gray))
        .font(.system(size: 17))
        .padding(.leading,5)
        .padding(.top, -4)
      Spacer()
    }
  }
}

struct ChatLogView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      MainMessagesView()
    }
  }
}
