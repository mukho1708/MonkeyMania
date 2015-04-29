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
    float _artifactXRange;
    float _artifactXInterval;
    float _ropeSegmentLength;
    NSMutableArray *_flares;
    NSMutableArray *_buckets;
    NSMutableArray *_waterEffects;
    BOOL _sceneFirstFlareOn;
    BOOL _bucketActive;
    float _bucketTimer;
    int _score;
    int _bonus;
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
    _artifactXRange = ([[CCDirector sharedDirector] viewSize].width - 260)/2;
    _artifactXInterval = _artifactXRange/3;
    _ropeSegmentLength = 65;
    _flares = [NSMutableArray array];
    _buckets = [NSMutableArray array];
    _waterEffects = [NSMutableArray array];
    _sceneFirstFlareOn = FALSE;
    _bucketActive = FALSE;
    _bucketTimer = 0;
    _score = 0;
    _bonus = 0;
    
    //Setup initial scenes
    
    [self setupSceneWithTop:top1];
    [self setupSceneWithTop:top2];
    
//    [self addRopeWithSize:[self getRopeSize] atPosX:[self getRopePosition] atTop:top1];
//    [self addRopeWithSize:[self getRopeSize] atPosX:0.85*top1.contentSize.width+arc4random_uniform(10) atTop:top1];
//    [self addRopeWithSize:[self getRopeSize] atPosX:top1.contentSize.width+0.15*top2.contentSize.width+arc4random_uniform(10) atTop:top2];
//    [self addRopeWithSize:[self getRopeSize] atPosX:top1.contentSize.width+0.85*top2.contentSize.width+arc4random_uniform(10) atTop:top2];
//    
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
    //physicsNode.debugDraw = TRUE;
    
}

-(void) setupSceneWithTop:(CCNode *)top
{
    CCNode *prevTop;
    if (top == top1)
        prevTop = top2;
    else
        prevTop = top1;
    
    if (_counter == 0) {
        [self addRopeWithSize:[self getRopeSize] atPosX:_ropeSegmentLength*2 -5 + arc4random_uniform(10) atTop:top1];
    }
    else{
        if ((_gameTimer < 30 && (arc4random_uniform(2) == 1)) || (_gameTimer >= 30 && _gameTimer < 90 && (arc4random_uniform(3) == 1)) || (_gameTimer > 90 && (arc4random_uniform(5) == 1))) {
            [self addBucketAtPosX:top.position.x + _artifactXInterval - (_artifactXRange - _ropeSegmentLength*2) - 5 + arc4random_uniform(10) atTop:top];
        }
        if ((!_sceneFirstFlareOn) || (_gameTimer >=30 && _gameTimer < 90 && arc4random_uniform(2)==1) || (_gameTimer >= 90))
        {
            [self addFlareWithSizeY:250 atPosX:top.position.x + _artifactXInterval*2 - (_artifactXRange - _ropeSegmentLength*2) - 5 + arc4random_uniform(10) atTop:top];
        }
        [self addRopeWithSize:[self getRopeSize] atPosX:top.position.x + _ropeSegmentLength*2 - 5 + arc4random_uniform(10) atTop:top];
    }
    if (_gameTimer >= 90 || arc4random_uniform(2) == 1) {
        [self addFlareWithSizeY:250 atPosX:top.position.x + _ropeSegmentLength*4 + arc4random_uniform(10) atTop:top];
        _sceneFirstFlareOn = TRUE;
    }
    else
    {
        _sceneFirstFlareOn = FALSE;
    }
    if ((_gameTimer < 30 && (arc4random_uniform(2) == 1)) || (_gameTimer >= 30 && _gameTimer < 90 && (arc4random_uniform(3) == 1)) || (_gameTimer > 90 && (arc4random_uniform(5) == 1))) {
        [self addBucketAtPosX:top.position.x + _ropeSegmentLength*4 + _artifactXInterval - 5 + arc4random_uniform(10) atTop:top];
    }
    if ((!_sceneFirstFlareOn) || (_gameTimer >=30 && _gameTimer < 90 && arc4random_uniform(2)==1) || (_gameTimer >= 90) ) {
        [self addFlareWithSizeY:250 atPosX:top.position.x + _ropeSegmentLength*4 + _artifactXInterval*2 - 5 + arc4random_uniform(10) atTop:top];
    }
    [self addRopeWithSize:[self getRopeSize] atPosX:top.position.x + _ropeSegmentLength*4 + _artifactXRange - 5 + arc4random_uniform(10) atTop:top];
    if (_gameTimer >= 90 || arc4random_uniform(2) == 1) {
        [self addFlareWithSizeY:250 atPosX:top.position.x + _ropeSegmentLength*6 + _artifactXRange + arc4random_uniform(10) atTop:top];
        _sceneFirstFlareOn = TRUE;
    }
    else
    {
        _sceneFirstFlareOn = FALSE;
    }
    
}

