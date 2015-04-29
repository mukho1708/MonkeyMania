#import "Monkey.h"
#import "Rope.h"
@interface MainScene : CCNode <CCPhysicsCollisionDelegate>
{
    // define variables here;
    CCNode* contentNode;
    CCPhysicsNode* physicsNode;
    CCNode* top1;
    CCNode* ground1;
    CCNode* top2;
    CCNode* ground2;
    CCLabelTTF* score;
    CCParticleSystem* fire_effect;
}
@end
