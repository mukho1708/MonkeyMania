#import "MainScene.h"

@implementation MainScene {
    NSArray *_grounds;
    NSArray *_tops;
    Monkey *_monkey;
    NSMutableArray *_ropes;
    NSMutableArray *_currentRope;
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
    NSMutableArray *_prevCurRope;
    float _ropeTimer;
    float _gameTimer;
    CCColor *_originalColor;
    Rope *_currentRopeMonkeySeg;
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
    _ropeTimer = 0;
    _gameTimer = 0;
    
    //Setup initial ropes
//    for (int i = 0; i<4; i++) {
//        _counter++;
//        if (i == 0 || i== 3) {
//            [self addRopeWithSize:1 atPosX:(i+1)*140 atTop:top1];
//        }
//        else
//        {
//            //_scene = 2;
//            //[self addRopeWithSize:1 atPosX:(i+1)*100+arc4random_uniform(20) atTop:top2];
//        }
//        
//    }
    _counter++;
    [self addRopeWithSize:1 atPosX:0.15*top1.contentSize.width+arc4random_uniform(10) atTop:top1];
    _counter++;
    [self addRopeWithSize:3 atPosX:0.85*top1.contentSize.width+arc4random_uniform(10) atTop:top1];
    _counter++;
    [self addRopeWithSize:2 atPosX:top1.contentSize.width+0.15*top2.contentSize.width+arc4random_uniform(10) atTop:top2];
    _counter++;
    [self addRopeWithSize:1 atPosX:top1.contentSize.width+0.85*top2.contentSize.width+arc4random_uniform(10) atTop:top2];
    
    _currentRope = [_ropes objectAtIndex:0];
    _prevCurRope = _currentRope;
    for (id obj in _currentRope) {
        if ([obj isKindOfClass:[Rope class]]) {
            ((Rope *)obj).physicsBody.collisionMask = @[];
        }
    }
    //_currentRope.physicsBody.collisionMask = @[];
    _currentRopeMonkeySeg = ((Rope *)_currentRope[[_currentRope count]-1]);
    
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.name = @"monkey";
    _monkey.position = [physicsNode convertToNodeSpace:[_currentRopeMonkeySeg convertToWorldSpace:ccp(_currentRopeMonkeySeg.contentSize.width*0.5,_currentRopeMonkeySeg.contentSize.height*0.85)]];
    _monkey.physicsBody.allowsRotation = FALSE;
    _originalColor = _monkey.color;
    maxX = _monkey.position.x;
    _beforeCollisionX = [physicsNode convertToWorldSpace:_monkey.position].x;
    [physicsNode addChild:_monkey];
    
    
    _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRopeMonkeySeg.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(_currentRopeMonkeySeg.contentSize.width,_currentRopeMonkeySeg.contentSize.height*0.85)];
    _allowImpulse = TRUE;
    
    physicsNode.collisionDelegate = self;
    // visualize physics bodies & joints
    //physicsNode.debugDraw = TRUE;
    
}

-(void) addRopeWithSize:(int)size atPosX:(float)x atTop:(CCNode *)top
{
    NSMutableArray *ropeParts = [NSMutableArray array];
    
    for (int i = 0; i < size; i++) {
        Rope *_rope = (Rope*)[CCBReader load:@"Rope"];
        _rope.name = [NSString stringWithFormat:@"rope%d", _counter];
        //_rope.rotation = 45+arc4random_uniform(30);
        if (_counter!=1) {
            _rope.physicsBody.allowsRotation = FALSE;
        }
        _rope.physicsBody.affectedByGravity = TRUE;
        //if (x <= 568) {
        _rope.position = ccp(x,([top convertToWorldSpace:top.position].y/2+top.contentSize.height) + (i * _rope.contentSize.height));//[top convertToWorldSpace:[top convertToWorldSpace:[top convertToNodeSpace:ccp(x, 1)]]];
        
        [physicsNode addChild:_rope];
        if (i==0) {
            CCPhysicsJoint *topRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody anchorA:[top convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(x,[top convertToWorldSpace:top.position].y/2+top.contentSize.height)]]];//ccp(x,1)];
            
            [_topRopeJoints addObject:topRopeJoint];
            [ropeParts addObject:topRopeJoint];
        }
        else
        {
            CCPhysicsJoint *interRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:((Rope *)ropeParts[[ropeParts count]-1]).physicsBody bodyB:_rope.physicsBody anchorA:ccp(_rope.contentSize.width/2,_rope.contentSize.height*0.95)];
            
            [ropeParts addObject:interRopeJoint];
        }
        
        [ropeParts addObject:_rope];
    }
    [_ropes addObject:ropeParts];
    
}