-(int) getRopeSize
{
    _counter++;
    int ropeSize;
    if (_gameTimer < 30) {
        ropeSize = 2;
    }
    else if (_gameTimer < 90) {
        ropeSize = 2 + arc4random_uniform(2);
    }
    else {
        ropeSize = 1 + arc4random_uniform(3);
    }
    _lastRopeSize = ropeSize;
    return ropeSize;
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
    effect.physicsBody.sensor = YES;
    [effect resetSystem];
    //effect.paused = TRUE;
    [physicsNode addChild:effect];
    [_flares addObject:effect];
}

-(void) addBucketAtPosX:(float)x atTop:(CCNode*)top
{
    CCNode* bucket = (CCNode *)[CCBReader load:@"Bucket"];
    bucket.position = ccp(x,0.75*[[CCDirector sharedDirector] viewSize].height);
    bucket.physicsBody.sensor = YES;
    [physicsNode addChild:bucket];
    [_buckets addObject:bucket];
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
        [_monkey.physicsBody applyImpulse:ccp(800, 150)];
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
        _score = (int)(maxX - _beforeCollisionX)/10;
        score.string = [NSString stringWithFormat:@"Score: %d", _score+_bonus];
        _gameTimer += delta;
        if (_bucketActive) {
            _bucketTimer -= delta;
        }
        if (_bucketTimer < 0) {
            _bucketTimer = 0;
            fire_effect.paused = FALSE;
        }
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
                    // Setup the new scene
                    [self setupSceneWithTop:top];
                }
            }
            
            // Remove offscreen ropes
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
            
            // Remove offscreen flares
            NSMutableArray *offScreenFlares = nil;
            
            for (CCParticleSystem *flare in _flares) {
                CGPoint flareWorldPosition = [physicsNode convertToWorldSpace:flare.position];
                CGPoint flareScreenPosition = [self convertToNodeSpace:flareWorldPosition];
                CGPoint monkeyWorldPosition = [physicsNode convertToWorldSpace:_monkey.position];
                CGPoint monkeyScreenPosition = [self convertToNodeSpace:monkeyWorldPosition];
                if (flareScreenPosition.x+flare.posVar.x < monkeyScreenPosition.x) {
                    if (!offScreenFlares) {
                        offScreenFlares = [NSMutableArray array];
                    }
                    [offScreenFlares addObject:flare];
                }
            }
            
            for (CCParticleSystem *flareToRemove in offScreenFlares) {
                [flareToRemove removeFromParent];
                [_flares removeObject:flareToRemove];
            }
            
            // Remove offscreen buckets
            NSMutableArray *offScreenBuckets = nil;
            
            for (CCNode *bucket in _buckets) {
                CGPoint bucketWorldPosition = [physicsNode convertToWorldSpace:bucket.position];
                CGPoint bucketScreenPosition = [self convertToNodeSpace:bucketWorldPosition];
                if (bucketScreenPosition.x < ((CCSprite *)bucket.children.firstObject).contentSize.width/2) {
                    if (!offScreenBuckets) {
                        offScreenBuckets = [NSMutableArray array];
                    }
                    [offScreenBuckets addObject:bucket];
                }
            }
            
            for (CCParticleSystem *bucketToRemove in offScreenBuckets) {
                [bucketToRemove removeFromParent];
                [_buckets removeObject:bucketToRemove];
            }
            
            // Remove offscreen waterEffects
            NSMutableArray *offScreenWaterEffects = nil;
            
            for (CCParticleSystem *waterEffect in _waterEffects) {
                CGPoint waterEffectWorldPosition = [physicsNode convertToWorldSpace:waterEffect.position];
                CGPoint waterEffectScreenPosition = [self convertToNodeSpace:waterEffectWorldPosition];
                if (waterEffectScreenPosition.x < waterEffect.posVar.x) {
                    if (!offScreenWaterEffects) {
                        offScreenWaterEffects = [NSMutableArray array];
                    }
                    [offScreenWaterEffects addObject:waterEffect];
                }
            }
            
            for (CCParticleSystem *waterEffectToRemove in offScreenWaterEffects) {
                [waterEffectToRemove removeFromParent];
                [_waterEffects removeObject:waterEffectToRemove];
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
//    [self gameOver];
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey bucket:(CCNode *)bucket {
    if(![bucket.physicsBody.collisionMask  isEqual: @[]])
    {
        CCAnimationManager *bucketAnimationManager = bucket.animationManager;
        [bucketAnimationManager runAnimationsForSequenceNamed:@"Tilt Bucket"];
        CCParticleSystem *waterEffect = (CCParticleSystem *)[CCBReader load:@"WaterEffect"];
        waterEffect.position = ccp(bucket.position.x + ((CCSprite *)bucket.children.firstObject).contentSize.width/2, bucket.position.y-10);
        [waterEffect resetSystem];
        [physicsNode addChild:waterEffect];
        [_waterEffects addObject:waterEffect];
        _bucketActive = TRUE;
        _bucketTimer = 5;
        fire_effect.paused = TRUE;
        bucket.physicsBody.collisionMask = @[];
        int bonus = _gameTimer < 30 ? 500 : _gameTimer < 90 ? 750 : 1000;
        _bonus += bonus;
    }
    return TRUE;
}


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey ground:(CCNode *)ground {
    [self gameOver];
    return TRUE;
}


@end
