import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isConnected = true
    @State private var navigate = false
    @State private var toLink = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        if Auth.auth().currentUser == nil { // if the user is not signed in
            LoginView()
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
        } else {
            MainAppView()
                .task {
                    isConnected = await checkConnection()
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
                .overlay {
                    if !isConnected {
                        ZStack {
                            NavigationLink("", destination: ContentView(), isActive: $navigate)
                            Color(white:0, opacity: 0.7)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white)
                                .frame(width: 350, height: 300)
                                .overlay {
                                    VStack {
                                        Text("Sorry! You're not connected to a partner!")
                                            .padding(.bottom, 20)
                                        Text("Enter your partner's username below:")
                                        HStack {
                                            TextField("Partner Username", text: $toLink)
                                                .padding(5)
                                                .autocapitalization(.none)
                                                .border(Color(uiColor: UIColor.systemGray3), width: 1)
                                            
                                            Button("Connect", action: {
                                                Task {
                                                    let result = await addPartner(username:toLink)
                                                    alertMessage = result.error
                                                    print("alertMessage is \(alertMessage)")
                                                    if alertMessage == "" {
                                                        alertMessage = "Attempted to connect to user with the username: \(toLink)\nIf that's correct, tell them to connect to you too!"
                                                    }
                                                    showAlert = result.alert
                                                    await isConnected = checkConnection()
                                                }
                                            })
                                        }
                                            .frame(width: 325)
                                        Text("")
                                        Text("Your partner will have to connect to you as well.")
                                            .multilineTextAlignment(.center)
                                        Text("")
                                        HStack {
                                            Text("Should be connected?")
                                            Button("Refresh", action: {
                                                Task{
                                                    isConnected = await checkConnection();
                                                }
                                            })
                                        } // end HStack
                                        .padding(.bottom, 20)
                                        Button("Sign Out", action: {
                                            do {
                                                try Auth.auth().signOut()
                                                navigate = true
                                            } catch let signOutError as NSError {
                                                print("Error signing out:", signOutError)
                                            }
                                        })
                                        .foregroundColor(.red)
                                    } // end VStack
                                }// end rectangle overlay
                        } // end ZStack
                    }
                } // end overlay
                .ignoresSafeArea()
                .colorScheme(.light) // Force the view to be in light mode
                .alert(alertMessage == "You can't connect to yourself!" ? "Error" : "Connection Attempted", isPresented: $showAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(alertMessage)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
