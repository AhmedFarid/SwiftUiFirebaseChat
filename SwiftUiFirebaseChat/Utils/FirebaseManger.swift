//
//  FirebaseManger.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 20/10/2022.
//

import Foundation
import Firebase
import FirebaseStorage

class FirebaseManger: NSObject {
  let auth: Auth
  let storage: Storage
  let fireStore: Firestore
  static let shared = FirebaseManger()
   
  
  override init() {
    FirebaseApp.configure()
    self.auth = Auth.auth()
    self.storage = Storage.storage()
    self.fireStore = Firestore.firestore()
    super.init()
  }
}
