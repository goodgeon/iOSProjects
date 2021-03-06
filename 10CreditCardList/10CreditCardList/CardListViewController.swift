//
//  CardListViewController.swift
//  10CreditCardList
//
//  Created by 李 グッゴン on 2022/06/21.
//

import Foundation
import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseFirestore

class CardListViewController: UITableViewController {
//    var ref: DatabaseReference!
    var db = Firestore.firestore()
    
    var creditCardList: [CreditCard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nibName = UINib(nibName: "CardListCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CardListCell")
        
//        ref = Database.database().reference()
//
//        ref.observe(.value, with: {[weak self] snapshot in
//            guard let value = snapshot.value as? [String: [String:Any]] else { return }
//
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: value)
//                let cardData = try JSONDecoder().decode([String: CreditCard].self, from: jsonData)
//                let cardList = Array(cardData.values)
//                self?.creditCardList = cardList.sorted { $0.rank < $1.rank }
//
//                DispatchQueue.main.async {
//                    self?.tableView.reloadData()
//                }
//            } catch let error {
//                print("ERROR JSON parsing \(error.localizedDescription)")
//            }
//        })
        
        
        //Firestore
        db.collection("creditCardList").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("ERROR Firestore fetching document \(String(describing: error))")
                return
            }
            
            self.creditCardList = documents.compactMap { doc -> CreditCard? in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: [])
                    let creditCard = try JSONDecoder().decode(CreditCard.self, from: jsonData)
                    return creditCard
                }catch let error {
                    print("ERROR JSON Parsing \(error.localizedDescription)")
                    return nil
                }
            }.sorted(by: {
                $0.rank < $1.rank
            })
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creditCardList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardListCell", for: indexPath) as? CardListCell else { return UITableViewCell() }
        
        cell.rankLabel.text = "\(creditCardList[indexPath.row].rank)위"
        cell.promotionLabel.text = "\(creditCardList[indexPath.row].promotionDetail.amount)만원 증정"
        cell.cardNameLabel.text = "\(creditCardList[indexPath.row].name)"
        
        let imageURL = URL(string: creditCardList[indexPath.row].cardImageURL)
        cell.cardImageView.kf.setImage(with: imageURL)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let detailViewController = storyboard.instantiateViewController(withIdentifier: "CardDetailViewController") as? CardDetailViewController else { return }
        
        detailViewController.promotionDetail = creditCardList[indexPath.row].promotionDetail
        self.show(detailViewController, sender: nil)
        
        //realtime database
//        ref.queryOrdered(byChild: "id").queryEqual(toValue: creditCardList[indexPath.row].id).observe(.value, with: {[weak self] snapshot in
//            guard let self = self,
//                  let value = snapshot.value as? [String: [String: Any]],
//                  let key = value.keys.first else { return }
//
//            self.ref.child("\(key)").child("isSelected").setValue(true)
//        })
        
        //Firestore
        //option1
        let cardID = creditCardList[indexPath.row].id
//        db.collection("creditCardList").document("card\(cardID)").updateData(["isSelected": true])
        
        //option2
        db.collection("creditCardList").whereField("id", isEqualTo: cardID).getDocuments { snapshot, _ in
            guard let document = snapshot?.documents.first else {
                print("ERROR Firestore fetching document")
                return
            }
            
            document.reference.updateData(["isSelected":true])
            
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //realtime database
//            ref.queryOrdered(byChild: "id").queryEqual(toValue: creditCardList[indexPath.row].id).observe(.value, with: {[weak self] snapshot in
//                guard let self = self,
//                      let value = snapshot.value as? [String: [String: Any]],
//                      let key = value.keys.first else { return }
//
//                self.ref.child(key).removeValue()
//            })
            
            //Firestore
            //option1
            let cardID = creditCardList[indexPath.row].id
//            db.collection("creditCardList").document("card\(cardID)").delete()
            
            //option2
            db.collection("creditCardList").whereField("id", isEqualTo: cardID).getDocuments(completion: { snapshot, _ in
                guard let document = snapshot?.documents.first else {
                    print("ERROR")
                    return
                }

                document.reference.delete()
            })
        }
    }
}
