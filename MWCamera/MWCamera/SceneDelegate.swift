//
//  SceneDelegate.swift
//  MWCamera
//
//  Created by Xavi Moll on 2/12/20.
//  Copyright © 2020 Future Workshops. All rights reserved.
//

import MobileWorkflowCore
import MWCameraPlugin

class SceneDelegate: MobileWorkflowSceneDelegate {
    
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        self.dependencies.plugins = [MWCameraPlugin.self]
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
