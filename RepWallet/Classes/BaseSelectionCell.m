//
//  BaseSelectionCell.m
//  repWallet
//
//  Created by Alberto Fiore on 3/13/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "BaseSelectionCell.h"

@implementation BaseSelectionCell

@synthesize btn, addedUnderline, underline;

- (void) show {

}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier boundClassName:(NSString *)aClassName dataKey:(NSString *)aDataKey label:(NSString *)aLabel
{
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier boundClassName:aClassName dataKey:aDataKey label:aLabel]) {
        
        RepWalletAppDelegate *appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        self.underline = nil;
        
        self.addedUnderline = NO;
        
        // Configuro il btn secondo la necessità
        
        float fontSize;
        if([appDelegate isIpad]){
            fontSize = [UIFont labelFontSize] + 14;
        } else {
            fontSize = [UIFont labelFontSize];
        }
        
        UIButton *b = [[UIButton alloc] initWithFrame:CGRectZero];
        b.backgroundColor = [UIColor clearColor];
        b.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        b.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"chooseElement.png"] forState:UIControlStateNormal];
        [b setBackgroundImage:[UIImage imageNamed:@"chooseElementDisabled.png"] forState:UIControlStateDisabled];
        [b setTitle:nil forState:UIControlStateDisabled];
        [b addTarget:self action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
        self.btn = b;
        [b release];
        
        [self.contentView addSubview:self.btn];        
        
    }
    
    return self;
}


-(void)layoutSubviews {
    
    [super layoutSubviews];
    
    CGRect rect =  CGRectZero;
    
    float btnWidth;
    float btnHeight, internalBtnHeight;
    float rightPadding, underlinePadding;
    float sepRowHeight, btnPadding, trickOrTreat;
    
    if ([(RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate] isIpad]) {
        underlinePadding = IPAD_UNDERLINE_PADDING;
        rightPadding = IPAD_RIGHT_PADDING;
        btnHeight = IPAD_CHOOSE_BTN_HEIGHT;
        btnWidth = IPAD_CHOOSE_BTN_WIDTH;
        internalBtnHeight = IPAD_CHOOSE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = IPAD_SEPARATOR_ROW_HEIGHT;
        btnPadding = IPAD_BTN_BOTTOM_PADDING;
        trickOrTreat = 0;
    } else {
        underlinePadding = UNDERLINE_PADDING;
        rightPadding = RIGHT_PADDING;
        btnHeight = CHOOSE_BTN_HEIGHT;
        btnWidth = CHOOSE_BTN_WIDTH;
        internalBtnHeight = CHOOSE_BTN_INTERNAL_HEIGHT;
        sepRowHeight = SEPARATOR_ROW_HEIGHT;
        btnPadding = BTN_BOTTOM_PADDING;
        trickOrTreat = 0;
    }
	// Rect area del btnbox
    if ((self.enabledCell && [self.btn backgroundImageForState:UIControlStateNormal] == nil)
        || (!self.enabledCell && [self.btn backgroundImageForState:UIControlStateDisabled] == nil)) {
        
        // abilitato/non abilitato ed è stato selezionato un valore
        
        if (!_isAddEditCell) {
            
            rect = CGRectMake(self.textLabel.frame.origin.x
                              + self.textLabel.frame.size.width
                              + 1.0 * self.indentationWidth,
                              self.contentView.frame.origin.y
                              + roundf(0.5 * (self.contentView.frame.size.height
                                              - btnHeight))
                              ,
                              self.contentView.frame.size.width
                              - (self.textLabel.frame.size.width
                                 + 3.0 * self.indentationWidth
                                 + self.textLabel.frame.origin.x)
                              - rightPadding,
                              btnHeight);
            
        } else {
            
            rect = CGRectMake(self.textLabel.frame.origin.x
                              + self.textLabel.frame.size.width
                              + 1.0 * self.indentationWidth,
                              self.textLabel.frame.origin.y,
                              self.contentView.frame.size.width
                              - (self.textLabel.frame.size.width
                                 + 3.0 * self.indentationWidth
                                 + self.textLabel.frame.origin.x)
                              - rightPadding,
                              self.textLabel.frame.size.height);
            
        }
        
    } else {
        
        if (!_isAddEditCell) {
            
            rect = CGRectMake(self.textLabel.frame.origin.x
                              + self.textLabel.frame.size.width
                              + 1.0 * self.indentationWidth,
                              self.textLabel.frame.origin.y
                              + self.textLabel.frame.size.height
                              + roundf(- 0.5 * btnHeight
                                       - 0.5 * internalBtnHeight)
                              - btnPadding
                              - trickOrTreat
                              ,
                              btnWidth,
                              btnHeight);
            
        } else {
            
            rect = CGRectMake(self.textLabel.frame.origin.x
                              + self.textLabel.frame.size.width
                              + 1.0 * self.indentationWidth,
                              self.contentView.center.y
                              - roundf(btnHeight * 0.5
                                       + 0.5 * internalBtnHeight
                                       + 0.5 * sepRowHeight)
                              - btnPadding
                              ,
                              btnWidth,
                              btnHeight);
            
        }
        
    }
	
	[self.btn setFrame:rect];
    
    if (!_isAddEditCell && self.addedUnderline) {
        
        [self.underline setFrame:CGRectMake(self.btn.frame.origin.x,
                                            self.contentView.frame.origin.y
                                            + self.contentView.frame.size.height
                                            - underlinePadding,
                                            self.btn.frame.size.width,
                                            1
                                            )];
    }
}

-(void)setEnabled:(BOOL)enabled
{
    if (!enabled) {

        [self.underline setBackgroundColor:[UIColor grayColor]];
        
        if (![self getControlValue]) {
            [self.btn setBackgroundImage:[UIImage imageNamed:@"chooseElementDisabled.png"] forState:UIControlStateDisabled];
            [self.btn setTitle:nil forState:UIControlStateNormal];
        } else {
            [self.btn setBackgroundImage:nil forState:UIControlStateDisabled];
            [self.btn setTitle:nil forState:UIControlStateNormal];
        }
        
    } else {
        
        [self.underline setBackgroundColor:[UIColor blackColor]];
        
        if (![self getControlValue]) {
            [self.btn setBackgroundImage:[UIImage imageNamed:@"chooseElement.png"] forState:UIControlStateNormal];
            [self.btn setTitle:nil forState:UIControlStateNormal];
        } else {
            [self.btn setBackgroundImage:nil forState:UIControlStateNormal];
        }
    }
    
    [self.btn setEnabled:enabled];
    
    [super setEnabled:enabled];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.underline release];
    [self.btn release];
    [super dealloc];
}

@end
