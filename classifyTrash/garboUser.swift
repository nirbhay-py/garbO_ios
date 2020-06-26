import Firebase
import JGProgressHUD
import Foundation

class GarboUser {
    var name:String!
    var email:String!
    var plasticScanned:Int!
    var itemsScanned:Int!
    init(name:String,email:String,plasticScanned:Int,itemsScanned:Int) {
        self.name = name
        self.email = email
        self.plasticScanned = plasticScanned
        self.itemsScanned = itemsScanned
    }
}
