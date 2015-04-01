#import "MainScene.h"

@implementation MainScene {
    Monkey *_monkey;
    Rope *_rope;
    CCPhysicsJoint *_monkeyRopeJoint;
    CCPhysicsJoint *_topRopeJoint;
    //CCPhysicsJoint *_monkeyRopeJointRotary;
    //CCNode *_contentNode;
}

- (void)didLoadFromCCB 
{
    // your code here
    self.userInteractionEnabled = TRUE;
    _rope = (Rope*)[CCBReader load:@"Rope"];
    //_rope.physicsBody.affectedByGravity=FALSE;
    _rope.rotation = 75.0f;
    _rope.position = [top convertToWorldSpace:ccp(100, 0)];
    [physicsNode addChild:_rope];
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.position = [physicsNode convertToNodeSpace:[_rope convertToWorldSpace:ccp(5,-171)]];
    //_monkey.physicsBody.affectedByGravity = FALSE;
    [physicsNode addChild:_monkey];
    // visualize physics bodies & joints
    physicsNode.debugDraw = TRUE;
    _topRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody anchorA:ccp(100,0)];
    _monkeyRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_rope.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(10,-150)];
    //_monkeyRopeJointRotary = [CCPhysicsJoint connectedRotaryLimitJointWithBodyA:_rope.physicsBody bodyB:_monkey.physicsBody min:5.0f max:5.0f];
    //physicsNode.collisionDelegate = self;
    
}

// called on every touch in this scene
-(void) touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    //CGPoint touchLocation = [touch locationInNode:_contentNode];
}

-(void) touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    // when touches end, meaning the user releases their finger, release the catapult
    [_monkeyRopeJoint invalidate];
    _monkeyRopeJoint = nil;
}


@end
