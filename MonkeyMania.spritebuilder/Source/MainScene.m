#import "MainScene.h"
#import "LastScreen.h"

@implementation MainScene {
    // Variable declarations
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
    CCActionTintTo *_orangeTintAction;
    CCActionTintTo *_redTintAction;
    CCActionTintTo *_blackTintAction;
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
//    int _score;
    int _bonus;
    float _touchBeganX;
    float _touchBeganY;
    float _touchEndedX;
    float _touchEndedY;
    NSDate *_touchStart;
    int _life;
    int _lifeLost;
    BOOL _reset;
    LastScreen *last;
}

- (void)didLoadFromCCB 
{
    // Variable initializations
    self.userInteractionEnabled = TRUE;
    _restartButton.visible = FALSE;
    _grounds = @[ground1, ground2];
    _tops = @[top1, top2];
    _ropes = [NSMutableArray array];
    _counter = 0;
    _ropeTimer = 0;
    _gameTimer = 0;
    _ropeSegmentLength = 65;
    _artifactXRange = ([[CCDirector sharedDirector] viewSize].width - _ropeSegmentLength*4)/2;
    _artifactXInterval = _artifactXRange/3;
    _flares = [NSMutableArray array];
    _buckets = [NSMutableArray array];
    _waterEffects = [NSMutableArray array];
    _sceneFirstFlareOn = FALSE;
    _bucketActive = FALSE;
    _bucketTimer = 0;
    _score = 0;
    _bonus = 0;
    _orangeTintAction = nil;
    _redTintAction = nil;
    _blackTintAction = nil;
    _touchBeganX = 0;
    _touchBeganY = 0;
    _touchEndedX = 0;
    _touchEndedY = 0;
    _life = 0;
    _lifeLost = 0;
    _reset = FALSE;
    
    //Setup initial scenes
    
    [self setupSceneWithTop:top1];
    [self setupSceneWithTop:top2];
    
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
    
    // Initialize the monkey and stop the burning effect
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.name = @"monkey";
    [((CCParticleSystem *)_monkey.children.firstObject) stopSystem];
    
    // Position it 85% from the top of the rope and middle it
    _monkey.position = [physicsNode convertToNodeSpace:[_currentRopeMonkeySeg convertToWorldSpace:ccp(_currentRopeMonkeySeg.contentSize.width*0.5,_currentRopeMonkeySeg.contentSize.height*0.85)]];
    _monkey.physicsBody.allowsRotation = FALSE;
    
    // Save original color to revert on jumping to new ropes. Set the initial color to white to be able to revert to original colour when using the CCActionTintTo transition
    _originalColor = _monkey.color;
    _monkey.color = [CCColor whiteColor];
    [_monkey runAction:[CCActionTintTo actionWithDuration:.1 color:_originalColor]];
    
    // Maximum distance travelled on the x-axis
    maxX = _monkey.position.x;
    
    // The world position the monkey should always be located at despite the infinite scrolling
    _beforeCollisionX = [physicsNode convertToWorldSpace:_monkey.position].x;
    [physicsNode addChild:_monkey];
    
    // Make the joint between the monkey and the rope and enable impulse on touch
    _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRopeMonkeySeg.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(_currentRopeMonkeySeg.contentSize.width,_currentRopeMonkeySeg.contentSize.height*0.85)];
    _allowImpulse = TRUE;
    
    physicsNode.collisionDelegate = self;
    // visualize physics bodies & joints
    //physicsNode.debugDraw = TRUE;
    
}

