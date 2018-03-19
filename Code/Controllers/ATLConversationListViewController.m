//
//  ATLUIConversationListViewController.m
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

#import <objc/runtime.h>
#import "ATLConversationListViewController.h"
#import "ATLMessagingUtilities.h"

static NSString *const ATLConversationCellReuseIdentifier = @"ATLConversationCellReuseIdentifier";
static NSString *const ATLImageMIMETypePlaceholderText = @"Attachment: Image";
static NSString *const ATLVideoMIMETypePlaceholderText = @"Attachment: Video";
static NSString *const ATLLocationMIMETypePlaceholderText = @"Attachment: Location";
static NSString *const ATLGIFMIMETypePlaceholderText = @"Attachment: GIF";
//parth
//"\(UserDefaults.standard.value(forKey: "userFirstname") as! String) has shared a Prioritii offer"

static NSString *const ATLOfferMIMETypePlaceholderText = @"Attachment: Prioritii experience";
//static NSString *ATLOfferMIMETypePlaceholderText;

static NSInteger const ATLConverstionListPaginationWindow = 30;
static CGFloat const ATLConversationListLoadMoreConversationsDistanceThreshold = 200.0f;
static CGFloat const ATLConversationListLoadingMoreConversationsIndicatorViewWidth = 30.0f;
static CGFloat const ATLConversationListLoadingMoreConversationsIndicatorViewHeight = 30.0f;

static UIView *ATLMakeLoadingMoreConversationsIndicatorView()
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0, 0.0, ATLConversationListLoadingMoreConversationsIndicatorViewWidth, ATLConversationListLoadingMoreConversationsIndicatorViewHeight)];
    activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [activityIndicatorView startAnimating];
    return activityIndicatorView;
}

@interface ATLConversationListViewController () <UIActionSheetDelegate, LYRQueryControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic) LYRQueryController *queryController;
@property (nonatomic) LYRConversation *conversationToDelete;
@property (nonatomic) LYRConversation *conversationSelectedBeforeContentChange;
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic) BOOL showingMoreConversationsIndicator;
@property (nonatomic, readwrite) UISearchController *searchController;
@property (nonatomic) NSMutableArray *insertedRowIndexPaths;
@property (nonatomic) NSMutableArray *deletedRowIndexPaths;
@property (nonatomic) NSMutableArray *updatedRowIndexPaths;

@end

@implementation ATLConversationListViewController

NSString *const ATLConversationListViewControllerTitle = @"Messages";
NSString *const ATLConversationTableViewAccessibilityLabel = @"Conversation Table View";
NSString *const ATLConversationTableViewAccessibilityIdentifier = @"Conversation Table View Identifier";

//parth
//
//NSString *const ATLConversationListViewControllerDeletionModeMyDevices = @"My Devices";
NSString *const ATLConversationListViewControllerDeletionModeMyDevices = @"DELETE";

NSString *const ATLConversationListViewControllerDeletionModeEveryone = @"Everyone";

+ (instancetype)conversationListViewControllerWithLayerClient:(LYRClient *)layerClient
{
    NSAssert(layerClient, @"Layer Client cannot be nil");
    return [[self alloc] initWithLayerClient:layerClient];
}

- (instancetype)initWithLayerClient:(LYRClient *)layerClient
{
    NSAssert(layerClient, @"Layer Client cannot be nil");
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)  {
        _layerClient = layerClient;
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
    _cellClass = [ATLConversationTableViewCell class];
    _deletionModes = @[@(LYRDeletionModeMyDevices), @(LYRDeletionModeAllParticipants)];
    _displaysAvatarItem = NO;
    _allowsEditing = YES;
    _rowHeight = 76.0f;
    //parth
    _shouldDisplaySearchController = NO;
    _hasAppeared = NO;
}

- (id)init
{
    [NSException raise:NSInternalInconsistencyException format:@"Failed to call designated initializer"];
    return nil;
}

