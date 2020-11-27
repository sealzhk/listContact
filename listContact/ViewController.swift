//
//  ViewController.swift
//  listContact
//
//  Created by Alua Zhakieva on 11/27/20.
//  Copyright © 2020 Alua Zhakieva. All rights reserved.
//

import UIKit
import RealmSwift
import ContactsUI

var contacts: Results<Contact>!
var realm = try! Realm()

class contactsCell: UITableViewCell {
    @IBOutlet weak var contListImage: UIImageView!
    @IBOutlet weak var contListName: UILabel!
    @IBOutlet weak var contListNum: UILabel!
}

class Contact: Object {
    @objc dynamic var name = ""
    @objc dynamic var phoneNum = ""
    @objc dynamic var image: NSData?
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var contListTV: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! contactsCell
        let contact = contacts[indexPath.row]
        cell.contListName.text = contact.name
        cell.contListNum.text = contact.phoneNum
        let image: UIImage = UIImage(data: contact.image! as Data)!
        cell.contListImage.image = image
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contacts = realm.objects(Contact.self)
        self.contListTV.delegate = self
        self.contListTV.dataSource = self
        self.reload()
    }
    
    func reload() {
           contListTV.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editContact" {
            let destination = segue.destination as! secVC
            let cont = contacts[contListTV.indexPathForSelectedRow!.row]
            destination.incomingCont = cont
        }
    }


}

class secVC: UIViewController {
    var incomingCont: Contact? = nil
    let contactsController = CNContactPickerViewController()
    @IBOutlet weak var contName: UITextField!
    @IBOutlet weak var contNum: UITextField!
    @IBOutlet weak var contImage: UIImageView!
    
    @IBAction func getContact(_ sender: Any) {
        contactsController.delegate = self
        self.present(contactsController, animated: true, completion: nil)
    }
    
    @IBAction func getImage(_ sender: Any) {
        self.chooseDir()
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let image = NSData(data: contImage.image!.jpegData(compressionQuality: 0.9)!)
        if let newC = incomingCont {
            try! realm.write {
                newC.name = contName.text!
                newC.phoneNum = contNum.text!
                newC.image = image
            }
        }
        else {
            let newCont = Contact()
            newCont.name = contName.text!
            newCont.phoneNum = contNum.text!
            newCont.image = image
            try! realm.write {
                realm.add(newCont)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let newC = incomingCont {
            contName.text = newC.name
            contNum.text = newC.phoneNum
            let cImage: UIImage = UIImage(data: newC.image! as Data)!
            contImage.image = cImage
        }
    }
}

extension secVC: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        print("Phone number: \(contact.phoneNumbers[0].value.stringValue)")
        print("Name: \(contact.givenName) \(contact.familyName)")
        self.contNum.text = contact.phoneNumbers[0].value.stringValue
        self.contName.text = "\(contact.givenName) \(contact.familyName)"
    }
}

extension secVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func chooseDir() {
           let libraryAction = UIAlertAction(title: "Choose from Library", style: .default) { (action) in
               self.showImage(sourceType: .photoLibrary)
           }
           let cameraAction = UIAlertAction(title: "Choose from Camera", style: .default) { (action) in
               self.showImage(sourceType: .camera)
           }
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
           
           AlertService.showAlert(style: .actionSheet, title: "Choose image from:", message: nil, actions: [libraryAction, cameraAction, cancelAction], completion: nil)
       }
       
       func showImage(sourceType: UIImagePickerController.SourceType) {
           let imagesController = UIImagePickerController()
           imagesController.delegate = self
           imagesController.sourceType = sourceType
           present(imagesController, animated: true, completion: nil)
       }
       
       func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
           if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
               contImage.image = editedImage
           }
           else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
               contImage.image = originalImage
           }
           
           dismiss(animated: true, completion: nil)
       }
}
