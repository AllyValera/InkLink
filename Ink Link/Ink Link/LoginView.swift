import SwiftUI
import Firebase

struct LoginView: View {
    // MARK: - Variables
    @State private var email = ""
    @State private var password = ""
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
                .frame(width: 360, height: 450)
            
            VStack {
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(2)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10.0)

                Spacer()
                    .frame(height: 30)
                
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .frame(width: 325)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay{
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.36, green: 0.45, blue: 0.49), lineWidth: 1)
                    }
                    .padding(.bottom, 20)
                    .autocapitalization(.none) // stops auto caps
                    .colorScheme(.light) // Force the view to be in light mode
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .frame(width: 325)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay{
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.36, green: 0.45, blue: 0.49), lineWidth: 1)
                    }
                    .padding(.bottom, 20)
                    .autocapitalization(.none) // stops auto caps
                    .colorScheme(.light) // Force the view to be in light mode
                
                // Sign In button
                Button(action: {
                    signIn()
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220, height: 60)
                        .background(Color.blue)
                        .cornerRadius(15.0)
                }
                .offset(y: 20)
                
                HStack {
                    Text("Don't have an account?")
                    NavigationLink(destination: RegisterView()) {
                        Text("Sign up here.")
                            .foregroundColor(Color.blue)
                    }
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
                }
                .padding(.top, 50)
                .offset(y: 27)
                .font(.system(size: 18))
                
                NavigationLink("", destination:ContentView(), isActive:$navigate)
            } // end VStack
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .colorScheme(.light)
        }
    }
    
    // MARK: - Functions
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                // TODO: navigate to the home page
                print("login successful")
                navigate = true;
                
            }
        }
    } // end signIn()
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