- (void)setLayerClient:(LYRClient *)layerClient
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Layer Client cannot be set after the view has been presented" userInfo:nil];
    }
    _layerClient = layerClient;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //parth
   
    //(UserDefaults.standard.value(forKey: "userFirstname") as! String) has shared a Prioritii offer"
   // ATLOfferMIMETypePlaceholderText = [NSString stringWithFormat:@"%@ has shared a Prioritii offer",[NSUserDefaults.standardUserDefaults valueForKey:@"userFirstname"]];
    
    self.tableView.separatorColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1];
 
    
    self.title = ATLLocalizedString(@"atl.conversationlist.title.key", ATLConversationListViewControllerTitle, nil);
    self.accessibilityLabel = ATLConversationListViewControllerTitle;
    
    self.tableView.accessibilityLabel = ATLConversationTableViewAccessibilityLabel;
    self.tableView.accessibilityIdentifier = ATLConversationTableViewAccessibilityIdentifier;
    self.tableView.isAccessibilityElement = YES;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:self.cellClass forCellReuseIdentifier:ATLConversationCellReuseIdentifier];
    
    if (self.shouldDisplaySearchController) {
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
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Perform setup here so that our children can initialize via viewDidLoad
    if (!self.queryController) {
        [self setupConversationQueryController];
    } else if (!self.queryController.delegate) {
        self.queryController.delegate = self;
        [self.tableView reloadData];
    }
    
    if (!self.hasAppeared) {
        // Hide the search bar
        CGFloat contentOffset = self.tableView.contentOffset.y + self.searchController.searchBar.frame.size.height;
        self.tableView.contentOffset = CGPointMake(0, contentOffset);
        self.tableView.rowHeight = self.rowHeight;
        if (self.allowsEditing) {
            [self addEditButton];
        }
    }
    
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath && self.clearsSelectionOnViewWillAppear) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
        [[self transitionCoordinator] notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            if (![context isCancelled]) return;
            if ([self.tableView indexPathForSelectedRow]) return;
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }];
    }
    
    // Track changes in authentication state to manipulate the query controller appropriately
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerClientDidAuthenticate:) name:LYRClientDidAuthenticateNotification object:self.layerClient];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerClientDidDeauthenticate:) name:LYRClientDidDeauthenticateNotification object:self.layerClient];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerClientDidSwitchSession:) name:LYRClientDidSwitchSessionNotification object:self.layerClient];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.hasAppeared = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.queryController.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRClientDidAuthenticateNotification object:self.layerClient];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRClientDidDeauthenticateNotification object:self.layerClient];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRClientDidSwitchSessionNotification object:self.layerClient];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Setters

- (void)setCellClass:(Class<ATLConversationPresenting>)cellClass
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change cell class after the view has been presented" userInfo:nil];
    }
    if (!class_conformsToProtocol(cellClass, @protocol(ATLConversationPresenting))) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cell class must conform to ATLConversationPresenting" userInfo:nil];
    }
    _cellClass = cellClass;
}

- (void)setDeletionModes:(NSArray *)deletionModes
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change deletion modes after the view has been presented" userInfo:nil];
    }
    _deletionModes = deletionModes;
}

- (void)setDisplaysAvatarItem:(BOOL)displaysAvatarItem
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change conversation image display after the view has been presented" userInfo:nil];
    }
    _displaysAvatarItem = displaysAvatarItem;
}

- (void)setAllowsEditing:(BOOL)allowsEditing
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change editing mode after the view has been presented" userInfo:nil];
    }
    _allowsEditing = allowsEditing;
}

- (void)setRowHeight:(CGFloat)rowHeight
{
    if (self.hasAppeared) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot change row height after the view has been presented" userInfo:nil];
    }
    _rowHeight = rowHeight;
}

#pragma mark - Set Up

