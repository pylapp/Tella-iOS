//
//  Copyright © 2021 INTERNEWS. All rights reserved.
//

import SwiftUI

struct FileInfoView: View {

    var file: VaultFile
    var body: some View {
        VStack(alignment: .center, spacing: 20){
            if file.type == .image {
                Image(uiImage: file.thumbnailImage)
                    .border(Color.green, width: 1)
                    .frame(width: 100, height: 100, alignment: .center)
            }
            Text(file.type.rawValue)
            Text(file.fileName)
            Text(file.containerName)
            Text("\(file.created)")
        }
    }
}