// Primary method to setup every screen with the scene containing 2 ropes and 2 sets of artifacts
-(void) setupSceneWithTop:(CCNode *)top
{
    // In case of the first scene start from the first rope, else start with the first artifact, the bucket, followed by the flare and the rope
    if (_counter == 0) {
        [self addRopeWithSize:[self getRopeSize] atPosX:_ropeSegmentLength*2 -5 + arc4random_uniform(10) atTop:top1];
    }
    else{
        if ((_gameTimer < 30 && (arc4random_uniform(4) == 1)) || (_gameTimer >= 30 && _gameTimer < 90 && (arc4random_uniform(7) == 1)) || (_gameTimer > 90 && (arc4random_uniform(10) == 1))) {
            [self addBucketAtPosX:top.position.x + _artifactXInterval - (_artifactXRange - _ropeSegmentLength*2) - 5 + arc4random_uniform(10) atTop:top];
        }
        if ((!_sceneFirstFlareOn) || (_gameTimer >=30 && _gameTimer < 90 && arc4random_uniform(2)==1) || (_gameTimer >= 90))
        {
            [self addFlareWithSizeY:250 atPosX:top.position.x + _artifactXInterval*2 - (_artifactXRange - _ropeSegmentLength*2) - 5 + arc4random_uniform(10) atTop:top];
        }
        [self addRopeWithSize:[self getRopeSize] atPosX:top.position.x + _ropeSegmentLength*2 - 5 + arc4random_uniform(10) atTop:top];
    }
    // Add the other artifacts after the first rope. [Flare, Bucket, Flare], [Second Rope], [Flare]. Use the _sceneFirstFlareOn flag to control the probability of the second flare
    if (_gameTimer >= 90 || arc4random_uniform(2) == 1) {
        [self addFlareWithSizeY:250 atPosX:top.position.x + _ropeSegmentLength*4 + arc4random_uniform(10) atTop:top];
        _sceneFirstFlareOn = TRUE;
    }
    else
    {
        _sceneFirstFlareOn = FALSE;
    }
    if ((_gameTimer < 30 && (arc4random_uniform(4) == 1)) || (_gameTimer >= 30 && _gameTimer < 90 && (arc4random_uniform(7) == 1)) || (_gameTimer > 90 && (arc4random_uniform(10) == 1))) {
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

// Method to get a variable rope size for different ropes based on how far into the game the player is (difficulty)
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


// Method to add a rope to the scene which consists of adding the rope segments and various joints
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
    NSMutableArray *flare = [NSMutableArray array];
    
    CCParticleSystem* effect = (CCParticleSystem *)[CCBReader load:@"Flare"];
    effect.position = ccp(x,size);
    effect.physicsBody.sensor = YES;
    if (_bucketActive) {
        [effect stopSystem];
    }
    [physicsNode addChild:effect];
    
    [flare addObject:effect];
    [flare addObject:@((1 + arc4random_uniform(4)) * 2)];
    
    [_flares addObject:flare];
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
    _reset = FALSE;
    _touchBeganX = [touch locationInNode:physicsNode].x;
    _touchBeganY = [touch locationInNode:physicsNode].y;
    _touchStart = [NSDate date];
}

-(void) touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    _touchEndedX = [touch locationInNode:physicsNode].x;
    _touchEndedY = [touch locationInNode:physicsNode].y;
    NSTimeInterval swipeTime = fabs([_touchStart timeIntervalSinceNow]);
    if (_touchEndedX - _touchBeganX > .001 * [[CCDirector sharedDirector] viewSize].width) {
        _prevCurRope = _currentRope;
        _ropeTimer = 0;
        
        _monkey.physicsBody.allowsRotation = TRUE;
        
        [_ropeMonkeyJoint invalidate];
        _ropeMonkeyJoint = nil;
        
        if (_allowImpulse) {
            //[_monkey.physicsBody applyImpulse:ccp(800, 150)];
            [_monkey.physicsBody applyImpulse:ccp((_touchEndedX-_touchBeganX)/(float)swipeTime > 800 ? 800 : (_touchEndedX-_touchBeganX)/(float)swipeTime, (_touchEndedY-_touchBeganY)/(float)swipeTime > 125 ? 125 : (_touchEndedY-_touchBeganY)/(float)swipeTime < -50 ? -50 : (_touchEndedY-_touchBeganY)/(float)swipeTime)];
            _allowImpulse = FALSE;
        
            animationManager = _monkey.animationManager;
            [animationManager runAnimationsForSequenceNamed:@"JumpRight"];
        }
        _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
        [contentNode runAction:_followMonkey];
    }
}

