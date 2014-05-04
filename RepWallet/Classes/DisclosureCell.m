//
//  DisclosureCell.m
//  repWallet
//
//  Created by Alberto Fiore on 6/7/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "DisclosureCell.h"

@implementation DisclosureCell


@synthesize notificationName;
@synthesize btn;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier notificationName:(NSString *)notificationName boundClassName:(NSString *)boundClassName dataKey:(NSString *)dataKey label:(NSString *)label
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:boundClassName dataKey:dataKey label:label]) {
        self.notificationName = notificationName;
        // Configuro il btn
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.backgroundColor = [UIColor clearColor];
        [b setBackgroundImage:[UIImage imageNamed:@"see.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"seeDisabled.png"] forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(disclosureBtnTouched) forControlEvents:UIControlEventTouchUpInside];
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


- (void)cellHasBeenSelected:(NSNotification *)notification
{
    
}

-(void)setControlValue:(id)value
{

}

-(id)getControlValue
{
    return nil;
}

-(void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self.btn setEnabled:enabled];
}

- (void)disclosureBtnTouched
{
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName
                                                        object:self
                                                      userInfo:nil];
}

- (void)dealloc {
    [self.btn release];
    [self.notificationName release];
    [super dealloc];
}


@end
