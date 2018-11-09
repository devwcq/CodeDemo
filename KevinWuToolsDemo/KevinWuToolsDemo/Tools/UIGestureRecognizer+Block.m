//
//  UIGestureRecognizer+Block.m
//  KevinWuDemo
//
//  Created by KevinWu on 2018/9/4.
//  Copyright © 2018年 wcq. All rights reserved.
//

#import "UIGestureRecognizer+Block.h"
#import <objc/runtime.h>
@implementation UIGestureRecognizer (Block)

+ (instancetype)wcq_gestureRecognizerWithActionBlock:(dispatch_block_t)block {
    return [[self alloc] wcq_initGestureRecognizerWithBlock:block];
}

- (instancetype)wcq_initGestureRecognizerWithBlock:(dispatch_block_t)block {
    if (self == [super init]) {
        [self wcq_addAssociateBlock:block];
        [self addTarget:self action:@selector(wcq_handleGestureBlock)];
    }
    return self;
}

- (void)wcq_addAssociateBlock:(dispatch_block_t)block {
    if (block) {
        objc_setAssociatedObject(self, _cmd, block, OBJC_ASSOCIATION_COPY);
    }
}

- (void)wcq_handleGestureBlock {
    dispatch_block_t block = objc_getAssociatedObject(self, @selector(wcq_addAssociateBlock:));
    if (block) {
        block();
    }
}
@end
