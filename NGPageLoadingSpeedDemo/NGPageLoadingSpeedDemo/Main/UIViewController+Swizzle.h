//
//  UIViewController+Swizzle.h
//  NGPageLoadingDemo
//
//  Created by ngmmxh on 2018/8/26.
//  Copyright © 2018年 ngmmxh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Swizzle)
@property(nonatomic,assign) CFAbsoluteTime viewLoadStartTime;

@end
