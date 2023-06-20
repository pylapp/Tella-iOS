//
//  Copyright © 2023 INTERNEWS. All rights reserved.
//

import Foundation
import Combine

class BaseUploadOperation : Operation {

    public var report: Report?
    public var urlSession : URLSession!
    public var mainAppModel :MainAppModel!
    
    public var reportVaultFiles: [ReportVaultFile]? = nil
    var initialResponse = CurrentValueSubject<UploadResponse?,APIError>(.initial)
    @Published var response = CurrentValueSubject<UploadResponse?,APIError>(.initial)
    
    public var uploadTasksDict : [URLSessionTask: UploadTask] = [:]
    
    private var filesToUpload : [FileToUpload] = []
    var subscribers : Set<AnyCancellable> = []
    var type: OperationType!
    
    override init() {
        super.init()
    }
    
    override func cancel() {
        _ = uploadTasksDict.keys.compactMap({$0.cancel()})
        updateReport(reportStatus: .submissionPartialParts)
        super.cancel()

    }
    
    override func main() {
        handleInialResponse()
    }
    
    init(urlSession:URLSession, mainAppModel :MainAppModel, type: OperationType) {
        
        self.urlSession = urlSession
        self.mainAppModel = mainAppModel
        self.type = type
        super.init()
    }
    
    func handleInialResponse() {
        self.initialResponse.sink { completion in
            
        } receiveValue: { uploadResponse in
            switch uploadResponse {
            case .progress(let progressInfo):
                
                let file = self.reportVaultFiles?.first(where: {$0.id == progressInfo.fileId})
                let instanceId = file?.instanceId
                
                let totalByteSent = self.updateReportFile(fileStatus: progressInfo.status, id: instanceId, bytesSent: progressInfo.bytesSent,current: progressInfo.current)
                
                if let _ = progressInfo.error {
                    self.updateReport(reportStatus: .submissionError)
                    
                }
                
                self.response.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: progressInfo.fileId, status: progressInfo.status, total: totalByteSent)))
                
                
                
                if progressInfo.status == .submitted {
                    self.checkAllFilesAreUploaded()
                }
                
                
            case .createReport(let apiId, let reportStatus, let error):
                self.updateReport(apiID:apiId, reportStatus: reportStatus)
                self.response.send(UploadResponse.createReport(apiId: apiId, reportStatus: reportStatus, error: error))
                
