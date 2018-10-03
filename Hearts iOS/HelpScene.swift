//
//  HelpScene.swift
//  Cards- A Collection
//
//  Created by Abhijith Vemulapati on 11/27/16.
//  Copyright © 2016 AcidFlavor. All rights reserved.
//

import UIKit
import SpriteKit

class HelpScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        let back = SKLabelNode(text: "Back")
        back.fontColor = UIColor.white
        back.fontName = "Helvetica Neue Bold"
        back.fontSize = 20
        back.position = CGPoint(x: 30, y: frame.midY - 150)
        addChild(back)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if let _ = atPoint(t.location(in: self)) as? SKLabelNode {
                let sce = MenuScene(fileNamed: "MenuScene")
                sce?.scaleMode = .aspectFill
                self.view?.presentScene(sce)
            }
        }
    }
}
