//
//  Rope.m
//  MonkeyMania
//
//  Created by Abhishek Mukhopadhyay on 3/31/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Rope.h"

@implementation Rope

- (void)didLoadFromCCB
{
    //self.position = ccp(400, 250);
    self.zOrder = 3;
    self.physicsBody.collisionType = @"rope";
}

@end
