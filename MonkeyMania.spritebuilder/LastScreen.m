//
//  LastScreen.m
//  MonkeyMania
//
//  Created by Abhishek Mukhopadhyay on 5/2/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "LastScreen.h"
#import "GameState.h"
#import "MainScene.h"

@implementation LastScreen {
    CCLabelTTF *lastScreenLabel;
    BOOL _scoreUpdated;
}

- (void)didLoadFromCCB
{
    _scoreUpdated = FALSE;
}

-(void) update:(CCTime)delta {
    
    if (_score > 0 && !_scoreUpdated) {
        if (_score <= [GameState gameState].highScore) {
            lastScreenLabel.string = [NSString stringWithFormat:@"Well Played! Your score is: %ld. \nNow try to beat the highest score %ld", _score, (long)[GameState gameState].highScore];
        } else {
            lastScreenLabel.string = [NSString stringWithFormat:@"Well Played! Your score is: %ld. \nYou beat your highest score!", _score];
            [GameState gameState].highScore = _score;
        }
        _scoreUpdated = TRUE;
    }
}

-(void)playAgain{
    CCScene *scene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
    
}

-(void)quit{
    CCScene *scene = [CCBReader loadAsScene:@"StartScene"];
    [[CCDirector sharedDirector] replaceScene:scene];
}
@end
