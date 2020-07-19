/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit

struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let monster   : UInt32 = 0b1       // 1
  static let projectile: UInt32 = 0b10      // 2
}

class GameScene: SKScene {
  let player = SKSpriteNode(imageNamed: "player")

  override func didMove(to view: SKView) {
    backgroundColor = SKColor.white
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    addChild(player)

    run(SKAction.repeatForever(SKAction.sequence([
      SKAction.run(addMonster),
      SKAction.wait(forDuration: 1.0)
    ])))

    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
  }

  private func addMonster() {
    let monster = SKSpriteNode(imageNamed: "monster")
    let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)

    monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
    addChild(monster)

    let actualDuration = random(min: 2, max: 4)
    let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()

    monster.run(SKAction.sequence([actionMove, actionMoveDone]))

    let body = SKPhysicsBody(rectangleOf: monster.size)
    body.isDynamic = true
    body.categoryBitMask = PhysicsCategory.monster
    body.contactTestBitMask = PhysicsCategory.projectile
    body.collisionBitMask = PhysicsCategory.none
    monster.physicsBody = body

  }

  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return (CGFloat(arc4random()) / CGFloat(UINT32_MAX) * (max - min)) + min
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }

    let touchLocation = touch.location(in: self)
    let projectile = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position

    let offset = touchLocation - player.position

    guard offset.x > 0 else { return }

    addChild(projectile)

    let direction = offset.normalized()
    let shotAmount = direction * size.width * 2
    let destination = projectile.position + shotAmount

    let actionMove = SKAction.move(to: destination, duration: 2)
    let actionMoveDone = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([actionMove, actionMoveDone]))

    let body = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    body.isDynamic = true
    body.categoryBitMask = PhysicsCategory.projectile
    body.contactTestBitMask = PhysicsCategory.monster
    body.collisionBitMask = PhysicsCategory.none
    body.usesPreciseCollisionDetection = true

    projectile.physicsBody = body
  }
}


extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    var monsterBody: SKPhysicsBody
    var projectileBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask  {
      monsterBody = contact.bodyA
      projectileBody = contact.bodyB
    } else {
      monsterBody = contact.bodyB
      projectileBody = contact.bodyA
    }

    guard monsterBody.categoryBitMask & PhysicsCategory.monster != 0 &&
      projectileBody.categoryBitMask & PhysicsCategory.projectile != 0 else { return }
    guard let monster = monsterBody.node as? SKSpriteNode, let projectile = projectileBody.node as? SKSpriteNode else {
      return
    }

    projectTileDidCollideWithMonster(projectile: projectile, monster: monster)
  }

  func projectTileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    print("Hit")
    monster.removeFromParent()
    projectile.removeFromParent()
  }
}


// MARK: - CGPoint helper
func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }

  func normalized() -> CGPoint {
    return self / length()
  }
}
