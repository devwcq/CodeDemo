//
//  UINavigationController+WCQFullScreenPopGesture.h
//  KevinWuDemo
//
//  Created by KevinWu on 2018/10/11.
//  Copyright © 2018年 wcq. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (WCQFullScreenPopGesture)
@property(nullable, nonatomic, readonly) UIGestureRecognizer *wcq_fullScreenInteractivePopGestureRecognizer;
@end

@interface UIViewController (WCQFullScreenPopGesture)
@property (nonatomic, assign) BOOL wcq_hideNavigationBar; //Default NO
@property (nonatomic, assign) BOOL wcq_disablePopGesture; //Default NO
@end


NS_ASSUME_NONNULL_END
