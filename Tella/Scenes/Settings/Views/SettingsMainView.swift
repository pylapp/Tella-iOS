//
//  SettingsMainView.swift
//  Tella
//
//  Copyright © 2022 INTERNEWS. All rights reserved.
//

import SwiftUI

struct SettingsMainView: View {
    
    @ObservedObject var appModel : MainAppModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var body: some View {
        ContainerView {
            VStack() {
                GenaralSettingsView(appModel: appModel)
                RecentFilesSettingsView()
                Spacer()
            }
        }.onReceive(appModel.shouldUpdateLanguage) {  vv in
            if vv {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            LeadingTitleToolbar(title: LocalizableSettings.title.localized)
        }
        
        .onDisappear(perform: {
            appModel.saveSettings()
        })
        
        .onDisappear {
            appModel.publishUpdates()
        }
    }
}

struct GenaralSettingsView : View {
    
    @State private var presentingLanguage = false
    @ObservedObject var appModel : MainAppModel
    @StateObject var lockViewModel = LockViewModel(unlockType: .update)
    @State var passwordTypeString : String = ""
    
    
    var body : some View {
        
        VStack(spacing: 0) {
            
            SettingsItemView(imageName: "settings.language",
                             title: LocalizableSettings.language.localized,
                             value: Language.currentLanguage.name)
                .onTapGesture {
                    presentingLanguage = true
                }
            
            DividerView()
            
            SettingsItemView(imageName: "settings.lock",
                             title: LocalizableSettings.lock.localized,
                             value: passwordTypeString)
            
                .navigateTo(destination: unlockView)
            
            DividerView()
            
            SettingsItemView(imageName: "settings.help",
                             title: LocalizableSettings.aboutAndHelp.localized,
                             value: "")
                .navigateTo(destination: AboutAndHelpView())
            
        }.background(Color.white.opacity(0.08))
            .cornerRadius(15)
            .padding()
            .fullScreenCover(isPresented: $presentingLanguage) {
                
            } content: {
                LanguageListView(isPresented: $presentingLanguage)
            }
            .onAppear {
                lockViewModel.shouldDismiss.send(false)
                let passwordType = AuthenticationManager().getPasswordType()
                passwordTypeString = passwordType == .tellaPassword ? LocalizableLock.passwordButtonTitle.localized : LocalizableLock.pinButtonTitle.localized
            }
    }
    
    var unlockView : some View {
        
        let passwordType = AuthenticationManager().getPasswordType()
        return passwordType == .tellaPassword ?
        
        UnlockPasswordView()
            .environmentObject(lockViewModel)
            .eraseToAnyView()  :
        
        UnlockPinView()
            .environmentObject(lockViewModel)
            .eraseToAnyView()
        
    }
    
}

struct RecentFilesSettingsView : View {
    
    @EnvironmentObject var appModel : MainAppModel
    
    var body : some View {
        
        VStack(spacing: 0) {
            
            SettingToggleItem(title: "Recent files",
                              description: "Gives you quick access to your recent files on Tella’s homescreen. ",
                              toggle: $appModel.settings.showRecentFiles)
        }.background(Color.white.opacity(0.08))
            .cornerRadius(15)
            .padding()
    }
}

struct DividerView : View {
    var body: some View {
        Divider()
            .frame(height: 1)
            .background(Color.white.opacity(0.2))
    }
    
}

struct SettingsItemView : View {
    
    var imageName : String = ""
    var title : String = ""
    var value : String = ""
    
    var body : some View {
        
        HStack {
            Image(imageName)
            Spacer()
                .frame(width: 10)
            Text(title)
                .font(.custom(Styles.Fonts.regularFontName, size: 14))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.custom(Styles.Fonts.regularFontName, size: 14))
                .foregroundColor(.white)
            
        }.padding(.all, 18)
            .contentShape(Rectangle())
    }
}

struct SettingsMainView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMainView(appModel: MainAppModel())
    }
}