#import "MainScene.h"

@implementation MainScene {
    Monkey *_monkey;
    Rope *_rope;
    CCPhysicsJoint *_monkeyRopeJoint;
}

- (void)didLoadFromCCB 
{
    // your code here
    _rope = (Rope*)[CCBReader load:@"Rope"];
    [physicsNode addChild:_rope];
    _rope.position = [physicsNode convertToNodeSpace:ccp(400, 250)];
    _monkey = (Monkey*)[CCBReader load:@"Monkey"];
    [physicsNode addChild:_monkey];
    _monkey.position = [physicsNode convertToNodeSpace:ccp(370,110)];
    // visualize physics bodies & joints
    physicsNode.debugDraw = TRUE;
    _monkeyRopeJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_rope.physicsBody bodyB:_monkey.physicsBody anchorA:_rope.anchorPointInPoints];

    
}

@end
