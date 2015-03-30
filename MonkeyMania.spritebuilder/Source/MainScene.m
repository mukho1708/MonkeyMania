#import "MainScene.h"

@implementation MainScene

- (void)didLoadFromCCB 
{
    // your code here
    monkey = (Monkey*)[CCBReader load:@"Monkey"];
    [physicsNode addChild:monkey];
}

@end
