//
//  GameViewController.swift
//  testSceneKitGameMine
//
//  Created by Eugene Mekhedov on 18.09.17.
//  Copyright © 2017 Eugene Mekhedov. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
    
    struct bodyType{
        static var ball = 1 << 1
        static var coin = 1 << 2
    }

    var scnView : SCNView!
    var scnScene = SCNScene()
    var scnCameraNode = SCNNode()
    var scnBallNode : SCNNode!
    
    var countBoxes = 0
    var lastBoxNumber = 0
    
    var left = false
    var correctPath = true
    
    var scoreNodeLabel : SCNNode!
    var highScoreNodeLabel : SCNNode!
    
    var score = 0
    var highScore = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        createFirstBox()
        for _ in 0...5{
            createBox()
        }
        createBall()
        setupLight()
        setupCamera()
        setupLabel()
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.gray
        scnView = self.view as! SCNView
        scnView.delegate = self
    }
    
    func setupScene(){
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupLight() {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.eulerAngles = SCNVector3(-45, 45, 0)
        
        scnScene.rootNode.addChildNode(lightNode)
        
        
        let lightNode2 = SCNNode()
        lightNode2.light = SCNLight()
        lightNode2.light?.type = .directional
        lightNode2.eulerAngles = SCNVector3(45, 45, 0)
        
        scnScene.rootNode.addChildNode(lightNode2)
    }

    
    func setupCamera(){
        scnCameraNode.camera = SCNCamera()
        scnCameraNode.camera?.usesOrthographicProjection = true
        scnCameraNode.camera?.orthographicScale = 3
        scnCameraNode.position = SCNVector3(x:20, y: 20, z: 20)
        scnCameraNode.eulerAngles = SCNVector3(34, 45, 0)

        let constraint = SCNLookAtConstraint(target: scnBallNode)
        constraint.isGimbalLockEnabled = true // target устанавливается по центру?
        scnCameraNode.constraints = [constraint]
                
        scnScene.rootNode.addChildNode(scnCameraNode)
        
    }
    
    func setupLabel(){
        scoreNodeLabel = SCNNode()
        
        let textGeometry = SCNText(string: "Score: \(score)", extrusionDepth: 0.1)
        textGeometry.font = UIFont(name: "Arial", size: 0.7)
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.init(colorLiteralRed: 0.899, green: 0.588, blue: 0.183, alpha: 1)
        textGeometry.materials = [textMaterial]
        scoreNodeLabel.geometry = textGeometry
        scoreNodeLabel.position = SCNVector3(0, 3, 0)
        scoreNodeLabel.eulerAngles = SCNVector3(0,45,0)
        scnScene.rootNode.addChildNode(scoreNodeLabel)
        
        
        highScoreNodeLabel = SCNNode()
        let highScoreGeometry = SCNText(string: "High score: \(highScore)", extrusionDepth: 0.1)
        highScoreGeometry.font = UIFont(name: "Arial", size: 0.7)
        let highScoreMaterial = SCNMaterial()
        highScoreMaterial.diffuse.contents = UIColor.init(colorLiteralRed: 0.899, green: 0.588, blue: 0.183, alpha: 1)
        highScoreGeometry.materials = [highScoreMaterial]
        highScoreNodeLabel.geometry = highScoreGeometry
        highScoreNodeLabel.position = SCNVector3(0, -4, 3)
        highScoreNodeLabel.eulerAngles = SCNVector3(0,45,0)
        scnScene.rootNode.addChildNode(highScoreNodeLabel)
    }
    
    func updateLabel(){
        DispatchQueue.main.async {
            (self.scoreNodeLabel.geometry as! SCNText).string = "Score: \(self.score)"
            (self.highScoreNodeLabel.geometry as! SCNText).string = "High score: \(self.highScore)"
        }
    }
    
    func createFirstBox(){
        correctPath = true
        
        countBoxes = 0
        lastBoxNumber = 0
        
        let boxNode = SCNNode()
        let boxGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.init(colorLiteralRed: 0.95, green: 0.75, blue: 0.3, alpha: 1)
        boxGeometry.materials = [boxMaterial]
        
        boxNode.geometry = boxGeometry
        boxNode.name = String(countBoxes)
        
        boxNode.position = SCNVector3(0,0,0)
        
        scnScene.rootNode.addChildNode(boxNode)
    }
    
    func createBox(){
        let tempBox = SCNNode()
        let prevBox = scnScene.rootNode.childNode(withName: String(countBoxes), recursively: false)!
        countBoxes += 1
        tempBox.name = String(countBoxes)
        tempBox.geometry = prevBox.geometry
        
        let randomNumber = arc4random_uniform(2)
        switch randomNumber {
        case 0:
            tempBox.position = SCNVector3(prevBox.position.x - Float((tempBox.geometry as! SCNBox).width), 3, prevBox.position.z)
            if correctPath {
                correctPath = false
                left = false
            }
        case 1:
            tempBox.position = SCNVector3(prevBox.position.x, 3, prevBox.position.z - Float((tempBox.geometry as! SCNBox).width))
            if correctPath {
                correctPath = false
                left = true
            }
        default:
            break;
        }
        addCoin(box: tempBox)
        scnScene.rootNode.addChildNode(tempBox)
        fadeIn(node: tempBox)
    }
    
    func addCoin(box: SCNNode){
        scnScene.physicsWorld.gravity = SCNVector3(0,0,0)
        let random = arc4random_uniform(8)
        if random == 3{
            let coinScene = SCNScene(named: "art.scnassets/coin.scn")
            let coin = coinScene?.rootNode.childNode(withName: "coin", recursively: false)
            coin?.position = SCNVector3(box.position.x, 3 + 1, box.position.z)
            if coin != nil{
                fadeIn(node: coin!)
                coin?.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2 * CGFloat.pi, z: 0, duration: 1)))
                
                coin?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: coin!, options: nil))
                coin?.physicsBody?.categoryBitMask = bodyType.coin
                coin?.physicsBody?.collisionBitMask = bodyType.ball
                coin?.physicsBody?.contactTestBitMask = bodyType.ball
                coin?.physicsBody?.isAffectedByGravity = false
                
                scnScene.rootNode.addChildNode(coin!)
            }
        }
    }
    
    func createBall(){
        
        score = 0
        let userDefaults = UserDefaults.standard
        if userDefaults.integer(forKey: "highScore") != 0{
            highScore = userDefaults.integer(forKey: "highScore")
        }else{
            highScore = 0
        }
        
        scnBallNode = SCNNode()
        let ballGeometry = SCNSphere(radius: 0.2)
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIColor.init(colorLiteralRed: 1, green: 0, blue: 0, alpha: 1)
        ballGeometry.materials = [ballMaterial]
        
        scnBallNode.geometry = ballGeometry
        scnBallNode.position = SCNVector3(0, 0.7, 0)
        
        scnBallNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: scnBallNode, options: nil))
        scnBallNode.physicsBody?.categoryBitMask = bodyType.ball
        scnBallNode.physicsBody?.collisionBitMask = bodyType.coin
        scnBallNode.physicsBody?.contactTestBitMask = bodyType.coin
        scnBallNode.physicsBody?.isAffectedByGravity = false
        
        scnScene.rootNode.addChildNode(scnBallNode)
    }
    
    func die(){
        scnBallNode.runAction(SCNAction.move(to: SCNVector3(scnBallNode.position.x,scnBallNode.position.y - 10,scnBallNode.position.z), duration: 1))
        
        let wait = SCNAction.wait(duration: 0.5)
        
        let removeBall = SCNAction.run { [weak self] (node) in
            self?.scnScene.rootNode.enumerateChildNodes({ (node, stop) in
                node.removeFromParentNode()
            })
        }
        
         let createScene = SCNAction.run { [weak self] (node) in
            self?.setupView()
            self?.setupScene()
            self?.createFirstBox()
            for _ in 0...5{
                self?.createBox()
            }
            self?.setupLight()
            self?.createBall()
            self?.setupCamera()
            self?.setupLabel()
        }
        
        let sequance = SCNAction.sequence([wait, removeBall, createScene])
        scnBallNode.runAction(sequance)
    }
    
    //MARK: Fade
    
    func fadeIn(node: SCNNode){
        node.opacity = 0
        node.runAction(SCNAction.move(to: SCNVector3(node.position.x, node.position.y - 3, node.position.z), duration: 0.5))
        node.runAction(SCNAction.fadeIn(duration: 0.5))
    }
    
    func fadeOut(node: SCNNode){
        node.runAction(SCNAction.move(to: SCNVector3(node.position.x, node.position.y - 2, node.position.z), duration: 1))
        node.runAction(SCNAction.fadeOut(duration: 1))
        let blockAction = SCNAction.run { (node) in
            node.removeFromParentNode()
        }
        let wait = SCNAction.wait(duration: 1)
        let sequance = SCNAction.sequence([wait, blockAction])
        
        node.runAction(sequance)
    }
    
    func addScore(){
        score += 1
        if score > highScore{
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
        updateLabel()
    }
    
    func removeCoin(coin: SCNNode){
        coin.physicsBody?.categoryBitMask = 1
        makeCoinSound(coin)
        coin.runAction(SCNAction.move(to: SCNVector3(coin.position.x, coin.position.y + 1, coin.position.z), duration: 0.5))
        coin.runAction(SCNAction.fadeOut(duration: 0.3))
        let wait = SCNAction.wait(duration: 1)
        let remove = SCNAction.run { (node) in
            node.removeFromParentNode()
        }
        let sequance = SCNAction.sequence([wait, remove])
        coin.runAction(sequance)
        
        addScore()
    }
    
    func makeCoinSound(_ coin: SCNNode){
        let audio = SCNAudioSource(fileNamed: "art.scnassets/coin.mp3")!
        audio.volume = 20
        coin.runAction(SCNAction.playAudio(audio, waitForCompletion: false))
    }
    
    //MARK: SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if nodeA.physicsBody?.categoryBitMask == bodyType.coin && nodeB.physicsBody?.categoryBitMask == bodyType.ball{
            removeCoin(coin: nodeA)
        }else if nodeA.physicsBody?.categoryBitMask == bodyType.ball && nodeB.physicsBody?.categoryBitMask == bodyType.coin{
            removeCoin(coin: nodeB)
        }
    }
    
    //MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if left == false{
            scnBallNode.removeAllActions()
            scnBallNode.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(-50,0,0), duration: 20)))
            
            scoreNodeLabel.removeAllActions()
            scoreNodeLabel.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(-50,0,0), duration: 20)))
            highScoreNodeLabel.removeAllActions()
            highScoreNodeLabel.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(-50,0,0), duration: 20)))

