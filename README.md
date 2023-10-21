# InkLink 
A collaboration with Matthew Shwe @ https://github.com/emaity

A drawing app made in Xcode with SwiftUI that allows users to pair up with a partner to send them unique and fun drawings.

When they download the app, the user can either login or register an account with a unique username. Each user's credentials are stored in Firebase Authentication. After logging in, the user is prompted to pair with a partner by typing their intended partner's unique username into a text box. (Disclaimer: The user is NOT able to pair with themselves except if manually input into the Firebase data for testing purposes). This information is stored in each user's document in the Firestore Database. If both users have each other's usernames as their intended partner, full access to the app is given. From here, there are these views:

  - Gallery View: This view allows you to see all the drawings (past and current) your partner has sent to you. Due to each drawing being saved under a filename based on the timestamp in which it was sent, this view is able to show the most recent drawing sent at the top of the screen. However, past drawings are also able to be seen by scrolling down on this screen.

  - Canvas View: Using Apple's PencilKit framework, this view allows for creativity. A canvas is available to draw on with a pencil, pen, or marker that can be modified with the color wheel and a size slider. Drawings can also be altered by the eraser tool, and buttons that allow the user to undo and redo previous strokes. This art can also be saved to the user's phone after the user allows the app to access their camera roll. Finally, when the user is done drawing, they can send it to their partner with the app's use of Firestore and Storage. 
  
  - Art Prompt View: Using a random word API, this app generates a random noun, animal, and adjective to provide some artistic inspiration to the user.

  - Settings View: From here, the user can check their username and their partner's name. They also have the ability to log out or to remove their partner. If the latter is done, then the user must pair with another partner before they are allowed to have access to the rest of the app.

Note: This app includes Firebase packages, which includes Firebase Authentication, Firestore Database, and Storage. Additionally, to allow the user to save their drawing to their device, you must use 'Privacy - Photo Library Additions Usage Description' to request access to their camera roll. 
