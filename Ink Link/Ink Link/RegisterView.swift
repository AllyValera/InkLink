import SwiftUI
import Firebase
import FirebaseFirestore

struct RegisterView: View {
    // MARK: - Variables
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    @State private var navigate = false
    // MARK: - body View
    var body: some View {
        ZStack {
            Image("paperplane")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.white).opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                )
                .frame(width: 360, height: 550)
            
            VStack {
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .background(Color.white.opacity(0.4))
                    .cornerRadius(10.0)

                Spacer()
                    .frame(height: 30)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay{
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.36, green: 0.45, blue: 0.49), lineWidth: 1)
                    }
                    .frame(width: 325)
                    .padding(.bottom, 20)
                    .autocapitalization(.none) // stops auto caps
                    .colorScheme(.light) // Force the view to be in light mode
                
                TextField("Username", text: $username)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay{
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.36, green: 0.45, blue: 0.49), lineWidth: 1)
                    }
                    .frame(width: 325)
                    .padding(.bottom, 20)
                    .autocapitalization(.none) // stops auto caps
                    .colorScheme(.light) // Force the view to be in light mode
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay{
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.36, green: 0.45, blue: 0.49), lineWidth: 1)
                    }
                    .frame(width: 325)
                    .padding(.bottom, 20)
                    .autocapitalization(.none) // stops auto caps
                    .colorScheme(.light) // Force the view to be in light mode
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay{
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.36, green: 0.45, blue: 0.49), lineWidth: 1)
                    }
                    .frame(width: 325)
                    .padding(.bottom, 20)
                    .autocapitalization(.none) // stops auto caps
                    .colorScheme(.light) // Force the view to be in light mode
                
                Button(action: {
                    register()
                }) {
                    Text("Register")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 60)
                        .background(Color.blue)
                        .cornerRadius(15.0)
                }
                HStack {
                    Text("Already have an account?")
                    NavigationLink(destination: LoginView()) {
                        Text("Log in here.")
                            .foregroundColor(Color.blue)
                    }
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
                }
                .offset(y: 15)
                .font(.system(size: 18))
            } //end VStack
            .padding()
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .colorScheme(.light)
        }
        
        NavigationLink("", destination: ContentView(), isActive: $navigate)
        
    } // end body
    
    // MARK: - Functions
    func register() {
        // TODO: Add extra criteria to check and validate usernames/passwords
        
        // Validation
        // Firebase automatically trims fields, but I will do it anyway to ensure consistency
        email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check email
        if email == "" || email.count < 5 || emailValid(thisEmail: email) == false {
            alertMessage = "Invalid Email! You must input an email address with an '@' and a '.'!"
            showAlert = true
            
            return
        }
        
        // Check username
        if username == "" || username.count < 6 || usernameValid(thisUser: username) == false {
            alertMessage = "Invalid Username! Username must be at least 6 characters without blank spaces!"
            showAlert = true
            
            return
        }
        
        // Check password
        // Firebase makes it so that passwords need to be at least 6 characters long, but I will include extra steps for validation
        if password == "" || password.count < 6 || passwordValid(thisPass: password) == false {
            alertMessage = "Invalid Password! Password must be at least 6 characters with at least one capital!"
            showAlert = true
            
            return
        }
        
        if confirmPassword == "" || confirmPassword != password {
            alertMessage = "Invalid Re-Entered Password! Re-Entered password must match previously input password!"
            showAlert = true
            
            return
        }
        
        // create a new user in Firebase Authentication with the specified email and password
        // The FirebaseAuth createUser method takes two parameters - the user's email and password
        // It returns a result object that contains information about the newly created user
        // If it was not successful it returns an error object
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error creating user:", error.localizedDescription)
                alertMessage = "Error creating user: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let uid = result?.user.uid else {
                print("No user UID found.")
                alertMessage = "Error creating user: No user UID found."
                showAlert = true
                return
            }
            
            // userData is a dictionary that contains a single key-value pair; will be stored in the Firestore database under a document with a unique ID that is created automatically by Firestore.
            let userData = ["username": username]
            
            // db is an instance of the Firestore database, which is used to communicate with Firestore and perform operations like reading and writing data.
            let db = Firestore.firestore()
            
            // usersRef is a reference to the users collection in Firestore. usersRef is used to add a new document to the users collection with the userData dictionary as its data.
            let usersRef = db.collection("users")
            
            // Check if username is already taken
            usersRef.whereField("username", isEqualTo: username).getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking username:", error.localizedDescription)
                    alertMessage = "Error creating user: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                // checks if a document in the Firestore collection "users" already exists with the username that the user is trying to register with. If so, the username is already taken and the function returns an error message.
                if let snapshot = snapshot, !snapshot.isEmpty {
                    print("Username already taken.")
                    alertMessage = "Error creating user: Username already taken."
                    showAlert = true
                    return
                }
                
                // Username is unique, add it to the database
                usersRef.document(uid).setData(userData) { error in
                    if let error = error {
                        print("Error adding user data:", error.localizedDescription)
                        alertMessage = "Error creating user: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    
                    // Registration successful, navigate to home page
                    print("Registration successful.")
                    // TODO: navigate to the home page
                    navigate = true
                }
            }
        }
    }  // end register
    
    // Checks validity of email
    private func emailValid(thisEmail: String) -> Bool {
        var symbol = 0
        var period = 0
        
        for char in thisEmail {
            if char == "@" {
                symbol += 1
            }
            
            if char == "." {
                period += 1
            }
        }
        
        if symbol == 1 && period > 0 {
            return true
        }
        
        return false
    } // end emailValid
    
    // Check username for validity
    private func usernameValid(thisUser: String) -> Bool {
        for char in thisUser {
            if char == " " {
                return false
            }
        }
        
        return true
    } // end usernameValid
    
    private func passwordValid(thisPass: String) -> Bool {
        var uppercase = 0
        
        for char in thisPass {
            let scalarValues = String(char).unicodeScalars
            let charAscii = scalarValues[scalarValues.startIndex].value
            
            // ASCII value of uppercase letters are 65-90
            if charAscii >= 65 && charAscii <= 90 {
                uppercase += 1
            }
        }
        
        if uppercase > 0 {
            return true
        }
        
        return false
    } // end passwordValid
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
