import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct drawing : Identifiable {
    let id = UUID()
    let image:UIImage
}

struct Gallery: View {
    @State private var images:[drawing] = []
    @State private var recentImage:UIImage = UIImage()
    
    @State private var gray = Color(red: 0.36, green: 0.45, blue: 0.49)
    @State private var green = Color(red: 0.39, green: 0.71, blue: 0.67)
    @State private var lightBlue = Color(red: 0.75, green: 0.99, blue: 0.98)
    @State private var lightGreen = Color(red: 0.85, green: 1.0, blue: 0.94)
    @State private var white = Color(red: 0.99, green: 1.0, blue: 0.99)
    
    var body: some View {
        ZStack {
            lightBlue.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack {
                        Text("Gallery")
                            .foregroundColor(Color.black)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        Image(uiImage: recentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay{
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 2)
                            }
                            .padding(.bottom, 25)
                        
                        Image("plane")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        
                        Text("Scroll for past drawings!")
                            .font(.title)
                            .foregroundColor(gray)
                            .padding(.bottom, 130)
                        
                        ForEach(images) { image in
                            Image(uiImage: image.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 350)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay{
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(gray, lineWidth: 5)
                                }
                                .padding(.bottom, 30)
                        }
                    } // end VStack
                    .task{
                        await updateImages()
                    }
                } // end ScrollView
            } // end VStack
        } // end ZStack
        .navigationTitle("")
        .navigationBarHidden(true)
    } // end body
    
    func updateImages() async {
        var recentImageURL:String
        
        guard let user = Auth.auth().currentUser else {
            print("Error finding currentuser when finding partner info")
            return
        }
        
        images.removeAll()
        let partnerUID = await findPartnerUID()
        let db = Firestore.firestore()
        
        // First, display the most recent image
        // Get download link from user's document
        let docRef = db.collection("users").document(user.uid)
        
        do {
            let snapshot = try await docRef.getDocument()
            if let imageURL = snapshot.get("recentURL") as? String {
                recentImageURL = imageURL
                // Download image
                let storage = Storage.storage()
                let storageRef = storage.reference(forURL: imageURL) // Storage reference made from saved URL in firestore
                // Download image with max size 1MB
                storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error when downloading image! \(error)")
                        return
                    } else {
                        guard let data = data else {
                            print("Error with image data or something lol")
                            return
                        }
                        guard let image = UIImage(data: data) else {
                            print("Error converting data to UIImage")
                            return
                        }
                        recentImage = image
                    }
                }
            } else {
                print("No recent image found")
                return
            }
        } catch {
            print("Error accessing document in Firestore when finding recent image")
            return
        }
        
        // let _ = here is just to get rid of an unsightly warning
        let _ = db.collection("\(partnerUID)->\(user.uid)").whereField("url", isNotEqualTo: recentImageURL).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error when finding user to connect to \(err)")
                } else if let querySnapshot = querySnapshot {
                    if querySnapshot.documents.count == 0 {
                        print("Nothing in this collection")
                        // perhaps an alert
                        return
                    }
                    for document in querySnapshot.documents { // For every image in connection folder, add to images array
                        // Follow image url and download image to save to array
                        guard let url = document.get("url") as? String else {
                            print("Error accessing url field, or maybe error unwrapping url to string")
                            return
                        }
                        let storage = Storage.storage()
                        let storageRef = storage.reference(forURL: url) // Storage reference made from saved URL in firestore
                        // Download image with max size 1MB
                        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Error when downloading image! \(error)")
                                return
                            } else {
                                guard let data = data else {
                                    print("Error with image data or something lol")
                                    return
                                }
                                guard let image = UIImage(data: data) else {
                                    print("Error converting data to UIImage")
                                    return
                                }
                                images.append(drawing(image:image))
                            }
                        }
                    } // end for loop
                } // if let querySnapshot =
            } // end query
    }// end updateImageArray()
} // end Gallery

struct Gallery_Previews: PreviewProvider {
    static var previews: some View {
        Gallery()
    }
}
