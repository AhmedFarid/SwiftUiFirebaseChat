//
//  ChatUser.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 20/10/2022.
//

import Foundation

struct ChatUser: Identifiable {
  
  var id: String { uid }
  
  let uid, email, profileImageUrl: String
  
  init(data: [String: Any]) {
    self.uid = data["uid"] as? String ?? ""
    self.email = data["email"] as? String ?? ""
    self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    
  }
}
