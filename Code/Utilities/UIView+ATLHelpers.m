//
//  UIView+ATLHelpers.m
//  Atlas
//
//  Created by Łukasz Przytuła on 09.11.2017.
//  Copyright (c) 2017 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "UIView+ATLHelpers.h"

@implementation UIView (ATLHelpers)

- (UIEdgeInsets)atl_safeAreaInsets {
    SEL selector = NSSelectorFromString(@"safeAreaInsets");
    if (![self respondsToSelector:selector]) {
        return UIEdgeInsetsZero;
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [[self class] instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:self];
    [invocation invoke];
    UIEdgeInsets returnValue;
    [invocation getReturnValue:&returnValue];
    return returnValue;
}

@end
