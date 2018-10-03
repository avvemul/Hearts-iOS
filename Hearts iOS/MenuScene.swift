//
//  MenuScene.swift
//  Hearts Mac
//
//  Created by Abhijith Vemulapati on 9/18/16.
//  Copyright © 2016 Abhijith Vemulapati. All rights reserved.
//

import UIKit
import SpriteKit
import Firebase

class MenuScene: SKScene {
    
    var cardSeg = UISegmentedControl()
    var scoreSeg = UISegmentedControl()
    var settingsView = UIView()
    var settingsUp = false
    var changeName = UITextField()
    let scores = [50,100,200]
    let imgPacks = ["", "-2"]
    var ss = UISegmentedControl()
    var multiOptionsView = UIView()
    
    override func didMove(to view: SKView) {
        print("I AM HERE")
        if let _ = UserDefaults.standard.string(forKey: "cardFace") {
        } else {
            UserDefaults.standard.set("", forKey: "cardFace")
            UserDefaults.standard.set(100, forKey: "maxScore")
        }
        backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
        let t = SKLabelNode(text: "CARDS - A COLLECTION")
        t.name = "Title"
        t.position = CGPoint(x: 512, y: 500)
        t.fontName = "Marker Felt"
        t.fontSize = 100
        addChild(t)
        let play = SKLabelNode(text: "Single")
        play.name = "Play"
        play.fontSize = 40
        play.fontName = "Marker Felt"
        play.position = CGPoint(x: 512, y: 310)
        addChild(play)
        let m = SKLabelNode(text: "Settings")
        m.name = "Settings"
        m.fontSize = 40
        m.fontName = "Marker Felt"
        m.position = CGPoint(x: 512, y: 130)
        addChild(m)
        let settings = SKLabelNode(text: "Help")
        settings.name = "Help"
        settings.fontSize = 40
        settings.fontName = "Marker Felt"
        settings.position = CGPoint(x: 512, y: 190)
        addChild(settings)
        let multi = SKLabelNode(text: "Multiplayer")
        multi.name = "Multi"
        multi.fontSize = 40
        multi.fontName = "Marker Felt"
        multi.position = CGPoint(x: 512, y: 250)
        addChild(multi)
    }
    
