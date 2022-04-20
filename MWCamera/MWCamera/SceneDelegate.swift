//
//  SceneDelegate.swift
//  MWCamera
//
//  Created by Xavi Moll on 2/12/20.
//  Copyright © 2020 Future Workshops. All rights reserved.
//

import UIKit
import MobileWorkflowCore
import MWCameraPlugin

class SceneDelegate: MWSceneDelegate {
    
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        self.dependencies.plugins = [MWCameraPluginStruct.self]
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
