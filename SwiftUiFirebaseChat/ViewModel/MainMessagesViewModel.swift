//
//  MainMessagesViewModel.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 20/10/2022.
//

import Foundation
import SwiftUI

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
