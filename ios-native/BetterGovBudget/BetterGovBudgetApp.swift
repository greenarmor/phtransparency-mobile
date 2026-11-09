import SwiftUI

@main
struct BetterGovBudgetApp: App {
    @State private var welcomed = false
    var body: some Scene {
        WindowGroup {
            if welcomed { RootTabs() } else { WelcomeView { welcomed = true } }
        }
    }
}

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack { NationalView() }.tabItem { Label("Philippines", systemImage: "flag") }
            NavigationStack { RegionListView() }.tabItem { Label("Regions", systemImage: "map") }
            NavigationStack { DistrictListView() }.tabItem { Label("Districts", systemImage: "building.columns") }
            NavigationStack { EnactedView() }.tabItem { Label("Enacted", systemImage: "checkmark.seal") }
            NavigationStack { AboutView() }.tabItem { Label("About", systemImage: "info.circle") }
        }
        .tint(Palette.red)
    }
}

struct WelcomeView: View {
    let onContinue: () -> Void
    var body: some View {
        ZStack {
            Palette.cream.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image("Logo").resizable().scaledToFit().frame(width: 150)
                Text("BetterGov Budget").font(.largeTitle.bold()).foregroundStyle(Palette.ink)
                Text("What every place in the Philippines gets in FY 2027 under the NEP and the House bill, with the page each figure is on.")
                    .multilineTextAlignment(.center).foregroundStyle(Palette.ink.opacity(0.75)).padding(.horizontal, 28)
                Spacer()
                Button(action: onContinue) {
                    Text("See the budget").font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Palette.red, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                }.padding(.horizontal, 28).padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.light)
    }
}