            case .initial:
                break
            case .none:
                break
            }
        }.store(in: &subscribers)
        
    }
    
    func updateReport(apiID: String? = nil, reportStatus: ReportStatus?) {
        
        if apiID != nil {
            self.report?.apiID = apiID
        }
        let report = Report(id: self.report?.id,
                            status: reportStatus,
                            apiID: apiID)
        do {
            _ = try mainAppModel.vaultManager.tellaData.updateReport(report: report)
            
        } catch {
            
        }
    }
    
    func updateReportFile(fileStatus:FileStatus, id:Int?, bytesSent:Int? = nil, current:Int? = nil ) -> Int {
        guard let id else { return 0 }
        
        _ =  self.reportVaultFiles?.compactMap { _ in
            let file = self.reportVaultFiles?.first(where: {$0.instanceId == id})
            
            file?.status = fileStatus
            
            if let bytesSent {
                file?.bytesSent = bytesSent
            }
            
            if let current {
                file?.current = current
            }
            return file
        }
        
        
        let file = self.reportVaultFiles?.first(where: {$0.instanceId == id})
        let totalBytesSent = (file?.current ?? 0)  + (file?.bytesSent ?? 0)
        
        do {
            let _ = try mainAppModel.vaultManager.tellaData.updateReportFile(reportFile: ReportFile(id: id,
                                                                                                    status: fileStatus,
                                                                                                    bytesSent: totalBytesSent))
        } catch {
            
        }
        return totalBytesSent
    }
    
    
    private func checkAllFilesAreUploaded() {
        
        // Check if all the files are submitted
        
        guard let isNotFishUploading = self.reportVaultFiles?.filter({$0.status != .submitted}) else {return}
        
        if ((isNotFishUploading.isEmpty)  ) {
            self.updateReport(reportStatus: .submitted)
            self.response.send(completion:.finished)
        }
    }
    
    func sendReport() {
        
        guard let report else {return }
        let api = ReportRepository.API.createReport((report))
        do {
            
            let request = try api.urlRequest()
            request.curlRepresentation()
            guard let task = self.urlSession?.dataTask(with: request) else { return}
            task.resume()
            uploadTasksDict[task] = UploadTask(task: task, response: .createReport)
            
            self.updateReport(reportStatus: ReportStatus.submissionInProgress)
            
        } catch {
            
        }
    }
    
    func uploadFiles() {
        
        guard let apiID = self.report?.apiID, let accessToken = report?.server?.accessToken, let serverUrl = report?.server?.url else { return }
        
        let filesToUpload = reportVaultFiles?.filter{$0.status != .submitted}
        
        filesToUpload?.forEach({ reportVaultFile in
            
            let vaultFileInfo = mainAppModel.loadFilesInfos(file: reportVaultFile,offsetSize: 0)
            
            guard let vaultFileInfo else { return }
            
            let fileToUpload = FileToUpload(idReport: apiID,
                                            fileUrlPath: vaultFileInfo.url,
                                            accessToken: accessToken,
                                            serverURL: serverUrl,
                                            data: vaultFileInfo.data,
                                            fileName: reportVaultFile.fileName,
                                            fileExtension: reportVaultFile.fileExtension,
                                            fileId: reportVaultFile.id,
                                            fileSize: reportVaultFile.size,
                                            bytesSent: reportVaultFile.bytesSent,
                                            uploadOnBackground: report?.server?.backgroundUpload ?? false)
            
            self.filesToUpload.append(fileToUpload)
            
            if reportVaultFile.status == .uploaded ||  reportVaultFile.size == reportVaultFile.bytesSent{
                self.postReportFile(fileId: reportVaultFile.id)
            } else {
                self.checkFileSizeOnServer(fileToUpload: fileToUpload)
            }
        })
    }
    
    func checkFileSizeOnServer(fileToUpload: FileToUpload) {
        
        let api = ReportRepository.API.headReportFile((fileToUpload))
        
        do {
            
            let request = try api.urlRequest()
            request.curlRepresentation()
            guard let task = self.urlSession?.dataTask(with: request) else { return}
            task.resume()
            
            uploadTasksDict[task] = UploadTask(task: task, response: .progress(fileId: fileToUpload.fileId, type: .headReportFile))
        } catch {
            
        }
    }
    
    func putReportFile(fileId: String?, size:Int) {
        guard  let fileToUpload = filesToUpload.first(where: {$0.fileId == fileId}) else {return}
        
        if size != 0 {
            if let fileUrlPath = self.mainAppModel.saveDataToTempFile(data: fileToUpload.data?.extract(size:size), fileName: fileToUpload.fileName, pathExtension: fileToUpload.fileExtension) {
                fileToUpload.fileUrlPath = fileUrlPath
            }
            fileToUpload.data = fileToUpload.data?.extract(size: size)
        }
        
        let api = ReportRepository.API.putReportFile((fileToUpload))
        
        do {
            
            let request = try api.urlRequest()
            request.curlRepresentation()
            let fileURL = api.fileToUpload?.url
            
            let _ = fileURL?.startAccessingSecurityScopedResource()
            defer { fileURL?.stopAccessingSecurityScopedResource() }
            
            guard let task = self.urlSession?.uploadTask(with: request, fromFile: fileURL!) else { return}
            task.resume()
            
            uploadTasksDict[task] = UploadTask(task: task, response: .progress(fileId: fileToUpload.fileId, type: .putReportFile))
            
        } catch {
            
        }
        
    }
    
    func postReportFile(fileId: String?) {
        guard  let fileToUpload = filesToUpload.first(where: {$0.fileId == fileId}) else {return}
        
        let api = ReportRepository.API.postReportFile((fileToUpload))
        
        do {
            
            let request = try api.urlRequest()
            request.curlRepresentation()
            guard let task = self.urlSession?.dataTask(with: request) else { return}
            task.resume()
            
            uploadTasksDict[task] = UploadTask(task: task,  response: .progress(fileId: fileToUpload.fileId, type: .postReportFile))
            
        } catch {
            
        }
    }
    
    func update(responseFromDelegate: URLSessionTaskResponse) {
        
        guard let task = responseFromDelegate.task else { return }
        let item = uploadTasksDict[task]
        
        switch item?.response {
            
        case .createReport:
            
            let result:UploadDecode<SubmitReportResult,ReportAPI> = getAPIResponse(response: responseFromDelegate.response, data: responseFromDelegate.data, error: responseFromDelegate.error)
            
            if let error = result.error {
                self.initialResponse.send(UploadResponse.createReport(apiId: nil, reportStatus: ReportStatus.submissionError, error: error))
                
                // TODO ?
            } else {
                let apiID = result.domain?.id
                let emptyFiles = self.report?.reportFiles?.isEmpty ?? true
                let reportStatus = emptyFiles ? ReportStatus.submitted : ReportStatus.submissionInProgress
                self.initialResponse.send(UploadResponse.createReport(apiId: apiID, reportStatus: reportStatus, error: nil))
                
                uploadFiles()
            }
            
            uploadTasksDict[task] = nil
            
        case .progress(let fileId, let type):
            
            switch type {
                
            case .putReportFile:
                
                if let data = responseFromDelegate.data , let response = responseFromDelegate.response {
                    let result:UploadDecode<FileDTO,FileAPI> = getAPIResponse(response:response, data: data, error: responseFromDelegate.error)
                    
                    if let _ = result.error {
                        self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: fileId, status: FileStatus.submissionError)))
                    } else {
                        
                        self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: fileId, status: FileStatus.uploaded)))
                        
                        postReportFile(fileId: fileId)
                    }
                    uploadTasksDict[task] = nil
                    
                } else {
                    self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(current:responseFromDelegate.current  ,fileId: fileId, status: FileStatus.partialSubmitted)))
                }
                
            case .headReportFile:

                let file = self.reportVaultFiles?.first(where: {$0.id == fileId})

                let result:UploadDecode<SizeResult,ServerFileSize>  = getAPIResponse(response: responseFromDelegate.response, data: responseFromDelegate.data, error: responseFromDelegate.error)
                
                let size = result.domain?.size
                
                if let _ = result.error {
                    // headReportFile
                    self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: fileId, status: FileStatus.submissionError)))
                    
                } else {
                    
                    self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(bytesSent: size, current:0 ,fileId: fileId, status: FileStatus.partialSubmitted)))
                    
                    let fileToUpload = filesToUpload.first(where: {$0.fileId == fileId})
                    if fileToUpload?.fileSize == size {
                        self.postReportFile(fileId: fileId)
                    } else {
                        self.putReportFile(fileId: fileId, size:size ?? 0)
                    }

                }
                uploadTasksDict[task] = nil
                
            case .postReportFile:
                
                let result:UploadDecode<BoolResponse,BoolModel> = getAPIResponse(response: responseFromDelegate.response, data: responseFromDelegate.data, error: responseFromDelegate.error)
                
                let success = result.domain?.success ?? false
                
                if let _ = result.error {
                    self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: fileId, status: FileStatus.submissionError)))
                } else {
//                    if success {
                        self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: fileId, status: FileStatus.submitted)))
