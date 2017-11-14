//
//  ATLParticipantTableViewController.m
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

#import "ATLParticipantTableViewController.h"
#import "ATLParticipantTableDataSet.h"
#import "ATLParticipantSectionHeaderView.h"
#import "ATLConstants.h"
#import "ATLAvatarView.h"
#import "ATLMessagingUtilities.h"

static NSString *const ATLParticipantTableSectionHeaderIdentifier = @"ATLParticipantTableSectionHeaderIdentifier";
static NSString *const ATLParticipantCellIdentifier = @"ATLParticipantCellIdentifier";

@interface ATLParticipantTableViewController () <UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic) ATLParticipantTableDataSet *participantsDataSet;
@property (nonatomic) NSMutableSet *selectedParticipants;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic) UISearchController *searchController;

@end

@implementation ATLParticipantTableViewController

NSString *const ATLParticipantTableViewAccessibilityIdentifier = @"Participant Table View Controller";
NSString *const ATLParticipantTableViewControllerTitle = @"Participants";

+ (instancetype)participantTableViewControllerWithParticipants:(NSSet *)participants sortType:(ATLParticipantPickerSortType)sortType
{
    return  [[self alloc] initWithParticipants:participants sortType:sortType];
}

- (id)initWithParticipants:(NSSet *)participants sortType:(ATLParticipantPickerSortType)sortType
{
    NSAssert(participants, @"Participants cannot be nil");
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _participants = participants;
        _sortType = sortType;
        _shouldShowAvatarItem = YES;
        _presenceStatusEnabled = YES;
        [self lyr_commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        [self lyr_commonInit];
    }
    return self;
}

- (void)lyr_commonInit
{
    _cellClass = [ATLParticipantTableViewCell class];
    _rowHeight = 48;
    _allowsMultipleSelection = YES;
    _selectedParticipants = [[NSMutableSet alloc] init];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRClientObjectsDidChangeNotification object:nil];
}

- (void)loadView
{
    self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelection = self.allowsMultipleSelection;
    self.tableView.accessibilityIdentifier = ATLParticipantTableViewAccessibilityIdentifier;
    self.tableView.sectionFooterHeight = 0;
    self.tableView.sectionHeaderHeight = 20;
    [self.tableView registerClass:[ATLParticipantSectionHeaderView class] forHeaderFooterViewReuseIdentifier:ATLParticipantTableSectionHeaderIdentifier];
    
    // UISearchController
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    // UISearchBar
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.translucent = NO;
    self.searchController.searchBar.accessibilityLabel = @"Search Bar";
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    // Since the search view covers the table view when active we make the
    // table view controller define the presentation context
    self.definesPresentationContext = YES;

    self.title = ATLLocalizedString(@"alt.participant.tableview.title.key", ATLParticipantTableViewControllerTitle, nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.hasAppeared) {
        self.tableView.rowHeight = self.rowHeight;
        self.tableView.allowsMultipleSelection = self.allowsMultipleSelection;
        [self.tableView registerClass:self.cellClass forCellReuseIdentifier:ATLParticipantCellIdentifier];
        self.participantsDataSet = [ATLParticipantTableDataSet dataSetWithParticipants:self.participants sortType:self.sortType];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerClientObjectsDidChange:) name:LYRClientObjectsDidChangeNotification object:nil];
        
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.hasAppeared = YES;
}

#pragma mark - Public Configuration

- (void)setParticipants:(NSSet *)participants
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change participants after view has been presented" userInfo:nil];
    }
    _participants = participants;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change multiple selection mode after view has been presented" userInfo:nil];
    }
    _allowsMultipleSelection = allowsMultipleSelection;
}

- (void)setCellClass:(Class<ATLParticipantPresenting>)cellClass
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change cell class after view has been presented" userInfo:nil];
    }
    _cellClass = cellClass;
}

- (void)setRowHeight:(CGFloat)rowHeight
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change row height after view has been presented" userInfo:nil];
    }
    _rowHeight = rowHeight;
}

