//
//  Copyright © 2021 INTERNEWS. All rights reserved.
//

import SwiftUI

struct SettingsView : View {
    
    @ObservedObject var appModel: MainAppModel
    
    init(appModel: MainAppModel) {
        self.appModel = appModel
        setupView()
    }
    
    private func setupView() {
    }
    
    var body: some View {
        ZStack {
            Styles.Colors.backgroundMain.edgesIgnoringSafeArea(.all)
            Form {
                Section{
                    SettingToggleItem(title: "Offline mode", description: "In offline Mode, all data is save for later submission. Useful to save cellular data or when connectivity is poor. Disable when you're ready to submit forms.", toggle: $appModel.settings.offLineMode)
                }
                .listRowBackground(Styles.Colors.backgroundTab)
                Section {
                    SettingMenu(viewModel: appModel.settings)
                }
            }.background(Styles.Colors.backgroundMain)
        }.onAppear() {
            UITableView.appearance().backgroundColor = UIColor.clear
            UITableView.appearance().separatorStyle = .singleLine
            UITableView.appearance().separatorColor = .white
            UISwitch.appearance().onTintColor = .green
        }
        .onDisappear(perform: {
            appModel.saveSettings()
        })
         .navigationBarItems(
            leading:
                Text("Settings")
                .font(.custom(Styles.Fonts.semiBoldFontName, size: 16))
                .foregroundColor(Color.white)
        )
        .onDisappear {
            appModel.publishUpdates()
        }
    }
}

struct SettingMenu: View {
    
    @ObservedObject var viewModel: SettingsModel

    var body: some View {
        List{
//            NavigationLink(destination: SettingsAboutHelp()) {
//                SettingItem(name: "General", image: Image(systemName: "gear"))
//            }
            VStack(alignment: .leading){
                NavigationLink(destination: SettingsSecurity(viewModel: viewModel)) {
                    EmptyView()
                }
                SettingItem(name: "Security", image: Image(systemName: "person.crop.circle.badge.exclam"))
            }
            NavigationLink(destination: SettingsDocumentation()) {
                SettingItem(name: "Documentation", image: Image(systemName: "hand.raised.fill"))
            }
            NavigationLink(destination: SettingsAboutHelp()) {
                SettingItem(name: "About & Help", image: Image(systemName: "key.fill"))
            }
        }
        .listRowBackground(Styles.Colors.backgroundTab)
        .cornerRadius(25)
    }
}

struct DemoDesign_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            SettingsView(appModel: MainAppModel())
        }
    }
}
