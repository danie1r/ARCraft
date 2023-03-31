//
//  MainViewController.swift
//  ARC
//
//  Created by Sproull Student on 2/18/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import RealityKit
import ARKit
import Combine
import Foundation


class MainViewController: UIViewController, ProfilePictureUpdater, UIImagePickerControllerDelegate, ARSessionDelegate, UITabBarDelegate, UINavigationControllerDelegate {
    
    var profile: UIImage!
    
   
    @IBOutlet weak var mainArView: ARView!
    @IBOutlet weak var bottomTab: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        InitNavigationBar()
        bottomTab.bringSubviewToFront(mainArView)
        bottomTab.delegate = self
    }
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if(item.tag == 1){
            seePhotos()
        }
        else if(item.tag == 3){
            showEffects()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        getProfilePicture()
    }
        
    // Profile picture protocol
    func setPicture(image: UIImage) {
        profile = image
    }
    
    func resetPicture() {
        profile = nil
        
    }
    
    // Create profile picture button in top right corner
    func InitNavigationBar() {
        let profile = UIImage(named: "Profile")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: profile, style: .plain, target: self, action: #selector(showProfile))
        self.navigationItem.rightBarButtonItem?.customView?.bringSubviewToFront(mainArView)
    }
    
    func getProfilePicture() {
        // Check profile picture
        if profile != nil {
            return
        }
        
        // Get current user
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        // CITATION: https://www.youtube.com/watch?v=YgjYVbg1oiA
        // Get firestore ref
        let db = Firestore.firestore()
        db.collection(user.uid).getDocuments { snapshot, error in
            
            guard error == nil else {
                return
            }
            
            guard snapshot != nil else {
                return
            }
            
            // In case there are multiple results
            var paths = [String]()
            for doc in snapshot!.documents {
                paths.append(doc["url"] as! String)
            }
            
            for path in paths {
                let storageRef = Storage.storage().reference()
                let profileRef = storageRef.child(path)
                profileRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    guard data != nil else {
                        return
                    }
                    
                    guard error == nil else {
                        return
                    }
                    
                    if let image = UIImage(data: data!){
                        DispatchQueue.main.async {
                            strongSelf.profile = image
                        }
                    }
                }
            }
        }
    }
    
    // Show effects panel
    func showEffects() {
        
        // CITATION: https://sarunw.com/posts/bottom-sheet-in-ios-15-with-uisheetpresentationcontroller/
        print("hi")
        let effectsVC = storyboard?.instantiateViewController(withIdentifier: "effectsVC") as! EffectsViewController
        effectsVC.arView = mainArView
        let nav = UINavigationController(rootViewController: effectsVC)

        nav.modalPresentationStyle = .pageSheet // Default
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
        }

        self.present(nav, animated: true, completion: nil)
    }
    
    // Show profile page or login / signup page
    @objc func showProfile() {
        let auth = Auth.auth()
        
        if auth.currentUser != nil {
            // Send to profile page
            let profileVC = storyboard?.instantiateViewController(withIdentifier: "profileVC") as! ProfilePageViewController
            profileVC.profile = profile
            profileVC.delegate = self
            navigationController?.pushViewController(profileVC, animated: true)
        }
        else {
            // Send to login and/or signup page
            let signupVC = storyboard?.instantiateViewController(withIdentifier: "signinVC") as! SigninViewController
            navigationController?.pushViewController(signupVC, animated: true)
        }
    }
    
    // See your camera roll or creations you've made?
    func seePhotos() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Check if online
//        guard let user = Auth.auth().currentUser else {
//            print("failed")
//            return
//        }
        
        if let videoURL = info[.mediaURL] as? NSURL {
            let urlSlices = videoURL.relativeString.split(separator: ".")
            //Create a temp directory using the file name
            let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let targetURL = tempDirectoryURL.appendingPathComponent(String(urlSlices[1])).appendingPathExtension(String(urlSlices[2]))

            //Copy the video over
            do {
                try FileManager.default.copyItem(at: videoURL as URL, to: targetURL)
                print(targetURL)
                let storageRef = Storage.storage().reference().child("craft.mov")
                storageRef.putFile(from: targetURL as URL, metadata: nil, completion: {
                    (metadata, error) in
                    
                    guard let metadata = metadata else {
                        // Uh-oh, an error occurred!
                        print(metadata)
                        return
                    }
                    if error != nil {
                        return
                    }
                })
            } catch {
                print(error)
                return
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // When you hit the camera / record button
    @IBAction func recordFeature(_ sender: Any) {
        print("and...... ACTION!")
    }
}
