//
//  ProfilePictureProtocol.swift
//  ARC
//
//  Created by Sproull Student on 2/25/23.
//

import Foundation
import UIKit

protocol ProfilePictureUpdater {
    func setPicture(image: UIImage)
    func resetPicture()
}
