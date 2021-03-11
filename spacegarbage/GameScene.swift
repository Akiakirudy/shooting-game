//
//  GameScene.swift
//  spacegarbage
//
//  Created by Akira Tachibana on 3/10/21.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //properties
    var starfield: SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel : SKLabelNode!
    var score:Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer : Timer!
    var possibleGarbage = ["satellite", "jupitar", "alien"]
    
    let garbageCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAcceleration : CGFloat = 0
    
     //background image
     override func didMove(to View: SKView){
         starfield = SKEmitterNode(fileNamed: "Starfield")
         starfield.position = CGPoint(x: 0, y: 1472)
         starfield.advanceSimulationTime(10)
         self.addChild(starfield)
        starfield.zPosition = -1
        
        //player property
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: self.frame.size.width / 2, y: player.size.height / 2 + 20)
        player.setScale(0.1)
        self.addChild(player)
        
        //I don't know what it is
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        //scorelabel property
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: 100, y: self.frame.size.height - 100)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 34
        scoreLabel.fontColor = UIColor.white
        score = 0
        self.addChild(scoreLabel)
        
        //create garbage repeatedly
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addGarbage), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error: Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
        
        
     }
    
    @objc func addGarbage() {
        possibleGarbage = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleGarbage) as! [String]
       
        let garbage = SKSpriteNode(imageNamed: possibleGarbage[0])
        garbage.setScale(0.1)
        let randomGarbagePostition = GKRandomDistribution(lowestValue: 0, highestValue: 414)
        let position = CGFloat(randomGarbagePostition.nextInt())
        garbage.position = CGPoint(x: position, y: self.frame.size.height + garbage.size.height)
        
        garbage.physicsBody = SKPhysicsBody(rectangleOf: garbage.size)
        garbage.physicsBody?.isDynamic = true
        
        garbage.physicsBody?.collisionBitMask = 0
        
        self.addChild(garbage)
        
        let animationDuration : TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -garbage.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        garbage.run(SKAction.sequence(actionArray))
    }

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fire()
    }
    
    func fire(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = garbageCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(torpedoNode)
        
        let animationDuration: TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x , y: self.frame.size.height +  10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody : SKPhysicsBody
        var secondBody : SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if firstBody.categoryBitMask & photonTorpedoCategory != 0 && (secondBody.categoryBitMask & garbageCategory) != 0 {
            torpedoDidCollideWithGarbage(torpedoNode: firstBody.node as! SKSpriteNode, garbageNode: secondBody.node as! SKSpriteNode)
        }
    }
    func torpedoDidCollideWithGarbage (torpedoNode: SKSpriteNode, garbageNode:SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = garbageNode.position
        self.addChild(explosion)
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        torpedoNode.removeFromParent()
        garbageNode.removeFromParent()
        
        //explosion will be removed after torpedoNOde and gargbageNode were deleted.
        self.run(SKAction.wait(forDuration: 2)){
            explosion.removeFromParent()
        }
        
        score += 5
    }
    
    override func didSimulatePhysics(){
        player.position.x += xAcceleration * 50
        
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    

    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    

}