-(void)runTutorialWithDelta:(CCTime)delta
{
    if (_gameTimer > 3 && (_gameTimer - delta) <= 3) {
        CCNodeColor *tutorialBg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.72 green:0.867 blue:1 alpha:1] width:150 height:100];
        tutorialBg.position = [_monkey convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(_monkey.position.x + _monkey.contentSize.width/2,_monkey.position.y*.5)]];
        CCLabelTTF *tutorialText = [CCLabelTTF labelWithString:@"I am burning up! I need to get to the next rope. Swipe to jump." fontName:@"Arial" fontSize:16];
        tutorialText.fontColor = [CCColor blackColor];
        tutorialText.dimensions = tutorialBg.contentSize;
        tutorialText.position = ccp(tutorialBg.contentSize.width/2, tutorialBg.contentSize.height/2);
        [tutorialBg addChild:tutorialText];
        [_monkey addChild:tutorialBg];
        
        CCActionFadeOut *tutorialFade = [CCActionFadeOut actionWithDuration:5];
        CCActionCallBlock *actionAfterFade = [CCActionCallBlock actionWithBlock:^{
            [tutorialBg removeAllChildren];
            [tutorialBg removeFromParent];
        }];
        [tutorialText runAction:tutorialFade];
        CCActionSequence *tutorialFadeSeq = [CCActionSequence actionWithArray:@[tutorialFade, actionAfterFade]];
        [tutorialBg runAction:tutorialFadeSeq];
    }
    
    if (_gameTimer > 9 && (_gameTimer - delta) <= 9) {
        CCNodeColor *tutorialBg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.72 green:0.867 blue:1 alpha:1] width:150 height:100];
        tutorialBg.position = [_monkey convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(_monkey.position.x + _monkey.contentSize.width/2,_monkey.position.y*.5)]];
        CCLabelTTF *tutorialText = [CCLabelTTF labelWithString:@"Beware of those towering flares! They look dangerous. Look for a gap." fontName:@"Arial" fontSize:16];
        tutorialText.fontColor = [CCColor blackColor];
        tutorialText.dimensions = tutorialBg.contentSize;
        tutorialText.position = ccp(tutorialBg.contentSize.width/2, tutorialBg.contentSize.height/2);
        [tutorialBg addChild:tutorialText];
        [_monkey addChild:tutorialBg];
        
        CCActionFadeOut *tutorialFade = [CCActionFadeOut actionWithDuration:5];
        CCActionCallBlock *actionAfterFade = [CCActionCallBlock actionWithBlock:^{
            [tutorialBg removeAllChildren];
            [tutorialBg removeFromParent];
        }];
        [tutorialText runAction:tutorialFade];
        CCActionSequence *tutorialFadeSeq = [CCActionSequence actionWithArray:@[tutorialFade, actionAfterFade]];
        [tutorialBg runAction:tutorialFadeSeq];
    }
    
    if (_gameTimer > 15 && (_gameTimer - delta) <= 15) {
        CCNodeColor *tutorialBg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.72 green:0.867 blue:1 alpha:1] width:150 height:100];
        tutorialBg.position = [_monkey convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(_monkey.position.x + _monkey.contentSize.width/2,_monkey.position.y*.5)]];
        CCLabelTTF *tutorialText = [CCLabelTTF labelWithString:@"The bucket is just what I need to put out the fire for sometime. It gives extra points and life!" fontName:@"Arial" fontSize:16];
        tutorialText.fontColor = [CCColor blackColor];
        tutorialText.dimensions = tutorialBg.contentSize;
        tutorialText.position = ccp(tutorialBg.contentSize.width/2, tutorialBg.contentSize.height/2);
        [tutorialBg addChild:tutorialText];
        [_monkey addChild:tutorialBg];
        
        CCActionFadeOut *tutorialFade = [CCActionFadeOut actionWithDuration:5];
        CCActionCallBlock *actionAfterFade = [CCActionCallBlock actionWithBlock:^{
            [tutorialBg removeAllChildren];
            [tutorialBg removeFromParent];
        }];
        [tutorialText runAction:tutorialFade];
        CCActionSequence *tutorialFadeSeq = [CCActionSequence actionWithArray:@[tutorialFade, actionAfterFade]];
        [tutorialBg runAction:tutorialFadeSeq];
    }
    
    if (_gameTimer > 30 && (_gameTimer - delta) <= 30) {
        CCNodeColor *tutorialBg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.72 green:0.867 blue:1 alpha:1] width:150 height:100];
        tutorialBg.position = [_monkey convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(_monkey.position.x + _monkey.contentSize.width/2,_monkey.position.y*.5)]];
        CCLabelTTF *tutorialText = [CCLabelTTF labelWithString:@"It seems to be getting tougher. Its easier to swing into a flare with longer ropes." fontName:@"Arial" fontSize:16];
        tutorialText.fontColor = [CCColor blackColor];
        tutorialText.dimensions = tutorialBg.contentSize;
        tutorialText.position = ccp(tutorialBg.contentSize.width/2, tutorialBg.contentSize.height/2);
        [tutorialBg addChild:tutorialText];
        [_monkey addChild:tutorialBg];
        
        CCActionFadeOut *tutorialFade = [CCActionFadeOut actionWithDuration:3];
        CCActionCallBlock *actionAfterFade = [CCActionCallBlock actionWithBlock:^{
            [tutorialBg removeAllChildren];
            [tutorialBg removeFromParent];
        }];
        [tutorialText runAction:tutorialFade];
        CCActionSequence *tutorialFadeSeq = [CCActionSequence actionWithArray:@[tutorialFade, actionAfterFade]];
        [tutorialBg runAction:tutorialFadeSeq];
    }
    
    if (_gameTimer > 90 && (_gameTimer - delta) <= 90) {
        CCNodeColor *tutorialBg = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0.72 green:0.867 blue:1 alpha:1] width:150 height:100];
        tutorialBg.position = [_monkey convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(_monkey.position.x + _monkey.contentSize.width/2,_monkey.position.y*.5)]];
        CCLabelTTF *tutorialText = [CCLabelTTF labelWithString:@"Lookout! Its about to get really rough." fontName:@"Arial" fontSize:16];
        tutorialText.fontColor = [CCColor blackColor];
        tutorialText.dimensions = tutorialBg.contentSize;
        tutorialText.position = ccp(tutorialBg.contentSize.width/2, tutorialBg.contentSize.height/2);
        [tutorialBg addChild:tutorialText];
        [_monkey addChild:tutorialBg];
        
        CCActionFadeOut *tutorialFade = [CCActionFadeOut actionWithDuration:3];
        CCActionCallBlock *actionAfterFade = [CCActionCallBlock actionWithBlock:^{
            [tutorialBg removeAllChildren];
            [tutorialBg removeFromParent];
        }];
        [tutorialText runAction:tutorialFade];
        CCActionSequence *tutorialFadeSeq = [CCActionSequence actionWithArray:@[tutorialFade, actionAfterFade]];
        [tutorialBg runAction:tutorialFadeSeq];
    }

}

