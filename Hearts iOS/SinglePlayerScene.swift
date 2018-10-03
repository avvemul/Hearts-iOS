//
//  GameScene.swift
//  Hearts Mac
//
//  Created by Abhijith Vemulapati on 9/9/16.
//  Copyright (c) 2016 Abhijith Vemulapati. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    var player : Player!
    var firstPlayer : Player!
    var players = [Player]()
    var playersInOriginalOrder = [Player]()
    var cards : Array<Card> = []
    var round = 1
    var cardsChosen = [Card]()
    var passCards = true
    var zConstant : CGFloat = 0.0
    var roundCards = [Card]()
    var gameNumber = 1
    var playerCanPlay = false
    var heartsBroken = false
    
    override func didMove(to view: SKView) {
        setBackground()
        createScoreNode()
        cards = makeDeck()
        view.ignoresSiblingOrder = true
        let names = ["Einstein", "Newton", "Archimedes"]
        players.append(Player(CPU: false, name: "You"))
        (0..<3).map{players.append(Player(CPU: true, name: names[$0]))}
        playersInOriginalOrder = players
        player = players[0]
        handOutCards()
        print(UIDevice.current.model)
        print(UIDevice.current.name)

    }
    
    func handOutCards() {
        var actions = [SKAction]()
        for c in cards {
            giveCardToCorrectPlayer(cards.index(of: c)!, c: c)
            actions.append(SKAction.run(SKAction.move(to: getTargetLocationForCard(cards.index(of: c)!), duration: 0.5), onChildWithName: c.name!))
            actions.append(SKAction.wait(forDuration: 0.005))
        }
            actions.append(SKAction.wait(forDuration: 0.5))
            actions.append(SKAction.run({self.spreadCards(true)}))
            orderPlayers()
            run(SKAction.sequence(actions))
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            var actions = [SKAction]()
            if let _ = atPoint(touch.location(in: self)) as? SKLabelNode {
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
                    scoresString += "\(p.name)   \(p.score) " + "(" + "\(p.overallScore)" + ")" + "\n"
                }
                alert.addAction(UIAlertAction(title: "See Scores", style: .default, handler: {(alt) in
                    let scores = UIAlertController(title: "Scores", message: scoresString, preferredStyle: .alert)
                    scores.addAction(UIAlertAction(title: "Back", style: .cancel, handler: {(a) in self.scene?.isPaused = false}))
                    self.view?.window?.rootViewController?.present(scores, animated: true, completion: nil)
                }))
                self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            if passCards {
                if let card = atPoint(touch.location(in: self)) as? Card {
                    if player.cards.contains(card) {
                        if !cardsChosen.contains(card) {
                            card.selectCard()
                            cardsChosen.append(card)
                            print("PASS")
                            if cardsChosen.count == 3 {
                                actions.append(SKAction.run({
                                    self.getChosenCardsFromAllPlayers()
                                    self.players.map{
                                        if $0.CPU {
                                            self.spreadCardsForCPU($0)
                                        }
                                    }
                                    self.spreadCards(true)
                                }))
                                passCards = false
                                actions.append(SKAction.wait(forDuration: 0.25))
                                run(SKAction.sequence(actions), completion: {
                                    self.orderPlayers()
                                    if self.players[0].CPU {
                                        self.cpuTurn(self.players[0])
                                    } else {
                                        self.playerCanPlay = true
                                    }
                                    self.cardsChosen.removeAll()
                                })
                            }
                        } else {
                            cardsChosen.remove(at: cardsChosen.index(of: card)!)
                            card.returnCardToOriginalSize()
                        }
                    }
                }
            }
            if !playerCanPlay {return}
            let availableCardKeys = getAvailableCards(player).map{$0.key}
            let location = touch.location(in: self)
            if let card = atPoint(location) as? Card {
                if availableCardKeys.contains(card.key){
                    if card.isSelected {
                        playerCanPlay = false
                        self.playCardForPlayer(card, p: player)
                        spreadCards(false)
                        run(SKAction.wait(forDuration: 0.25), completion: {self.checkIfRoundOver(self.player)})
                    } else {
                        player.cards.map{$0.returnCardToOriginalSize()}
                        card.selectCard()
                    }
                }
            } else {
                player.cards.map{$0.returnCardToOriginalSize()}
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let _ = atPoint(touch.location(in: self)) as? SKLabelNode {
                if let scoresNode = childNode(withName: "scores") {
                    scoresNode.removeFromParent()
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let _ = atPoint(touch.location(in: self)) as? SKLabelNode {
                if let scoresNode = childNode(withName: "scores") {
                    scoresNode.removeFromParent()
                }
            }
        }
    }
    
    func getPassCardsFromPlayers() -> [[Card]]{
        var chosenCardSets = [[Card]]()
        for p in players {
            if p.CPU {
                chosenCardSets.append(getPassCardsForCPU(p))
                print(p.cards.map{$0.key})
            } else {
                chosenCardSets.append(Array(cardsChosen))
                cardsChosen.map{p.cards.remove(at: p.cards.index(of: $0)!)}
                print(p.cards.map{$0.key})
                print(p.name)
            }
        }
        print(chosenCardSets.map{$0.map{$0.key}})
        return chosenCardSets
    }
    
    func getPassCardsForCPU(_ p : Player) -> [Card] {
        var sortedCards = p.cards.sorted{$0.number > $1.number}
        sortedCards = sortedCards.filter{$0.key != "12s"}
        var passCards = [Card]()
        for i in (0..<3) {
            passCards.append(sortedCards[i])
        }
        passCards.map{p.cards.remove(at: p.cards.index(of: $0)!)}
        return passCards
    }
    
    func getPassTypeForRound() -> Int {
        switch gameNumber % 4 {
        case 1:
            return 1
        case 2:
            return -1
        case 3:
            return 2
        default:
            return 0
        }
    }
    
    func getChosenCardsFromAllPlayers() {
        let pNum = getPassTypeForRound()
        var chosenCardSets = getPassCardsFromPlayers()
        for c in (0..<4) {
            print(chosenCardSets[c].map{$0.key})
            print(players[c].name)
            if c + pNum > 3 {
                if pNum == 1 {
                    for card in chosenCardSets[c] {
                        players[0].cards.append(card)
                    }
                } else {
                    for card in chosenCardSets[c] {
                        players[c - pNum].cards.append(card)
                    }
                }

            } else if c + pNum < 0 {
                for card in chosenCardSets[c] {
                    players[3].cards.append(card)
                }
            } else {
                print(c + pNum)
                for card in chosenCardSets[c] {
                    players[c + pNum].cards.append(card)
                }

            }
        }
    }
    
    func playNextPlayer(_ currentPlayer : Player) {
        var actions = [SKAction]()
         if players.index(where: {$0.name == currentPlayer.name})! + 1 < 4 {
            if players[players.index(where: {$0.name == currentPlayer.name})! + 1].CPU {
                actions.append(SKAction.wait(forDuration: 0.1))
                self.run(SKAction.sequence(actions), completion: {
                    self.cpuTurn(self.players[self.players.index(where: {$0.name == currentPlayer.name})! + 1])
                })
            } else {playerCanPlay = true}
        } else {
            if players[0].CPU {
                actions.append(SKAction.wait(forDuration: 0.1))
                self.run(SKAction.sequence(actions), completion: {self.cpuTurn(self.players[0])})
            } else {playerCanPlay = true}
        }
    }
    
    
    
    func playCardForPlayer(_ card : Card, p : Player) {
        card.zPosition = zConstant
        zConstant += 1
        roundCards.append(card)
        card.texture = card.cardFace
        card.returnCardToOriginalSize()
        print("CARD" + card.key)
        let a = SKAction.run(SKAction.move(to: getCardPlayedLocation(p), duration: 0.25), onChildWithName: card.key)
        let b = SKAction.run(SKAction.rotate(toAngle: 0, duration: 0.25), onChildWithName: card.key)
        run(SKAction.sequence([a,b]))
        if card.suit == "h" {
            heartsBroken = true
        }

        p.cards.remove(at: p.cards.index(where: {$0.key == card.key})!)
    }
    
    func queenSpadesPlayed() -> Bool {
        return players.filter({$0.cards.contains(where: {$0.key == "12s"})}).count == 0
    }
    
    func cpuTurn(_ p : Player) {
        var actions = [SKAction]()
        let available = getAvailableCards(p)
        let notPlayed = players[0].cards + players[1].cards + players[2].cards + players[3].cards
        let play = p.playOptimalCard(roundCards, availableCards: available, round: round, cardsNotPlayed: notPlayed)
        actions.append(SKAction.wait(forDuration: 0.25))
        actions.append(SKAction.run({
            self.playCardForPlayer(play, p: p)
            self.spreadCardsForCPU(p)
        }))
        actions.append(SKAction.wait(forDuration: 0.5))
        actions.append(SKAction.run({self.checkIfRoundOver(p)}))
        self.run(SKAction.sequence(actions))
    }
    
    func checkIfRoundOver(_ p : Player) {
        var selector : Selector!
        if roundIsOver() {
            giveScoreToPlayerForRound()
            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(GameScene.setUpForNextRound), userInfo: nil, repeats: false)
        } else {
            playNextPlayer(p)
        }
    }
    
    func gameIsOver() -> Bool {
        return (round > 13) // Tetu was here
    }
    
    func setUpForNextGame() {
        round = 1
        gameNumber += 1
        heartsBroken = false
        print(players.map({$0.score}))
        if players.filter({$0.score == 26}).count == 0 {
            players.map{$0.overallScore += $0.score; $0.score = 0}
        } else {
            for p in players {
                if p.name != players[players.index(where: {$0.score == 26})!].name {
                    p.overallScore += 26
                }
            }
        }
        players.map({$0.cards.removeAll()})
        let overall = UserDefaults.standard.integer(forKey: "maxScore")
        if players.filter({$0.overallScore >= overall}).count > 0 {
            UserDefaults.standard.set(players.min(by: {$0.overallScore < $1.overallScore})?.name , forKey: "gameWinner")
            let scene = EndScene(fileNamed: "EndScene")
            scene?.scaleMode = .aspectFill
            self.view?.presentScene(scene!, transition: .doorsOpenVertical(withDuration: 1.0))
            return
        }
        players = playersInOriginalOrder
        roundCards.removeAll()
        cards = shuffleCards(cards)
        handOutCards()
        cards.map{if $0.texture == $0.cardFace {$0.flipReverse()}}
        if getPassTypeForRound() == 0 {
            self.orderPlayers()
            if players[0].CPU {cpuTurn(players[0])}
            else {playerCanPlay = true}
        } else {
            passCards = true
        }
    }
    
    func setUpForNextRound() {
        round += 1
        print("ROUND")
        print(round)
        orderPlayers()
        self.roundCards.map{$0.run(SKAction.move(to: self.getDiscardLocationForCards(self.players[0]), duration: 0.5))}
        roundCards.removeAll()
        if gameIsOver() {
            setUpForNextGame()
        } else {
            if players[0].CPU {cpuTurn(players[0])}
            else {playerCanPlay = true}
        }
    }
    
    func roundIsOver() -> Bool {
        return roundCards.count == 4
    }
    
    func giveCardToCorrectPlayer(_ n : Int, c : Card) {
        if n % 4 == 1 {
            players[1].cards.append(c)
        }
        else if n%4 == 2 {
            players[2].cards.append(c)
        }
        else if n%4 == 3 {
            players[3].cards.append(c)
        } else {
            player.cards.append(c)
        }
        
    }
    
    func getTargetLocationForCard(_ n : Int) -> CGPoint {
        if n % 4 == 1 {
            return CGPoint(x: 100, y: 384)
        }
        else if n%4 == 2 {
            return CGPoint(x: 512, y: 668)
        }
        else if n%4 == 3 {
            return CGPoint(x: 924, y: 384)
        } else {
            return CGPoint(x: 512, y: 100)
        }
    }
    
    func getDiscardLocationForCards (_ n : Player) -> CGPoint {
        if n.name == "You" {
            return CGPoint(x: 512, y: -500)
        }
        else if n.name == "Archimedes" {
            return CGPoint(x: 1200, y: 384)
        }
        else if n.name == "Newton" {
            return CGPoint(x: 512, y: 1300)
        } else {
            return CGPoint(x: -500, y: 384)
        }
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
    
    func spreadCards(_ flip: Bool) {
        var actions = [SKAction]()
        var angleToRotateTo = CGFloat()
        var movePosition = CGPoint()
        player.cards.sort(by: {$0.number < $1.number})
        for c in player.cards {
            c.zPosition = zConstant
            zConstant += 1.0
            let w = Float(player.cards.index(of: c)!) - Float((Float(player.cards.count) - 1.0) / 2.0)
            movePosition.x = CGFloat(512.0 + (w * (60.0 + Float((12 - player.cards.count) * 4))))
            angleToRotateTo = CGFloat(-1.0 * Float(w * Float(M_PI / 36.0)))
            movePosition.y = CGFloat(getYPosition(c) + 90.0)
            actions.append(SKAction.run(SKAction.move(to: movePosition, duration: 0.5), onChildWithName: c.key))
            actions.append(SKAction.run(SKAction.rotate(toAngle: CGFloat(angleToRotateTo), duration: 0.25), onChildWithName: c.key))
            if flip {
                if c.texture == c.cardBack {
                    c.flip()
                }
            }
        }
        self.run(SKAction.sequence(actions))
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
        card.position = getMidPoint()
        addChild(card)
        return card
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func setBackground() {
        let sn = SKSpriteNode(imageNamed: "images")
        sn.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        sn.zPosition = -1.0
        sn.size = CGSize(width: self.frame.width, height: self.frame.height)
        addChild(sn)
    }
    
    func getMidPoint() -> CGPoint {
        return CGPoint(x: self.frame.midX, y: self.frame.midY)
    }
    
    func getCardPlayedLocation(_ n : Player) -> CGPoint {
        if n.name == "You" {
            return CGPoint(x: self.frame.midX, y: self.frame.midY - 50)
        }
        else if n.name == "Archimedes" {
            return CGPoint(x: self.frame.midX + 70, y: self.frame.midY)
        }
        else if n.name == "Newton" {
            return CGPoint(x: self.frame.midX, y: self.frame.midY + 70)
        } else {
            return CGPoint(x: self.frame.midX - 70, y: self.frame.midY)
        }
    }
    
    func orderPlayers() {
        var firstPlayer : Player!
        let temp = players
        if round == 1 {
            firstPlayer = temp.filter{$0.cards.map{$0.key}.contains("2c")}[0]
        } else {
            firstPlayer = players[roundCards.index(of: getRoundHighestCard())!]
        }
        players.removeAll()
        let startIndex = temp.index(where: {$0.name == firstPlayer.name})
        players = []
        let endIndex = startIndex! + 3
        for i in (startIndex!...endIndex) {
            if i < 4 {
                players.append(temp[i])
            } else {
                players.append(temp[i - 4])
            }
        }
    }
    
    func getRoundHighestCard() -> Card {
        let roundSameSuit = roundCards.filter{$0.suit == roundCards[0].suit}
        return roundSameSuit.sorted{$0.number > $1.number}[0]
    }
    
    func giveScoreToPlayerForRound() {
        let highest = players[roundCards.index(of: getRoundHighestCard())!]
        highest.score += getScoreForRound()
    }
    
    func getScoreForRound() -> Int {
        return roundCards.map{$0.value}.reduce(0, +)
    }
    
    func spreadCardsForCPU(_ p : Player) {
        let anchor = getAnchorPositionForPlayer(p)
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
    
    func getAnchorPositionForPlayer(_ p : Player) -> CGPoint {
        if p.name == "Einstein" {
            return CGPoint(x: 100, y: 384)
        } else if p.name == "Newton" {
            return CGPoint(x: 512, y: 668)
        } else {
            return CGPoint(x: 912, y: 384)
        }
    }
    
    func getAvailableCards(_ p : Player) -> [Card] {
        var available = [Card]()
        if round == 1 {
            if players.index(where: {$0.name == p.name}) == 0 {
                return p.cards.filter{$0.key == "2c"}
            }
            available = available.filter{$0.suit != "h"}
        }
        
        if (players.index(where: {$0.name == p.name})! != 0) {
            available = p.cards.filter{$0.suit == roundCards[0].suit}
        }
        
        if available.count == 0 {
            available = p.cards
        }
        
        if (!heartsBroken && players.index(where: {$0.name == p.name}) == 0) {
            available = available.filter{$0.suit != "h"}
        }
        
        return available
    }
}
