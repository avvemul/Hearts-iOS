//
//  MultiplayerScene.swift
//  
//
//  Created by Abhijith Vemulapati on 11/19/16.
//
//

import UIKit
import SpriteKit
import Firebase

class MultiplayerScene : SKScene {
    var round : Int?
    var currentPlayer : Player!
    var roomKey : String! = ""
    var playerNames: [String]?
    var count = 0
    var passCards = false
    var cards = [Card]()
    var players = [Player]()
    var playersInOriginalOrder = [Player]()
    var player : Player!
    var heartsBroken = false
    var zConstant = CGFloat(0.0)
    var roundCards = [Card]()
    var cardsToPass = [Card]()
    var roomKeyLabel = SKLabelNode()
    
    override func didMove(to view: SKView) {
        UserDefaults.standard.set(roomKey, forKey: "roomKey")
        UserDefaults.standard.set(true, forKey: "inGame")
        createScoreNode()
        lobby()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    func createScoreNode() {
        let scores = SKLabelNode()
        scores.position = CGPoint(x: frame.width - 70, y: frame.height - 150)
        scores.text = "Menu"
        scores.fontColor = UIColor.white
        scores.fontName = "Helvetica Neue Bold"
        scores.zPosition = zConstant
        zConstant += 1
        addChild(scores)
    }
    
    func menuPressed() {
        scene?.isPaused = true
        let alert = UIAlertController(title: "Menu", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Quit Game", style: .destructive, handler: {(alt) in
            let sc = MenuScene(fileNamed: "MenuScene")
            sc?.scaleMode = .aspectFill
            self.view?.presentScene(sc)
        }))
        alert.addAction(UIAlertAction(title: "Back", style: .cancel, handler: {(alt) in
            self.scene?.isPaused = false
        }))
        var scoresString = ""
        for p in playersInOriginalOrder {
            scoresString += "\(p.name)  \(p.score) " + "(" + "\(p.overallScore)" + ")" + "\n"
        }
        alert.addAction(UIAlertAction(title: "See Scores", style: .default, handler: {(alt) in
            let scores = UIAlertController(title: "Scores", message: scoresString, preferredStyle: .alert)
            scores.addAction(UIAlertAction(title: "Back", style: .cancel, handler: {(a) in self.scene?.isPaused = false}))
            self.view?.window?.rootViewController?.present(scores, animated: true, completion: nil)
        }))
        self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let roomRef = FIRDatabase.database().reference().child("rooms").child(roomKey)
        for touch in touches {
            if let _ = atPoint(touch.location(in: self)) as? SKLabelNode {
                menuPressed()
            }
            if let card = atPoint(touch.location(in: self)) as? Card {
                if passCards {
                    if card.isSelected {
                        cardsToPass.remove(at: cardsToPass.index(of: card)!)
                        card.returnCardToOriginalSize()
                    } else {
                        cardsToPass.append(card)
                        card.selectCard()
                    }
                    if cardsToPass.count == 3 {
                        passCards = false
                        FIRDatabase.database().reference().child("rooms").child(roomKey).child("players").child(self.player.name).child("cardsToPass").setValue(cardsToPass.map({$0.key}))
                        FIRDatabase.database().reference().child("rooms").child(roomKey).child("playerPutData").setValue(true)

                    }
                }
                else {
                    if currentPlayer == nil {return}
                    if currentPlayer.name != player.name {return}
                    if card.isSelected {
                        playCard(card: card, p: player)
                        spreadCards()
                    } else {
                        if getPlayableCards().contains(card) {
                            print("selecting")
                            player.cards.map({$0.returnCardToOriginalSize()})
                            card.selectCard()
                        }
                    }
                }
            }
        }
    }
    
    func playerInfoButton() {
        var playerInfoNode = SKLabelNode(text: "Menu")
        playerInfoNode.fontName = "Helvetica Neue Bold"
        playerInfoNode.position = CGPoint(x: 950, y: 700)
        playerInfoNode.name = "playerInfo"
        addChild(playerInfoNode)
        roomKeyLabel = SKLabelNode(text: "Room key: \(roomKey!)")
        roomKeyLabel.fontName = "Helvetica Neue Bold"
        roomKeyLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(roomKeyLabel)
    }
    
    func setUpMultiGame() {
        cards = makeDeck()
    }
    
    func getPlayableCards() -> [Card] {
        var playableCards = player.cards
        if round! == 1 {
            if roundCards.count == 0 {
                playableCards = [player.cards[player.cards.index(where: {$0.key == "2c"})!]]
            } else {
                playableCards = playableCards.filter({$0.suit == "c"})
            }
            if playableCards.count == 0 {
                playableCards = player.cards.filter({$0.suit != "h"})
            }
        }
        else {
            if roundCards.count == 0 {
                if !heartsBroken {
                    playableCards = playableCards.filter({$0.suit != "h"})
                }
            } else {
                playableCards = playableCards.filter({$0.suit == roundCards[0].suit})
            }
        }
        
        if playableCards.count == 0 {
            return player.cards
        }
        return playableCards
    }
    
    func getCardPlayPosition(p : Player) -> CGPoint {
        switch playersInOriginalOrder.index(where: {$0.name == p.name})! {
        case 1:
            return CGPoint(x: frame.midX - 70, y: frame.midY)
        case 2:
            return CGPoint(x: frame.midX, y: frame.midY + 50)
        case 3:
            return CGPoint(x: frame.midX + 70, y: frame.midY)
        default:
            return CGPoint(x: frame.midX, y: frame.midY - 50)
        }
    }
    
    func playCard(card : Card, p : Player) {
        var updated = false
        card.zPosition = zConstant
        zConstant += 1
        card.texture = card.cardFace
        card.returnCardToOriginalSize()
        card.run(SKAction.rotate(toAngle: 0, duration: 0.25))
        card.run(SKAction.move(to: getCardPlayPosition(p: p), duration: 0.25))
        if !roundCards.contains(card) {
            roundCards.append(card)
        }
        
        if p.cards.contains(card) {
            p.cards.remove(at: p.cards.index(of: card)!)
        }

        if p.name == self.player.name {
            FIRDatabase.database().reference().child("rooms").child(roomKey).child("roundCards").setValue(roundCards.map({$0.key}))
            updated = true
        }
        
        if self.roundCards.count == 4 {
            FIRDatabase.database().reference().child("rooms").child(roomKey).child("players").child(player.name).child("playerStatus").setValue("lastCardPlayed")
            updated = true
        }
        
        if updated {
            FIRDatabase.database().reference().child("rooms").child(roomKey).child("playerPutData").setValue(true)
        }
    }
    
    func discardCards() {
        var actions = [SKAction]()
        actions.append(SKAction.wait(forDuration: 0.25))
        let determiningCards = roundCards.filter({$0.suit == roundCards[0].suit})
        let c = roundCards.index(where: {$0.key == determiningCards.max(by: {$0.number > $1.number})?.key})
        let roundWinner = players[c!]
        actions.append(SKAction.run {
            self.roundCards.map({$0.run(SKAction.move(to: self.discardPointFor(p: roundWinner), duration: 0.25))})
        })
        run(SKAction.sequence(actions))
    }
    
    func discardPointFor(p: Player) -> CGPoint {
        switch playersInOriginalOrder.index(where: {$0.name == p.name})! {
        case 1:
            return CGPoint(x: -200, y: frame.midY)
        case 2:
            return CGPoint(x: frame.midX, y: 900)
        case 3:
            return CGPoint(x: 1200, y: frame.midY)
        default:
            return CGPoint(x: frame.midX, y: -200)
        }
    }
    
    func createPlayers() -> [Player] {
        let myName = UserDefaults.standard.string(forKey: "name")
        var p = [Player]()
        for n in playerNames! {
            p.append(Player(CPU: false, name: n))
        }
        player = p[p.index(where: {$0.name == myName})!]
        return p
    }
    
    func getPlayerNames(snapShot: FIRDataSnapshot) -> [String] {
        var a = [String]()
        for child in snapShot.children {
            a.append((child as! FIRDataSnapshot).value as! String)
        }
        return a
    }
    
    func getCardFromKey(key : String) -> Card {
        return cards[cards.index(where: {$0.key == key})!]
    }
    
    func getCardsForPlayer(keys : [String]) -> [Card] {
        var playerCards = [Card]()
        for key in keys {
            playerCards.append(getCardFromKey(key: key))
        }
        return playerCards
    }
    
    func giveCardsToPlayers(players : FIRDataSnapshot) {
        for p in self.players {
            let pCards = players.childSnapshot(forPath: p.name).childSnapshot(forPath: "cards").value as? [String]
            p.cards = getCardsForPlayer(keys: pCards!)
        }
    }
    
    func lobby() {
        let name = UserDefaults.standard.string(forKey: "name")!
        let waitLbl = SKLabelNode(text: "Waiting for other players...")
        waitLbl.name = "Settings"
        waitLbl.fontSize = 40
        waitLbl.fontName = "Helvetica Neue Bold"
        waitLbl.position = CGPoint(x: 512, y: 136)
        addChild(waitLbl)
        FIRDatabase.database().reference().child("rooms").child(roomKey).observe(.value, with: {(snap) in
            let pS = snap.childSnapshot(forPath: "players").childSnapshot(forPath: name).childSnapshot(forPath: "playerStatus").value
            if let ps = pS as? String {
                if ps == "received" || ps == "playing" {
                    if snap.childSnapshot(forPath: "gameStatus").value as? String == "terminated" {
                        let scene = MenuScene(fileNamed: "MenuScene")
                        scene?.scaleMode = .aspectFill
                        self.view?.presentScene(scene!, transition: .doorsOpenVertical(withDuration: 1.0))
                        
                    } else if snap.childSnapshot(forPath: "gameStatus").value as? String == "play" {
                        if self.passCards {
                            self.passCards = false
                            for p in self.players {
                                p.cards.removeAll()
                                let sn = snap.childSnapshot(forPath: "players").childSnapshot(forPath: p.name).childSnapshot(forPath: "cards")
                                let cardKeys = (sn.value as? [String])
                                for c in cardKeys! {p.cards.append(self.getCardFromKey(key: c))}
                            }
                            var actions = [SKAction]()
                            actions.append(SKAction.run({self.spreadCards()}))
                            actions.append(SKAction.run {
                                self.players.filter({$0.name != self.player.name}).map({self.spreadCardsFor(p: $0)})
                            })
                            self.run(SKAction.sequence(actions))
                        }
                        let cP = snap.childSnapshot(forPath: "currentPlayer").value as? String
                        if self.round == snap.childSnapshot(forPath: "round").value as? Int {
                            if let c = snap.childSnapshot(forPath: "roundCards").value as? [String] {
                                self.roundCards = c.map({self.getCardFromKey(key: $0)})
                            }
                            if self.currentPlayer.name != cP || ((snap.childSnapshot(forPath: "lastCard").value as? Bool)! && self.roundCards.count == self.players.count) {
                                print("Im right here lmao")
                                self.playCard(card: self.roundCards[self.roundCards.count - 1], p: self.currentPlayer)
                                self.currentPlayer = self.getPlayerFromName(n: cP!)
                            }
                            
                            if self.roundCards.count == self.players.count {
                                self.discardCards()
                            }
                            
                            
                        } else {
                            self.roundCards.removeAll()
                            self.currentPlayer = self.getPlayerFromName(n: cP!)
                            self.round = snap.childSnapshot(forPath: "round").value as? Int
                            let pn = (snap.childSnapshot(forPath: "playerOrder").value as? [String])!
                            var temp = [Player]()
                            for p in (0..<pn.count) {
                                temp.append(self.getPlayerFromName(n: pn[p]))
                            }
                            self.players = temp
                            for p in self.players {
                                p.score = (snap.childSnapshot(forPath: "players").childSnapshot(forPath: p.name).childSnapshot(forPath: "score").value as? Int)!
                            }
                            self.currentPlayer = self.players[self.players.index(where: {$0.name == cP!})!]
                        }
                        self.heartsBroken = (snap.childSnapshot(forPath: "heartsAreBroken").value as? Bool)!
                    } else if snap.childSnapshot(forPath: "gameStatus").value as? String == "passCards" {
                        self.passCards = true
                    }
                    return
                }
            }
            if self.count >= 1 {return}
            if snap.childSnapshot(forPath: "gameStatus").value as? String == "ready" {
                self.count += 1
                self.playerNames = self.getPlayerNames(snapShot: snap.childSnapshot(forPath: "playerOrder"))
                self.players = self.createPlayers()
                self.setUpMultiGame()
                self.giveCardsToPlayers(players: (snap.childSnapshot(forPath: "players")))
            FIRDatabase.database().reference().child("rooms").child(self.roomKey).child("players").child((self.player?.name)!).updateChildValues(["playerStatus" : "received"])
                FIRDatabase.database().reference().child("rooms").child(self.roomKey).child("playerPutData").setValue(true)
                self.orderRespectToPlayer()
                self.passOutCards()
                waitLbl.removeFromParent()
                self.roomKeyLabel.removeFromParent()
            } else if snap.childSnapshot(forPath: "gameStatus").value as? String == "gameOver" {
                let winner = snap.childSnapshot(forPath: "winner").value as? String
                UserDefaults.standard.set(self.players.min(by: {$0.overallScore < $1.overallScore})?.name , forKey: "gameWinner")
                let scene = EndScene(fileNamed: "EndScene")
                scene?.scaleMode = .aspectFill
                self.view?.presentScene(scene!, transition: .doorsOpenVertical(withDuration: 1.0))
                FIRDatabase.database().reference().child("rooms").child(self.roomKey).removeAllObservers()
                return
            }
        })
    }
    
    func orderRespectToPlayer() {
        var temp = [Player]()
        let startIndex = players.index(where: {$0.name == player?.name})!
        for i in (startIndex..<startIndex + 4) {
            if i >= players.count {
                temp.append(players[i - 4])
            } else {
                temp.append(players[i])
            }
        }
        playersInOriginalOrder = temp
        print(playersInOriginalOrder.map({$0.name}))
    }
    
    func getPlayerFromName(n : String) -> Player {
        return players[players.index(where: {$0.name == n})!]
    }
    
    func getDestinationPointForPlayer(p : Player) -> CGPoint {
        switch playersInOriginalOrder.index(where: {$0.name == p.name})! {
        case 1:
            return CGPoint(x: 100, y: 384)
        case 2:
            return CGPoint(x: 512, y: 668)
        case 3:
            return CGPoint(x: 924, y: 384)
        default:
            return CGPoint(x: 512, y: 100)
        }
    }
    
    func passOutCards() {
        var actions = [SKAction]()
        for card in cards {
            actions.append(SKAction.run(SKAction.move(to: sendCardToLocation(card: card), duration: 0.5), onChildWithName: card.name!))
            actions.append(SKAction.wait(forDuration: 0.005))
        }
        actions.append(SKAction.wait(forDuration: 1.0))
        actions.append(SKAction.run({self.spreadCards()}))
        actions.append(SKAction.run {
            self.players.filter({$0.name != self.player.name}).map({self.spreadCardsFor(p: $0)})
        })
        run(SKAction.sequence(actions))
    }
    
    func sendCardToLocation(card : Card) -> CGPoint {
        for p in players {
            if p.cards.contains(where: {$0.key == card.key}) {
                return getDestinationPointForPlayer(p: p)
            }
        }
        return CGPoint()
    }
    
    func spreadCardsFor(p: Player) {
        let anchor = getDestinationPointForPlayer(p: p)
        if anchor.y == self.frame.midY {
            for c in p.cards {
                c.zPosition = zConstant
                zConstant = zConstant + 1
                c.returnCardToOriginalSize()
                if c.texture != c.cardBack {
                    c.flipReverse()
                }
                c.run(SKAction.rotate(toAngle: CGFloat(M_PI / 2), duration: 0.5))
                var yP = CGFloat(20 * p.cards.index(of: c)! + 264)
                if anchor.x > anchor.y {
                    yP = CGFloat(-20 * p.cards.index(of: c)! + 504)
                }
                c.run(SKAction.move(to: CGPoint(x: anchor.x, y: yP), duration: 0.5))
                print("moved")
            }
        } else if anchor.x == self.frame.midX {
            for c in p.cards {
                c.zPosition = zConstant
                zConstant = zConstant + 1
                c.run(SKAction.rotate(toAngle: 0, duration: 0.5))
                if c.texture != c.cardBack {
                    c.flipReverse()
                }
                c.returnCardToOriginalSize()
                let xP = CGFloat(20 * p.cards.index(of: c)! + 392)
                c.run(SKAction.move(to: CGPoint(x: xP, y: anchor.y), duration: 0.5))
            }
        }
    }
    
    func makeDeck() -> Array<Card>{
        var cards : Array<Card> = []
        let suits = ["h", "s", "c", "d"]
        let nums = (2...14)
        for n in nums{
            for s in suits {
                cards.append(addCardNode(n, suit: s))
            }
        }
        cards.map{$0.setValue()}
        cards = shuffleCards(cards)
        return cards
    }
    
    func shuffleCards(_ cards : [Card]) -> [Card] {
        var cards = cards
        for i in (0..<cards.count - 1) {
            let j = Int(arc4random_uniform(UInt32(cards.count - i))) + i
            guard i != j else { continue }
            swap(&cards[i], &cards[j])
        }
        return cards
    }
    
    func addCardNode(_ num : Int, suit : String) -> Card {
        let card = Card(suit : suit, number : num)
        card.name = card.key
        card.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(card)
        return card
    }
    
    func getYPosition(_ c : Card) -> CGFloat {
        if player.cards.count == 1 {
            return 10
        }
        let x = Float(player.cards.index(of: c)!)
        let ll = Float(player.cards.count - 1)
        let l = (-160.0) / pow(ll, 2.0)
        let lBy2 = Float(player.cards.count - 1) / 2.0
        let p = pow(x - lBy2, 2.0) * l
        return CGFloat(p) + 40.0
    }
    
    func spreadCards() {
        var actions = [SKAction]()
        var angleToRotateTo = CGFloat()
        var movePosition = CGPoint()
        player.cards.sort(by: {$0.number < $1.number})
        for c in player.cards {
            c.zPosition = zConstant + 2
            zConstant += 1.0
            let w = Float(player.cards.index(of: c)!) - Float((Float(player.cards.count) - 1.0) / 2.0)
            movePosition.x = CGFloat(512.0 + (w * (60.0 + Float((12 - player.cards.count) * 4))))
            angleToRotateTo = CGFloat(-1.0 * Float(w * Float(M_PI / 36.0)))
            movePosition.y = CGFloat(getYPosition(c) + 90.0)
            print("\(movePosition.x) \(movePosition.y) \(angleToRotateTo)")
            actions.append(SKAction.run(SKAction.move(to: movePosition, duration: 0.5), onChildWithName: c.key))
            actions.append(SKAction.run(SKAction.rotate(toAngle: CGFloat(angleToRotateTo), duration: 0.25), onChildWithName: c.key))
            if c.texture == c.cardBack {
                c.flip()
            }
        }
        actions.append(SKAction.run {
            print(self.player.cards.map({$0.position}))
        })
        self.run(SKAction.sequence(actions))
    }

    
}
