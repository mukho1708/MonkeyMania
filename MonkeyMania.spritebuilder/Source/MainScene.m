#import "MainScene.h"

@implementation MainScene {
    // Declarations
    NSArray *_grounds;
    NSArray *_tops;
    Monkey *_monkey;
    NSMutableArray *_ropes;
    NSMutableArray *_currentRope;
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
    int _lastRopeSize;
}

- (void)didLoadFromCCB 
{
    // Initialization
    self.userInteractionEnabled = TRUE;
    _restartButton.visible = FALSE;
    _grounds = @[ground1, ground2];
    _tops = @[top1, top2];
    _ropes = [NSMutableArray array];
    _counter = 0;
    _ropeTimer = 0;
    _gameTimer = 0;
    
    //Setup initial scenes
    
    [self addRopeWithSize:[self getRopeSize] atPosX:[self getRopePosition] atTop:top1];
    _counter++;
    [self addRopeWithSize:[self getRopeSize] atPosX:0.85*top1.contentSize.width+arc4random_uniform(10) atTop:top1];
    _counter++;
    [self addRopeWithSize:[self getRopeSize] atPosX:top1.contentSize.width+0.15*top2.contentSize.width+arc4random_uniform(10) atTop:top2];
    _counter++;
    [self addRopeWithSize:[self getRopeSize] atPosX:top1.contentSize.width+0.85*top2.contentSize.width+arc4random_uniform(10) atTop:top2];
    
    // Set current and previous rope
    _currentRope = [_ropes objectAtIndex:0];
    _prevCurRope = _currentRope;
    
    // Set the collision mask of the current rope, on which the monkey is located, to empty
    for (id obj in _currentRope) {
        if ([obj isKindOfClass:[CCNode class]]) {
            ((Rope *)obj).physicsBody.collisionMask = @[];
        }
    }
    
    // Get the last segement of the first/current rope to which the monkey will be attached
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
    physicsNode.debugDraw = TRUE;
    
}

-(int) getRopeSize
{
    _counter++;
    int ropeSize = 1 + arc4random_uniform(3);
    _lastRopeSize = ropeSize;
    return ropeSize;
}

-(float) getRopePosition
{
    float ropePosition;
    if (_counter == 1)
    {
        ropePosition = _lastRopeSize*65 + arc4random_uniform(10);
    }
    else
    {
        ropePosition = 1.0f;
    }
    return ropePosition;
}

-(void) addRopeWithSize:(int)size atPosX:(float)x atTop:(CCNode *)top
{
    NSMutableArray *ropeParts = [NSMutableArray array];
    
    for (int i = 0; i < size; i++) {
        Rope *_rope = (Rope*)[CCBReader load:@"Rope"];
        _rope.name = [NSString stringWithFormat:@"rope%d", _counter];
        
        if (_counter!=1) {
            _rope.physicsBody.allowsRotation = FALSE;
        }
        _rope.physicsBody.affectedByGravity = TRUE;
        
        _rope.position = ccp(x,([top convertToWorldSpace:top.position].y/2+top.contentSize.height) + (i * _rope.contentSize.height));
        
        [physicsNode addChild:_rope];
        
        if (i==0) {
            CCPhysicsJoint *topRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody anchorA:[top convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(x,[top convertToWorldSpace:top.position].y/2+top.contentSize.height)]]];//ccp(x,1)];
            
            CCPhysicsJoint *topRopeRotaryJoint = [CCPhysicsJoint connectedRotaryLimitJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody min:-1.3 max:1.3];
            
            [ropeParts addObject:topRopeJoint];
            [ropeParts addObject:topRopeRotaryJoint];
        }
        else
        {
            CCPhysicsJoint *interRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:((Rope *)ropeParts[[ropeParts count]-1]).physicsBody bodyB:_rope.physicsBody anchorA:ccp(_rope.contentSize.width/2,_rope.contentSize.height*0.95)];
            
            CCPhysicsJoint *interRopeRotaryJoint = [CCPhysicsJoint connectedRotaryLimitJointWithBodyA:((Rope *)ropeParts[[ropeParts count]-1]).physicsBody bodyB:_rope.physicsBody min:-.15 max:.15];
            
            [ropeParts addObject:interRopeJoint];
            [ropeParts addObject:interRopeRotaryJoint];
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
    effect.physicsBody.sensor = YES;
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
        [_monkey.physicsBody applyImpulse:ccp(800, 100)];
        _allowImpulse = FALSE;
    
        animationManager = _monkey.animationManager;
        [animationManager runAnimationsForSequenceNamed:@"JumpRight"];
    }
    _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
    [contentNode runAction:_followMonkey];
}

- (void)update:(CCTime)delta
{
    if (!_gameOver) {
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
                    [self addRopeWithSize:[self getRopeSize] atPosX:top.position.x+0.15*top.contentSize.width+arc4random_uniform(10) atTop:top];
                    _counter++;
                    [self addRopeWithSize:[self getRopeSize] atPosX:top.position.x+0.85*top.contentSize.width+arc4random_uniform(10) atTop:top];
                    [self addFlareWithSizeY:250 atPosX:top.position.x+300 atTop:top];
                }
            }
            
            NSMutableArray *offScreenRopes = nil;
            
            for (NSMutableArray *rope in _ropes) {
                CGPoint ropeWorldPosition = [physicsNode convertToWorldSpace:((Rope *)rope[2]).position];
                CGPoint ropeScreenPosition = [self convertToNodeSpace:ropeWorldPosition];
                if (ropeScreenPosition.x < (((Rope *)rope[2]).contentSizeInPoints.width/2)) {
                    if (!offScreenRopes) {
                        offScreenRopes = [NSMutableArray array];
                    }
                    [offScreenRopes addObject:rope];
                }
            }

            for (NSMutableArray *ropeToRemove in offScreenRopes) {
                for (id obj in ropeToRemove) {
                    if ([obj isKindOfClass:[CCNode class]]) {
                        [((Rope *)obj) removeFromParent];
                    }
                    if([obj isKindOfClass:[CCPhysicsJoint class]]){
                        [((CCPhysicsJoint *)obj) invalidate];
                    }
                }
                [_ropes removeObject:ropeToRemove];
            }
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
        
        bool foundSegement = FALSE;
        
        for (NSMutableArray *aRope in _ropes) {
            for (id obj in aRope) {
                if (obj == rope) {
                    foundSegement = TRUE;
                }
            }
            if (foundSegement) {
                _currentRope = aRope;
                foundSegement = FALSE;
            }
        }
        _currentRopeMonkeySeg = (Rope *)rope;
        _prevCurRope = _currentRope;
        for (id obj in _currentRope) {
            if ([obj isKindOfClass:[CCNode class]]) {
                ((Rope *)obj).physicsBody.collisionMask = @[];
                ((Rope *)obj).physicsBody.allowsRotation = TRUE;
            }
        }
        _ropeTimer = 0;
        monkey.physicsBody.allowsRotation = FALSE;
        //_currentRopeMonkeySeg.physicsBody.allowsRotation = TRUE;
        
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

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey flare:(CCParticleSystem *)flare {
    if (flare.particleCount == 0) {
        return TRUE;
    }
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey ground:(CCNode *)ground {
    [self gameOver];
    return TRUE;
}


@end
