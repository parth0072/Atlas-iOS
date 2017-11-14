//
//  ATLPresenceStatusView.m
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

#import "ATLPresenceStatusView.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation ATLPresenceStatusView

CGFloat const ATLMStartAngle = 0.0;
CGFloat const ATLMEndAngle = M_PI*2;

# pragma mark - Initialize

-(instancetype)initWithFrame:(CGRect)rect statusColor:(UIColor *)statusColor mode:(ATLMPresenceStatusViewMode)mode
{
    self = [self initWithFrame:rect];
    if (self) {
        _statusColor = statusColor;
        _mode = mode;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        _statusColor = [UIColor lightGrayColor];
        _statusBackgroundColor = [UIColor whiteColor];
        _mode = ATLMPresenceStatusViewModeFill;
    }
    return self;
}

# pragma mark - Setters

- (void)setMode:(ATLMPresenceStatusViewMode)mode
{
    _mode = mode;
    [self setNeedsDisplay];
}

- (void)setStatusColor:(UIColor *)statusColor
{
    _statusColor = statusColor;
    [self setNeedsDisplay];
}

- (void)setStatusBackgroundColor:(UIColor *)statusBackgroundColor
{
    _statusBackgroundColor = statusBackgroundColor;
    [self setNeedsDisplay];
}

# pragma mark - Drawing
// Draw a circle in the center of the view using the color and mode of this ATLPresenceStatusView
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    CGPoint center = CGPointMake(CGRectGetWidth(self.bounds) * 0.5, CGRectGetHeight(self.bounds) * 0.5);
    
    // We are drawing a circle to fit the bounds, so we need the smallest side
    CGFloat diameter = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGFloat radius = diameter * 0.5;
    
    // Draw background first
    CGContextSetFillColorWithColor(context, _statusBackgroundColor.CGColor);
    CGContextAddArc(context, center.x, center.y, radius, ATLMStartAngle, ATLMEndAngle, YES);
    CGContextFillPath(context);
    CGContextSaveGState(context);

    CGFloat borderWidth = diameter / 6.0;
    
    switch (_mode) {
        case ATLMPresenceStatusViewModeFill:
        {
            // Fill the circle
            CGContextSetFillColorWithColor(context, _statusColor.CGColor);
            CGContextAddArc(context, center.x, center.y, radius - (borderWidth * 0.5), ATLMStartAngle, ATLMEndAngle, YES);
            CGContextFillPath(context);
            break;
        }
        case ATLMPresenceStatusViewModeBordered:
        {
            // Inset the radius
            CGContextAddArc(context, center.x, center.y, radius - borderWidth, ATLMStartAngle, ATLMEndAngle, YES);

            CGContextSetLineWidth(context, borderWidth);
            CGContextSetStrokeColorWithColor(context, _statusColor.CGColor);
            CGContextStrokePath(context);
            break;
        }
    }
    
}

@end
