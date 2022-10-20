//
//  NewMessageView.swift
//  SwiftUiFirebaseChat
//
//  Created by Systems on 20/10/2022.
//

import SwiftUI

struct NewMessageView: View {
  
  // for dismiss view cancel button
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    
    //MARK: - Navigation View
    NavigationView {
      
      //MARK: - Navigation View
      ScrollView {
        ForEach(0..<10) { num in
          Text("New User")
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
    NewMessageView()
  }
}
