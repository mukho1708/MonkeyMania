//
//  GameState.h
//  MonkeyMania
//
//  Created by Abhishek Mukhopadhyay on 5/1/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameState : NSObject
+(GameState*) gameState;

@property (nonatomic, assign) NSInteger highScore;
@end
