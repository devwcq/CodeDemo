//
//  UIGestureRecognizer+Block.h
//  KevinWuDemo
//
//  Created by KevinWu on 2018/9/4.
//  Copyright © 2018年 wcq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (Block)
+ (instancetype)wcq_gestureRecognizerWithActionBlock:(dispatch_block_t)block;
@end