//            scnCameraNode.removeAllActions()
//            scnCameraNode.runAction(SCNAction.repeatForever(SCNAction.move(to: SCNVector3(scnCameraNode.position.x - 50,scnCameraNode.position.y, scnCameraNode.position.z), duration: 20)))
//            scnCameraNode.position = SCNVector3(scnCameraNode.position.x - 50, scnCameraNode.position.y, scnCameraNode.position.z)
            
            left = true
        }else{
            scnBallNode.removeAllActions()
            scnBallNode.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0,0,-50), duration: 20)))
            
            scoreNodeLabel.removeAllActions()
            scoreNodeLabel.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0,0,-50), duration: 20)))
            highScoreNodeLabel.removeAllActions()
            highScoreNodeLabel.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0,0,-50), duration: 20)))
            left = false
        }
        scnCameraNode.position = SCNVector3(scnBallNode.position.x + 20, scnCameraNode.position.y, scnBallNode.position.z + 20)

        
    }
    //MARK: - SCNSceneRendererDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        let deleteBox = scnScene.rootNode.childNode(withName: String(lastBoxNumber), recursively: true)
        let currentBox = scnScene.rootNode.childNode(withName: String(lastBoxNumber + 1), recursively: true)
        
        if (deleteBox?.position.x)! > scnBallNode.position.x + 1 || (deleteBox?.position.z)! > scnBallNode.position.z + 1{
            lastBoxNumber += 1
            fadeOut(node: deleteBox!)
            createBox()
        }
        
        if scnBallNode.position.x > (currentBox?.position.x)! - 0.5 && scnBallNode.position.x < (currentBox?.position.x)! + 0.5 ||
           scnBallNode.position.z > (currentBox?.position.z)! - 0.5 && scnBallNode.position.z < (currentBox?.position.z)! + 0.5{
            //On platform
        }else{
            die()
        }
        
    }
}