- (void)update:(CCTime)delta
{
    if (!_gameOver) {
        _score = (int)(maxX - _beforeCollisionX)/10;
        scoreLabel.string = [NSString stringWithFormat:@"Score: %d", _score+_bonus];
        
        _gameTimer += delta;
        
        [self runTutorialWithDelta:delta];
        
        if (_bucketActive) {
            _bucketTimer -= delta;
        }
        else
        {
            for (NSMutableArray *flare in _flares) {
                float duration = ((NSNumber *)flare[1]).floatValue;
                flare[1] = @((duration - delta) < 0 ? 8 : (duration - delta));
                if (((NSNumber *)flare[1]).floatValue < 2 && ((CCParticleSystem *)flare[0]).particleCount==0) {
                    [((CCParticleSystem *)flare[0]) resetSystem];
                }
                else if (((NSNumber *)flare[1]).floatValue > 2 && ((CCParticleSystem *)flare[0]).particleCount>0)
                {
                    [((CCParticleSystem *)flare[0]) stopSystem];
                }
            }
        }
        if (_bucketTimer < 0) {
            _bucketTimer = 0;
            _bucketActive = FALSE;
            [fire_effect resetSystem];
            for (NSMutableArray *flare in _flares) {
                [((CCParticleSystem *)flare[0]) resetSystem];
            }
        }
        
        if (_currentRope == _prevCurRope) {
            _ropeTimer += delta;
        }
        if (_ropeTimer >= 1 && _ropeTimer < 3 && _orangeTintAction == nil) {
            _orangeTintAction = [CCActionTintTo actionWithDuration:3 color:[CCColor orangeColor]];
            [_monkey runAction:_orangeTintAction];
        }
        else if (_ropeTimer >= 3 && _ropeTimer < 6 && _redTintAction == nil) {
            _redTintAction = [CCActionTintTo actionWithDuration:3 color:[CCColor redColor]];
            [_monkey runAction:_redTintAction];
        }
        else if(_ropeTimer >= 6 && _ropeTimer < 9 && _blackTintAction == nil) {
            _blackTintAction = [CCActionTintTo actionWithDuration:3 color:[CCColor blackColor]];
            [_monkey runAction:_blackTintAction];
        }
        else if (_ropeTimer > 9)
        {
            [_ropeMonkeyJoint invalidate];
            _ropeMonkeyJoint = nil;
            _allowImpulse = FALSE;
            [self gameOver];
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
            
            for (NSMutableArray *flare in _flares) {
                CGPoint flareWorldPosition = [physicsNode convertToWorldSpace:((CCParticleSystem *)flare[0]).position];
                CGPoint flareScreenPosition = [self convertToNodeSpace:flareWorldPosition];
                CGPoint monkeyWorldPosition = [physicsNode convertToWorldSpace:_monkey.position];
                CGPoint monkeyScreenPosition = [self convertToNodeSpace:monkeyWorldPosition];
                if (flareScreenPosition.x+((CCParticleSystem *)flare[0]).posVar.x < monkeyScreenPosition.x) {
                    if (!offScreenFlares) {
                        offScreenFlares = [NSMutableArray array];
                    }
                    [offScreenFlares addObject:flare];
                }
            }
            
            for (NSMutableArray *flareToRemove in offScreenFlares) {
                [((CCParticleSystem *)flareToRemove[0]) removeFromParent];
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
        if(_life != 0)
        {
            _reset = TRUE;
            _lifeLost++;
            monkeyLifeLabel.string = [NSString stringWithFormat:@"%dX", --_life];
            CCActionScaleTo *scaleUp = [CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:4];
            CCActionScaleTo *scaleDown = [CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1];
            CCActionSequence *scaleUpDown = [CCActionSequence actionWithArray:@[scaleUp, scaleDown]];
            [monkeyLifeLabel runAction:scaleUpDown];
            
            BOOL found = FALSE;
            
            for (NSMutableArray *aRope in _ropes) {
                if (found) {
                    _currentRope = aRope;
                }
                if (_currentRope == aRope) {
                    found = TRUE;
                }
            }
            if (!found) {
                _currentRope = _ropes.firstObject;
            }
            ((Rope *)_currentRope[2]).rotation = 0;
            
            _currentRopeMonkeySeg = ((Rope *)_currentRope[[_currentRope count]-1]);
            
            // Position it 85% from the top of the rope and middle it
            _monkey.position = [physicsNode convertToNodeSpace:[_currentRopeMonkeySeg convertToWorldSpace:ccp(_currentRopeMonkeySeg.contentSize.width*0.5,_currentRopeMonkeySeg.contentSize.height*0.85)]];
            
            _ropeTimer = 0;
            _monkey.physicsBody.allowsRotation = FALSE;
            
            [animationManager runAnimationsForSequenceNamed:@"Default"];
            
            _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRopeMonkeySeg.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(5,[_currentRopeMonkeySeg convertToNodeSpace:_monkey.position].y)];
            
            physicsNode.position = ccp(physicsNode.position.x - ([physicsNode convertToWorldSpace:_monkey.position].x - _beforeCollisionX), physicsNode.position.y);
            
            _monkey.rotation = 0.f;
            [_monkey stopAction:_orangeTintAction];
            [_monkey stopAction:_redTintAction];
            [_monkey stopAction:_blackTintAction];
            _orangeTintAction = nil;
            _redTintAction = nil;
            _blackTintAction = nil;
            [_monkey runAction:[CCActionTintTo actionWithDuration:1 color:_originalColor]];
            
            _allowImpulse = TRUE;
            
        }
        else
        {
            _gameOver = TRUE;
            _restartButton.visible = TRUE;
            
            [_monkey stopAction:_orangeTintAction];
            [_monkey stopAction:_redTintAction];
            [_monkey stopAction:_blackTintAction];
            _orangeTintAction = nil;
            _redTintAction = nil;
            _blackTintAction = nil;
            
            if (_monkey.children.count > 1) {
                [(CCNodeColor *)(_monkey.children.lastObject) removeFromParent];
            }

            
            [((CCParticleSystem *)_monkey.children.firstObject) resetSystem];
            
            _monkey.physicsBody.velocity = ccp(_monkey.physicsBody.velocity.x * 0.25, _monkey.physicsBody.velocity.y);
            _monkey.rotation = 270.f;
            _monkey.physicsBody.allowsRotation = FALSE;
            [_monkey stopAllActions];
            [animationManager setPaused:YES];
            
            _monkey.physicsBody.collisionMask = @[@"ground", @"top"];
            _followMonkey = [CCActionFollow actionWithTarget:_monkey worldBoundary:self.boundingBox];
            [_monkey runAction:_followMonkey];
            _blackTintAction = [CCActionTintTo actionWithDuration:0.5 color:[CCColor blackColor]];
            [_monkey runAction:_blackTintAction];
            [_monkey runAction:[CCActionFadeOut actionWithDuration:2]];
            CCActionMoveBy *moveBy = [CCActionMoveBy actionWithDuration:0.2f position:ccp(-2, 2)];
            CCActionInterval *reverseMovement = [moveBy reverse];
            CCActionSequence *shakeSequence = [CCActionSequence actionWithArray:@[moveBy, reverseMovement]];
            CCActionEaseBounce *bounce = [CCActionEaseBounce actionWithAction:shakeSequence];
            
            [self runAction:bounce];
            [self performSelector:@selector(restart) withObject:nil afterDelay:0.5f];
        }
    }
}

- (void)restart {
    last = (LastScreen *)[CCBReader load:@"LastScreen" owner:self];
    last.score = _score + _bonus;
    [levelNode addChild:last];
}

-(BOOL)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey rope:(CCNode *)rope {
    if (![rope.physicsBody.collisionMask  isEqual: @[]] && !_gameOver) {
        
        bool foundSegment = FALSE;
        
        for (NSMutableArray *aRope in _ropes) {
            for (id obj in aRope) {
                if (obj == rope) {
                    foundSegment = TRUE;
                }
            }
            if (foundSegment) {
                _currentRope = aRope;
                foundSegment = FALSE;
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
        
        [animationManager runAnimationsForSequenceNamed:@"Default"];
    
        if (_ropeMonkeyJoint != nil) {
            [_ropeMonkeyJoint invalidate];
            _ropeMonkeyJoint = nil;
        }
        
        monkey.position = ccp(_currentRopeMonkeySeg.position.x, monkey.position.y);
        _ropeMonkeyJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentRopeMonkeySeg.physicsBody bodyB:monkey.physicsBody anchorA:ccp(5,[_currentRopeMonkeySeg convertToNodeSpace:monkey.position].y)];
        
        physicsNode.position = ccp(physicsNode.position.x - ([physicsNode convertToWorldSpace:_monkey.position].x - _beforeCollisionX), physicsNode.position.y);
        
        monkey.rotation = 0.f;
        [monkey stopAction:_orangeTintAction];
        [monkey stopAction:_redTintAction];
        [monkey stopAction:_blackTintAction];
        _orangeTintAction = nil;
        _redTintAction = nil;
        _blackTintAction = nil;
        [monkey runAction:[CCActionTintTo actionWithDuration:1 color:_originalColor]];
        
        _allowImpulse = TRUE;
    }
    return TRUE;
}

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey flare:(CCParticleSystem *)flare {
    if (!_gameOver && !_reset) {
        float duration;
        for (NSMutableArray *flareArray in _flares) {
            if (((CCParticleSystem  *)flareArray[0]) == flare) {
                duration = ((NSNumber *)flareArray[1]).floatValue;
            }
        }
        if (duration < 2 && !_bucketActive) {
            [self gameOver];
        }
    }
    return TRUE;
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey bucket:(CCNode *)bucket {
    if(![bucket.physicsBody.collisionMask  isEqual: @[]] && !_gameOver)
    {
        CCAnimationManager *bucketAnimationManager = bucket.animationManager;
        [bucketAnimationManager runAnimationsForSequenceNamed:@"Tilt Bucket"];
        CCParticleSystem *waterEffect = (CCParticleSystem *)[CCBReader load:@"WaterEffect"];
        waterEffect.position = ccp(bucket.position.x + ((CCSprite *)bucket.children.firstObject).contentSize.width/2, bucket.position.y-10);
        [waterEffect resetSystem];
        [physicsNode addChild:waterEffect];
        [_waterEffects addObject:waterEffect];
        _bucketActive = TRUE;
        _bucketTimer = 10;
        [fire_effect stopSystem];
        for (NSMutableArray *flare in _flares) {
            [((CCParticleSystem *)flare[0]) stopSystem];
        }
        bucket.physicsBody.collisionMask = @[];
        int bonus = _gameTimer < 30 ? 750 : _gameTimer < 90 ? 1000 : 1500;
        _bonus += bonus;
        if (_bonus/3000 - _lifeLost > _life) {
            monkeyLifeLabel.string = [NSString stringWithFormat:@"%dX", ++_life];
            CCActionScaleTo *scaleUp = [CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:4];
            CCActionScaleTo *scaleDown = [CCActionScaleTo actionWithDuration:0.5 scaleX:1 scaleY:1];
            CCActionSequence *scaleUpDown = [CCActionSequence actionWithArray:@[scaleUp, scaleDown]];
            [monkeyLifeLabel runAction:scaleUpDown];
        }
        
        waterBar.contentSizeInPoints = CGSizeMake(fmodf(waterBar.contentSizeInPoints.width - ((float)4*bonus/500)/100 * [[CCDirector sharedDirector] viewSize].width ,waterBaseBar.contentSizeInPoints.width), waterBar.contentSizeInPoints.height);
        
        CCLabelTTF *bucketBonus = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", bonus] fontName:@"Arial" fontSize:16];
        bucketBonus.position = [monkey convertToNodeSpace:[physicsNode convertToWorldSpace:ccp(monkey.position.x,monkey.position.y + monkey.contentSize.height/2)]];
        bucketBonus.fontColor = [CCColor colorWithRed:0.72 green:0.867 blue:1 alpha:1];
        [monkey addChild:bucketBonus];
        
        CCActionFadeOut *bonusFade = [CCActionFadeOut actionWithDuration:2];
        CCActionMoveBy *bonusMove = [CCActionMoveBy actionWithDuration:2 position:ccp(0,monkey.contentSize.height)];
        CCActionCallBlock *actionAfterMoving = [CCActionCallBlock actionWithBlock:^{
            [bucketBonus removeFromParent];
        }];
        [bucketBonus runAction:bonusFade];
        CCActionSequence *bonusLabelMove = [CCActionSequence actionWithArray:@[bonusMove, actionAfterMoving]];
        [bucketBonus runAction:bonusLabelMove];
    }
    return TRUE;
}


-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair monkey:(CCNode *)monkey ground:(CCNode *)ground {
    if (!_gameOver && !_reset) {
        [self gameOver];
    }
    return TRUE;
}


@end