-(void) addFlareWithSizeY:(int)size atPosX:(float)x atTop:(CCNode*)top
{
    CCParticleSystem* effect = (CCParticleSystem *)[CCBReader load:@"Flare"];
    effect.position = ccp(x,size);
    [effect resetSystem];
    [physicsNode addChild:effect];
}

// called on every touch in this scene
-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    //CGPoint touchLocation = [touch locationInNode:_contentNode];
    _prevCurRope = _currentRope;
    _ropeTimer = 0;
}

-(void) touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    
    _monkey.physicsBody.allowsRotation = TRUE;
    
    [_ropeMonkeyJoint invalidate];
    _ropeMonkeyJoint = nil;
    
    if (_allowImpulse) {
        [_monkey.physicsBody applyImpulse:ccp(1800, 300)];
        _allowImpulse = FALSE;
    
        animationManager = _monkey.animationManager;
        [animationManager runAnimationsForSequenceNamed:@"JumpRight"];
    }
    _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
    [contentNode runAction:_followMonkey];
}

- (void)update:(CCTime)delta
{
    score.string = [NSString stringWithFormat:@"Score: %d", (int)(maxX-_beforeCollisionX)/10];
    _gameTimer += delta;
    if (_currentRope == _prevCurRope) {
        _ropeTimer += delta;
    }
    if (_ropeTimer > 3) {
        _monkey.color = [CCColor orangeColor];
        if (_ropeTimer > 6) {
            _monkey.color = [CCColor redColor];
            if(_ropeTimer > 9) {
                _monkey.color = [CCColor blackColor];
                [_ropeMonkeyJoint invalidate];
                _ropeMonkeyJoint = nil;
//                CCPhysicsJoint* topRopeJoint;
//                for (CCPhysicsJoint* joint in _currentRope.physicsBody.joints) {
//                    if ([_topRopeJoints indexOfObject:joint] != -1) {
//                        topRopeJoint = joint;
//                    }
//                }
//                [topRopeJoint invalidate];
//                topRopeJoint = nil;
                _allowImpulse = FALSE;
            }
        }
    }
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
                [self addRopeWithSize:1 atPosX:top.position.x+0.15*top.contentSize.width+arc4random_uniform(10) atTop:top];
                _counter++;
                [self addRopeWithSize:1 atPosX:top.position.x+0.85*top.contentSize.width+arc4random_uniform(10) atTop:top];
                [self addFlareWithSizeY:250 atPosX:top.position.x+300 atTop:top];
            }
        }
        
//        NSMutableArray *offScreenRopes = nil;
//        
//        for (Rope *rope in _ropes) {
//            CGPoint ropeWorldPosition = [physicsNode convertToWorldSpace:rope.position];
//            CGPoint ropeScreenPosition = [self convertToNodeSpace:ropeWorldPosition];
//            if (ropeScreenPosition.x < (rope.contentSizeInPoints.width/2)) {
//                if (!offScreenRopes) {
//                    offScreenRopes = [NSMutableArray array];
//                }
//                [offScreenRopes addObject:rope];
//            }
//        }
//        
//        for (Rope *ropeToRemove in offScreenRopes) {
//            CCPhysicsJoint *jointToRemove = ropeToRemove.physicsBody.joints.firstObject;
//            [_topRopeJoints removeObject:jointToRemove];
//            [jointToRemove invalidate];
//            jointToRemove = nil;
//            [ropeToRemove removeFromParent];
//            [_ropes removeObject:ropeToRemove];
//        }
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
        _currentRopeMonkeySeg = (Rope *)rope;
        _prevCurRope = _currentRope;
        _ropeTimer = 0;
        monkey.physicsBody.allowsRotation = FALSE;
        _currentRopeMonkeySeg.physicsBody.allowsRotation = TRUE;
        
        [animationManager runAnimationsForSequenceNamed:@"Default"];
    
        if (_ropeMonkeyJoint != nil) {
            [_ropeMonkeyJoint invalidate];
            _ropeMonkeyJoint = nil;
        }
        
        monkey.position = ccp(_currentRopeMonkeySeg.position.x, monkey.position.y);
        _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRopeMonkeySeg.physicsBody bodyB:monkey.physicsBody anchorA:ccp(5,[_currentRopeMonkeySeg convertToNodeSpace:monkey.position].y)];
        
        physicsNode.position = ccp(physicsNode.position.x - ([physicsNode convertToWorldSpace:_monkey.position].x - _beforeCollisionX), physicsNode.position.y);
        
        monkey.rotation = 0.f;
        monkey.color = _originalColor;
        
        _allowImpulse = TRUE;
    }
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey ground:(CCNode *)ground {
    [self gameOver];
    return TRUE;
}


@end
