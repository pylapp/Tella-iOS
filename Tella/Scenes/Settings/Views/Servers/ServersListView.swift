//  Tella
//
//  Copyright © 2022 INTERNEWS. All rights reserved.
//

import SwiftUI

struct ServersListView: View {
    @EnvironmentObject var serversViewModel : ServersViewModel
    
    var body: some View {
        
        ContainerView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 8)
                
                SettingsCardView (cardViewArray: [SettingsAddServerCardView().environmentObject(serversViewModel).eraseToAnyView(),
                                                  SettingsServerItemView(title: "CLEEN Foundation").eraseToAnyView(),
                                                  SettingsServerItemView(title: "Election monitoring").eraseToAnyView()])
                Spacer()
            }
        }
        .toolbar {
            LeadingTitleToolbar(title: "Servers")
        }
    }
}

struct ServersListView_Previews: PreviewProvider {
    static var previews: some View {
        ServersListView()
    }
}
