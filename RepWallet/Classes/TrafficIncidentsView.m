//
//  TrafficIncidentsView.m
//  repWallet
//
//  Created by Alberto Fiore on 11/9/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "TrafficIncidentsView.h"
#import "RepWalletAppDelegate.h"

@implementation TrafficIncidentsView

@synthesize text, mapAnnotation, leftSwipeReco, rightSwipeReco, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8]];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 
                                                                   5, 
                                                                   self.frame.size.width - 20, 
                                                                   self.frame.size.height - 10)];
        
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        self.text = label;
        
        [label release];

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
        
        self.mapAnnotation = nil;
        
        UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextIncident)];
        leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        self.leftSwipeReco = leftSwipeGesture;
        [leftSwipeGesture release];
        [self addGestureRecognizer:self.leftSwipeReco];
        
        UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevIncident)];
        rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
        self.rightSwipeReco = rightSwipeGesture;
        [rightSwipeGesture release];
        [self addGestureRecognizer:self.rightSwipeReco];

    }
    return self;
}

-(void)setupMapAnnotation:(MapAnnotation *)mapAnnotation 
{
    self.mapAnnotation = mapAnnotation;
    self.text.text = [NSString stringWithFormat:@"%@: %@", mapAnnotation.calloutTitle, mapAnnotation.calloutSubtitle];
}

-(void)nextIncident {
    if (self.delegate && [self.delegate respondsToSelector:@selector(trafficIncidentsViewChangedIncidentForMarkerAtIndex:)]) {
        [self.delegate trafficIncidentsViewChangedIncidentForMarkerAtIndex:self.mapAnnotation.index - 1];
    }
}

-(void)prevIncident {
    if (self.delegate && [self.delegate respondsToSelector:@selector(trafficIncidentsViewChangedIncidentForMarkerAtIndex:)]) {
        [self.delegate trafficIncidentsViewChangedIncidentForMarkerAtIndex:self.mapAnnotation.index + 1];
    }
}

- (void)dealloc
{
    [self.mapAnnotation release];
    [self.text release];
    [super dealloc];
}

@end
