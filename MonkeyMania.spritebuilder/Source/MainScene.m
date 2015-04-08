#import "MainScene.h"

@implementation MainScene {
    Monkey *_monkey;
    NSMutableArray *_ropes;
    NSMutableArray *_topRopeJoints;
    //CCNode *contentNode;
    CCPhysicsJoint *_ropeMonkeyJoint;
    //CCPhysicsJoint *_monkeyRopeJointRotary;
    //CCNode *_contentNode;
    CCAction *_followMonkey;
    BOOL _gameOver;
    CCButton *_restartButton;
    CCAnimationManager* animationManager;
}

- (void)didLoadFromCCB 
{
    // your code here
    self.userInteractionEnabled = TRUE;
    _restartButton.visible = FALSE;
    _ropes = [NSMutableArray array];
    _topRopeJoints = [NSMutableArray array];
    
    //Setup initial ropes
    for (int i = 0; i<6; i++) {
        [self addRopeWithSize:1 atPosX:(i+1)*(150+arc4random_uniform(50))];
    }
    
    
    Rope *firstRope = [_ropes objectAtIndex:0];
    firstRope.physicsBody.collisionMask = @[];
    firstRope.rotation = 75.0f;
    
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.position = [physicsNode convertToNodeSpace:[firstRope convertToWorldSpace:ccp(5,-151)]];
    [physicsNode addChild:_monkey];
    
    _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:firstRope.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(10,-150)];
    
    
    physicsNode.collisionDelegate = self;
    // visualize physics bodies & joints
    physicsNode.debugDraw = TRUE;
    
}

-(void) addRopeWithSize:(int)size atPosX:(float)x
{
    
    for (int i = 0; i < size; i++) {
        Rope *_rope = (Rope*)[CCBReader load:@"Rope"];
        _rope.rotation = 45+arc4random_uniform(30);
        _rope.position = [top convertToWorldSpace:ccp(x, 1)];
        [physicsNode addChild:_rope];
        [_ropes addObject:_rope];
        if (i==0) {
            CCPhysicsJoint *_topRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody anchorA:ccp(x,1)];
            [_topRopeJoints addObject:_topRopeJoint];
        }
        
        
    }
    
}

// called on every touch in this scene
-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    //CGPoint touchLocation = [touch locationInNode:_contentNode];
}

-(void) touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    
    _monkey.physicsBody.allowsRotation = TRUE;
    
    [_ropeMonkeyJoint invalidate];
    _ropeMonkeyJoint = nil;
    
    animationManager = _monkey.animationManager;
    [animationManager runAnimationsForSequenceNamed:@"JumpRight"];
    
    _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
    [contentNode runAction:_followMonkey];
}

- (void)gameOver {
    if (!_gameOver) {
        _gameOver = TRUE;
        _restartButton.visible = TRUE;
        
        _monkey.physicsBody.velocity = ccp(0.0f, _monkey.physicsBody.velocity.y);
        _monkey.rotation = 270.f;
        _monkey.physicsBody.allowsRotation = FALSE;
        [_monkey stopAllActions];
        [animationManager setPaused:YES];
        
        CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
        CCActionInterval *reverseMovement = [moveBy reverse];
        CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
        CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequence];
        
        [self runAction:bounce];
    }
}

- (void)restart {
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
}

-(BOOL)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey rope:(CCNode *)rope {
    _monkey.physicsBody.allowsRotation = FALSE;
    rope.physicsBody.collisionMask = @[];
    if (_ropeMonkeyJoint != nil) {
        [_ropeMonkeyJoint invalidate];
        _ropeMonkeyJoint = nil;
    }
    monkey.position = [physicsNode convertToNodeSpace:[rope convertToWorldSpace:ccp(5,-151)]];
    _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:rope.physicsBody bodyB:monkey.physicsBody anchorA:ccp(10,-150)];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey ground:(CCNode *)ground {
    [self gameOver];
    return TRUE;
}


@end
