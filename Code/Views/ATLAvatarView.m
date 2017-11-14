//
//  ATLAvatarView.m
//  Atlas
//
//  Created by Kevin Coleman on 10/22/14.
//  Copyright (c) 2015 Layer. All rights reserved.
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
#import "ATLAvatarView.h"
#import "ATLConstants.h"
#import "ATLPresenceStatusView.h"

@interface ATLAvatarView ()

@property (nonatomic) UILabel *initialsLabel;
@property (nonatomic) ATLPresenceStatusView *presenceStatusView;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) NSURL *remoteImageURL;

@end

@implementation ATLAvatarView

NSString *const ATLAvatarViewAccessibilityLabel = @"ATLAvatarViewAccessibilityLabel";


+ (NSCache *)sharedImageCache
{
    static NSCache *_sharedImageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedImageCache = [NSCache new];
    });
    return _sharedImageCache;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (void)lyr_commonInit
{
    // Default UI Appearance
    _initialsFont = [UIFont systemFontOfSize:14];
    _initialsColor = [UIColor blackColor];
    _avatarImageViewDiameter = 30;

    self.contentMode = UIViewContentModeScaleAspectFill;
    self.accessibilityLabel = ATLAvatarViewAccessibilityLabel;
    
    // Image View
    _imageView = [[UIImageView alloc] init];
    _imageView.backgroundColor = ATLLightGrayColor();
    _imageView.clipsToBounds = YES;
    [self addSubview:_imageView];
    
    // Initials Label
    _initialsLabel = [[UILabel alloc] init];
    _initialsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _initialsLabel.textAlignment = NSTextAlignmentCenter;
    _initialsLabel.adjustsFontSizeToFitWidth = YES;
    _initialsLabel.minimumScaleFactor = 0.75;
    _initialsLabel.textColor = _initialsColor;
    _initialsLabel.font = _initialsFont;
    [self addSubview:_initialsLabel];
    
    // Presence Status View
    _presenceStatusView = [[ATLPresenceStatusView alloc] init];
    _presenceStatusEnabled = true;
    [self addSubview:_presenceStatusView];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(self.avatarImageViewDiameter, self.avatarImageViewDiameter);
}

- (void)resetView
{
    self.avatarItem = nil;
    self.imageView.image = nil;
    self.initialsLabel.text = nil;
    [self.downloadTask cancel];
}

- (void)dealloc
{
    [self.downloadTask cancel];
}

- (void)setAvatarItem:(id<ATLAvatarItem>)avatarItem
{
    self.imageView.image = nil;
    
    if ([avatarItem avatarImageURL]) {
        self.initialsLabel.text = nil;
        [self loadAvatarImageWithURL:[avatarItem avatarImageURL]];
    } else if (avatarItem.avatarImage) {
        self.initialsLabel.text = nil;
        self.imageView.image = avatarItem.avatarImage;
    } else if (avatarItem.avatarInitials) {
        self.imageView.image = nil;
    }
    
    if (self.imageView.image == nil && avatarItem.avatarInitials) {
        self.initialsLabel.text = avatarItem.avatarInitials;
    }
    switch (avatarItem.presenceStatus) {
        case LYRIdentityPresenceStatusAvailable:
            self.presenceStatusView.statusColor = [UIColor colorWithRed:79.0/255.0 green:191.0/255.0 blue:98.0/255.0 alpha:1.0];
            self.presenceStatusView.mode = ATLMPresenceStatusViewModeFill;
            break;
        case LYRIdentityPresenceStatusBusy:
            self.presenceStatusView.statusColor = [UIColor colorWithRed:230.0/255.0 green:68.0/255.0 blue:63.0/255.0 alpha:1.0];
            self.presenceStatusView.mode = ATLMPresenceStatusViewModeFill;
            break;
        case LYRIdentityPresenceStatusAway:
            self.presenceStatusView.statusColor = [UIColor colorWithRed:247.0/255.0 green:202.0/255.0 blue:64.0/255.0 alpha:1.0];
            self.presenceStatusView.mode = ATLMPresenceStatusViewModeFill;
            break;
        case LYRIdentityPresenceStatusInvisible:
            self.presenceStatusView.statusColor = [UIColor colorWithRed:79.0/255.0 green:191.0/255.0 blue:98.0/255.0 alpha:1.0];
            self.presenceStatusView.mode = ATLMPresenceStatusViewModeBordered;
            break;
        case LYRIdentityPresenceStatusOffline:
        default:
            self.presenceStatusView.statusColor = [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:156.0/255.0 alpha:1.0];
            self.presenceStatusView.mode = ATLMPresenceStatusViewModeBordered;
            break;
    }

    _avatarItem = avatarItem;
}

- (void)setInitialsColor:(UIColor *)initialsColor
{
    self.initialsLabel.textColor = initialsColor;
    _initialsColor = initialsColor;
}

- (void)setInitialsFont:(UIFont *)initialsFont
{
    self.initialsLabel.font = initialsFont;
    _initialsFont = initialsFont;
}

- (void)setImageViewBackgroundColor:(UIColor *)imageViewBackgroundColor
{
    self.backgroundColor = imageViewBackgroundColor;
    _imageViewBackgroundColor = imageViewBackgroundColor;
}

- (void)setPresenceStatusEnabled:(BOOL)presenceStatusEnabled
{
    self.presenceStatusView.hidden = !presenceStatusEnabled;
    _presenceStatusEnabled = presenceStatusEnabled;
}

- (void)loadAvatarImageWithURL:(NSURL *)imageURL
{
    if (![imageURL isKindOfClass:[NSURL class]] || imageURL.absoluteString.length == 0) {
        NSLog(@"Cannot fetch image without URL");
        return;
    }
    
    // Check if image is in cache
    __block NSString *stringURL = imageURL.absoluteString;
    UIImage *image = [[[self class] sharedImageCache] objectForKey:stringURL];
    if (image) {
        self.imageView.image = image;
        return;
    }
    
    // If not, fetch the image and add to the cache
    [self fetchImageFromRemoteImageURL:imageURL];
}

- (void)fetchImageFromRemoteImageURL:(NSURL *)remoteImageURL
{
    self.downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:remoteImageURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (!error && location) {
            __block UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
            if (image) {
                [[[self class] sharedImageCache] setObject:image forKey:remoteImageURL.absoluteString cost:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateWithImage:image forRemoteImageURL:remoteImageURL];
                });
            }
        }
    }];
    [self.downloadTask resume];
}

- (void)updateWithImage:(UIImage *)image forRemoteImageURL:(NSURL *)remoteImageURL;
{
    if (self.remoteImageURL.absoluteString == remoteImageURL.absoluteString) {
        return;
    }
    self.remoteImageURL = remoteImageURL;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.initialsLabel.text = nil;
            self.imageView.image = image;
            self.alpha = 1.0;
        }];
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Image View
    self.imageView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    
    CGFloat avatarViewDiameter = MIN(CGRectGetWidth(self.imageView.bounds), CGRectGetHeight(self.imageView.bounds));
    self.imageView.layer.cornerRadius = avatarViewDiameter * 0.5;

    // Initials Label
    self.initialsLabel.frame = CGRectInset(self.bounds, 3, 3);
    
    // Presence Status View
    // The width of the presence status is 0.4 the height of the AvatarView
    CGFloat width = self.bounds.size.height * 0.4;
    self.presenceStatusView.frame = CGRectMake(
                                               self.bounds.size.width - width,
                                               self.bounds.size.height - width,
                                               width,
                                               width
                                               );
}
    
@end
