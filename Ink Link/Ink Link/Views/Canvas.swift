import SwiftUI
import PencilKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct Canvas: View {
    var body: some View {
        Drawing()
    }
}

struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas()
    }
}

struct Drawing: View {
    @State private var navigate = false
    @State private var connected = false
    @State private var showAlert = false
    @State var partnerUID = ""
    
    @State var canvas = PKCanvasView()
    @State var isdraw = true
    @Environment(\.undoManager) var undoManager // undoManager class provided by Swift

    // Default is a black pen
    @State var color: Color = Color.black
    @State var type: PKInkingTool.InkType = .pen
    @State var penSize: CGFloat = 5.0 // default size value
    
    @State var isPresentingColorPicker = false // added state variable

    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink("", destination: ContentView(), isActive: $navigate)
                Color(red: 0.85, green: 1.0, blue: 0.94) // set background color here
                    .ignoresSafeArea()
                
                ZStack {
                    DrawingView(canvas: $canvas, isdraw: $isdraw, type: $type, color: $color, penSize: $penSize)
                }
                .frame(width: 350, height: 400)
                .cornerRadius(20) // rounded corners for canvas
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2)
                ) // border around canvas
                .offset(y: -115)
                // force light mode so canvas doesn't appear weird
                .preferredColorScheme(.light)
                .navigationBarItems(leading: Button(action: {
                    // Save drawing to user's phone
                    saveImageToLibrary()
                }, label: {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.title)
                        .foregroundColor(Color.blue)
                }), trailing: HStack(spacing: 15) {
                    // ColorPicker
                    ColorPicker("", selection: $color)
                    
                    // erase tool
                    Button(action: {
                        isdraw = false
                    }) {
                        Image(systemName: "eraser")
                            .foregroundColor(Color.blue)
                    }
                    
                    // pencil
                    Button(action: {
                        isdraw = true
                        type = .pencil
                    }) {
                        Label {
                        } icon: {
                            Image(systemName: "pencil")
                        }
                    }
                    
                    // pen
                    Button(action: {
                        isdraw = true
                        type = .pen
                    }) {
                        Label {
                            Text("Pen")
                        } icon: {
                            Image(systemName: "pencil.tip")
                        }
                    }
                    
                    // marker
                    Button(action: {
                        isdraw = true
                        type = .marker
                    }) {
                        Label {
                            Text("Marker")
                        } icon: {
                            Image(systemName: "highlighter")
                        }
                    }
                })
                
                VStack {
                    HStack {
                        // Undo button
                        Button(action: {
                            undoManager?.undo()
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(Color.gray)
                            
                            Text("Undo")
                                .foregroundColor(Color.gray)
                                .offset(y: 2)
                        }
                        .offset(y: 20)
                        
                        Spacer()
                            .frame(width: 205)
                        
                        // Redo button
                        Button(action: {
                            undoManager?.redo()
                        }) {
                            Text("Redo")
                                .foregroundColor(Color.gray)
                                .offset(y: 2)
                            
                            Image(systemName: "arrow.uturn.forward")
                                .foregroundColor(Color.gray)
                        }
                        .offset(y: 20)
                    }
                    
                    HStack {
                        Text("Pen Size")
                            .italic()
                            .bold()
                        
                        Slider(value: $penSize, in: 1...50, step: 1)
                            .frame(width: 225)
                    }
                    .offset(y: 25)
                    
                    Text("Size: \(Int(penSize))")
                        .font(.system(size: 15))
                        .offset(y: 10)
                                        
                    Button(action: {
                        Task {
                            await sendImage()
                        }
                    }) {
                        Label {
                            Text("Send to Partner")
                                .font(.system(size: 25))
                                .bold()
                        } icon: {
                            Image(systemName: "paperplane.circle")
                                .font(.system(size: 25))
                        }
                    }
                    .offset(y: 50)
                } // end VStack
                .offset(y: 125)
            } // end ZStack
        } // end NavigationView
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            connected = await checkConnection()
            if(!connected) {
                navigate = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Your drawing has been sent successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
    } // end body

    // Requires both Firebase Firestore and Firebase Storage.
    // It first uploads the image data to Firebase Storage using imagesRef.putData() and then retrieves the download URL of the uploaded image using imagesRef.downloadURL().
    // The download URL is then stored in a Firestore document along with the filename using db.collection("images").addDocument().
    func sendImage() async {
        guard let user = Auth.auth().currentUser else {
            print("Error finding currentUser while trying to send image")
            return
        }
        let db = Firestore.firestore()
        
        // Getting partner uid for purposes of folder creation/accessing
        // Might be better to use the getPartnerUID function
        let docRef = db.collection("users").document(user.uid)
        do {
            let snapshot = try await docRef.getDocument()
            if let partnerID = snapshot.get("partnerID") as? String {
                partnerUID = partnerID
            } else {
                print("User does not have a partner")
                return
            }
        } catch {
            print("Error accessing document in Firestore when checking for connection")
            return
        }
        
        // get the size of the canvas
        let canvasSize = await canvas.bounds.size
        
        // create a new image context with a transparent background
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        
        // get the current context
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // draw the canvas onto the context
        await canvas.layer.render(in: context)
        
        // get the image from the context
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return
        }
        
        // end the image context
        UIGraphicsEndImageContext()
        
        // create a unique filename based on timestamp
        let connectionFolder = "\(user.uid)->\(partnerUID)"
        let filename = "\(user.uid)+\(Int(Date().timeIntervalSince1970)).png"
        
        // convert the image to Data format
        guard let imageData = image.pngData() else { return }
        
        // add the image data to Firebase Storage
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("\(connectionFolder)/\(filename)")
        
        imagesRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                print("Image uploaded successfully!")
                // add the image URL to Firestore
                imagesRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                    } else {
                        if let downloadURL = url?.absoluteString {
                            // Add image information into designated folder for images from sender to receiver
                            db.collection(connectionFolder).addDocument(data: [
                                "filename": filename,
                                "url": downloadURL
                            ])
                            // List the most recent iamge information on the receiver's document
                            db.collection("users").document(partnerUID).updateData(
                            [
                                "recentFilename": filename,
                                "recentURL": downloadURL
                            ])
                            print("Image URL added to Firestore!")
                            
                            // tell the user the image was uploaded successfully
                            showAlert = true
                        }
                    }
                }
            }
        }
    } // end sendImage
    
    // NOTE: To do this, you must set 'Privacy - Photo Library Additions Usage Description' under info
    // Saves the user's drawing to their phone library
    // The extra steps are needed because the image might save weirdly if the user is in dark mode
    func saveImageToLibrary() {
        // get the size of the canvas
        let canvasSize = canvas.bounds.size
        
        // create a new image context with a transparent background
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)
        
        // get the current context
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // draw the canvas onto the context
        canvas.layer.render(in: context)
        
        // get the image from the context
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return
        }
        
        // end the image context
        UIGraphicsEndImageContext()
        
        // save to user's phone library
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
} // end Drawing view

struct DrawingView: UIViewRepresentable {
    // to capture drawings for saving into albums
    @Binding var canvas: PKCanvasView
    @Binding var isdraw: Bool
    @Binding var type: PKInkingTool.InkType
    @Binding var color: Color
    @Binding var penSize: CGFloat
    
    // Updating inktype
     var ink : PKInkingTool {
        PKInkingTool(type, color: UIColor(color), width: penSize)
    }
    
    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = isdraw ? ink : eraser
        canvas.contentSize = CGSize(width: 350 , height: 400)
        canvas.backgroundColor = UIColor.white // Set the background color of the PKCanvasView
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // updating the tool whenever the view updates
        uiView.tool = isdraw ? ink : eraser
    }
    
    func erase() {
        canvas.tool = eraser
    }
}
