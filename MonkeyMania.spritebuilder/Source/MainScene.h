#import "Monkey.h"
#import "Rope.h"
@interface MainScene : CCNode <CCPhysicsCollisionDelegate>
{
    // define variables here;
    CCPhysicsNode* physicsNode;
    CCNode* top;
}
@end
