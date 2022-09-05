//  Tella
//
//  Copyright © 2022 INTERNEWS. All rights reserved.
//

import SwiftUI

struct SuccessAdvancedSettingsView: View {
   
    @EnvironmentObject var serversViewModel : ServersViewModel
    @Binding var isPresented : Bool
    
    var body: some View {
        ContainerView {
            
            VStack {
                
                Spacer()
                
                topview
                
                Spacer()
                    .frame(height: 48)
                
                TellaButtonView<AnyView> (title: "OK",
                                          nextButtonAction: .action,
                                          buttonType: .yellow) {
                    isPresented = false
                    
                    serversViewModel.popToRoot = false
                    serversViewModel.popToRoot2 = true
                }
                
                Spacer()

            } .padding(EdgeInsets(top: 0, leading: 26, bottom: 0, trailing: 26))
        }
        
        .navigationBarHidden(true)
        
    }
    
    var topview: some View {
        
        VStack {
            Image("settings.checked-circle")
            
            Spacer()
                .frame(height: 16)
            
            Text("Advanced settings complete")
                .font(.custom(Styles.Fonts.semiBoldFontName, size: 18))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: 16)
            
            Text("You can always change your Reports preferences in the Tella Settings. ")
                .font(.custom(Styles.Fonts.regularFontName, size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
}
struct SuccessAdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessAdvancedSettingsView(isPresented: .constant(false))
    }
}
