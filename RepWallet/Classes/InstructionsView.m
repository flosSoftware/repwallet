//
//  InstructionsView.m
//  repWallet
//
//  Created by Alberto Fiore on 10/15/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "InstructionsView.h"
#import "RepWalletAppDelegate.h"

@implementation InstructionsView

@synthesize text, 
//backBtn, fwdBtn, 
instructionsArray, actualPointer, leftSwipeReco, rightSwipeReco, delegate;

- (id)initWithInstrus:(NSArray *)instrArr andFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.instructionsArray = instrArr;
        
//        NSLog(@"array %@", self.instructionsArray);
        
        self.actualPointer = -1;
        
        [self setBackgroundColor:[UIColor colorWithRed:0.0 green:0.39 blue:0.5 alpha:0.8]];
        
        
//        self.backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect]; 
//        UIImage * backArr = [UIImage imageNamed:@"back_info_btn.png"];
//        self.backBtn.frame = CGRectMake(10, 25, backArr.size.width, backArr.size.height);
//        self.backBtn.hidden = NO;
//        [self.backBtn setImage:backArr forState:UIControlStateNormal];
//        [self.backBtn addTarget:self action:@selector(prevInstro) forControlEvents:UIControlEventTouchUpInside];
//        [self.backBtn setEnabled:NO];
//        [self addSubview:self.backBtn];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(
                                                                   //self.backBtn.frame.origin.x + self.backBtn.frame.size.width + 
                                                                   10, 
                                                                5, 
                                                                self.frame.size.width 
                                                                   - 2 * (
//                                                                          self.backBtn.frame.origin.x + self.backBtn.frame.size.width + 
                                                                          10), 
                                                                self.frame.size.height - 10)];
        
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        self.text = label;
        
        [label release];
        
        self.text.text = @"Instructions (swipe left to show)"
//        [[instrArr objectAtIndex:0] objectAtIndex:0]
        ;
        
        RepWalletAppDelegate * appDelegate = (RepWalletAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if([appDelegate isIpad]){
            
            self.text.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
            
        } else {
            
            self.text.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 2];
        }

        self.text.backgroundColor = [UIColor clearColor];
        self.text.textColor = [UIColor whiteColor];
        self.text.numberOfLines = 0;
        self.text.lineBreakMode = UILineBreakModeWordWrap;
        [self addSubview:self.text];
        
//        self.fwdBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect]; 
//        UIImage * fwdArr = [UIImage imageNamed:@"fwd_info_btn.png"];
//        self.fwdBtn.frame = CGRectMake(self.frame.size.width - fwdArr.size.width - 10, 25, fwdArr.size.width, fwdArr.size.height);
//        self.fwdBtn.hidden = NO;
//        [self.fwdBtn setImage:fwdArr forState:UIControlStateNormal];
//        [self.fwdBtn addTarget:self action:@selector(nextInstro) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:self.fwdBtn];
        
        UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextInstro)];
        leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        self.leftSwipeReco = leftSwipeGesture;
        [leftSwipeGesture release];
        [self addGestureRecognizer:self.leftSwipeReco];
        
        UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevInstro)];
        rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
        self.rightSwipeReco = rightSwipeGesture;
        [rightSwipeGesture release];
        [self addGestureRecognizer:self.rightSwipeReco];
        
    }
    return self;
}

-(void)prevInstro {
    
//    NSLog(@"prevInstro");
    
    if (self.actualPointer <= 0) {
        
        [self.rightSwipeReco setEnabled:NO];
        return;
        
    } else {
        
        self.actualPointer--;
        
        //    NSLog(@"actual pointer %i", self.actualPointer);
        
        self.text.text = [[self.instructionsArray objectAtIndex:self.actualPointer] objectForKey:@"text"];

//        if (self.delegate && [self.delegate respondsToSelector:@selector(instructionsViewChangedInstructionForLocationAtRouteIndex:)]) {
//            [self.delegate instructionsViewChangedInstructionForRoutingAtRouteIndex:[[[self.instructionsArray objectAtIndex:self.actualPointer] objectAtIndex:2] intValue]];
//        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(instructionsViewChangedInstructionForRoutingAtLocation:)]) {

            [self.delegate instructionsViewChangedInstructionForRoutingAtLocation:[[self.instructionsArray objectAtIndex:self.actualPointer] objectForKey:@"location"]];
        }
        
        if (self.actualPointer == [self.instructionsArray count] - 2) {
            [self.leftSwipeReco setEnabled:YES];
        }
    }
}

-(void)nextInstro {
    
//    NSLog(@"nextInstro");
    
    if (self.actualPointer == [self.instructionsArray count] - 1) {
        
        [self.leftSwipeReco setEnabled:NO];
        return;
        
    } else {
        
        self.actualPointer++;

//        NSLog(@"actual pointer %i", self.actualPointer);
        
        self.text.text = [[self.instructionsArray objectAtIndex:self.actualPointer] objectForKey:@"text"];
        
//        if (self.delegate && [self.delegate respondsToSelector:@selector(instructionsViewChangedInstructionForLocationAtRouteIndex:)]) {
//            [self.delegate instructionsViewChangedInstructionForLocationAtRouteIndex:[[[self.instructionsArray objectAtIndex:self.actualPointer] objectAtIndex:2] intValue]];
//        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(instructionsViewChangedInstructionForRoutingAtLocation:)]) {
            
            [self.delegate instructionsViewChangedInstructionForRoutingAtLocation:[[self.instructionsArray objectAtIndex:self.actualPointer] objectForKey:@"location"]];
        }
        
        if (self.actualPointer == 1) {
            [self.rightSwipeReco setEnabled:YES];
        }
    }
}
- (void)dealloc
{
    [self.leftSwipeReco release];
    [self.rightSwipeReco release];
    [self.text release];
//    [self.backBtn release];
//    [self.fwdBtn release];
    [self.instructionsArray release];
    [super dealloc];
}

@end
