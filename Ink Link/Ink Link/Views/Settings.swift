import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Settings: View {
    @State private var navigate = false
    @State private var connected = false
    @State private var toLink = ""
    @State private var partnerInfo = ""
    @State private var username = ""
    
    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemGray3)
                .ignoresSafeArea()
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
                .frame(width: 375, height: 450)
            
            VStack {
                NavigationLink("", destination: ContentView(), isActive: $navigate)
                Text("Settings")
                    .fontWeight(.bold)
                    .font(.largeTitle)
                    .offset(y: -160)
                
                HStack {
                    Text("Hello,")
                        .font(.title2)
                    Text("\(username)")
                        .font(.title2)
                }
                .offset(y:-70)
                .task {
                    username = await findUsername()
                }
                
                HStack {
                    Text("Connection Status:")
                        .underline()
                    
                    if(connected) {
                        Text("Connected to partner!")
                    } else {
                        Text("Not connected to anyone :(")
                    }
                }
                .offset(y: -50)
                
                Spacer()
                    .frame(height: 50)
                
                HStack {
                    Text("Partner Info: ")
                        .underline()
                    Text(partnerInfo)
                }
                .task {
                    partnerInfo = await findPartnerUsername()
                    connected = await checkConnection()
                }
                .padding()
                
                Button("Remove Partner", action: {
                    unlinkPartner()
                    navigate = true
                })
                
                Button("Sign Out", action: {
                    do {
                        try Auth.auth().signOut()
                        navigate = true
                    } catch let signOutError as NSError {
                        print("Error signing out:", signOutError)
                    }
                })
                .foregroundColor(.red)
                .offset(y: 125)
                
                Image("plane")
                    .resizable()
                    .frame(width: 350, height: 100)
                    .offset(y: 150)
            } // end VStack
        } // end ZStack
        .navigationTitle("")
        .navigationBarHidden(true)
    } // end body
}

// MARK: - Functions
func addPartner(username:String) async -> (error: String, alert: Bool) {
    var errorMessage = ""
    guard let user = Auth.auth().currentUser else {
        print("Error finding currentUser while trying to add partner")
        return ("Error finding currentUser while trying to add partner", true)
    }
    
    let db = Firestore.firestore()
    let userRef = db.collection("users").document(user.uid)
    
    do {
        let snapshot = try await userRef.getDocument()
        // get partnerUsername if it exists
        if let info = snapshot.get("username") as? String {
            if (username == info) {
                print("You can't connect to yourself!")
                return ("You can't connect to yourself!", true)
            }
        } else {
            print("Could not find user's username, somehow")
        }
    } catch {
        print("Error accessing document in Firestore")
    }
    
    // Search database for document with username as specified
    
    // The "let _ =" here is just to silence a warning that Swift gives about using
    // an asynchronous alternative
    let _ = db.collection("users").whereField("username", isEqualTo: username)
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error when finding user to connect to \(err)")
            } else {
                if querySnapshot!.documents.count == 0 {
                    print("No users found with this username")
                    errorMessage = "No users found with this username" // This doesn't work! function returns before reaching this point
                    return
                }
                for document in querySnapshot!.documents { // there should only be one document here
                    let partnerRef = document.reference
                    userRef.updateData( ["partnerID":partnerRef.documentID] )
                    userRef.updateData( ["partnerUsername":username] )
                    print("Connected user to ", username)
                }
            }
        }
    
    return (errorMessage , true)
}

func unlinkPartner() {
    guard let user = Auth.auth().currentUser else {
        print("Error finding currentUser while trying to remove partner")
        return
    }
    
    let userRef = Firestore.firestore().collection("users").document(user.uid)
    
    userRef.updateData([
        "partnerID": FieldValue.delete(),
        "partnerUsername": FieldValue.delete()
    ]) { err in
        if let error = err {
            print("Error removing partner: \(error)")
            // perhaps an alert
        } else {
            print("Removed partner successfully")
        }
    }
    
    
}

func findUsername() async -> String {
    let db = Firestore.firestore()
    var username:String = ""
    guard let user = Auth.auth().currentUser else {
        print("Error finding currentuser when searching for username")
        return ""
    }
    // Find our current user's document in the database
    let docRef = db.collection("users").document(user.uid)
    do {
        let snapshot = try await docRef.getDocument()
        // get partnerUsername if it exists
        if let info = snapshot.get("username") as? String {
            username = info
        } else {
            print("User does not have a partner")
        }
    } catch {
        print("Error accessing document in Firestore")
    }
    return username
}

func findPartnerUsername() async -> String {
    let db = Firestore.firestore()
    var partnerInfo:String = ""
    guard let user = Auth.auth().currentUser else {
        print("Error finding currentuser when finding partner info")
        return ""
    }
    // Find our current user's document in the database
    let docRef = db.collection("users").document(user.uid)
    do {
        let snapshot = try await docRef.getDocument()
        // get partnerUsername if it exists
        if let info = snapshot.get("partnerUsername") as? String {
            partnerInfo = info
        } else {
            print("User does not have a partner")
        }
    } catch {
        print("Error accessing document in Firestore")
    }
    return partnerInfo
}

func findPartnerUID() async -> String {
    let db = Firestore.firestore()
    var partnerUID = ""
    guard let user = Auth.auth().currentUser else {
        print("Error finding currentuser when finding partner info")
        return ""
    }
    let docRef = db.collection("users").document(user.uid)
    do {
        let snapshot = try await docRef.getDocument()
        if let partnerID = snapshot.get("partnerID") as? String {
            partnerUID = partnerID
        } else {
            print("User does not have a partner")
        }
    } catch {
        print("Error accessing document in Firestore when checking for connection")
    }
    return partnerUID
}

func checkConnection() async -> Bool {
    let db = Firestore.firestore()
    var partnerInfo = ""
    var userToPartner = false
    var partnerToUser = false
    
    guard let user = Auth.auth().currentUser else {
        print("Error finding currentUser while checking for partner connection")
        return false
    }
    
    // Check for a partnerID in the document of the currentUser
    var docRef = db.collection("users").document(user.uid)
    do {
        let snapshot = try await docRef.getDocument()
        if let partnerID = snapshot.get("partnerID") as? String {
            userToPartner = true
            partnerInfo = partnerID
        } else {
            print("User does not have a partner")
            return false
        }
    } catch {
        print("Error accessing document in Firestore when checking for connection")
        return false
    }
    
    // Check if partner is connected to user
    docRef = db.collection("users").document(partnerInfo)
    do {
        let snapshot = try await docRef.getDocument()
        if let partnerID = snapshot.get("partnerID") as? String {
            if partnerID == user.uid { // User is also the user's partner, return true
                partnerToUser = true
                return true
            }
        } else {
            print("Partner is not connected to user")
            return false
        }
    } catch {
        print("Error accessing document in Firestore when checking User's Partner's document")
        return false
    }
    
    return (userToPartner && partnerToUser) // Code should technically never reach this point, I think
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
