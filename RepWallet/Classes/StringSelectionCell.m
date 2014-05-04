//
//  StringSelectionCell.m
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "StringSelectionCell.h"

@implementation StringSelectionCell

@synthesize stringValue, stringSelectionVC, dataSourceArray;

- (void) unsectionedStringSelectionViewControllerSelectedString:(NSString *)string {
    
    [self setControlValue:string];

    [self postEndEditingNotification];
}


- (void) show {
    
    UnsectionedStringSelectionViewController *mainViewController = [[UnsectionedStringSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDatasource:self.dataSourceArray];
    self.stringSelectionVC = mainViewController;
    [mainViewController release];
	self.stringSelectionVC.title = @"Choose";
    self.stringSelectionVC.delegate = self;
    self.stringSelectionVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    self.stringSelectionVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.stringSelectionVC];
    UIColor * c = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    navigationController.navigationBar.tintColor = c;
    UIViewController *vc = [self viewController];
    
    if ([vc respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        
        [vc presentViewController:navigationController animated:YES completion:NULL];
        
    } else if([vc respondsToSelector:@selector(presentModalViewController:animated:)]) {
        
        [vc presentModalViewController:navigationController animated:YES];
        
    }
	
    [navigationController release];
    
}

- (id) initWithStyle:(UITableViewCellStyle)style dataSource:(NSArray *)aDataSource reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {
        
        self.stringValue = nil;
        
        self.dataSourceArray = aDataSource;
        
        if([self.dataSourceArray count] == 0)
            [self setEnabled:NO];
        else
            [self setEnabled:YES];
    }
    
    return self;
}


-(void) setControlValue:(id)value
{
    if (value) {
        
        self.stringValue = value;
        
        [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
        [self.btn setTitle:value forState:UIControlStateNormal];
        
    } else {
        
        self.stringValue = nil;
        [self.btn setBackgroundImage:[UIImage imageNamed:@"chooseElement.png"] forState:UIControlStateNormal];
        [self.underline removeFromSuperview];
        self.underline = nil;
        self.addedUnderline = NO;
        [self.btn setTitle:nil forState:UIControlStateNormal];
    }
    
    [self layoutSubviews];
	
}

-(id) getControlValue
{
    return self.stringValue;
}

-(void)layoutSubviews {
    
    [super layoutSubviews];
    
    if (!_isAddEditCell && [self getControlValue] != nil && !self.addedUnderline) {
        
        self.addedUnderline = YES;
        
        // aggiungo la riga sotto
        
        float underlinePadding;
        
        if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
            underlinePadding = IPAD_UNDERLINE_PADDING;
            
        } else {
            underlinePadding = UNDERLINE_PADDING;
            
        }
        
        UIView * v = [[UIView alloc] initWithFrame:CGRectMake(self.btn.frame.origin.x,
                                                              self.contentView.frame.origin.y
                                                              + self.contentView.frame.size.height
                                                              - underlinePadding,
                                                              self.btn.frame.size.width,
                                                              1
                                                              )];
        
        [v setBackgroundColor:[UIColor blackColor]];
        
        self.underline = v;
        
        [self.contentView addSubview:self.underline];
        
        [v release];
    }

}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    
    [self layoutSubviews];
}

-(void)reload
{
    if([self.dataSourceArray count] == 0)
        [self setEnabled:NO];
    else
        [self setEnabled:YES];
}


- (void)dealloc
{
    if (self.stringSelectionVC) {
        self.stringSelectionVC.delegate = nil;
    }
    
    [self.dataSourceArray release];
    [self.stringValue release];
    [self.stringSelectionVC release];
    [super dealloc];
}
@end
