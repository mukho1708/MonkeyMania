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
    CCLabelTTF* scoreLabel;
    CCParticleSystem* fire_effect;
    CCNodeColor* waterBaseBar;
    CCNodeColor* waterBar;
    CCLabelTTF* monkeyLifeLabel;
    CCNode* levelNode;
}
@property (nonatomic, assign) NSInteger score;
@end
