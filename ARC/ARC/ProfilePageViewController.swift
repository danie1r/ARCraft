//
//  ProfilePageViewController.swift
//  ARC
//
//  Created by Sproull Student on 2/18/23.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class ProfilePageViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var emailAddress: UILabel!
    var profile: UIImage!
    var delegate: ProfilePictureUpdater?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        profilePicture.layer.cornerRadius = profilePicture.frame.size.height / 2
        
        if Auth.auth().currentUser != nil {
            emailAddress.text = Auth.auth().currentUser?.email
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        profilePicture.image = profile
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let picture = profilePicture.image else {
            return
        }
        
        delegate?.setPicture(image: picture)
    }
    
    @IBAction func changeProfilePicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        guard let profile = profilePicture else {
            return
        }
        
        // Set profile picture with Firebase
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        // Check if we can convert image to data
        let imageData = image.jpegData(compressionQuality: 0.7)
        guard imageData != nil else {
            return
        }
        
        // Specify file path and name
        let storageRef = Storage.storage().reference()
        let profilePath = "profile/\(user.uid).jpg"
        let profileRef = storageRef.child(profilePath)
        
        // Upload data
        profileRef.putData(imageData!, metadata: nil) {
            metadata, error in
            
            if error != nil || metadata == nil {
                return
            }
            
            // Save reference to file in Firestore DB
            let db = Firestore.firestore()
            db.collection(user.uid).document().setData(["url":profilePath])
        }
        
        // Set profile picture on app
        profile.image = image
        dismiss(animated: true)
    }
    
    func setDefault() {
        let defaultImage = UIImage(named: "ARC_Small")
        profilePicture.image = defaultImage
    }
    
    @IBAction func shareFeature(_ sender: Any) {
        guard let strongStoryboard = storyboard else {
            return
        }

        guard let collectionVC = strongStoryboard.instantiateViewController(withIdentifier: "collectionVC") as? CollectionViewController  else {
            return
        }

        present(collectionVC, animated: true, completion: nil)
    }
    
    // TEST: Can share basic image
    func shareFile() {
        let image = UIImage(named: "ARC_Small")
                
        // set up activity view controller
        let imageToShare = [ image! ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func showCameraFeed(_ sender: Any) {
        print("Insert Camera Implementation")
    }
    
    @IBAction func signoutAttempt(_ sender: Any) {
        if IsLoggedIn() {
            do {
                try Auth.auth().signOut()
                profilePicture.image = nil
                delegate?.resetPicture()
                navigationController?.popViewController(animated: true)
            }
            catch {
                print("An error occurred")
            }
        }
        else {
            print("Already not logged in.")
        }
    }
    
    // Check if logged in
    func IsLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
}
