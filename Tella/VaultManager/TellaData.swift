//  Tella
//
//  Copyright © 2022 INTERNEWS. All rights reserved.
//

import Foundation
import Combine

class TellaData : ObservableObject {
    
    var database : TellaDataBase?
    
    // Servers
    var servers = CurrentValueSubject<[Server], Error>([])
    
    // Reports
    var draftReports = CurrentValueSubject<[Report], Error>([])
    var submittedReports = CurrentValueSubject<[Report], Error>([])
    var outboxedReports = CurrentValueSubject<[Report], Error>([])
    
    init(key: String?) {
        self.database = TellaDataBase(key: key)
        getServers()
        getReports()
    }
    
    func addServer(server : Server) throws -> Int {
        
        guard let database = database else {
            throw SqliteError()
        }
        let id = try database.addServer(server: server)
        getServers()
        
        return id
        
    }
    
    func updateServer(server : Server) throws -> Int {
        
        guard let database = database else {
            throw SqliteError()
        }
        let id = try database.updateServer(server: server)
        getServers()
        return id
    }
    
    func deleteServer(serverId : Int) throws -> Int {
        
        guard let database = database else {
            throw SqliteError()
        }
        let id = try database.deleteServer(serverId: serverId)
        getServers()
        return id
        
    }
    
    func getServers(){
        guard let database = database else {
            return
        }
        
        servers.value = database.getServer()
    }
    
    func getReports() {
        guard let database = database else {
            return
        }
        self.draftReports.value = database.getReports(reportStatus: ReportStatus.draft)
        self.outboxedReports.value = database.getReports(reportStatus: ReportStatus.outbox)
        self.submittedReports.value = database.getReports(reportStatus: ReportStatus.submitted)
    }
    
    func addReport(report : Report) throws -> Int {
        
        guard let database = database else {
            throw SqliteError()
        }
        let id = try database.addReport(report: report)
        getReports()
        return id
        
    }
    
    func updateReport(report : Report) throws -> Int {
        
        guard let database = database else {
            throw SqliteError()
        }
        let id = try database.updateReport(report: report)
        getReports()
        return id
        
    }
    
    func deleteReport(reportId : Int?) throws -> Int {
        
        guard let database = database else {
            throw SqliteError()
        }
        let id = try database.deleteReport(reportId: reportId)
        getReports()
        return id
    }
}
