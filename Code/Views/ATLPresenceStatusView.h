//
//  ATLPresenceStatusView.h
//  Atlas
//
//  Created by JP McGlone on 4/5/17.
//  Copyright (c) 2017 Layer, Inc. All rights reserved.
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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ATLMPresenceStatusViewMode) {
    ATLMPresenceStatusViewModeFill,
    ATLMPresenceStatusViewModeBordered
};

@interface ATLPresenceStatusView : UIView

/**
 @abstract Sets the color of the presence status fill or border. Default is [UIColor lightGrayColor]
 */
@property (nonatomic) UIColor *statusColor;

/**
 @abstract Sets the color of the presence status background color. Default is [UIColor whiteColor]
 */
@property (nonatomic) UIColor *statusBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 @abstract Sets the mode for the ATLMPresenceStatusView. Default is ATLMPresenceStatusViewModeFill
 */
@property (nonatomic) ATLMPresenceStatusViewMode mode;

/**
 @abstract Initialize with a color and mode
 */
-(instancetype)initWithFrame:(CGRect)rect statusColor:(UIColor *)statusColor mode:(ATLMPresenceStatusViewMode)mode;

@end
