//
//  GameState.m
//  MonkeyMania
//
//  Created by Abhishek Mukhopadhyay on 5/1/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GameState.h"

@implementation GameState

static GameState *singletonState;
static dispatch_once_t token;

+(GameState*) gameState
{
    dispatch_once(&token, ^{
        singletonState = [[GameState alloc] init];
    });
    return singletonState;
}

static NSString* KeyForHighScore = @"highScore";

-(void) setHighScore:(NSInteger)highScore
{
    [[NSUserDefaults standardUserDefaults] setInteger:highScore forKey:KeyForHighScore];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger) highScore
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:KeyForHighScore] == 0 ? 5000 : [[NSUserDefaults standardUserDefaults] integerForKey:KeyForHighScore];
}

@end
