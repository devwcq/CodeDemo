//
//  UIViewController+VCProfiler.m
//  KVODemo
//
//  Created by KevinWu on 2018/10/02.
//  Copyright © 2018年 wcq. All rights reserved.
//

#import "UIViewController+VCProfiler.h"
#import "objc/runtime.h"
static void wcqVCProfiler_swizzleInstanceMethod(Class class, SEL originSelector, SEL swizzleSelector) {
    Method originMethod = class_getInstanceMethod(class, originSelector);
    Method swizzleMethod = class_getInstanceMethod(class, swizzleSelector);
    BOOL addMethodSuccess = class_addMethod(class, originSelector, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (addMethodSuccess) {
        class_replaceMethod(class, swizzleSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    }else {
        method_exchangeImplementations(originMethod, swizzleMethod);
    }
}

static NSString *const kWcqVCProfilerObserverKeypath = @"WcqVCProfilerObserverKeypath";

@interface WcqVCProfilerObserverPrivate : NSObject

@end

@implementation WcqVCProfilerObserverPrivate
+ (WcqVCProfilerObserverPrivate *)sharedObserver {
    static dispatch_once_t onceToken;
    static WcqVCProfilerObserverPrivate *observer;
    dispatch_once(&onceToken, ^{
        observer = [WcqVCProfilerObserverPrivate new];
    });
    return observer;
}
@end

@interface WcqVCProfilerObserverRemoveManagerPrivate : NSObject
@property (nonatomic, unsafe_unretained) UIViewController *target;
@property (nonatomic, copy) NSString *oberverKeyPath;
@end

@implementation WcqVCProfilerObserverRemoveManagerPrivate
- (void)dealloc {
    if (_target) {
        [_target removeObserver:[WcqVCProfilerObserverPrivate sharedObserver] forKeyPath:_oberverKeyPath];
    }
    _target = nil;
    _oberverKeyPath = nil;
}
@end

static void wcqVCProfiler_viewDidLoad(UIViewController *kvoSelf, SEL seleter) {
    Class kvoClass = object_getClass(kvoSelf);
    Class originClass = class_getSuperclass(kvoClass);
    IMP superViewDidload = class_getMethodImplementation(originClass, seleter);
    void (*viewDidload)(UIViewController *, SEL) = (void *)superViewDidload;
    CFAbsoluteTime beiginTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"Class:%@ 开始执行viewDidLoad方法 ",NSStringFromClass(originClass));
    viewDidload(kvoSelf,seleter);
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"Class:%@ 结束viewDidLoad方法  耗时 == %.4f",NSStringFromClass(originClass),(endTime - beiginTime));
}


/*
 1.添加KVO，让系统帮我们生产一个新的KVO子类。
 2.向KVO子类里面添加我们需要我们需要计算耗时的自定义方法
 3.移除观察者，处理好引用关系
 */

@implementation UIViewController (VCProfiler)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wcqVCProfiler_swizzleInstanceMethod(UIViewController.class, @selector(initWithCoder:), @selector(wcqVCProfiler_initWithCoder:));
        wcqVCProfiler_swizzleInstanceMethod(UIViewController.class, @selector(initWithNibName:bundle:), @selector(wcqVCProfiler_initWithNibName:bundle:));
    });
}

- (instancetype)wcqVCProfiler_initWithCoder:(NSCoder *)aDecoder {
    [self wcqVCProfiler_addKVOandHookKVOClass];
    return [self wcqVCProfiler_initWithCoder:aDecoder];
}
- (instancetype)wcqVCProfiler_initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    [self wcqVCProfiler_addKVOandHookKVOClass];
    return [self wcqVCProfiler_initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}


- (void)wcqVCProfiler_addKVOandHookKVOClass {
    if (![self belongToBlacklistViewControllers]) {
        [self addObserver:[WcqVCProfilerObserverPrivate sharedObserver] forKeyPath:kWcqVCProfilerObserverKeypath options:NSKeyValueObservingOptionNew context:nil];
        WcqVCProfilerObserverRemoveManagerPrivate *removeManager = objc_getAssociatedObject(self, _cmd);
        if (!removeManager) {
            removeManager = [WcqVCProfilerObserverRemoveManagerPrivate new];
            removeManager.target = self;
            removeManager.oberverKeyPath = kWcqVCProfilerObserverKeypath;
            objc_setAssociatedObject(self, _cmd, removeManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        Class kvoClass = object_getClass(self);
        class_addMethod(kvoClass, @selector(viewDidLoad), (IMP)wcqVCProfiler_viewDidLoad, method_getTypeEncoding(class_getClassMethod(kvoClass, @selector(viewDidLoad))));
    }
}

- (BOOL)belongToBlacklistViewControllers {//去掉系统VC
    NSString *className = NSStringFromClass(self.class);
    if ([className hasPrefix:@"NS"] || [className hasPrefix:@"_NS"] || [className hasPrefix:@"UI"]) {
        return YES;
    }
    return NO;
}
@end
