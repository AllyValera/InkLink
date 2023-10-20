import SwiftUI

struct ArtPrompts: View {
    @State private var noun = ""
    @State private var animal = ""
    @State private var adjective = ""
    @State private var navigate = false
    @State private var connected = false
    
    var body: some View {
        ZStack {
            NavigationLink("", destination: ContentView(), isActive: $navigate)
            Color(red: 0.75, green: 0.99, blue: 0.98)
                .ignoresSafeArea()
            
            Image("easel")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .frame(width: 350, height: 450)
                .offset(y: 90)
            
            VStack {
                // Maybe to make "Art Prompt Generator" show up at the very top of the page and stay there, we can use a NavigationView with a navigationBarTitle modifier instead of this?
                Text("Art Prompt Generator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                    .offset(y: -175)
                
                Text("Click the button to generate some inspiration!")
                    .padding(.bottom, 20)
                    .offset(y: -175)
                
                Button("Generate Prompt") {
                    fetchWord(type: "noun")
                    fetchWord(type: "animal")
                    fetchWord(type: "adjective")
                }
                .offset(y: -175)
                
                VStack {
                    Text("Noun: \(noun)\n\n")
                    
                    Text("Animal: \(animal)\n\n")
                    
                    Text("Adjective: \(adjective)")
                }
                .offset(y: -25)
            } // end VStack
        } // end ZStack
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            connected = await checkConnection()
            if(!connected) {
                navigate = true
            }
        }
    } // end body
    
    func fetchWord(type: String) {
        // incomplete url
        let urlString = "https://random-word-form.herokuapp.com/random/\(type)"
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    if let word = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        DispatchQueue.main.async {
                            
                            // Deciding what word to get from the url
                            switch type {
                            case "noun":
                                self.noun = word
                            case "animal":
                                self.animal = word
                            case "adjective":
                                self.adjective = word
                            default:
                                break
                            }
                        }
                    }
                }
            }.resume()
        }
    } // end fetchWord
}

struct ArtPrompts_Previews: PreviewProvider {
    static var previews: some View {
        ArtPrompts()
    }
}
