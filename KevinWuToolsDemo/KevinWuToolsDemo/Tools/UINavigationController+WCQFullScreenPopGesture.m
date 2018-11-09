//
//  UINavigationController+WCQFullScreenPopGesture.m
//  KevinWuDemo
//
//  Created by KevinWu on 2018/10/11.
//  Copyright © 2018年 wcq. All rights reserved.
//

#import "UINavigationController+WCQFullScreenPopGesture.h"
#import <objc/runtime.h>

static inline void wcq_swizzleInstanceSelector(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL addMethodSuccess = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (addMethodSuccess) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

typedef void(^WcqFullScreenPopGestureViewWillAppearBlock)(BOOL navigationBarShowYesOrNo , BOOL animated);
@interface UIViewController (_WCQFullScreenPopGestureViewWillAppearBlockPriviate)
@property (nonatomic , copy) WcqFullScreenPopGestureViewWillAppearBlock wcq_fullScreenViewWillAppearBlock;
@end

@implementation UIViewController (_WCQFullScreenPopGestureViewWillAppearBlockPriviate)
- (WcqFullScreenPopGestureViewWillAppearBlock)wcq_fullScreenViewWillAppearBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWcq_fullScreenViewWillAppearBlock:(WcqFullScreenPopGestureViewWillAppearBlock)wcq_fullScreenViewWillAppearBlock {
    objc_setAssociatedObject(self, @selector(wcq_fullScreenViewWillAppearBlock), wcq_fullScreenViewWillAppearBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wcq_swizzleInstanceSelector(self, @selector(viewWillAppear:), @selector(wcq_fullScreenViewWillAppear:));
    });
}

- (void)wcq_fullScreenViewWillAppear:(BOOL)animated {
    [self wcq_fullScreenViewWillAppear:animated];
    !self.wcq_fullScreenViewWillAppearBlock ?: self.wcq_fullScreenViewWillAppearBlock(self.wcq_hideNavigationBar, animated);
}
@end


@interface _WCQFullScreenInteractivePopGestureRecognizerDelegate : NSObject
<
UIGestureRecognizerDelegate
>
@property (nonatomic , weak) UINavigationController *navigationController;
@end

@implementation _WCQFullScreenInteractivePopGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    else if (self.navigationController.viewControllers.lastObject.wcq_disablePopGesture) {
        return NO;
    }
    else if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {//private ivar
        return NO;
    }
    else if ([gestureRecognizer translationInView:gestureRecognizer.view].x <= 0) {
        return NO;
    }
    return YES;
}
@end



@implementation UINavigationController (WCQFullScreenPopGesture)
- (_WCQFullScreenInteractivePopGestureRecognizerDelegate *)wcq_fullScreenPanGestureDelegate {
    _WCQFullScreenInteractivePopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [_WCQFullScreenInteractivePopGestureRecognizerDelegate new];
        delegate.navigationController = self;
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN);
    }
    return delegate;
}

- (UIGestureRecognizer *)wcq_fullScreenInteractivePopGestureRecognizer {
    UIPanGestureRecognizer *wcq_fullScreenPanGesture = objc_getAssociatedObject(self, _cmd);
    if (!wcq_fullScreenPanGesture) {
        wcq_fullScreenPanGesture = [[UIPanGestureRecognizer alloc] init];
        wcq_fullScreenPanGesture.maximumNumberOfTouches = 1;
        wcq_fullScreenPanGesture.delegate = self.wcq_fullScreenPanGestureDelegate;
        objc_setAssociatedObject(self, _cmd, wcq_fullScreenPanGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return wcq_fullScreenPanGesture;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wcq_swizzleInstanceSelector(self, @selector(pushViewController:animated:), @selector(wcq_fullScreenPushViewController:animated:));
        wcq_swizzleInstanceSelector(self, @selector(setViewControllers:animated:), @selector(wcq_fullScreenSetViewControllers:animated:));
    });
}

- (void)wcq_fullScreenPushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self wcq_fullScreenPushViewController:viewController animated:animated];
    [self wcq_fullScreenAddPopGestureToViewController:viewController];
}

- (void)wcq_fullScreenSetViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    [self wcq_fullScreenSetViewControllers:viewControllers animated:animated];
    [self wcq_fullScreenAddPopGestureToViewController:viewControllers.lastObject];
}

- (void)wcq_fullScreenAddPopGestureToViewController:(UIViewController *)nextShowViewController {
    if (nextShowViewController) {
        id target = self.interactivePopGestureRecognizer.delegate;
        SEL action = NSSelectorFromString(@"handleNavigationTransition:");//private method
        if ([target respondsToSelector:action]) {
            if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.wcq_fullScreenInteractivePopGestureRecognizer]) {
                [self.wcq_fullScreenInteractivePopGestureRecognizer addTarget:target action:action];
                [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.wcq_fullScreenInteractivePopGestureRecognizer];
                self.interactivePopGestureRecognizer.enabled = NO;
            }
        }
        __weak typeof(self) weakSelf = self;
        WcqFullScreenPopGestureViewWillAppearBlock viewWillShowBlock = ^(BOOL navigationBarShowYesOrNo , BOOL animated) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf setNavigationBarHidden:navigationBarShowYesOrNo animated:animated];
        };
        nextShowViewController.wcq_fullScreenViewWillAppearBlock = viewWillShowBlock;
    }
}
@end



@implementation UIViewController (WCQFullScreenPopGesture)
-(BOOL)wcq_hideNavigationBar {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    return number.boolValue;
}

- (void)setWcq_hideNavigationBar:(BOOL)wcq_hideNavigationBar {
    objc_setAssociatedObject(self, @selector(wcq_hideNavigationBar), @(wcq_hideNavigationBar), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)wcq_disablePopGesture {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    return number.boolValue;
}

- (void)setWcq_disablePopGesture:(BOOL)wcq_disablePopGesture {
    objc_setAssociatedObject(self, @selector(wcq_disablePopGesture), @(wcq_disablePopGesture), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
