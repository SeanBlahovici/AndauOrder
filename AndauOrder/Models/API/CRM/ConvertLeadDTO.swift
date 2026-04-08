import Foundation

struct ConvertLeadRequest: Encodable, Sendable {
    let Deals: ConvertDealData
}

struct ConvertDealData: Encodable, Sendable {
    let Deal_Name: String
    let Closing_Date: String
    let Stage: String
    let Amount: Decimal
}

struct ConvertLeadResponse: Decodable, Sendable {
    let Contacts: CRMRecordID
    let Accounts: CRMRecordID
    let Deals: CRMRecordID
}