- (void)addEditButton
{
    if (self.navigationItem.leftBarButtonItem) return;
    self.editButtonItem.accessibilityLabel = @"Edit Button";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)setupConversationQueryController
{
    NSAssert(self.queryController == nil, @"Cannot initialize more than once");
    if (!self.layerClient.authenticatedUser) {
        return;
    }
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastMessage.receivedAt" ascending:NO]];
    
    if ([self.dataSource respondsToSelector:@selector(conversationListViewController:willLoadWithQuery:)]) {
        query = [self.dataSource conversationListViewController:self willLoadWithQuery:query];
        if (![query isKindOfClass:[LYRQuery class]]){
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Data source must return an `LYRQuery` object." userInfo:nil];
        }
    }
    
    NSError *error;
    self.queryController = [self.layerClient queryControllerWithQuery:query error:&error];
    if (!self.queryController) {
        NSLog(@"LayerKit failed to create a query controller with error: %@", error);
        return;
    }
    self.showingMoreConversationsIndicator = [self moreConversationsAvailable];
    self.queryController.paginationWindow = ATLConverstionListPaginationWindow;
    self.queryController.delegate = self;
    
    BOOL success = [self.queryController execute:&error];
    if (!success) {
        NSLog(@"LayerKit failed to execute query with error: %@", error);
        return;
    }
}

- (void)deinitializeQueryController
{
    self.queryController = nil;
    [self.tableView reloadData];
}

- (void)layerClientDidAuthenticate:(NSNotification *)notification
{
    if (self.queryController == nil) {
        [self setupConversationQueryController];
    }
}

- (void)layerClientDidSwitchSession:(NSNotification *)notification
{
    [self deinitializeQueryController];
    [self setupConversationQueryController];
}