//                    } else {
//                        self.initialResponse.send(UploadResponse.progress(progressInfo: UploadProgressInfo(fileId: fileId, status: FileStatus.submissionError)))
//                    }
                }
                
                uploadTasksDict[task] = nil
                
            default:
                break
            }
            
        default:
            break
        }
    }
}

extension BaseUploadOperation {
    
    func getAPIResponse<Value1, Value2> (response:HTTPURLResponse?, data: Data?, error: Error?) -> UploadDecode<Value1, Value2> where Value1: DataModel, Value2: DomainModel {
        
        guard let code = (response)?.statusCode else {
            return UploadDecode(dto: nil, domain: nil, error: APIError.unexpectedResponse)
        }
        guard HTTPCodes.success.contains(code) else {
            debugLog("Error code: \(code)")
            return UploadDecode(dto: nil, domain: nil, error: APIError.httpCode(code))
        }
        
        if let size = (response)?.allHeaderFields.filter({($0.key as? String) == "size"}),
           !size.isEmpty   {
            
            if let jsonString = JSONStringEncoder().encode(size as! [String:Any]) {
                do{
                    let result : Value1 = try jsonString.decoded()
                    let dtoResponse  =    result
                    let domainResponse  =   (result.toDomain() as? Value2)
                    
                    return UploadDecode(dto: dtoResponse, domain: domainResponse, error: nil)
                }
                catch {
                    return UploadDecode(dto: nil, domain: nil, error: APIError.unexpectedResponse)
                }
            }
        }
        guard let data = data else {
            return UploadDecode(dto: nil, domain: nil, error: APIError.unexpectedResponse)
        }
        
        let dataString = String(decoding:  data  , as: UTF8.self)
        debugLog("Result:\(dataString)")
        do {
            let result : Value1 = try data.decoded()
            let dtoResponse  =   result
            let domainResponse  =   result.toDomain() as? Value2
            
            return UploadDecode(dto: dtoResponse, domain: domainResponse, error: nil)
        }
        catch {
            return UploadDecode(dto: nil, domain: nil, error: APIError.unexpectedResponse)
        }
    }
    
}
