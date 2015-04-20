#import "MainScene.h"

@implementation MainScene {
    NSArray *_grounds;
    NSArray *_tops;
    Monkey *_monkey;
    NSMutableArray *_ropes;
    Rope *_firstRope;
    NSMutableArray *_topRopeJoints;
    //CCNode *contentNode;
    CCPhysicsJoint *_ropeMonkeyJoint;
    //CCPhysicsJoint *_monkeyRopeJointRotary;
    //CCNode *_contentNode;
    CCAction *_followMonkey;
    BOOL _gameOver;
    CCButton *_restartButton;
    CCAnimationManager* animationManager;
    int _counter;
    BOOL _allowImpulse;
    float maxX;
    BOOL _afterCollision;
    float _onCollisionX;
    BOOL _frameAfterCollision;
    int _scene;
}

- (void)didLoadFromCCB 
{
    // your code here
    self.userInteractionEnabled = TRUE;
    _restartButton.visible = FALSE;
    _afterCollision = FALSE;
    _grounds = @[ground1, ground2];
    _tops = @[top1, top2];
    _ropes = [NSMutableArray array];
    _topRopeJoints = [NSMutableArray array];
    _counter = 0;
    _scene = 1;
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
    
    
    _firstRope = [_ropes objectAtIndex:0];
    //_firstRope.physicsBody.allowsRotation = TRUE;
    _firstRope.physicsBody.collisionMask = @[];
    //_firstRope.rotation = 75.0f;
    
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.name = @"monkey";
    _monkey.position = [physicsNode convertToNodeSpace:[_firstRope convertToWorldSpace:ccp(5,-201)]];
    maxX = _monkey.position.x;
//    _beforeCollision = _monkey.position.x;
    [physicsNode addChild:_monkey];
    
    _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_firstRope.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(10,-200)];
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
        [_monkey.physicsBody applyImpulse:ccp(150, 50)];
        _allowImpulse = FALSE;
    }
    animationManager = _monkey.animationManager;
    [animationManager runAnimationsForSequenceNamed:@"JumpRight"];
    
    _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
    [contentNode runAction:_followMonkey];
}

- (void)update:(CCTime)delta
{
//    _sinceTouch += delta;
//    
//    character.rotation = clampf(character.rotation, -30.f, 90.f);
//    
//    if (character.physicsBody.allowsRotation) {
//        float angularVelocity = clampf(character.physicsBody.angularVelocity, -2.f, 1.f);
//        character.physicsBody.angularVelocity = angularVelocity;
//    }
//    
//    if ((_sinceTouch > 0.5f)) {
//        [character.physicsBody applyAngularImpulse:-40000.f*delta];
//    }
    if(_monkey.position.x>maxX && (_ropeMonkeyJoint == nil || _ropeMonkeyJoint.bodyA != _firstRope.physicsBody))
    {
        maxX = _monkey.position.x;

        if (_afterCollision) {
            _frameAfterCollision = TRUE;
        }
        if (_frameAfterCollision) {
            _frameAfterCollision = FALSE;
            physicsNode.position = ccp(physicsNode.position.x - (_monkey.position.x - _onCollisionX), physicsNode.position.y);
        }
        else
        {
            physicsNode.position = ccp(physicsNode.position.x - (_monkey.physicsBody.velocity.x * delta), physicsNode.position.y);
        }
        
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
                _scene = 3;
                _counter++;
                [self addRopeWithSize:1 atPosX:top.position.x+100+arc4random_uniform(20) atTop:top];
                _counter++;
                [self addRopeWithSize:1 atPosX:top.position.x+500+arc4random_uniform(20) atTop:top];
            }
        }
        
//        _parallaxBackground.position = ccp(_parallaxBackground.position.x - (character.physicsBody.velocity.x * delta), _parallaxBackground.position.y);
//        
//        // loop the bushes
//        for (CCNode *bush in _bushes) {
//            // get the world position of the bush
//            CGPoint bushWorldPosition = [_parallaxBackground convertToWorldSpace:bush.position];
//            // get the screen position of the bush
//            CGPoint bushScreenPosition = [self convertToNodeSpace:bushWorldPosition];
//            
//            // if the left corner is one complete width off the screen,
//            // move it to the right
//            if (bushScreenPosition.x <= (-1 * bush.contentSize.width)) {
//                for (CGPointObject *child in _parallaxBackground.parallaxArray) {
//                    if (child.child == bush) {
//                        child.offset = ccp(child.offset.x + 2*bush.contentSize.width, child.offset.y);
//                    }
//                }
//            }
//        }
//        
//        // loop the clouds
//        for (CCNode *cloud in _clouds) {
//            // get the world position of the cloud
//            CGPoint cloudWorldPosition = [_parallaxBackground convertToWorldSpace:cloud.position];
//            // get the screen position of the cloud
//            CGPoint cloudScreenPosition = [self convertToNodeSpace:cloudWorldPosition];
//            
//            // if the left corner is one complete width off the screen,
//            // move it to the right
//            if (cloudScreenPosition.x <= (-1 * cloud.contentSize.width)) {
//                for (CGPointObject *child in _parallaxBackground.parallaxArray) {
//                    if (child.child == cloud) {
//                        child.offset = ccp(child.offset.x + 2*cloud.contentSize.width, child.offset.y);
//                    }
//                }
//            }
//        }
        
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
        
//        if (!_gameOver)
//        {
//            @try
//            {
//                character.physicsBody.velocity = ccp(80.f, clampf(character.physicsBody.velocity.y, -MAXFLOAT, 200.f));
//                
//                [super update:delta];
//            }
//            @catch(NSException* ex)
//            {
//                
//            }
//        }
    }
    if (_afterCollision) {
        _afterCollision = FALSE;
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
        monkey.physicsBody.allowsRotation = FALSE;
        [animationManager runAnimationsForSequenceNamed:@"Default"];
    
        if (_ropeMonkeyJoint != nil) {
            [_ropeMonkeyJoint invalidate];
            _ropeMonkeyJoint = nil;
        }
        _afterCollision = TRUE;
        _onCollisionX = monkey.position.x;
        _followMonkey = [CCActionFollow actionWithTarget:monkey worldBoundary:self.boundingBox];
        [contentNode runAction:_followMonkey];
        monkey.position = [physicsNode convertToNodeSpace:[rope convertToWorldSpace:ccp(5,-201)]];
        _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:rope.physicsBody bodyB:monkey.physicsBody anchorA:ccp(10,-200)];
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