- (void)layerClientDidDeauthenticate:(NSNotification *)notification
{
    [self deinitializeQueryController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.queryController numberOfObjectsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self reuseIdentifierForConversation:nil atIndexPath:indexPath];
    
    UITableViewCell<ATLConversationPresenting> *conversationCell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [self configureCell:conversationCell atIndexPath:indexPath];
    //parth
    [conversationCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [conversationCell setBackgroundColor:[UIColor blackColor]];
    return conversationCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{

    //parth
    //prioritii conversation
    LYRConversation *convesation = [self.queryController objectAtIndexPath:indexPath];
    if ([convesation participants].count == 1)
    {
        NSLog(@"Prioritii Conversation");
        return false;
    }
    return self.allowsEditing;
}

#pragma mark - Cell Configuration

- (void)configureCell:(UITableViewCell<ATLConversationPresenting> *)conversationCell atIndexPath:(NSIndexPath *)indexPath
{
    LYRConversation *conversation = [self.queryController numberOfObjectsInSection:indexPath.section] ? [self.queryController objectAtIndexPath:indexPath] : nil;
    if (conversation == nil) {
        return;     // NOTE the early return if the conversation isn't found!
    }

    
    [conversationCell presentConversation:conversation];
    
    if (self.displaysAvatarItem) {
        if ([self.dataSource respondsToSelector:@selector(conversationListViewController:avatarItemForConversation:)]) {
            id<ATLAvatarItem> avatarItem = [self.dataSource conversationListViewController:self avatarItemForConversation:conversation];
            [conversationCell updateWithAvatarItem:avatarItem];
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Conversation View Delegate must return an object conforming to the `ATLAvatarItem` protocol." userInfo:nil];
        }
    }
    
    //check for unread count
    if([self.dataSource respondsToSelector:@selector(conversationListViewController:unreadCount:)])
    {
        NSString *unreadCount = [self.dataSource conversationListViewController:self unreadCount:conversation];
        if ([unreadCount isEqualToString:@"0"])
        {
           [conversationCell updateCount:true :unreadCount];
        }else{
           [conversationCell updateCount:false :unreadCount];
        }
        
    }
    
    if ([self.dataSource respondsToSelector:@selector(conversationListViewController:titleForConversation:)]) {
        NSAttributedString *conversationTitle = [self.dataSource conversationListViewController:self titleForConversation:conversation];
        [conversationCell updateWithConversationTitle:conversationTitle];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Conversation View Delegate must return a conversation label" userInfo:nil];
    }
    
    NSString *lastMessageText;
    if ([self.dataSource respondsToSelector:@selector(conversationListViewController:lastMessageTextForConversation:)]) {
        lastMessageText = [self.dataSource conversationListViewController:self lastMessageTextForConversation:conversation];
    }
    if (!lastMessageText) {
        lastMessageText = [self defaultLastMessageTextForConversation:conversation];
    }
    [conversationCell updateWithLastMessageText:lastMessageText];
}

#pragma mark - Reloading Conversations

- (void)reloadCellForConversation:(LYRConversation *)conversation
{
    if (!conversation) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"`conversation` cannot be nil." userInfo:nil];
    }
    if (!self.queryController) {
        return;
    }
    NSIndexPath *indexPath = [self.queryController indexPathForObject:conversation];
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UITableViewDelegate

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
 
    
    NSMutableArray *actions = [NSMutableArray new];
    if ([self.dataSource respondsToSelector:@selector(conversationListViewController:rowActionsForDeletionModes:)]) {
        NSArray *customActions = [self.dataSource conversationListViewController:self rowActionsForDeletionModes:(NSArray<UITableViewRowAction *> *)self.deletionModes];
        for (id action in customActions) {
            if (![action isKindOfClass:[UITableViewRowAction class]]) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"must supply an array of `UITableViewRowAction` objects" userInfo:nil];
            }
        }
        return customActions;
    } else {
        for (NSNumber *deletionMode in self.deletionModes) {
            NSString *actionString;
            UIColor *actionColor;
            if ([self.dataSource respondsToSelector:@selector(conversationListViewController:textForButtonWithDeletionMode:)]) {
                actionString = [self.dataSource conversationListViewController:self textForButtonWithDeletionMode:deletionMode.integerValue];
            } else {
                switch (deletionMode.integerValue) {
                    case LYRDeletionModeMyDevices:
                        actionString = ATLLocalizedString(@"atl.conversationlist.deletionmode.mydevices.key", ATLConversationListViewControllerDeletionModeMyDevices, nil);
                        break;
                    case LYRDeletionModeAllParticipants:
                        actionString = ATLLocalizedString(@"atl.conversationlist.deletionmode.everyone.key", ATLConversationListViewControllerDeletionModeEveryone, nil);
                        break;
                    default:
                        break;
                }
            }
            if ([self.dataSource respondsToSelector:@selector(conversationListViewController:colorForButtonWithDeletionMode:)]) {
                actionColor = [self.dataSource conversationListViewController:self colorForButtonWithDeletionMode:deletionMode.integerValue];
            } else {
                switch (deletionMode.integerValue) {
                    case LYRDeletionModeMyDevices:
                        actionColor = [UIColor redColor];
                        break;
                    case LYRDeletionModeAllParticipants:
                        actionColor = [UIColor grayColor];
                        break;
                    default:
                        break;
                }
            }
            UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:actionString handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                [self deleteConversationAtIndexPath:indexPath withDeletionMode:deletionMode.integerValue];
            }];
            deleteAction.backgroundColor = actionColor;
            [actions addObject:deleteAction];
        }
    }
    return actions;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.conversationToDelete = [self.queryController objectAtIndexPath:indexPath];
    //parth
    //UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:ATLConversationListViewControllerDeletionModeEveryone otherButtonTitles:ATLConversationListViewControllerDeletionModeMyDevices, nil];
    //remove second username
     UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:ATLConversationListViewControllerDeletionModeMyDevices otherButtonTitles:nil, nil];
    [actionSheet showInView:self.view];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(conversationListViewController:didSelectConversation:)]){
        LYRConversation *conversation = [self.queryController objectAtIndexPath:indexPath];
        [self.delegate conversationListViewController:self didSelectConversation:conversation];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self deleteConversation:self.conversationToDelete withDeletionMode:LYRDeletionModeAllParticipants];
    } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
        [self deleteConversation:self.conversationToDelete withDeletionMode:LYRDeletionModeMyDevices];
    } else if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self setEditing:NO animated:YES];
    }
    self.conversationToDelete = nil;
}

