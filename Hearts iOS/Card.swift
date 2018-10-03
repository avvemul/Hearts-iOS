//
//  Card.swift
//  Hearts
//
//  Created by Abhijith Vemulapati on 8/8/16.
//  Copyright © 2016 Abhijith Vemulapati. All rights reserved.
//

import SpriteKit

class Card: SKSpriteNode {
    let suit : String
    let number : Int
    let key : String
    let cardFace : SKTexture
    let cardBack : SKTexture
    var isSelected : Bool
    var value : Int
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(suit : String, number : Int) {
        self.key = String(number) + suit
        self.suit = suit
        self.number = number
        self.value = 0
        self.cardFace = SKTexture(imageNamed: key + UserDefaults.standard.string(forKey: "cardFace")!)
        self.cardBack = SKTexture(imageNamed: "b")
        self.isSelected = false
        super.init(texture: cardBack, color : SKColor.clear, size: CGSize(width: cardFace.size().width * 1.25, height: cardFace.size().height * 1.25))
    }
    
    func setValue() {
        if self.suit == "h" {
            self.value = 1
        } else if self.key == "12s" {
            self.value =  13
        }
    }
    
    func selectCard() {
        run(SKAction.scale(to: 1.2, duration: 0.1))
        self.isSelected = true
    }
    
    func returnCardToOriginalSize() {
        run(SKAction.scale(to: 1.0, duration: 0.1))
        self.isSelected = false
    }
    
    func flip() {
        let firstHalfFlip = SKAction.scaleX(to: 0.0, duration: 0.4)
        let secondHalfFlip = SKAction.scaleX(to: 1.0, duration: 0.4)
        run(firstHalfFlip, completion: {
            self.texture = self.cardFace
            self.run(secondHalfFlip)
        }) 
    }
    
    func flipReverse() {
        let firstHalfFlip = SKAction.scaleX(to: 0.0, duration: 0.4)
        let secondHalfFlip = SKAction.scaleX(to: 1.0, duration: 0.4)
        run(firstHalfFlip, completion: {
            self.texture = self.cardBack
            self.run(secondHalfFlip)
        }) 
    }
    
}
