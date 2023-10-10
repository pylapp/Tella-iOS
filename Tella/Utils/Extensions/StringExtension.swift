//  Tella
//
//  Copyright © 2022 INTERNEWS. All rights reserved.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers


extension String {
    func getDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormat.dataBase.rawValue
        dateFormatter.locale = Locale(identifier: "en")
        return dateFormatter.date(from: self) // replace Date String
    }
    
    func getBaseURL() -> String? {
        let url = NSURL(string: self)
        return "https://" + (url?.host ?? "")
    }
    
    func getFileSizeWithoutUnit() -> String {
        let array =  self.getStringComponents(separator: " ")
        guard !array.isEmpty else {return ""}
        return array[0]
    }
    
    func getStringComponents(separator: String) -> [String] {
        return self.components(separatedBy: separator)
    }
    
    var fileType: TellaFileType {
        
        let fileType: TellaFileType
        
        switch self.lowercased() {
            
        case "gif", "jpeg", "jpg", "png", "tif", "tiff", "wbmp", "ico", "jng", "bmp", "svg", "svgz", "webp", "heic", "heif" :
            fileType = .image
            
        case "hevc", "3gpp", "3gp", "ts", "mp4", "mpeg", "mpg", "mov", "webm", "flv", "m4v", "mng", "asx", "asf", "wmv", "avi", "wma":
            fileType = .video
            
        case "mid", "midi", "kar", "mp3", "ogg", "m4a", "ra":
            fileType = .audio
            
        case "txt", "doc", "pdf", "rtf", "xls", "ppt", "docx", "xlsx", "pptx":
            fileType = .document
            
        default:
            fileType = .other
        }
        return fileType
        
    }
    
    func getRecoveredFileName() -> String {
        
        var fileType = ""
        
        switch self.fileType {
        case .image:
            fileType = "image"
        case .video:
            fileType = "video"
        case .audio:
            fileType = "audio"
        case .document:
            fileType = "document"
        default:
            fileType = "file"
        }
        
        return "\(fileType)-\(Date().getDate())"
    }


    
}

extension String {

    func mimeType() -> String? {
         if let type = UTType(filenameExtension: self) {
            if let mimetype = type.preferredMIMEType {
                return mimetype as String
            }
        }
        return nil
    }
    
    func getExtension() -> String {
        
        let unmanagedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, self as CFString, nil)?.takeRetainedValue()
       guard let fileExtension = UTTypeCopyPreferredTagWithClass((unmanagedFileUTI)!, kUTTagClassFilenameExtension)?.takeRetainedValue()
        else { return ""}
        
        return fileExtension as String
    }

    
    
    var tellaFileType: TellaFileType {

        guard let type = UTType(mimeType: self) else {
            return .other
        }
        
        if type.conforms(to: .video) || type.conforms(to: .movie) {
            return .video
        }
        
        if type.conforms(to: .image) {
            return .image
        }
        
        if type.conforms(to: .audio) {
            return .audio
        }
        
//        enum OpenXmlFormats : String {
//
//            case word = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
//            case presentation = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
//            case sheet = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

//        let word = "application/msword"
//        let excel = "application/vnd.ms-excel"
//        let powerPoint = "application/mspowerpoint"

        if type.conforms(to: .pdf) || type.conforms(to: .presentation) || type.conforms(to: .spreadsheet) {
            return .document

        }

 

        
 

        return .other
    }

    
    
    
}