#pragma mark - Data Source

- (NSString *)reuseIdentifierForConversation:(LYRConversation *)conversation atIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier;
    if ([self.dataSource respondsToSelector:@selector(reuseIdentifierForConversationListViewController:)]) {
        reuseIdentifier = [self.dataSource reuseIdentifierForConversationListViewController:self];
    }
    if (!reuseIdentifier) {
        reuseIdentifier = ATLConversationCellReuseIdentifier;
    }
    return reuseIdentifier;
}

#pragma mark - LYRQueryControllerDelegate

- (void)queryControllerWillChangeContent:(LYRQueryController *)queryController
{
    LYRConversation *selectedConversation;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath) {
        selectedConversation = [self.queryController objectAtIndexPath:indexPath];
    }
    self.conversationSelectedBeforeContentChange = selectedConversation;
}

- (void)queryController:(LYRQueryController *)controller
        didChangeObject:(id)object
            atIndexPath:(NSIndexPath *)indexPath
          forChangeType:(LYRQueryControllerChangeType)type
           newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case LYRQueryControllerChangeTypeInsert:
            [self.insertedRowIndexPaths addObject:newIndexPath];
            break;
        case LYRQueryControllerChangeTypeUpdate:
            [self.updatedRowIndexPaths addObject:indexPath];
            break;
        case LYRQueryControllerChangeTypeMove:
            [self.deletedRowIndexPaths addObject:indexPath];
            [self.insertedRowIndexPaths addObject:newIndexPath];
            break;
        case LYRQueryControllerChangeTypeDelete:
            [self.deletedRowIndexPaths addObject:indexPath];
            break;
        default:
            break;
    }
}

- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController
{
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:self.deletedRowIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView insertRowsAtIndexPaths:self.insertedRowIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadRowsAtIndexPaths:self.updatedRowIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    self.insertedRowIndexPaths = nil;
    self.deletedRowIndexPaths = nil;
    self.updatedRowIndexPaths = nil;
    
    [self configureLoadingMoreConversationsIndicatorView];

    if (self.conversationSelectedBeforeContentChange) {
        NSIndexPath *indexPath = [self.queryController indexPathForObject:self.conversationSelectedBeforeContentChange];
        if (indexPath) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        self.conversationSelectedBeforeContentChange = nil;
    }
}

- (NSMutableArray *)insertedRowIndexPaths
{
    return _insertedRowIndexPaths ?: (_insertedRowIndexPaths = [[NSMutableArray alloc] init]);
}

- (NSMutableArray *)deletedRowIndexPaths
{
    return _deletedRowIndexPaths ?: (_deletedRowIndexPaths = [[NSMutableArray alloc] init]);
}

- (NSMutableArray *)updatedRowIndexPaths
{
    return _updatedRowIndexPaths ?: (_updatedRowIndexPaths = [[NSMutableArray alloc] init]);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        return;
    }
    [self configurePaginationWindow];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self configurePaginationWindow];
}

#pragma mark - Pagination

- (void)configurePaginationWindow
{
    if ([self moreConversationsAvailable] && [self isNearBottom]) {
        [self expandPaginationWindow];
    }
}

- (void)expandPaginationWindow
{
    self.queryController.paginationWindow += self.queryController.paginationWindow + ATLConverstionListPaginationWindow < self.queryController.totalNumberOfObjects ? ATLConverstionListPaginationWindow : self.queryController.totalNumberOfObjects - self.queryController.paginationWindow;
}

- (BOOL)moreConversationsAvailable
{
    return self.queryController.paginationWindow < self.queryController.totalNumberOfObjects;
}

- (BOOL)isNearBottom
{
    return self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.frame.size.height) - ATLConversationListLoadMoreConversationsDistanceThreshold;
}

