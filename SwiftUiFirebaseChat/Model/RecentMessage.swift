//
//  RecentMessage.swift
//  SwiftUiFirebaseChat
//
//  Created by macbook on 04/11/2022.
//

import Foundation

struct RecentMessage: Identifiable {
  var id: String { documentId }
  
  let documentId: String
  let text, fromId, toId: String
  let email, profileImageUrl: String
  let timestamp: Timestamp
  
  
  init(documentId: String,data: [String: Any]) {
    self.documentId = documentId
    self.text = data["text"] as? String ?? ""
    self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    self.email = data["email"] as? String ?? ""
    self.fromId = data["fromId"] as? String ?? ""
    self.toId = data["toId"] as? String ?? ""
    self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
  }
  
}
