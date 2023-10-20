import SwiftUI

struct MainAppView: View {
    var body: some View {
        TabView{
            Gallery()
                .tabItem() {
                    Image(systemName: "photo")
                }
            Canvas()
                .tabItem() {
                    Image(systemName: "paintbrush")
                }
            ArtPrompts()
                .tabItem {
                    Image(systemName: "lightbulb")
                }
            Settings()
                .tabItem() {
                    Image(systemName: "gearshape")
                }
        }
    } // end body
} // end MainAppView

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
