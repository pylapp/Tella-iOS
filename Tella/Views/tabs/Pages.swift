//
//  Pages.swift
//  Tella
//
//  Copyright © 2021 INTERNEWS. All rights reserved.
//

import Foundation

public enum Pages: Hashable {
    case new
    case draft
    case outbox
    case sent
    
    static func fromHashValue(hashValue: Pages) -> Int {
        switch hashValue {
        case .new:
            return 0
        case .draft:
            return 1
        case .outbox:
            return 2
        case .sent:
            return 3
        }
    }
    
    static func fromValueHash(value: Int) -> Pages {
        switch value {
        case 0:
            return .new
        case 1:
            return .draft
        case 2:
            return .outbox
        case 3:
            return .sent
        default:
            return .new
        }
    }
}