- (void)setSortType:(ATLParticipantPickerSortType)sortType
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change sort type after view has been presented" userInfo:nil];
    }
    _sortType = sortType;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self.delegate participantTableViewController:self didSearchWithString:searchString completion:^(NSSet * _Nonnull filteredParticipants) {
        if (![searchString isEqualToString:self.searchController.searchBar.text]) return;
        self.participantsDataSet = [ATLParticipantTableDataSet dataSetWithParticipants:filteredParticipants sortType:self.sortType];
        [self.tableView reloadData];
        for (id<ATLParticipant> participant in self.selectedParticipants) {
            NSIndexPath *indexPath = [self indexPathForParticipant:participant inTableView:self.tableView];
            if (!indexPath) continue;
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    return dataSet.sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    return [dataSet.sectionTitles indexOfObject:title];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    return dataSet.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    return [dataSet numberOfParticipantsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell <ATLParticipantPresenting> *participantCell = [tableView dequeueReusableCellWithIdentifier:ATLParticipantCellIdentifier];
    [self configureCell:participantCell atIndexPath:indexPath forTableView:tableView];
    return participantCell;
}

#pragma mark - Cell Configuration

- (void)configureCell:(UITableViewCell<ATLParticipantPresenting> *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    id<ATLParticipant> participant = [self participantForTableView:tableView atIndexPath:indexPath];
    [cell presentParticipant:participant withSortType:self.sortType shouldShowAvatarItem:self.shouldShowAvatarItem presenceStatusEnabled:self.presenceStatusEnabled];
    if ([self.blockedParticipantIdentifiers containsObject:[participant userID]]) {
        NSBundle *resourcesBundle = ATLResourcesBundle();
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"block"  inBundle:resourcesBundle compatibleWithTraitCollection:nil]];
    }
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    NSString *sectionName = dataSet.sectionTitles[section];
    ATLParticipantSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:ATLParticipantTableSectionHeaderIdentifier];
    headerView.sectionHeaderLabel.text = sectionName;
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<ATLParticipant> participant = [self participantForTableView:tableView atIndexPath:indexPath];
    [self.selectedParticipants addObject:participant];
    if (tableView != self.tableView) {
        NSIndexPath *indexPath = [self indexPathForParticipant:participant inTableView:self.tableView];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [self.delegate participantTableViewController:self didSelectParticipant:participant];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<ATLParticipant> participant = [self participantForTableView:tableView atIndexPath:indexPath];
    [self.selectedParticipants removeObject:participant];
    if (tableView != self.tableView) {
        NSIndexPath *indexPath = [self indexPathForParticipant:participant inTableView:self.tableView];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    if ([self.delegate respondsToSelector:@selector(participantTableViewController:didDeselectParticipant:)]) {
        [self.delegate participantTableViewController:self didDeselectParticipant:participant];
    }
}

#pragma mark - Helpers

- (ATLParticipantTableDataSet *)dataSetForTableView:(UITableView *)tableView
{
    return self.participantsDataSet;
}

- (id<ATLParticipant>)participantForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    id<ATLParticipant> participant = [dataSet participantAtIndexPath:indexPath];
    return participant;
}

- (NSIndexPath *)indexPathForParticipant:(id<ATLParticipant>)participant inTableView:(UITableView *)tableView
{
    ATLParticipantTableDataSet *dataSet = [self dataSetForTableView:tableView];
    NSIndexPath *indexPath = [dataSet indexPathForParticipant:participant];
    return indexPath;
}

#pragma mark - Notification Handlers

- (void)layerClientObjectsDidChange:(NSNotification *)notification
{
    NSArray *changes = notification.userInfo[LYRClientObjectChangesUserInfoKey];
    NSInteger changeCount = 0;
    for (LYRObjectChange *change in changes) {
        // Interested only in LYRIdentity objects who are potential participants.
        if (![change.object isKindOfClass:[LYRIdentity class]]) {
            continue;
        }
        if (![change.object conformsToProtocol:@protocol(ATLParticipant)]) {
            continue;
        }

        id<ATLParticipant> particpant = change.object;

        switch (change.type) {
            case LYRObjectChangeTypeCreate:
                [self.participantsDataSet addParticipant:particpant];
                changeCount++;
                break;

            case LYRObjectChangeTypeUpdate:
                [self.participantsDataSet particpant:particpant updatedProperty:change.property];
                changeCount++;
                break;

            case LYRObjectChangeTypeDelete:
                [self.participantsDataSet removeParticipant:particpant];
                changeCount++;
                break;

            default:
                NSAssert(YES, @"Unrecognized LYRObjectChangeType.");
                break;
        }
    }

    if (changeCount > 0) {
        [self.tableView reloadData];
    }
}

@end
