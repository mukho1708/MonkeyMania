#import "MainScene.h"

@implementation MainScene {
    Monkey *_monkey;
    Rope *_rope;
    CCPhysicsJoint *_monkeyRopeJoint;
    CCPhysicsJoint *_topRopeJoint;
}

- (void)didLoadFromCCB 
{
    // your code here
    _rope = (Rope*)[CCBReader load:@"Rope"];
    //_rope.physicsBody.affectedByGravity=FALSE;
    _rope.rotation = 10.0f;
    _rope.position = [top convertToWorldSpace:ccp(100, 0)];
    [physicsNode addChild:_rope];
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    _monkey.position = [physicsNode convertToNodeSpace:[_rope convertToWorldSpace:ccp(5,-171)]];
    //_monkey.physicsBody.affectedByGravity = FALSE;
    [physicsNode addChild:_monkey];
    // visualize physics bodies & joints
    //physicsNode.debugDraw = TRUE;
    _topRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:top.physicsBody bodyB:_rope.physicsBody anchorA:ccp(100,0)];
    _monkeyRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_rope.physicsBody bodyB:_monkey.physicsBody anchorA:ccp(5,-150)];


    
}



@end
