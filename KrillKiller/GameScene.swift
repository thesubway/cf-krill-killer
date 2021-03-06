//
//  GameScene.swift
//  KrillKiller
//
//  Created by Bradley Johnson on 9/8/14.
//  Copyright (c) 2014 CodeFellows. All rights reserved.
//

import SpriteKit
import CoreMotion
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var whale = WhaleNode(imageNamed: "orca_01.png")
    var currentDepth = 50.0
    var depthLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var pauseButton = SKSpriteNode(imageNamed: "pause.jpg")
    var currentScore = 0
    var deltaTime = 0.0
    var timeSinceLastSmallBubble = 0.0
    var nextSmallBubbleTime = 0.2
    var previousTime = 0.0
    var foodYDelta = 0.0
    var timeOfLastMeal = 0.0
    var currentTime = 0.0
    var magnetBegin = 0.0
    var diverBegin = 0.0
    
    //categories:
    let whaleCategory = 0x1 << 0
    let krillCategory = 0x1 << 1
    
    // health bar
    var oxygen = 100.0
    var healthBarLocation : CGPoint!
    var healthBarWidth = 60
    var healthBarHeight = 11
    var healthBar : SKSpriteNode!
    var barColorSpectrum : [UIColor]!
    
    // overlay
    var overlay : SKShapeNode!
    var clearColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
    var overlayColorSpectrum : [UIColor]!
    var breatheLabel : SKLabelNode!
    var pausedLabel : SKLabelNode!
    var gameOverLabel : SKLabelNode!
    
    // view properties
    var oceanDepth = 2350
    var ocean : SKSpriteNode!
    var middleXPosition : Int!
    var middleYPosition : Int!
    
    var waves : SKSpriteNode!
    
    //motion properties
    var mManager = CMMotionManager()
    var currentYDirection : Double = 0.0
    
    //spawn controllers
    var spawnControllers = [SpawnController]()
    
    // audio
    var backgroundAudioPlayer = AVAudioPlayer()
    var soundPlayManager = SoundPlayManager()
    
    override func didMoveToView(view: SKView) {        
        
        self.physicsWorld.contactDelegate = self
        
        if let theSize = self.view?.bounds.size {
            self.scene?.size = theSize
        }
        else {
            //crash it:
            assert(1 == 2)
        }
        
        // Ocean background
//        var color = UIColor(red: 28.0/255.0, green: 84.0/255.0, blue: 192.0/255.0, alpha: 0.5)
//        var oceanWidth = CGFloat(self.view!.frame.width + 100)
         var oceanSize = CGSize(width: 900 , height: 2352)
        self.ocean = SKSpriteNode(color: UIColor.blueColor(), size: oceanSize)
//        self.ocean.texture = SKTexture(imageNamed: "ocean")
        middleXPosition = Int(self.view!.frame.width / 2)
        middleYPosition = Int(scene!.size.height / 2)
        
        self.ocean.anchorPoint = CGPoint(x: 0, y: 0)
        self.ocean.position = CGPoint(x: 0, y: -oceanDepth + middleXPosition + Int(self.currentDepth))
        self.addChild(ocean)
        
        self.setupOceanBackgrounds()
        
        // Sky background
//        var skyBG = SKSpriteNode(imageNamed: "sky_01.png")
//        skyBG.position = CGPointMake(284, 290)
//        self.addChild(skyBG)
        
        // Clouds
        self.setupClouds()

        // Wave background
        self.setupWaves()
        
        self.setupWhale()
        
        self.setupWaveAlphaFade()
        
//        //set background to blue
//        self.backgroundColor = UIColor.grayColor()
        
        //adding label to keep track of the current depth
        self.depthLabel.position = CGPoint(x: 280, y: 10)
        self.depthLabel.text = "\(self.currentDepth)"
        self.addChild(self.depthLabel)
        if let theScene = self.scene {
            //            self.scoreLabel.position = CGPoint(x: theScene.frame.width - 80, y: theScene.frame.height - 50)
            self.scoreLabel.position = CGPoint(x: 30, y: 18)
            self.scoreLabel.fontName = "Copperplate"
            self.scoreLabel.fontSize = 20
            self.scoreLabel.fontColor = UIColor(red: 128.0/255.0, green: 179.0/255.0, blue: 252.0/255.0, alpha: 1.0)
            self.scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
            //self.scoreLabel.text = "\(self.currentScore)"
            self.addChild(self.scoreLabel)
            //            self.pauseButton.position = CGPoint(x: theScene.frame.width - 20, y: 48)
            //            self.pauseButton.size = CGSize(width: 25, height: 25)
            //            self.addChild(self.pauseButton)
            
        // UI: Score bar
        var scoreBar = SKSpriteNode(imageNamed: "uiscorebar_01.png")
        scoreBar.position = CGPointMake(45, 24)
        self.addChild(scoreBar)
        
        // UI: Lifemeter bar
        var lifeMeterBar = SKSpriteNode(imageNamed: "uilifemeterbar_01.png")
        lifeMeterBar.position = CGPointMake(theScene.frame.width - 46, 24)
        self.addChild(lifeMeterBar)
            
        // UI: add health bar
        var oxygen : Double = 100
        var oxygenMask : SKSpriteNode!
        var healthCropNode = SKCropNode()
        healthBarLocation = CGPoint(x: 110, y: self.scene!.size.height - 20)
        var healthBarBackground = SKSpriteNode(color: UIColor.grayColor(), size: CGSize(width: healthBarWidth, height: healthBarHeight))
        healthBarBackground.position = lifeMeterBar.frame.origin
        healthBarBackground.anchorPoint = CGPoint(x: 0, y: 0)
        healthBarBackground.position.y += 5
        healthBarBackground.position.x += 4
        self.addChild(healthBarBackground)
        healthBar = SKSpriteNode(color: UIColor.greenColor(), size: CGSize(width: healthBarWidth, height: healthBarHeight))
        healthBar.position = lifeMeterBar.frame.origin
        healthBar.position.y += 5
        healthBar.position.x += 4
        healthBar.anchorPoint = CGPoint(x: 0, y: 0)
        self.addChild(healthBar)

//        healthBar.zPosition = lifeMeterBar.zPosition - 1
//        healthBarBackground.zPosition = lifeMeterBar.zPosition - 2
            
            healthBarBackground.zPosition = 100
            healthBar.zPosition = 101
            lifeMeterBar.zPosition = 102
            
            barColorSpectrum = [UIColor]()
            for i in 0..<100 {
                var greenness : CGFloat = CGFloat(Double(i * 2.5) / 255.0)
                var redness : CGFloat = CGFloat(1 - greenness)
                barColorSpectrum.append(UIColor(red: redness, green: greenness, blue: 0.0/255.0, alpha: 1.0))
            }
            
            var overlayRect = CGRect(origin: self.view!.frame.origin, size: self.view!.frame.size)
            overlay = SKShapeNode(rect: overlayRect)
            overlay.fillColor = clearColor
            self.addChild(overlay)
            overlay.zPosition = 99
            
            overlayColorSpectrum = [UIColor]()
            for i in 0..<50 {
                var overlayAlpha = CGFloat(Double((i % 5)) / 10)
                overlayColorSpectrum.append(UIColor(red: 1, green: 0, blue: 0, alpha: overlayAlpha))
            }
            
            breatheLabel = setupOverlayText("Breathe!")
            pausedLabel = setupOverlayText("Paused")
            pausedLabel.alpha = 0
            gameOverLabel = setupOverlayText("GAME OVER")
            
        }
        
        self.setupMotionDetection()
        
        self.setupSpawnControllers()
        
        self.startBackgroundMusic()
        self.depthLabel.hidden = true
    }
    
    func setupOverlayText(text: String) -> SKLabelNode {
        var newNode = SKLabelNode(text: text)
        newNode.alpha = 0
        overlay.addChild(newNode)
        newNode.position.x = CGFloat(middleXPosition)
        newNode.position.y = CGFloat(middleYPosition)
        return newNode
    }
    
    func setupOceanBackgrounds() {
        
        //total ocean size
        var oceanSize = CGSize(width: 900.5 , height: 2352)
        
        var imageHeightInPoints : CGFloat = 784
        
        //add top images
        var topOffset = CGFloat(oceanSize.height - imageHeightInPoints)
        var topImageOrigin = CGPoint(x: 0, y: topOffset)
        
        var top = SKSpriteNode(imageNamed: "oceantop_01.jpg")
        top.anchorPoint = CGPointZero
        top.position = topImageOrigin
        self.ocean.addChild(top)
        
        var top2 = SKSpriteNode(imageNamed: "oceantop_01.jpg")
        top2.anchorPoint = CGPointZero
        top2.position = CGPoint(x: 900, y: topOffset)
        self.ocean.addChild(top2)
        
        top.name = "ocean"
        top2.name = "ocean"
        
        //add middle images
        var middleOffset = CGFloat(oceanSize.height - (imageHeightInPoints * 2))
        var middleImageOrigin = CGPoint(x: 0, y: middleOffset)
        
        var middle = SKSpriteNode(imageNamed: "oceanmiddle_01.jpg")
        middle.anchorPoint = CGPointZero
        middle.position = middleImageOrigin
        self.ocean.addChild(middle)
        
        var middle2 = SKSpriteNode(imageNamed: "oceanmiddle_01.jpg")
        middle2.anchorPoint = CGPointZero
        middle2.position = CGPoint(x: 900, y: middleOffset)
        self.ocean.addChild(middle2)
        
        middle.name = "ocean"
        middle2.name = "ocean"
        
        
        //add bottom images
        var bottomOffset = CGFloat(0)
        var bottomImageOrigin = CGPoint(x: 0, y: bottomOffset)
        
        var bottom = SKSpriteNode(imageNamed: "oceanbottom_01.jpg")
        bottom.anchorPoint = CGPointZero
        bottom.position = bottomImageOrigin
        self.ocean.addChild(bottom)
        
        var bottom2 = SKSpriteNode(imageNamed: "oceanbottom_01.jpg")
        bottom2.anchorPoint = CGPointZero
        bottom2.position = CGPoint(x: 900, y: bottomOffset)
        self.ocean.addChild(bottom2)
        
        bottom.name = "ocean"
        bottom2.name = "ocean"
        
    }
    
    func setupSpawnControllers() {
        
        var area1 = CGRect(x: self.view!.frame.width + 20, y: 1334, width: 200, height: 666)
        var spawnController1 = SpawnController(spawnArea: area1, depthLevel: 1, frequency: 0.5, theOcean: self.ocean)
        self.spawnControllers.append(spawnController1)
        
        var area2 = CGRect(x: self.view!.frame.width + 20, y: 668, width: 200, height: 666)
        var spawnController2 = SpawnController(spawnArea: area2, depthLevel: 2, frequency: 1.0, theOcean: self.ocean)
        self.spawnControllers.append(spawnController2)
        
        var area3 = CGRect(x: self.view!.frame.width + 20, y: 0, width: 200, height: 666)
        var spawnController3 = SpawnController(spawnArea: area3, depthLevel: 3, frequency: 2.0, theOcean: self.ocean)
        self.spawnControllers.append(spawnController3)
    }
    
    func setupWhale() {
        self.whale.position = CGPoint(x: 35, y: self.middleYPosition)
        self.whale.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: whale.size.width - 30, height: whale.size.height - 30))
        self.whale.physicsBody?.affectedByGravity = false
        self.whale.name = "whale"
        //        self.whale.physicsBody?.contactTestBitMask = 1
        self.whale.physicsBody?.categoryBitMask = UInt32(whaleCategory)
        self.whale.physicsBody?.contactTestBitMask = UInt32(krillCategory)
        self.whale.physicsBody?.collisionBitMask = 0
        self.addChild(self.whale)
    }
    
    
    func setupWaves() {
        
        for var i = 0; i < 2; i++ {
            
            var newI = CGFloat(i)
            
            var wave3BG = SKSpriteNode(imageNamed: "wave_03.png")
            wave3BG.anchorPoint = CGPointZero
            wave3BG.position = CGPointMake(newI * wave3BG.size.width, 2180)
            wave3BG.name = "wave3"
            self.ocean.addChild(wave3BG)
            
            var wave2BG = SKSpriteNode(imageNamed: "wave_02.png")
            wave2BG.anchorPoint = CGPointZero
            wave2BG.position = CGPointMake(-newI * wave2BG.size.width, 2180)
            wave2BG.name = "wave2"
            self.ocean.addChild(wave2BG)

            var wave1BG = SKSpriteNode(imageNamed: "wave_01.png")
            wave1BG.anchorPoint = CGPointZero
            wave1BG.position = CGPointMake(newI * wave1BG.size.width, 2180)
            wave1BG.name = "wave1"
            self.ocean.addChild(wave1BG)
//            self.addChild(wave1BG)
        }
    }
    
    func setupWaveAlphaFade() {
        
        for var i = 0; i < 2; i++ {
            
            var newI = CGFloat(i)
            
            var wave1bBG = SKSpriteNode(imageNamed: "wave_01b.png")
            wave1bBG.zPosition = 100
            wave1bBG.anchorPoint = CGPointZero
            wave1bBG.position = CGPointMake(newI * wave1bBG.size.width, 2170)
            wave1bBG.name = "wave0"
            self.ocean.addChild(wave1bBG)
        }
    }
    
    func setupClouds() {
        
        for var i = 0; i < 1; i++ {
            
            var newI = CGFloat(i)
            
            var cloud1BG = SKSpriteNode(imageNamed: "cloud_01.png")
            cloud1BG.anchorPoint = CGPointZero
            cloud1BG.position = CGPointMake(newI * cloud1BG.size.width - 100, 2250) //3rd
            cloud1BG.name = "cloud1"
            self.ocean.addChild(cloud1BG)

            var cloud2BG = SKSpriteNode(imageNamed: "cloud_02.png")
            cloud2BG.anchorPoint = CGPointZero
            cloud2BG.position = CGPointMake(newI * cloud2BG.size.width - 60, 2280) //1st
            cloud2BG.name = "cloud2"
            self.ocean.addChild(cloud2BG)
 
            var cloud3BG = SKSpriteNode(imageNamed: "cloud_03.png")
            cloud3BG.anchorPoint = CGPointZero
            cloud3BG.position = CGPointMake(newI * cloud3BG.size.width - 60, 2240) //2nd
            cloud3BG.name = "cloud3"
            self.ocean.addChild(cloud3BG)
            
            var cloud4BG = SKSpriteNode(imageNamed: "cloud_04.png")
            cloud4BG.anchorPoint = CGPointZero
            cloud4BG.position = CGPointMake(newI * cloud4BG.size.width - 60, 2265)
            cloud4BG.name = "cloud4"
            self.ocean.addChild(cloud4BG)
        }
    }
    
    
    func setupMotionDetection() {
        
        self.mManager.accelerometerUpdateInterval = 0.05
        self.mManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { (accelerometerData : CMAccelerometerData!, error) in
            
            //keeping track of the devices orientation in relation to our gameplay. we will use this property in our update loop to figure out which way the wale should be pointing
            
            self.currentYDirection = accelerometerData.acceleration.y // CHECK: screen rotation changes whale rotation
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
        }
        for eachTouch in touches {
            var timer1 = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("pausePressed"), userInfo: nil, repeats: false)
        }
    }
    
    func pausePressed() {
        if self.view?.paused == true {
            //un-pause, hide "Paused" text
            self.view?.paused = false
            pausedLabel.alpha = 0
        }
        else if self.view?.paused == false {
            //pause, display "Paused" text
            self.view?.paused = true
            pausedLabel.alpha = 1
        }
    }
    func pauseAfterDelay() {
        var timer1 = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("pauseGame"), userInfo: nil, repeats: false)
        timer1.fire()
    }
    func pauseGame() {
        self.view?.paused = true
    }
    
    override func update(currentTime: CFTimeInterval) {
        self.currentTime = currentTime
        var timeSinceEating = self.currentTime - self.timeOfLastMeal
        if timeSinceEating < 0.5 && self.timeOfLastMeal != 0 {
            self.whale.texture = SKTexture(imageNamed: "orca_02")
        }
        else {
            self.whale.texture = SKTexture(imageNamed: "orca_01")
        }
        var timeSinceMagnet = self.currentTime - self.magnetBegin
        if self.magnetBegin != 0 && timeSinceMagnet <= 10.0 {
            self.attractFood()
            self.whale.texture = SKTexture(imageNamed: "orcaMermaid")
        }
        var timeSinceDive = self.currentTime - self.diverBegin
        if self.diverBegin != 0 && timeSinceDive <= 10.0 {
            self.oxygen = 100
            self.whale.texture = SKTexture(imageNamed: "orcaDiver")
            if self.magnetBegin != 0 && timeSinceMagnet <= 10.0 {
                self.whale.texture = SKTexture(imageNamed: "orcaDiverMermaid")
            }
        }
        //SET SCORE
        self.scoreLabel.text = "\(self.currentScore)"
        
        //Spawn Controllers
        
        for spawner in self.spawnControllers {
            spawner.update(currentTime)
        }
        
        //Calculate angle of whale to properly move ocean
        
        if self.currentDepth >= 0.0 {
            
        }
        var newValue = self.translate(self.currentYDirection)
        var newRadian : CGFloat = CGFloat(M_PI * newValue / 180.0)
        self.whale.zRotation = newRadian
        var testValue = -35.0
        self.updateDepth(newValue)

        
        
        //grab delta time
        self.deltaTime = currentTime - self.previousTime
        self.previousTime = currentTime
        self.timeSinceLastSmallBubble += self.deltaTime
        
        //see if enough time has passed to spawn food
        if self.timeSinceLastSmallBubble > self.nextSmallBubbleTime {
            self.spawnBubble()
            self.timeSinceLastSmallBubble = 0
        }
        
        self.depthLabel.text = "\(2000 - self.currentDepth)"
        
        
        // Artwork
        // eumerate through wave1
        self.ocean.enumerateChildNodesWithName("wave1", usingBlock: { (node, stop) -> Void in
            if let wave1BG = node as? SKSpriteNode {
                wave1BG.position = CGPointMake(wave1BG.position.x - 0.2, wave1BG.position.y) // sidescroll speed
                if wave1BG.position.x <= wave1BG.size.width * -1 {
                    wave1BG.position = CGPointMake(wave1BG.position.x + wave1BG.size.width * 2, wave1BG.position.y)
                }
            }
        })
        
        // eumerate through wave1b - front fade (needs to match wave1)
        self.ocean.enumerateChildNodesWithName("wave0", usingBlock: { (node, stop) -> Void in
            if let wave1bBG = node as? SKSpriteNode {
                wave1bBG.position = CGPointMake(wave1bBG.position.x - 0.2, wave1bBG.position.y) // sidescroll speed
                if wave1bBG.position.x <= wave1bBG.size.width * -1 {
                    wave1bBG.position = CGPointMake(wave1bBG.position.x + wave1bBG.size.width * 2, wave1bBG.position.y)
                }
            }
        })
        
        // eumerate through wave2
        self.ocean.enumerateChildNodesWithName("wave2", usingBlock: { (node, stop) -> Void in
            if let wave2BG = node as? SKSpriteNode {
                wave2BG.position = CGPointMake(wave2BG.position.x + 0.4, wave2BG.position.y) // sidescroll speed
                if wave2BG.position.x >= wave2BG.size.width * 1 {
                    wave2BG.position = CGPointMake(wave2BG.position.x - wave2BG.size.width * 2, wave2BG.position.y)
                }
            }
        })
        
        // eumerate through wave3
        self.ocean.enumerateChildNodesWithName("wave3", usingBlock: { (node, stop) -> Void in
            if let wave3BG = node as? SKSpriteNode {
                wave3BG.position = CGPointMake(wave3BG.position.x - 0.7, wave3BG.position.y) // sidescroll speed
                if wave3BG.position.x <= wave3BG.size.width * -1 {
                    wave3BG.position = CGPointMake(wave3BG.position.x + wave3BG.size.width * 2, wave3BG.position.y)
                }
            }
        })
        
        self.ocean.enumerateChildNodesWithName("cloud1", usingBlock: { (node, stop) -> Void in
            if let cloud1BG = node as? SKSpriteNode {
                cloud1BG.position = CGPointMake(cloud1BG.position.x - 0.13, cloud1BG.position.y) // sidescroll speed
                if cloud1BG.position.x <= cloud1BG.size.width * -1 {
                    cloud1BG.position = CGPointMake(cloud1BG.position.x + 1000, cloud1BG.position.y)
                }
            }
        })
        
        self.ocean.enumerateChildNodesWithName("cloud2", usingBlock: { (node, stop) -> Void in
            if let cloud2BG = node as? SKSpriteNode {
                cloud2BG.position = CGPointMake(cloud2BG.position.x - 0.10, cloud2BG.position.y) // sidescroll speed
                if cloud2BG.position.x <= cloud2BG.size.width * -1 {
                    cloud2BG.position = CGPointMake(cloud2BG.position.x + 650, cloud2BG.position.y)
                }
            }
        })
        
        self.ocean.enumerateChildNodesWithName("cloud3", usingBlock: { (node, stop) -> Void in
            if let cloud3BG = node as? SKSpriteNode {
                cloud3BG.position = CGPointMake(cloud3BG.position.x - 0.18, cloud3BG.position.y) // sidescroll speed
                if cloud3BG.position.x <= cloud3BG.size.width * -1 {
                    cloud3BG.position = CGPointMake(cloud3BG.position.x + 830, cloud3BG.position.y)
                }
            }
        })
        
        self.ocean.enumerateChildNodesWithName("cloud4", usingBlock: { (node, stop) -> Void in
            if let cloud4BG = node as? SKSpriteNode {
                cloud4BG.position = CGPointMake(cloud4BG.position.x - 0.08, cloud4BG.position.y) // sidescroll speed
                if cloud4BG.position.x <= cloud4BG.size.width * -1 {
                    cloud4BG.position = CGPointMake(cloud4BG.position.x + 910, cloud4BG.position.y)
                }
            }
        })
        
        // ocean
        self.ocean.enumerateChildNodesWithName("ocean", usingBlock: { (node, stop) -> Void in
            if let oceanBG = node as? SKSpriteNode {
                oceanBG.position = CGPointMake(oceanBG.position.x - 1, oceanBG.position.y) // sidescroll speed
                if oceanBG.position.x <= oceanBG.size.width * -1 {
                    oceanBG.position = CGPointMake(oceanBG.position.x + oceanBG.size.width * 2, oceanBG.position.y)
                }
            }
        })
        
        updateHealthBar()
    }
    
    //method used to take a our current motion value and translate it to degrees between -45 and 45
    func translate(value : Double) -> Double {
        
        var leftSpan = -0.7 - (0.7)
        var rightSpan = 45.0 - (-45.0)
        
        //convert left range into a 0-1 range
        var valueScale = (value - 0.7) / leftSpan
        
        return -45 + (valueScale * rightSpan)
    }
    
    func updateDepth (angle : Double) {
        // angle = ~ current angle, value between -30 and 30
        if ( angle < 0 ) {
            if currentDepth <= 2000 {
                currentDepth -= (angle / 10)
            }
        } else if (angle >= 0 ) {
            if currentDepth > 1 {
                currentDepth -= (angle / 10)
            }
        }
//        self.ocean.position = CGPoint(x: 0, y: -oceanDepth + middleXPosition + 50 + Int(self.currentDepth))
        self.ocean.position = CGPoint(x: 0, y: self.currentDepth - 2030)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var bodies = [contact.bodyA,contact.bodyB]
        for eachBody in bodies {
            
            if let foodNode = eachBody.node as? FoodNode {
                var foodName = foodNode.imageName
                if foodName == "krill" {
                    self.currentScore += 0
                }
                else if foodName == "fishsmall_01" || foodName == "fishsmall_02" || foodName == "fishsmall_03" {
//                    eachBody.node?.removeFromParent()
                    self.currentScore += 1
                }
                else if foodName == "fishmed_01" || foodName == "fishmed_02" || foodName == "fishmed_03" {
//                    eachBody.node?.removeFromParent()
                    self.currentScore += 5
                }
                else if foodName == "fishlarge_01" || foodName == "fishlarge_02" || foodName == "fishlarge_03" {
//                    eachBody.node? .removeFromParent()
                    self.currentScore += 10
                }
                self.timeOfLastMeal = self.currentTime
                eachBody.node?.removeFromParent()
                self.soundPlayManager.playEatSound(contact.bodyA.node!)
            } else if eachBody.node?.name == "enemy" {
                self.oxygen = self.oxygen - 10
            }
            else if let powerupNode = eachBody.node as? PowerupNode {
                var powerupName = powerupNode.imageName
                if powerupName == "bubble_01" || powerupName == "bubble_02" || powerupName == "bubble_03" {
                    self.oxygen += 20
                }
                else if powerupName == "scuba2" {
                    self.oxygen = 100
                    self.diverBegin = self.currentTime
                }
                else if powerupName == "mermaid" {
                    self.magnetBegin = self.currentTime
                }
                eachBody.node?.removeFromParent()
            }
            else if eachBody.node?.name == nil {
                eachBody.node?.removeFromParent()
            }
            
        }
    }
    
    func attractFood() {
        //should only work for food within decent range:
        self.ocean.enumerateChildNodesWithName("krill", usingBlock: { (node, stop) -> Void in
            if let foodNode = node as? FoodNode {
                
                var whaleMiddle = self.whale.frame.height / 2.0
                var magnetY : CGFloat = 0.0
                if let theScene = self.scene?.frame.height {
                    magnetY = 2000.0 - CGFloat(self.currentDepth) + CGFloat(theScene) / 2.0 + whaleMiddle
                }
                var whalePoint = CGPoint(x: CGFloat(self.whale.frame.width / 4),y: magnetY - self.whale.frame.height / 2)
                //find out food's location:
                var foodX = foodNode.position.x
                var foodY = foodNode.position.y
                var deltaX = foodX - whalePoint.x
                var deltaY = foodY - whalePoint.y
                var distSquared = deltaX * deltaX + deltaY * deltaY
                var magnet = SKAction.moveTo(whalePoint, duration: 0.20)
                if sqrt(distSquared) <= 400.0 {
                foodNode.removeActionForKey("mover")
                var removeAction = SKAction.runBlock { () -> Void in
                        //                    foodNode.runAction(magnet)
                    dispatch_after(1, dispatch_get_main_queue(), {
                        var foodName = foodNode.imageName
                        if foodName == "krill" {
                            self.currentScore += 0
                        }
                        else if foodName == "fishsmall_01" || foodName == "fishsmall_02" || foodName == "fishsmall_03" {
                            //                    eachBody.node?.removeFromParent()
                            self.currentScore += 1
                        }
                        else if foodName == "fishmed_01" || foodName == "fishmed_02" || foodName == "fishmed_03" {
                            //                    eachBody.node?.removeFromParent()
                            self.currentScore += 5
                        }
                        else if foodName == "fishlarge_01" || foodName == "fishlarge_02" || foodName == "fishlarge_03" {
                            //                    eachBody.node? .removeFromParent()
                            self.currentScore += 10
                        }
                        self.timeOfLastMeal = self.currentTime
                        foodNode.removeFromParent()
                        self.soundPlayManager.playEatSound(self.whale)
                        foodNode.attracted = true
                        foodNode.removeFromParent()
                    })
                    
                }
                            //ensures krill removed from taking up memory:
                            var actions = SKAction.sequence([magnet,removeAction])
                    foodNode.runAction(actions)
                }
            }
        })
    }
    
    func updateHealthBar() {
        oxygen -= 0.1
        
        if currentDepth < 1 {
            if oxygen < 95 {
                oxygen += 5
            } else if oxygen < 100 {
                oxygen = 100
            }
        }
        
        if oxygen > 0 {
            healthBar.size.width = CGFloat((Double(healthBarWidth) / 100.0)) * CGFloat(oxygen)
            if oxygen > 99 {
                healthBar.color = barColorSpectrum[99]
            } else {
                healthBar.color = barColorSpectrum[Int(oxygen)]
            }
        } else {
            healthBar.size.width = 0
        }
        
        switch oxygen {
        case 0:
            breatheLabel.alpha = 0
            gameOver()
        case 0..<50:
            breatheLabel.alpha = 1
            overlay.fillColor = overlayColorSpectrum[Int(oxygen)]
        default:
            overlay.fillColor = clearColor
            breatheLabel.alpha = 0
        }
    }
    
    func startBackgroundMusic() {
        
        var error : NSError?
        var backgroundMusic = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("whalesong", ofType: "caf")!)
        self.backgroundAudioPlayer = AVAudioPlayer(contentsOfURL: backgroundMusic, error: &error)
        
        if (error != nil) {
        }
        self.backgroundAudioPlayer.prepareToPlay()
        self.backgroundAudioPlayer.numberOfLoops = -1 // infinite
        self.backgroundAudioPlayer.play()
    }
    
    func gameOver() {
        gameOverLabel.alpha = 1
    }
    
    func spawnBubble() -> Void {
        
        var bubble = SKSpriteNode(imageNamed: "bubble_01")
        bubble.size = CGSize(width: bubble.size.width / 3, height: bubble.size.height / 3)
        
        var distanceFromGround = 2000 - self.currentDepth
        
        if self.currentDepth < 2000 {
            
            
            var highestBound = CGFloat(distanceFromGround) + (self.view!.frame.height)
            var lowestBound = CGFloat(distanceFromGround)
            
            var yCoord = CGFloat(arc4random() % UInt32(self.view!.frame.height) + UInt32(distanceFromGround))
            
            bubble.position = CGPoint(x: self.view!.frame.width + 30, y: yCoord)
            
            var mover = SKAction.moveToX(-30, duration: 0.7)
            var remove = SKAction.runBlock({ () -> Void in
                bubble.removeFromParent()
            })
            self.ocean.addChild(bubble)
            var sequence = SKAction.sequence([mover,remove])
            bubble.runAction(sequence)
            
        }
    }

    
}
