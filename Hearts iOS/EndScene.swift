//
//  EndScene.swift
//  Cards- A Collection
//
//  Created by Abhijith Vemulapati on 11/23/16.
//  Copyright © 2016 AcidFlavor. All rights reserved.
//

import UIKit
import SpriteKit

class EndScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        let winner = UserDefaults.standard.string(forKey: "gameWinner")!
        let winnerLabel = SKLabelNode(text: winner + " won!")
        winnerLabel.fontSize = 70
        winnerLabel.fontColor = UIColor.white
        winnerLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        addChild(winnerLabel)
        let playNewGameNode = SKLabelNode(text: "Play Again")
        playNewGameNode.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        playNewGameNode.fontColor = UIColor.white
        playNewGameNode.fontSize = 50
        playNewGameNode.name = "New"
        addChild(playNewGameNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: self)
            if let n = atPoint(loc) as? SKLabelNode {
                if n.name == "New" {
                    let scene = GameScene(fileNamed: "GameScene")
                    scene?.scaleMode = .aspectFill
                    view?.presentScene(scene!, transition: .doorsOpenVertical(withDuration: 1.0))
                }
            }
        }
    }
}
