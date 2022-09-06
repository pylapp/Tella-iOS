//  Tella
//
//  Copyright © 2022 INTERNEWS. All rights reserved.
//

import SwiftUI

struct AdvancedServerSettingsView: View {
    
    @State var shareInfo : Bool = false
    @State var backgroundUpload : Bool = false
    @State var presentingSuccessAdvancedSettings : Bool = false
    
    @EnvironmentObject var serversViewModel : ServersViewModel
    
    var body: some View {
        
        ContainerView {
            VStack {
                
                Spacer()
                
                Image("settings.verification-info")
                
                Spacer()
                    .frame(height: 16)
                
                Text("Advanced settings")
                    .font(.custom(Styles.Fonts.semiBoldFontName, size: 18))
                    .foregroundColor(.white)
                
                Spacer()
                    .frame(height: 16)
                
                SettingsCardView(cardViewArray: [ShareInfoView(shareInfo: $shareInfo).eraseToAnyView(),
                                                 BackgroundUploadView(backgroundUpload: $backgroundUpload).eraseToAnyView()])
                
                Spacer()
                
                BottomLockView<AnyView>(isValid:.constant(true),
                                        nextButtonAction: .action,
                                        nextAction:  {
                    presentingSuccessAdvancedSettings = true
                })
                
                
            }
            nextViewLink
        }
        .navigationBarHidden(true)
        
    }
    
    
    private var nextViewLink: some View {
        SuccessAdvancedSettingsView(isPresented: $presentingSuccessAdvancedSettings).environmentObject(serversViewModel)
            .addNavigationLink(isActive: $presentingSuccessAdvancedSettings)
    }
    
}

struct AdvancedServerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedServerSettingsView()
    }
}