    override func update(_ currentTime: TimeInterval) {}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let button = atPoint(touch.location(in: self)) as? SKLabelNode {
                if button.name == "Play" && !settingsUp {
                    let scene = GameScene(fileNamed: "GameScene")!
                    scene.scaleMode = .aspectFill
                    self.view?.presentScene(scene, transition: SKTransition.flipVertical(withDuration: 1.0))
                } else if button.name == "Multi" && !settingsUp {
                    let al = UIAlertController(title: "Multiplay", message: nil, preferredStyle: .alert)
                    al.addAction(UIAlertAction(title: "Create Room", style: .default, handler: {(a) in
                        self.create()
                    }))
                    al.addAction(UIAlertAction(title: "Join Room", style: .default, handler: {(a) in
                        self.join()
                    }))
                    if let _ = UserDefaults.standard.string(forKey: "name") {
                        self.view?.window?.rootViewController?.present(al, animated: true, completion: nil)
                    }
                    else {
                        let a = UIAlertController(title: "Enter A Username", message: nil, preferredStyle: .alert)
                        a.addTextField(configurationHandler: nil)
                        a.addAction(UIAlertAction(title: "Save", style: .cancel, handler: {(aa) in
                            FIRDatabase.database().reference().child("names").observeSingleEvent(of: .value, with: {(s) in
                                print(s.hasChild((a.textFields?[0].text)!))
                                if !s.hasChild((a.textFields?[0].text)!) {
                                    FIRDatabase.database().reference().child("names").child((a.textFields?[0].text)!).setValue(true)
                                    UserDefaults.standard.set((a.textFields?[0].text)!, forKey: "name")
                                    self.view?.window?.rootViewController?.present(al, animated: true, completion: nil)

                                } else {
                                    self.view?.window?.rootViewController?.present(a, animated: true, completion: nil)
                                }
                            })
                        }))
                        view?.window?.rootViewController?.present(a, animated: true, completion: nil)
                    }
                } else if button.name == "Help" && !settingsUp {
                    let scene = HelpScene(fileNamed: "HelpScene")!
                    scene.scaleMode = .aspectFill
                    view?.presentScene(scene)
                } else if button.name == "Settings" {
                    settingsView = UIView(frame: CGRect(x: (view?.frame.midX)! - 150, y: (view?.frame.midY)! - 200, width: 300, height: 400))
                    settingsView.backgroundColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
                    settingsView.layer.cornerRadius = 20
                    scoreSeg = UISegmentedControl(items: ["50", "100", "200"])
                    scoreSeg.frame = CGRect(x: (settingsView.frame.width / 2) - 50, y: 20, width: 100, height: 40)
                    cardSeg = UISegmentedControl()
                    cardSeg.frame = CGRect(x: (settingsView.frame.width / 2) - 73, y: settingsView.frame.height - 250, width: 73 * 2, height: 110)
                    cardSeg.insertSegment(with: #imageLiteral(resourceName: "13s").withRenderingMode(.alwaysOriginal), at: 0, animated: false)
                    cardSeg.insertSegment(with: #imageLiteral(resourceName: "13s-2").withRenderingMode(.alwaysOriginal), at: 1, animated: false)
                    cardSeg.selectedSegmentIndex = imgPacks.index(of: UserDefaults.standard.string(forKey: "cardFace")!)!
                    scoreSeg.selectedSegmentIndex = scores.index(of: UserDefaults.standard.integer(forKey: "maxScore"))!
                    let doneButton = UIButton(type: .roundedRect)
                    doneButton.frame = CGRect(x: (settingsView.frame.width / 2) - 50, y: settingsView.frame.height - 80, width: 100, height: 60)
                    doneButton.setTitleColor(UIColor.black, for: .normal)
                    doneButton.setTitle("Done", for: .normal)
                    doneButton.addTarget(self, action: #selector(MenuScene.doneChangingSettings), for: .touchUpInside)
                    changeName = UITextField(frame: CGRect(x: (settingsView.frame.width / 2) - 125, y: 100, width: 250, height: 20))
                    changeName.borderStyle = .bezel
                    changeName.placeholder = "Username"
                    if let username = UserDefaults.standard.string(forKey: "name") {
                        changeName.text = username
                    }
                    settingsView.addSubview(cardSeg)
                    settingsView.addSubview(scoreSeg)
                    settingsView.addSubview(changeName)
                    settingsView.addSubview(doneButton)
                    self.view?.addSubview(settingsView)
                    settingsUp = true
                }
            }
        }
    }
    
    func doneChangingSettings() {
        UserDefaults.standard.set(scores[scoreSeg.selectedSegmentIndex], forKey: "maxScore")
        UserDefaults.standard.set(imgPacks[cardSeg.selectedSegmentIndex], forKey: "cardFace")
        UserDefaults.standard.set(changeName.text!, forKey: "name")
        settingsView.removeFromSuperview()
        settingsUp = false
    }
    
    func getRandomKey() -> String {
        var a = ""
        let alph = Array("abcdefghijklmnopqrstuvwxyz".characters)
        for _ in (0..<5) {
            a.append(alph[Int(arc4random_uniform(UInt32(alph.count)))])
        }
        return a
    }
    
    func create() {
        multiOptionsView = UIView(frame: CGRect(x: (view?.frame.midX)! - 150, y: (view?.frame.midY)! - 75, width: 300, height: 150))
        multiOptionsView.backgroundColor = UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
        multiOptionsView.layer.cornerRadius = 20
        let doneButton = UIButton(type: .roundedRect)
        doneButton.frame = CGRect(x: (multiOptionsView.frame.width / 2) - 50, y: multiOptionsView.frame.height - 50, width: 100, height: 60)
        doneButton.setTitleColor(UIColor.black, for: .normal)
        doneButton.setTitle("Continue", for: .normal)
        doneButton.titleLabel?.font = UIFont(name: "Marker Felt", size: 20)
        ss = UISegmentedControl(items: ["50", "100", "200"])
        ss.selectedSegmentIndex = 0
        ss.frame = CGRect(x: (multiOptionsView.frame.width / 2) - 50, y: 20, width: 100, height: 40)
        doneButton.addTarget(self, action: "continueWithSettings", for: .touchUpInside)
        multiOptionsView.addSubview(doneButton)
        multiOptionsView.addSubview(ss)
        self.view?.addSubview(multiOptionsView)
    }
    
    func continueWithSettings() {
        let roomKey = getRandomKey()
        multiOptionsView.removeFromSuperview()
        FIRDatabase.database().reference().child("rooms").child(roomKey).child("maxScore").setValue(scores[ss.selectedSegmentIndex])
        FIRDatabase.database().reference().child("rooms").child(roomKey).child("gameStatus").setValue("lobby")
        FIRDatabase.database().reference().child("rooms").child(roomKey).child("playerPutData").setValue(true)
        createNewPlayerInRoom(roomKey: roomKey)
        goToMultiScene(roomKey: roomKey)
    }
    
    func join() {
        let a = UIAlertController(title: "Join", message: nil, preferredStyle: .alert)
        a.addTextField(configurationHandler: {(tf) in
            tf.placeholder = "Enter your room key"
        })
        a.addAction(UIAlertAction(title: "Join", style: .default, handler: {(ac) in
            if !(a.textFields?[0].text?.isEmpty)! {
                let roomKey = (a.textFields?[0].text)!
                FIRDatabase.database().reference().child("rooms").observeSingleEvent(of: .value, with: {(s) in
                    if s.childSnapshot(forPath: roomKey).hasChildren() {
                        if s.childSnapshot(forPath: roomKey).childSnapshot(forPath: "gameStatus").value as? String == "lobby" {
                            self.createNewPlayerInRoom(roomKey: roomKey)
                            self.goToMultiScene(roomKey: roomKey)
                        }
                    }
                })
            }
            else {
                a.dismiss(animated: true, completion: nil)
            }
        }))
        view?.window?.rootViewController?.present(a, animated: true, completion: nil)
    }
    
    func createNewPlayerInRoom(roomKey : String) {
        let na = UserDefaults.standard.string(forKey: "name")
        FIRDatabase.database().reference().child("rooms").child(roomKey).child("players").child(na!).updateChildValues(Player(CPU: false, name: na!).playerDict())
        FIRDatabase.database().reference().child("rooms").child(roomKey).child("playerPutData").setValue(true)
    }
    
    func goToMultiScene(roomKey : String) {
        let multiScene = MultiplayerScene(fileNamed: "MenuScene")
        multiScene?.scaleMode = .aspectFill
        multiScene?.roomKey = roomKey
        self.view?.presentScene(multiScene)
    }
    
}
