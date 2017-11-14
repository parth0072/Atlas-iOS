//
//  ATLUIParticipantTableViewCell.m
//  Atlas
//
//  Created by Kevin Coleman on 8/29/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
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

#import "ATLParticipantTableViewCell.h"
#import "ATLConstants.h"
#import "ATLAvatarView.h"

@interface ATLParticipantTableViewCell ()

@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) ATLAvatarView *avatarView;
@property (nonatomic) id<ATLParticipant> participant;
@property (nonatomic) ATLParticipantPickerSortType sortType;

@property (nonatomic) NSLayoutConstraint *nameWithAvatarLeftConstraint;
@property (nonatomic) NSLayoutConstraint *nameWithoutAvatarLeftConstraint;

@end

@implementation ATLParticipantTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
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
    // UIAppearance Defaults
    _boldTitleFont = [UIFont boldSystemFontOfSize:17];
    _titleFont = [UIFont systemFontOfSize:17];
    _titleColor = [UIColor blackColor];
    _shouldBoldTitle = YES;
    
    self.nameLabel = [UILabel new];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.nameLabel];
    
    self.avatarView = [[ATLAvatarView alloc] init];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.imageView.layer.masksToBounds = YES;
    self.avatarView.hidden = YES;
    [self.contentView addSubview:self.avatarView];
    
    [self configureNameLabelConstraints];
    [self configureAvatarViewLayoutConstraints];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.accessoryView = nil;
    [self.avatarView resetView];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    // We don't want the default behavior that changes image view backgrounds to transparent while highlighted.
    UIColor *preservedAvatarBackgroundColor = self.avatarView.imageView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    self.avatarView.imageView.backgroundColor = preservedAvatarBackgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // We don't want the default behavior that changes image view backgrounds to transparent while selected.
    UIColor *preservedAvatarBackgroundColor = self.avatarView.imageView.backgroundColor;
    [super setSelected:selected animated:animated];
    self.avatarView.imageView.backgroundColor = preservedAvatarBackgroundColor;
}

- (void)presentParticipant:(id<ATLParticipant>)participant withSortType:(ATLParticipantPickerSortType)sortType shouldShowAvatarItem:(BOOL)shouldShowAvatarItem presenceStatusEnabled:(BOOL)presenceStatusEnabled
{
    self.accessibilityLabel = [participant displayName];
    self.participant = participant;
    self.sortType = sortType;
    if (shouldShowAvatarItem) {
        [self removeConstraint:self.nameWithoutAvatarLeftConstraint];
        [self addConstraint:self.nameWithAvatarLeftConstraint];
        self.avatarView.hidden = NO;
    } else {
        [self removeConstraint:self.nameWithAvatarLeftConstraint];
        [self addConstraint:self.nameWithoutAvatarLeftConstraint];
        self.avatarView.hidden = YES;
    }
    self.avatarView.avatarItem = self.participant;
    self.avatarView.presenceStatusEnabled = presenceStatusEnabled;
    [self configureNameLabel];
    self.accessibilityLabel = participant.displayName;
}

- (void)setTitleFont:(UIFont *)titleFont
{
    _titleFont = titleFont;
    [self configureNameLabel];
}

- (void)setBoldTitleFont:(UIFont *)boldTitleFont
{
    _boldTitleFont = boldTitleFont;
    [self configureNameLabel];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    _titleColor = titleColor;
    [self configureNameLabel];
}

- (void)configureNameLabel
{
    NSString *participantName = self.participant.displayName?: @"Unknown Participant";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:participantName attributes:@{NSFontAttributeName: self.titleFont}];

    NSRange rangeToBold = NSMakeRange(NSNotFound, 0);
    switch (self.sortType) {
        case ATLParticipantPickerSortTypeFirstName:
            if (self.participant.firstName.length != 0) {
                rangeToBold = [self.participant.displayName rangeOfString:self.participant.firstName];
            }
            break;
        case ATLParticipantPickerSortTypeLastName:
            if (self.participant.lastName.length != 0) {
                rangeToBold = [self.participant.displayName rangeOfString:self.participant.lastName options:NSBackwardsSearch];
            }
            break;
    }
    if (rangeToBold.location != NSNotFound && self.shouldBoldTitle) {
        [attributedString addAttributes:@{NSFontAttributeName: self.boldTitleFont} range:rangeToBold];
    }

    self.nameLabel.attributedText = attributedString;
    self.nameLabel.textColor = self.titleColor;
}

- (void)configureNameLabelConstraints
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.nameLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:8]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.nameLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.nameLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    // NOTE: We're not using NSLayoutRelationLessThanOrEqual here because doing so would cause iOS 8.0 to not update the label's intrinsic content size constraints when the label's value is changed / the cell is reused.
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.nameLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
    self.nameWithAvatarLeftConstraint = [NSLayoutConstraint constraintWithItem:self.nameLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.avatarView attribute:NSLayoutAttributeRight multiplier:1.0 constant:15];
    self.nameWithoutAvatarLeftConstraint = [NSLayoutConstraint constraintWithItem:self.nameLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15];
}

- (void)configureAvatarViewLayoutConstraints
{
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:0.6 constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.avatarView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.avatarView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

@end
