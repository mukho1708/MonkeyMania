//
//  Monkey.m
//  MonkeyMania
//
//  Created by Abhishek Mukhopadhyay on 3/30/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Monkey.h"

@implementation Monkey

- (void)didLoadFromCCB
{
    self.position = ccp(270, 110);
    self.zOrder = 3;
    self.physicsBody.collisionType = @"monkey";
}

@end
