//
//  StartScene.m
//  MonkeyMania
//
//  Created by Abhishek Mukhopadhyay on 5/2/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "StartScene.h"
#import "MainScene.h"
#import "GameState.h"

@implementation StartScene {
    CCLabelTTF *highScoreLabel;
}

- (void)didLoadFromCCB
{
    highScoreLabel.string = [NSString stringWithFormat:@"Current High Score: %ld", (long)[GameState gameState].highScore];
    // Variable initializations
    self.userInteractionEnabled = TRUE;
}

-(void)play {
    CCScene *mainScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] presentScene:mainScene];
}
@end
