//
//  DocumentPickerCell.m
//  repWallet
//
//  Created by Alberto Fiore on 27/02/13.
//  Copyright (c) 2013 Alberto Fiore. All rights reserved.
//

#import "DocumentPickerCell.h"
#import "Document.h"
#import "AddEditViewController.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation DocumentPickerCell

@synthesize btn, oldDocs, docs, dao, docuVC;


-(void)documentViewControllerCanceled {
    
    [self setControlValue:self.oldDocs];
    
}

-(void)documentViewControllerRemovedDocumentWithURL:(NSURL *)docURL {
    
    if (!self.docs) {
        
        [self setControlValue:[NSSet set]];
        
    } else {
        
        NSString * url = [docURL absoluteString];
        
        NSMutableSet *s = [NSMutableSet setWithSet:self.docs];
        
        NSMutableArray *a = [NSMutableArray array];
        
        for (Document *d in s) {
            if ([d.url isEqualToString:url]) {
                [a addObject:d];
                break;
            }
        }
        
        for(Document *d in a) {
            [s removeObject:d];
        }
        
        [self setControlValue:[NSSet setWithSet:s]];
        
    }
}

-(void)documentViewControllerAddedDocumentWithURL:(NSURL *)docURL {
    
    Document *doc = [(Document *)[[NSManagedObject alloc] initWithEntity:[self.dao getEntityDescriptionForName:@"Document"] insertIntoManagedObjectContext:self.dao.managedObjectContext] autorelease];
    
    doc.url = [docURL absoluteString];
    
    if (!self.docs) {
        
        [self setControlValue:[NSSet setWithObject:doc]];
        
    } else {
        
        [self setControlValue:[self.docs setByAddingObject:doc]];
        
    }
}

- (void) presentDocumentViewControllerWithDocuments:(NSMutableArray *)docsToShow {
    
    DocumentViewController * mainViewController = [[DocumentViewController alloc] initWithDocumentsURLs:docsToShow];
    self.docuVC = mainViewController;
    [mainViewController release];
    self.docuVC.delegate = self;
    self.docuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.docuVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.docuVC];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    navigationController.toolbar.tintColor = c;
	UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }
    
	[navigationController release];
    
}

- (void) btnClicked {
    
    NSMutableArray *documentsToShow = [NSMutableArray array];
    
    if (!self.docs) {
        
        self.oldDocs = nil;
        
    } else {
        
        self.oldDocs = [NSSet setWithSet:self.docs];
        
        for (Document *doc in self.docs) {
            NSURL *url = [NSURL URLWithString:doc.url];
            [documentsToShow addObject:url];
        }
        
    }

    [self presentDocumentViewControllerWithDocuments:documentsToShow];

}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label dao:(DAO *)dao
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        
        self.dao = dao;
        
        // Configuro il btn
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.backgroundColor = [UIColor clearColor];
        [b setBackgroundImage:[UIImage imageNamed:@"see.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"seeDisabled.png"] forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
        self.btn = b;
        [self.contentView addSubview:self.btn];
        [b release];
    }
    
    return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    
    float btnW, btnH, internalBtnHeight, sepRowHeight, btnPadding;
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        btnW = IPAD_SEE_BUTTON_WIDTH;
        btnH = IPAD_SEE_BUTTON_HEIGHT;
        internalBtnHeight = IPAD_SEE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
    } else {
        btnW = SEE_BUTTON_WIDTH;
        btnH = SEE_BUTTON_HEIGHT;
        internalBtnHeight = SEE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = BTN_BOTTOM_PADDING;
    }
    
    CGRect rect;
    
    if (!_isAddEditCell) {
        rect = CGRectMake(self.textLabel.frame.origin.x
                          + self.textLabel.frame.size.width
                          + 1.0 * self.indentationWidth,
                          self.textLabel.frame.origin.y
                          + self.textLabel.frame.size.height
                          - roundf((0.5 * (btnH - internalBtnHeight)) + internalBtnHeight)
                          - btnPadding,
                          btnW,
                          btnH);
        
    } else {
        rect = CGRectMake(self.textLabel.frame.origin.x
                          + self.textLabel.frame.size.width
                          + 1.0 * self.indentationWidth,
                          self.contentView.center.y
                          - roundf(btnH * 0.5
                                   + 0.5 * internalBtnHeight
                                   + 0.5 * sepRowHeight)
                          - btnPadding
                          ,
                          btnW,
                          btnH);
    }
    
    [self.btn setFrame:rect];
}

-(void)setControlValue:(id)value
{
//    NSLog(@"set control value to %@", value);
    self.docs = value;
}

-(id)getControlValue
{
    return self.docs;
}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self.btn setEnabled:enabled];
}

- (void)dealloc {
    
    if (self.docuVC) {
        self.docuVC.delegate = nil;
    }
    
    [self.docuVC release];
    [self.oldDocs release];
    [self.dao release];
    [self.docs release];
    [self.btn release];
    [super dealloc];
}


@end
