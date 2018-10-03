//
//  Player.swift
//  Hearts
//
//  Created by Abhijith Vemulapati on 8/9/16.
//  Copyright © 2016 Abhijith Vemulapati. All rights reserved.
//

class Player {
    var cards : [Card]
    let CPU : Bool
    var score : Int
    var overallScore : Int
    let name : String
    
    init(CPU : Bool, name : String) {
        self.cards = []
        self.CPU = CPU
        self.score = 0
        self.overallScore = 0
        self.name = name
    }
    
    func playerDict() -> [String : Any] {
        return [
            "cards" : self.cards.map({$0.key}),
            "score" : self.score,
            "overallScore" : self.overallScore,
            "playerStatus" : "joined"
            ]
    }
    func isHeartsOutThere() -> Bool{
        // Determines if Hearts is there
        return true // For now
    }
    func playOptimalCard(_ roundCards : [Card], availableCards : [Card], round : Int, cardsNotPlayed : [Card]) -> Card {
        let roundScore = roundCards.map{$0.value}
        let order = roundCards.count
        if availableCards.count == 1 {
            return availableCards[0]
        }
        
        if round == 1 {
            return availableCards.sorted(by: {$0.number > $1.number})[0]
        }
        
        if availableCards.count == self.cards.count && order != 0 {
            if availableCards.contains(where: {$0.key == "12s"}) {
                return availableCards[availableCards.index(where: {$0.key == "12s"})!]
            }
            else {
                return availableCards.sorted(by: {$0.number > $1.number})[0]
            }
        }
        if order == 0 {
            print (availableCards.count)
            return availableCards.sorted(by: {$0.number > $1.number})[availableCards.count/2]
        } else if order == 3 {
            if roundScore.reduce(0, +) == 0 {
                if roundCards[0].suit == "s" {
                    let sp = availableCards.sorted(by: {$0.number > $1.number}).filter{$0.key != "12s"}
                    if roundCards.contains(where: {$0.number >= 13 && $0.suit == "s"}) {
                        
                    } else {
                        if sp.count > 0 {
                            return sp[0]
                        } else {
                            return availableCards[0]
                        }
                    }
                }
                return availableCards.sorted(by: {$0.number > $1.number})[0]
            } else {
                let bM = availableCards.filter({$0.number < roundCards[0].number})
                if bM.count == 0 {
                    return availableCards.sorted(by: {$0.number < $1.number})[0]
                } else {
                    return bM[0]
                }
            }
        } else {
            let bM = availableCards.filter({$0.number < roundCards[0].number})
            if bM.count == 0 {
                return availableCards.sorted(by: {$0.number < $1.number})[0]
            } else {
                return bM[0]
            }

        }
        
        return availableCards[0]
    }
}