- (void)configureLoadingMoreConversationsIndicatorView
{
    BOOL moreConversationsAvailable = [self moreConversationsAvailable];
    if (moreConversationsAvailable == self.showingMoreConversationsIndicator) {
        return;
    }
    self.showingMoreConversationsIndicator = moreConversationsAvailable;

    // The indicator view is installed as the table's footer view. When no indicator is needed, install an empty view. This is required in order to suppress the dummy separator lines that UITableView draws to simulate empty rows.
    self.tableView.tableFooterView = self.showingMoreConversationsIndicator ? ATLMakeLoadingMoreConversationsIndicatorView() : [[UIView alloc] init];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    if ([searchString isEqualToString:@""]) {
        [self updateQueryControllerWithPredicate:nil];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(conversationListViewController:didSearchForText:completion:)]) {
        [self.delegate conversationListViewController:self didSearchForText:searchString completion:^(NSSet *filteredParticipants) {
            if (![searchString isEqualToString:self.searchController.searchBar.text]) return;
            NSSet *participantIdentifiers = [filteredParticipants valueForKey:@"userID"];

            LYRPredicate *predicate = [LYRPredicate predicateWithProperty:@"participants" predicateOperator:LYRPredicateOperatorIsIn value:participantIdentifiers];

            [self updateQueryControllerWithPredicate: predicate];
        }];
    }
}

#pragma mark - Helpers

- (void)updateQueryControllerWithPredicate:(LYRPredicate *)predicate {
    self.queryController.query.predicate = predicate;
    
    NSError *error;
    [self.queryController execute:&error];
    
    [self.tableView reloadData];
}

- (NSString *)defaultLastMessageTextForConversation:(LYRConversation *)conversation
{
    NSString *lastMessageText;
    LYRMessage *lastMessage = conversation.lastMessage;
    LYRMessagePart *messagePart = lastMessage.parts[0];
    
    if ([messagePart.MIMEType isEqualToString:ATLMIMETypeTextPlain]) {
        lastMessageText = [[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding];
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImageJPEG]) {
        //parth
        if ([lastMessage.parts[2].MIMEType isEqualToString:ATLMIMETypeImageoffer])
        {
            lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.offer.key", ATLOfferMIMETypePlaceholderText, nil);
        }
        else
        {
              lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.text.key", ATLImageMIMETypePlaceholderText, nil);
        }
      
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImagePNG]) {
        lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.png.key", ATLImageMIMETypePlaceholderText, nil);
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImageGIF]) {
        lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.gif.key", ATLGIFMIMETypePlaceholderText, nil);
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeLocation]) {
        lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.location.key", ATLLocationMIMETypePlaceholderText, nil);
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeVideoMP4]) {
        lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.video.key", ATLVideoMIMETypePlaceholderText, nil);
    }else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImageoffer]) {
        lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.offer.key", ATLMIMETypeImageoffer, nil);
    }
    else {
        lastMessageText = ATLLocalizedString(@"atl.conversationlist.lastMessage.text.default.key", ATLImageMIMETypePlaceholderText, nil);
    }
    return lastMessageText;
}

- (void)deleteConversationAtIndexPath:(NSIndexPath *)indexPath withDeletionMode:(LYRDeletionMode)deletionMode
{
    LYRConversation *conversation = [self.queryController objectAtIndexPath:indexPath];
    [self deleteConversation:conversation withDeletionMode:deletionMode];
}

- (void)deleteConversation:(LYRConversation *)conversation withDeletionMode:(LYRDeletionMode)deletionMode
{
    NSError *error;
    BOOL success = [conversation delete:deletionMode error:&error];
    if (!success) {
        if ([self.delegate respondsToSelector:@selector(conversationListViewController:didFailDeletingConversation:deletionMode:error:)]) {
            [self.delegate conversationListViewController:self didFailDeletingConversation:conversation deletionMode:deletionMode error:error];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(conversationListViewController:didDeleteConversation:deletionMode:)]) {
            [self.delegate conversationListViewController:self didDeleteConversation:conversation deletionMode:deletionMode];
        }
    }
}

@end
