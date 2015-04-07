#import "Monkey.h"
#import "Rope.h"
@interface MainScene : CCNode <CCPhysicsCollisionDelegate>
{
    // define variables here;
    CCNode* contentNode;
    CCPhysicsNode* physicsNode;
    CCNode* top;
    CCNode* ground;
}
@end
