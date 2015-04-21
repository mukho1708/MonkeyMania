#import "MainScene.h"

@implementation MainScene {
    NSArray *_grounds;
    NSArray *_tops;
    Monkey *_monkey;
    NSMutableArray *_ropes;
    Rope *_currentRope;
    NSMutableArray *_topRopeJoints;
    CCPhysicsJoint *_ropeMonkeyJoint;
    CCAction *_followMonkey;
    BOOL _gameOver;
    CCButton *_restartButton;
    CCAnimationManager* animationManager;
    int _counter;
    BOOL _allowImpulse;
    float maxX;
    float _beforeCollisionX;
}

- (void)didLoadFromCCB 
{
    // your code here
    self.userInteractionEnabled = TRUE;
    _restartButton.visible = FALSE;
    _grounds = @[ground1, ground2];
    _tops = @[top1, top2];
    _ropes = [NSMutableArray array];
    _topRopeJoints = [NSMutableArray array];
    _counter = 0;
    
    //Setup initial ropes
    for (int i = 0; i<4; i++) {
        _counter++;
        if (i == 0 || i== 3) {
            [self addRopeWithSize:1 atPosX:(i+1)*140 atTop:top1];
        }
        else
        {
            //_scene = 2;
            //[self addRopeWithSize:1 atPosX:(i+1)*100+arc4random_uniform(20) atTop:top2];
        }
        
    }
    
    
    _currentRope = [_ropes objectAtIndex:0];
    _currentRope.physicsBody.collisionMask = @[];
    
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.name = @"monkey";
    _monkey.position = [physicsNode convertToNodeSpace:[_currentRope convertToWorldSpace:ccp(_currentRope.contentSize.width*0.5,_currentRope.contentSize.height*0.85)]];
    _monkey.physicsBody.allowsRotation = FALSE;
    maxX = _monkey.position.x;
    _beforeCollisionX = [physicsNode convertToWorldSpace:_monkey.position].x;
    [physicsNode addChild:_monkey];
    
    
    _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRope.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(_currentRope.contentSize.width,_currentRope.contentSize.height*0.85)];
    _allowImpulse = TRUE;
    
    physicsNode.collisionDelegate = self;
    // visualize physics bodies & joints
    //physicsNode.debugDraw = TRUE;
    
}

-(void) addRopeWithSize:(int)size atPosX:(float)x atTop:(CCNode *)top
{
    
    for (int i = 0; i < size; i++) {
        Rope *_rope = (Rope*)[CCBReader load:@"Rope"];
        _rope.name = [NSString stringWithFormat:@"rope%d", _counter];
        //_rope.rotation = 45+arc4random_uniform(30);
        _rope.physicsBody.allowsRotation = FALSE;
        _rope.physicsBody.affectedByGravity = TRUE;
        //if (x <= 568) {
        _rope.position = ccp(x,320);//[top convertToWorldSpace:[top convertToWorldSpace:[top convertToNodeSpace:ccp(x, 1)]]];
        
        [physicsNode addChild:_rope];
        [_ropes addObject:_rope];
        if (i==0) {
            CCPhysicsJoint *topRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody anchorA:[top convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(x,320)]]];//ccp(x,1)];
            
            [_topRopeJoints addObject:topRopeJoint];
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
    
    if (_allowImpulse) {
        [_monkey.physicsBody applyImpulse:ccp(170, 50)];
        _allowImpulse = FALSE;
    }
    animationManager = _monkey.animationManager;
    [animationManager runAnimationsForSequenceNamed:@"JumpRight"];
    
    _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
    [contentNode runAction:_followMonkey];
}

- (void)update:(CCTime)delta
{
    if(_monkey.position.x>maxX && _ropeMonkeyJoint == nil)
    {
        maxX = _monkey.position.x;

        physicsNode.position = ccp(physicsNode.position.x - (_monkey.physicsBody.velocity.x * delta), physicsNode.position.y);
        
        // loop the ground
        for (CCNode *ground in _grounds) {
            // get the world position of the ground
            CGPoint groundWorldPosition = [physicsNode convertToWorldSpace:ground.position];
            // get the screen position of the ground
            CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
            
            // if the left corner is one complete width off the screen, move it to the right
            if (groundScreenPosition.x <= (-1 * ground.contentSize.width)) {
                ground.position = ccp(ground.position.x + 2 * ground.contentSize.width, ground.position.y);
            }
        }
        
        // loop the top
        for (CCNode *top in _tops) {
            // get the world position of the top
            CGPoint topWorldPosition = [physicsNode convertToWorldSpace:top.position];
            // get the screen position of the top
            CGPoint topScreenPosition = [self convertToNodeSpace:topWorldPosition];
            
            // if the left corner is one complete width off the screen, move it to the right
            if (topScreenPosition.x <= (-1 * top.contentSize.width)) {
                top.position = ccp(top.position.x + 2 * top.contentSize.width, top.position.y);
                _counter++;
                [self addRopeWithSize:1 atPosX:top.position.x+100+arc4random_uniform(20) atTop:top];
                _counter++;
                [self addRopeWithSize:1 atPosX:top.position.x+500+arc4random_uniform(20) atTop:top];
            }
        }
        
        NSMutableArray *offScreenRopes = nil;
        
        for (CCNode *rope in _ropes) {
            CGPoint ropeWorldPosition = [physicsNode convertToWorldSpace:rope.position];
            CGPoint ropeScreenPosition = [self convertToNodeSpace:ropeWorldPosition];
            if (ropeScreenPosition.x < (rope.contentSizeInPoints.width/2)) {
                if (!offScreenRopes) {
                    offScreenRopes = [NSMutableArray array];
                }
                [offScreenRopes addObject:rope];
            }
        }
        
        for (CCNode *ropeToRemove in offScreenRopes) {
            CCPhysicsJoint *jointToRemove = ropeToRemove.physicsBody.joints.firstObject;
            [_topRopeJoints removeObject:jointToRemove];
            [jointToRemove invalidate];
            jointToRemove = nil;
            [ropeToRemove removeFromParent];
            [_ropes removeObject:ropeToRemove];
        }
    }
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
    if (![rope.physicsBody.collisionMask  isEqual: @[]]) {
        rope.physicsBody.collisionMask = @[];
        _currentRope = (Rope *)rope;
        monkey.physicsBody.allowsRotation = FALSE;
        
        [animationManager runAnimationsForSequenceNamed:@"Default"];
    
        if (_ropeMonkeyJoint != nil) {
            [_ropeMonkeyJoint invalidate];
            _ropeMonkeyJoint = nil;
        }
        
        monkey.position = ccp(_currentRope.position.x, monkey.position.y);
        _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRope.physicsBody bodyB:monkey.physicsBody anchorA:ccp(5,[_currentRope convertToNodeSpace:monkey.position].y)];
        
        physicsNode.position = ccp(physicsNode.position.x - ([physicsNode convertToWorldSpace:_monkey.position].x - _beforeCollisionX), physicsNode.position.y);
        
        _monkey.rotation = 0.f;
        
        _allowImpulse = TRUE;
    }
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey ground:(CCNode *)ground {
    [self gameOver];
    return TRUE;
}


@end
